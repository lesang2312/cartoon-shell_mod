// Network settings: live status, DNS profiles/custom DNS and network tools.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.commons
import qs.components
import "./network/" as Net
import "../wifi/" as WifiUI

Item {
  id: root

  property string dev: ""
  property string devType: ""
  property string conName: ""
  property string ip: ""
  property string gateway: ""
  property string mac: ""
  property string dnsList: ""
  property string connectivity: "unknown"
  property bool wifiRadio: true
  property int signal: 0
  property real rxSpeed: 0
  property real txSpeed: 0
  property real _lastRx: -1
  property real _lastTx: -1
  property real _lastT: 0
  property int pingMs: -1
  property bool pinging: false
  property bool dnsBusy: false
  property bool netBusy: false
  property bool customDnsVisible: false
  property string toast: ""

  readonly property bool online: dev !== "" && (connectivity === "full" || connectivity === "limited" || connectivity === "portal")
  readonly property bool hasLink: dev !== ""
  readonly property string statusText: {
    if (QuickSettingsService.airplane) return tr("airplane_active");
    if (!hasLink) return tr("disconnected");
    if (connectivity === "full") return tr("internet_connected");
    if (connectivity === "portal") return tr("captive_portal");
    if (connectivity === "limited") return tr("limited_connection");
    return tr("connected");
  }
  readonly property color statusColor: {
    if (!hasLink || QuickSettingsService.airplane) return theme.normal.red;
    if (connectivity === "full") return theme.normal.green;
    return theme.normal.yellow;
  }
  readonly property string heroIcon: {
    if (QuickSettingsService.airplane) return "flight";
    if (!hasLink) return "wifi_off";
    if (devType === "ethernet") return "lan";
    if (signal <= 40) return "network_wifi_1_bar";
    if (signal <= 70) return "network_wifi_3_bar";
    return "signal_wifi_4_bar";
  }

  readonly property var dnsPresets: [
    { id: "auto", key: "dns_auto", icon: "autorenew", servers: "" },
    { id: "google", key: "dns_google", icon: "public", servers: "8.8.8.8 8.8.4.4" },
    { id: "cloudflare", key: "dns_cloudflare", icon: "bolt", servers: "1.1.1.1 1.0.0.1" },
    { id: "adguard", key: "dns_adguard", icon: "shield", servers: "94.140.14.14 94.140.15.15" }
  ]

  function tr(key) { return LanguageService.t("network", key); }

  function fmtSpeed(bytesPerSecond) {
    var bits = Math.max(0, bytesPerSecond) * 8;
    if (bits >= 1e9) return { v: (bits / 1e9).toFixed(2), u: "Gbps" };
    if (bits >= 1e6) return { v: (bits / 1e6).toFixed(1), u: "Mbps" };
    if (bits >= 1e3) return { v: (bits / 1e3).toFixed(0), u: "Kbps" };
    return { v: Math.round(bits).toString(), u: "bps" };
  }

  function currentDnsId() {
    var current = dnsList.replace(/,/g, " ").trim();
    if (!current) return "auto";
    for (var i = 1; i < dnsPresets.length; i++) {
      var first = dnsPresets[i].servers.split(" ")[0];
      if (current.indexOf(first) === 0) return dnsPresets[i].id;
    }
    return "custom";
  }

  function showToast(message) {
    toast = message;
    toastTimer.restart();
  }

  function isIPv4(value) {
    var parts = String(value).trim().split(".");
    if (parts.length !== 4) return false;
    for (var i = 0; i < parts.length; i++) {
      if (!/^\d{1,3}$/.test(parts[i])) return false;
      var n = Number(parts[i]);
      if (n < 0 || n > 255) return false;
    }
    return true;
  }

  function refresh() {
    if (!infoProc.running) infoProc.running = true;
  }

  function runPing() {
    if (pingProc.running) return;
    pinging = true;
    pingMs = -1;
    pingProc.running = true;
  }

  // Pass arguments directly to nmcli; connection names and DNS values are not shell-interpolated.
  function applyDns(servers, automatic) {
    if (!hasLink || conName === "" || conName === "--" || dnsBusy) {
      showToast(tr("dns_need_connection"));
      return;
    }
    dnsBusy = true;
    dnsProc.command = automatic
      ? ["nmcli", "connection", "modify", conName, "ipv4.dns", "", "ipv4.ignore-auto-dns", "no"]
      : ["nmcli", "connection", "modify", conName, "ipv4.dns", servers, "ipv4.ignore-auto-dns", "yes"];
    dnsProc.running = true;
  }

  function applyCustomDns() {
    var first = dnsPrimaryField.text.trim();
    var second = dnsSecondaryField.text.trim();
    if (!isIPv4(first) || (second !== "" && !isIPv4(second))) {
      showToast(tr("dns_invalid"));
      return;
    }
    if (second === first) second = "";
    applyDns(second === "" ? first : first + " " + second, false);
  }

  function restartNetwork() {
    if (netBusy) return;
    netBusy = true;
    restartProc.running = true;
  }

  // Network snapshot. This runs only while the Network page is visible.
  Process {
    id: infoProc
    command: ["sh", "-c", `
dev=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
gw=$(ip route show default 2>/dev/null | awk '{print $3; exit}')
[ -z "$dev" ] && dev=$(nmcli -t -f DEVICE,STATE device 2>/dev/null | awk -F: '$2=="connected" && $1!="lo"{print $1; exit}')
echo "dev=$dev"
echo "gw=$gw"
if [ -n "$dev" ]; then
  echo "ip=$(ip -4 -o addr show dev "$dev" 2>/dev/null | awk '{print $4; exit}')"
  echo "mac=$(cat /sys/class/net/$dev/address 2>/dev/null)"
  echo "rx=$(cat /sys/class/net/$dev/statistics/rx_bytes 2>/dev/null)"
  echo "tx=$(cat /sys/class/net/$dev/statistics/tx_bytes 2>/dev/null)"
  echo "type=$(nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: -v d="$dev" '$1==d{print $2; exit}')"
  echo "con=$(nmcli -g GENERAL.CONNECTION device show "$dev" 2>/dev/null | head -n1)"
  echo "dns=$(nmcli -t -f IP4.DNS device show "$dev" 2>/dev/null | cut -d: -f2- | paste -sd, -)"
  echo "sig=$(nmcli -t -f ACTIVE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}')"
fi
echo "radio=$(nmcli radio wifi 2>/dev/null)"
echo "conn=$(nmcli networking connectivity 2>/dev/null)"
`]
    stdout: StdioCollector {
      onStreamFinished: {
        var values = {};
        (this.text || "").split("\n").forEach(function (line) {
          var splitAt = line.indexOf("=");
          if (splitAt > 0) values[line.substring(0, splitAt)] = line.substring(splitAt + 1).trim();
        });
        root.dev = values.dev || "";
        root.gateway = values.gw || "";
        root.ip = values.ip || "";
        root.mac = values.mac || "";
        root.devType = values.type || "";
        root.conName = values.con || "";
        root.dnsList = values.dns || "";
        root.signal = parseInt(values.sig) || 0;
        root.wifiRadio = values.radio === "enabled";
        root.connectivity = values.conn || "unknown";

        var rx = parseFloat(values.rx), tx = parseFloat(values.tx), now = Date.now();
        if (!isNaN(rx) && root._lastRx >= 0 && now > root._lastT) {
          var elapsed = (now - root._lastT) / 1000;
          root.rxSpeed = Math.max(0, (rx - root._lastRx) / elapsed);
          root.txSpeed = Math.max(0, (tx - root._lastTx) / elapsed);
        } else if (isNaN(rx) || isNaN(tx)) {
          root.rxSpeed = 0;
          root.txSpeed = 0;
        }
        root._lastRx = isNaN(rx) ? -1 : rx;
        root._lastTx = isNaN(tx) ? -1 : tx;
        root._lastT = now;
      }
    }
  }

  Process {
    id: pingProc
    command: ["ping", "-c", "3", "-W", "2", "1.1.1.1"]
    stdout: StdioCollector { id: pingOutput }
    onExited: function(exitCode) {
      root.pinging = false;
      var output = pingOutput.text || "";
      var match = output.match(/(?:rtt|round-trip).*?=\s*[\d.]+\/([\d.]+)\//);
      root.pingMs = exitCode === 0 && match ? Math.round(parseFloat(match[1])) : -2;
    }
  }

  Process {
    id: dnsProc
    onExited: function(exitCode) {
      if (exitCode === 0) {
        dnsUpProc.command = ["nmcli", "connection", "up", root.conName];
        dnsUpProc.running = true;
      } else {
        root.dnsBusy = false;
        root.showToast(root.tr("dns_failed"));
      }
    }
  }

  Process {
    id: dnsUpProc
    onExited: function(exitCode) {
      root.dnsBusy = false;
      if (exitCode === 0) {
        root.showToast(root.tr("dns_applied"));
        root.refresh();
      } else {
        root.showToast(root.tr("dns_reconnect_failed"));
      }
    }
  }

  Process {
    id: restartProc
    command: ["sh", "-c", "nmcli networking off && sleep 1 && nmcli networking on"]
    onExited: function(exitCode) {
      root.netBusy = false;
      if (exitCode === 0) {
        root.showToast(root.tr("network_restarted"));
        root.refresh();
        wifiMgr.scanWifiNetworks();
      } else {
        root.showToast(root.tr("network_restart_failed"));
      }
    }
  }

  Process {
    id: radioProc
    onExited: function(exitCode) {
      if (exitCode !== 0) root.showToast(root.tr("wifi_toggle_failed"));
      root.refresh();
      wifiMgr.checkWifiStatus();
      scanDelay.restart();
    }
  }

  Timer {
    id: scanDelay
    interval: 1500
    onTriggered: wifiMgr.scanWifiNetworks()
  }

  Process {
    id: editorProc
    command: ["sh", "-c", "nm-connection-editor || kitty -e nmtui"]
    onExited: function(exitCode) {
      if (exitCode !== 0) root.showToast(root.tr("editor_unavailable"));
    }
  }

  Timer {
    interval: 5000
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: toastTimer
    interval: 2600
    onTriggered: root.toast = ""
  }

  WifiService { id: wifiMgr }

  Component.onCompleted: {
    QuickSettingsService.refresh();
    wifiMgr.start();
    runPing();
  }
  Component.onDestruction: wifiMgr.stop()

  ScrollView {
    anchors.fill: parent
    anchors.margins: ScalerService.s(20)
    clip: true
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    ColumnLayout {
      width: parent.width
      spacing: ScalerService.s(12)

      CustomText {
        name: root.tr("title")
        size: "large"
        isBold: true
        Layout.topMargin: ScalerService.s(8)
      }

      Rectangle {
        Layout.fillWidth: true
        height: ScalerService.s(1)
        color: theme.primary.foreground
        opacity: 0.28
      }

      Net.NetCard {
        title: root.tr("connection_status")
        icon: "wifi_tethering"

        RowLayout {
          Layout.fillWidth: true
          spacing: ScalerService.s(12)
          Rectangle {
            Layout.preferredWidth: ScalerService.s(54)
            Layout.preferredHeight: ScalerService.s(54)
            radius: width / 2
            color: Qt.alpha(root.statusColor, 0.16)
            border.width: ScalerService.s(1)
            border.color: Qt.alpha(root.statusColor, 0.65)
            IconText {
              anchors.centerIn: parent
              name: root.heroIcon
              size: "normal"
              textColor: root.statusColor
            }
          }
          ColumnLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(3)
            CustomText {
              Layout.fillWidth: true
              name: root.hasLink ? (root.conName || root.dev) : root.tr("no_connection")
              size: "small"
              isBold: true
              elide: Text.ElideRight
            }
            CustomText {
              Layout.fillWidth: true
              name: root.statusText
              size: "xs"
              textColor: root.statusColor
              wrapMode: Text.WordWrap
            }
            CustomText {
              visible: root.hasLink
              name: (root.devType === "ethernet" ? "Ethernet" : "Wi-Fi") + (root.devType === "wifi" && root.signal > 0 ? " • " + root.signal + "%" : "") + (root.ip ? " • " + root.ip.split("/")[0] : "")
              size: "xs"
              textColor: theme.primary.dim_foreground
            }
          }
        }
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: ScalerService.s(8)
        rowSpacing: ScalerService.s(8)
        Net.StatTile { Layout.fillWidth: true; icon: "arrow_downward"; label: root.tr("download"); value: root.fmtSpeed(root.rxSpeed).v; unit: root.fmtSpeed(root.rxSpeed).u; accent: theme.normal.green }
        Net.StatTile { Layout.fillWidth: true; icon: "arrow_upward"; label: root.tr("upload"); value: root.fmtSpeed(root.txSpeed).v; unit: root.fmtSpeed(root.txSpeed).u; accent: theme.normal.blue }
        Net.StatTile { Layout.fillWidth: true; icon: "network_ping"; label: root.tr("latency"); value: root.pinging ? "…" : (root.pingMs >= 0 ? root.pingMs.toString() : (root.pingMs === -2 ? root.tr("error") : "--")); unit: root.pingMs >= 0 && !root.pinging ? "ms" : ""; accent: root.pingMs < 0 ? theme.primary.dim_foreground : (root.pingMs < 60 ? theme.normal.green : (root.pingMs < 150 ? theme.normal.yellow : theme.normal.red)) }
      }

      Net.NetCard {
        title: root.tr("quick_connection")
        icon: "toggle_on"
        RowLayout {
          Layout.fillWidth: true
          spacing: ScalerService.s(10)
          ColumnLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(2)
            CustomText { name: "Wi-Fi"; size: "small"; isBold: true }
            CustomText { Layout.fillWidth: true; name: root.wifiRadio ? root.tr("wifi_on_desc") : root.tr("wifi_off_desc"); size: "xs"; textColor: theme.primary.dim_foreground; wrapMode: Text.WordWrap }
          }
          CustomToggleSwitch {
            adapter: root.wifiRadio
            onClicked: {
              root.wifiRadio = !root.wifiRadio;
              radioProc.command = ["nmcli", "radio", "wifi", root.wifiRadio ? "on" : "off"];
              radioProc.running = true;
            }
          }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: theme.button.border; opacity: 0.4 }
        RowLayout {
          Layout.fillWidth: true
          spacing: ScalerService.s(10)
          ColumnLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(2)
            CustomText { name: root.tr("airplane_mode"); size: "small"; isBold: true }
            CustomText { Layout.fillWidth: true; name: root.tr("airplane_desc"); size: "xs"; textColor: theme.primary.dim_foreground; wrapMode: Text.WordWrap }
          }
          CustomToggleSwitch {
            adapter: QuickSettingsService.airplane
            onClicked: QuickSettingsService.toggleAirplane()
          }
        }
      }

      Net.NetCard {
        title: root.tr("wifi_networks") + " (" + wifiMgr.wifiList.length + ")"
        icon: "wifi"
        visible: root.wifiRadio
        headerRight: [
          Rectangle {
            width: ScalerService.s(32); height: ScalerService.s(32); radius: width / 2
            color: scanMa.containsMouse ? Qt.alpha(theme.button.background_select, 0.5) : "transparent"
            IconText {
              anchors.centerIn: parent
              name: "refresh"
              size: "xs"
              textColor: theme.button.text
              RotationAnimation on rotation { running: wifiMgr.isScanning; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
            }
            MouseArea { id: scanMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: wifiMgr.scanWifiNetworks() }
          }
        ]
        CustomText {
          visible: wifiMgr.wifiList.length === 0
          Layout.fillWidth: true
          name: wifiMgr.isScanning ? root.tr("scanning") : root.tr("no_wifi")
          size: "xs"
          textColor: theme.primary.dim_foreground
          horizontalAlignment: Text.AlignHCenter
          Layout.margins: ScalerService.s(8)
        }
        Repeater {
          model: wifiMgr.wifiList.slice(0, 8)
          delegate: WifiUI.WifiNetworkItem {
            required property var modelData
            Layout.fillWidth: true
            networkData: modelData
            wifiManager: wifiMgr
          }
        }
      }

      Net.NetCard {
        title: root.tr("dns_title")
        icon: "dns"
        CustomText {
          Layout.fillWidth: true
          name: root.hasLink ? root.tr("dns_for_connection") + " \"" + root.conName + "\" · " + root.tr("current_dns") + ": " + (root.dnsList ? root.dnsList.replace(/,/g, ", ") : root.tr("unknown")) : root.tr("dns_need_connection")
          size: "xs"
          textColor: theme.primary.dim_foreground
          wrapMode: Text.WordWrap
        }
        GridLayout {
          Layout.fillWidth: true
          columns: 2
          columnSpacing: ScalerService.s(8)
          rowSpacing: ScalerService.s(8)
          opacity: root.hasLink ? 1 : 0.42
          enabled: root.hasLink && !root.dnsBusy
          Repeater {
            model: root.dnsPresets
            delegate: Net.NetButton {
              required property var modelData
              icon: modelData.icon
              label: root.tr(modelData.key)
              active: root.currentDnsId() === modelData.id
              busy: root.dnsBusy
              onClicked: root.applyDns(modelData.servers, modelData.id === "auto")
            }
          }
        }
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: ScalerService.s(38)
          radius: ScalerService.s(10)
          color: root.customDnsVisible ? Qt.alpha(theme.button.background_select, 0.45) : Qt.alpha(theme.button.background, 0.24)
          border.width: ScalerService.s(1)
          border.color: root.customDnsVisible ? theme.button.border_select : theme.button.border
          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: ScalerService.s(10)
            anchors.rightMargin: ScalerService.s(10)
            IconText { name: "edit"; size: "xs"; textColor: theme.button.text }
            CustomText { Layout.fillWidth: true; name: root.tr("custom_dns"); size: "xs"; isBold: true }
            IconText { name: root.customDnsVisible ? "expand_less" : "expand_more"; size: "xs"; textColor: theme.button.text }
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.customDnsVisible = !root.customDnsVisible }
        }
        ColumnLayout {
          Layout.fillWidth: true
          spacing: ScalerService.s(8)
          visible: root.customDnsVisible
          CustomText { Layout.fillWidth: true; name: root.tr("custom_dns_hint"); size: "xs"; textColor: theme.primary.dim_foreground; wrapMode: Text.WordWrap }
          RowLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(8)
            TextField {
              id: dnsPrimaryField
              Layout.fillWidth: true
              enabled: !root.dnsBusy
              placeholderText: root.tr("dns_primary_placeholder")
              color: theme.primary.foreground
              selectionColor: theme.button.background_select
              font.family: Settings.appearance.font
              font.pixelSize: ScalerService.s(13)
              leftPadding: ScalerService.s(10); rightPadding: ScalerService.s(10)
              background: Rectangle { color: Qt.alpha(theme.primary.dim_background, 0.45); radius: ScalerService.s(9); border.width: ScalerService.s(1); border.color: dnsPrimaryField.activeFocus ? theme.button.border_select : theme.button.border }
            }
            TextField {
              id: dnsSecondaryField
              Layout.fillWidth: true
              enabled: !root.dnsBusy
              placeholderText: root.tr("dns_secondary_placeholder")
              color: theme.primary.foreground
              selectionColor: theme.button.background_select
              font.family: Settings.appearance.font
              font.pixelSize: ScalerService.s(13)
              leftPadding: ScalerService.s(10); rightPadding: ScalerService.s(10)
              background: Rectangle { color: Qt.alpha(theme.primary.dim_background, 0.45); radius: ScalerService.s(9); border.width: ScalerService.s(1); border.color: dnsSecondaryField.activeFocus ? theme.button.border_select : theme.button.border }
            }
          }
          Net.NetButton {
            Layout.fillWidth: true
            icon: "check_circle"
            label: root.tr("apply_custom_dns")
            busy: root.dnsBusy
            onClicked: root.applyCustomDns()
          }
        }
      }

      Net.NetCard {
        title: root.tr("connection_details")
        icon: "info"
        visible: root.hasLink
        Net.DetailRow { label: root.tr("interface"); value: root.dev + (root.devType ? " (" + root.devType + ")" : "") }
        Net.DetailRow { label: root.tr("ipv4_address"); value: root.ip }
        Net.DetailRow { label: root.tr("gateway"); value: root.gateway }
        Net.DetailRow { label: "DNS"; value: root.dnsList.replace(/,/g, ", ") }
        Net.DetailRow { label: root.tr("mac_address"); value: root.mac }
      }

      Net.NetCard {
        title: root.tr("network_tools")
        icon: "build"
        GridLayout {
          Layout.fillWidth: true
          columns: 2
          columnSpacing: ScalerService.s(8)
          rowSpacing: ScalerService.s(8)
          Net.NetButton { icon: "speed"; label: root.tr("ping_test"); busy: root.pinging; onClicked: root.runPing() }
          Net.NetButton {
            icon: "sync"
            label: root.tr("refresh")
            onClicked: { root.refresh(); wifiMgr.scanWifiNetworks(); root.runPing(); }
          }
          Net.NetButton { icon: "restart_alt"; label: root.tr("restart_network"); busy: root.netBusy; onClicked: root.restartNetwork() }
          Net.NetButton { icon: "settings_ethernet"; label: root.tr("connection_editor"); onClicked: editorProc.running = true }
        }
      }

      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        visible: root.toast !== ""
        implicitWidth: toastText.implicitWidth + ScalerService.s(24)
        implicitHeight: ScalerService.s(32)
        radius: height / 2
        color: Qt.alpha(root.toast.indexOf("✓") === 0 ? theme.normal.green : theme.normal.red, 0.20)
        border.width: ScalerService.s(1)
        border.color: root.toast.indexOf("✓") === 0 ? theme.normal.green : theme.normal.red
        CustomText { id: toastText; anchors.centerIn: parent; name: root.toast; size: "xs" }
      }
      Item { Layout.preferredHeight: ScalerService.s(8) }
    }
  }
}
