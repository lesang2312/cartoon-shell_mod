pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Trạng thái + hành động cho Win11 Quick Settings: Wi-Fi, Airplane, Battery saver, Night light
Singleton {
    id: root

    property bool wifiEnabled: true
    property bool airplane: false
    property bool batterySaver: false
    property bool nightLight: false
    property bool hasPowerProfiles: true
    property bool hasNightLight: true

    // ---- Đọc trạng thái (chỉ chạy khi panel đang mở) ----
    function refresh() {
        if (!stateProc.running)
            stateProc.running = true;
    }

    Process {
        id: stateProc
        command: ["sh", "-c", `
            w=$(nmcli radio wifi 2>/dev/null); [ "$w" = disabled ] && w=0 || w=1
            a=0; if command -v rfkill >/dev/null 2>&1; then rfkill list 2>/dev/null | grep -q "Soft blocked: no" || a=1; fi
            hp=0; s=0; if command -v powerprofilesctl >/dev/null 2>&1; then hp=1; [ "$(powerprofilesctl get 2>/dev/null)" = power-saver ] && s=1; fi
            hn=0; n=0
            for t in hyprsunset wlsunset gammastep; do command -v $t >/dev/null 2>&1 && hn=1; pgrep -x $t >/dev/null 2>&1 && n=1; done
            echo "$w $a $s $n $hp $hn"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split(/\s+/);
                if (p.length < 6)
                    return;
                root.wifiEnabled = p[0] === "1";
                root.airplane = p[1] === "1";
                root.batterySaver = p[2] === "1";
                root.nightLight = p[3] === "1";
                root.hasPowerProfiles = p[4] === "1";
                root.hasNightLight = p[5] === "1";
            }
        }
    }

    Timer {
        interval: 2500
        repeat: true
        running: VisibleService.quickSettings
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // ---- Hành động ----
    Process {
        id: actionProc
        onExited: {
            NetworkService.updateWifi();
            root.refresh();
        }
    }
    function _run(cmd) {
        actionProc.command = ["sh", "-c", cmd];
        actionProc.running = true;
    }

    function toggleWifi() {
        wifiEnabled = !wifiEnabled; // cập nhật ngay, lần refresh sau sẽ đồng bộ lại
        _run(`nmcli radio wifi ${wifiEnabled ? "on" : "off"}`);
    }

    function toggleAirplane() {
        airplane = !airplane;
        _run(airplane ? "rfkill block all" : "rfkill unblock all");
    }

    function toggleBatterySaver() {
        batterySaver = !batterySaver;
        _run(`powerprofilesctl set ${batterySaver ? "power-saver" : "balanced"}`);
    }

    function toggleNightLight() {
        nightLight = !nightLight;
        _run(nightLight ? `
            if command -v hyprsunset >/dev/null 2>&1; then nohup hyprsunset -t 4000 >/dev/null 2>&1 &
            elif command -v wlsunset >/dev/null 2>&1; then nohup wlsunset -t 4000 -T 6500 >/dev/null 2>&1 &
            elif command -v gammastep >/dev/null 2>&1; then nohup gammastep -O 4000 >/dev/null 2>&1 &
            fi` : "pkill -x hyprsunset; pkill -x wlsunset; pkill -x gammastep; true");
    }
}
