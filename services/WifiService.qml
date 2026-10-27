import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: wifiManager

    property var wifiList: []
    property bool wifiEnabled: true
    property string connectedWifi: ""
    property bool isScanning: false
    property string openSsid: ""     // SSID đang mở hộp mật khẩu
    property bool userTyping: false  // true khi đang nhập password
    property bool enabled: false
    property string connectionError: ""  // Lỗi kết nối
    property string currentPassword: ""  // Mật khẩu hiện tại đang được lấy
    property string requestedSsid: ""    // SSID đang yêu cầu lấy password

    // =============================
    //   WIFI PROCESS HANDLERS
    // =============================
    Process {
        id: getPasswordProcess
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    wifiManager.currentPassword = this.text.trim();
                } else {
                    wifiManager.currentPassword = "";
                }
            }
        }
    }
    Process {
        id: wifiToggleProcess
        onRunningChanged: if (!running) {
            checkWifiStatus();
            if (wifiEnabled)
                scanWifiNetworks();
        }
    }

    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    wifiManager.wifiEnabled = (this.text.trim() === "enabled");
                }
            }
        }
    }

    Process {
        id: wifiScanProcess

        command: ["bash", "-c", `
# Tab-separated output: IN-USE, SIGNAL, SECURITY, SSID, SAVED_PASSWORD ("--" if none)
saved=$(nmcli -t --escape no -f NAME,TYPE connection show 2>/dev/null | sed -n 's/:802-11-wireless$//p')
declare -A cache
nmcli -t --escape no -f IN-USE,SIGNAL,SECURITY,SSID device wifi list 2>/dev/null | while IFS= read -r line; do
  inuse=\${line%%:*}; rest=\${line#*:}
  signal=\${rest%%:*}; rest=\${rest#*:}
  sec=\${rest%%:*};    ssid=\${rest#*:}
  [ -z "$ssid" ] && continue
  if [ -z "\${cache[$ssid]+x}" ]; then
    pass="--"
    if printf '%s\n' "$saved" | grep -Fxq -- "$ssid"; then
      p=$(nmcli -s -g 802-11-wireless-security.psk connection show "$ssid" 2>/dev/null)
      [ -n "$p" ] && pass=$p
    fi
    cache[$ssid]=$pass
  fi
  printf '%s\t%s\t%s\t%s\t%s\n' "\${inuse// /}" "$signal" "\${sec:-Open}" "$ssid" "\${cache[$ssid]}"
done
`]

        stdout: StdioCollector {
            onStreamFinished: {
                parseWifiList(this.text || "");
                wifiManager.isScanning = false;
            }
        }
    }

    Process {
        id: wifiConnectProcess
        stdout: SplitParser {
            splitMarker: "\n"
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.includes("Error")) {
                    wifiManager.connectionError = "Mật khẩu không đúng hoặc không thể kết nối";
                    forgetPassword(wifiManager.requestedSsid);
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                Qt.callLater(function () {
                    checkConnectedWifi();
                    scanWifiNetworks();
                });
            }
        }
    }

    Process {
        id: connectedWifiProcess
        command: ["nmcli", "-t", "--escape", "no", "-f", "ACTIVE,SSID", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = (this.text || "").trim().split('\n');
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].startsWith("yes:")) {
                        wifiManager.connectedWifi = lines[i].substring(4);
                        return;
                    }
                }
                wifiManager.connectedWifi = "";
            }
        }
    }

    // =============================
    //   WIFI FUNCTIONS
    // =============================
    function checkWifiStatus() {
        if (!wifiStatusProcess.running)
            wifiStatusProcess.running = true;
    }

    function scanWifiNetworks() {
        if (wifiManager.wifiEnabled && !wifiScanProcess.running) {
            wifiManager.isScanning = true;
            wifiScanProcess.running = true;
        }
    }

    function toggleWifi() {
        var cmd = wifiManager.wifiEnabled ? "off" : "on";
        wifiToggleProcess.command = ["nmcli", "radio", "wifi", cmd];
        wifiToggleProcess.running = true;
    }

    function connectToWifi(ssid, password) {
        wifiManager.connectionError = "";
        wifiManager.requestedSsid = ssid;

        if (password) {
            wifiConnectProcess.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password];
        } else {
            wifiConnectProcess.command = ["nmcli", "device", "wifi", "connect", ssid];
        }
        wifiConnectProcess.running = true;
    }

    function getSavedPassword(ssid) {
        // Lấy mật khẩu từ NetworkManager
        wifiManager.requestedSsid = ssid;
        getPasswordProcess.command = ["nmcli", "-s", "-g", "802-11-wireless-security.psk", "connection", "show", ssid];
        getPasswordProcess.running = true;

        // Trả về mật khẩu hiện tại (có thể rỗng nếu đang loading)
        return wifiManager.currentPassword;
    }

    function forgetPassword(ssid) {
        var forgetProcess = Qt.createQmlObject('import Quickshell.Io; Process {}', wifiManager);
        forgetProcess.command = ["nmcli", "connection", "delete", ssid];
        forgetProcess.running = true;
    }

    function disconnectWifi() {
        wifiConnectProcess.command = ["nmcli", "device", "disconnect"];
        wifiConnectProcess.running = true;
        wifiManager.connectedWifi = "";
    }

    function checkConnectedWifi() {
        if (!connectedWifiProcess.running)
            connectedWifiProcess.running = true;
    }

    function parseWifiList(text) {
        var lines = text.split('\n');
        var networksMap = {};

        for (var i = 0; i < lines.length; i++) {
            if (!lines[i].trim())
                continue;
            var parts = lines[i].split('\t');
            if (parts.length < 4)
                continue;
            var inUse = parts[0] === "*";
            var signal = parseInt(parts[1]) || 0;
            var security = parts[2] || "Open";
            var ssid = parts[3];
            var savedPassword = parts.length >= 5 ? parts[4] : "--";
            if (!ssid)
                continue;
            var existing = networksMap[ssid];
            if (!existing || signal > existing.signal || inUse) {
                networksMap[ssid] = {
                    ssid: ssid,
                    signal: signal,
                    security: security,
                    isConnected: inUse || (existing ? existing.isConnected : false) || ssid === wifiManager.connectedWifi,
                    saved_password: savedPassword
                };
            }
        }

        wifiManager.wifiList = Object.values(networksMap).sort((a, b) => b.signal - a.signal);
    }

    // =============================
    //   AUTO REFRESH
    // =============================
    Component.onCompleted: {
        if (wifiManager.userTyping) {
            return;
        }
        checkWifiStatus();
        checkConnectedWifi();
        if (wifiManager.wifiEnabled)
            scanWifiNetworks();
    }
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            if (wifiManager.userTyping) {
                return;
            }
            checkWifiStatus();
            checkConnectedWifi();
            if (wifiManager.wifiEnabled)
                scanWifiNetworks();
        }
    }

    // Hàm khởi động manager
    function start() {
        enabled = true;
        checkWifiStatus();
        checkConnectedWifi();
        if (wifiManager.wifiEnabled)
            scanWifiNetworks();
    }

    // Hàm dừng manager
    function stop() {
        enabled = false;

        wifiStatusProcess.running = false;
        wifiScanProcess.running = false;
        wifiConnectProcess.running = false;
        connectedWifiProcess.running = false;
        wifiToggleProcess.running = false;

        isScanning = false;
        userTyping = false;
        openSsid = "";
    }
}
