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
    // Hiệu suất / tiết kiệm điện
    property string powerProfile: "balanced"   // power-saver | balanced | performance
    property bool effectsEnabled: true          // animation + blur + shadow của Hyprland
    property bool powerSaverMode: false         // chế độ tiết kiệm điện tổng hợp
    property bool _prevGlass: true

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
            cur=none; [ $hp = 1 ] && cur=$(powerprofilesctl get 2>/dev/null)
            fx=1; hyprctl getoption animations:enabled 2>/dev/null | grep -q "int: 0" && fx=0
            echo "$w $a $s $n $hp $hn \${cur:-none} $fx"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split(/\s+/);
                if (p.length < 8)
                    return;
                root.wifiEnabled = p[0] === "1";
                root.airplane = p[1] === "1";
                root.batterySaver = p[2] === "1";
                root.nightLight = p[3] === "1";
                root.hasPowerProfiles = p[4] === "1";
                root.hasNightLight = p[5] === "1";
                if (p[6] !== "none")
                    root.powerProfile = p[6];
                root.effectsEnabled = p[7] === "1";
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

    // ---- Hiệu suất / tiết kiệm điện ----
    function setPowerProfile(profile) {
        powerProfile = profile;
        batterySaver = profile === "power-saver";
        _run(`powerprofilesctl set ${profile}`);
    }

    // Tắt/bật animation, blur, đổ bóng của Hyprland (chỉ có hiệu lực tới khi reload Hyprland).
    function setEffects(on) {
        effectsEnabled = on;
        const v = on ? 1 : 0;
        _run(`hyprctl --batch "keyword animations:enabled ${v} ; keyword decoration:blur:enabled ${v} ; keyword decoration:shadow:enabled ${v} ; keyword decoration:drop_shadow ${v}"`);
    }

    // Chế độ tiết kiệm điện: power-saver + tắt hiệu ứng + tắt Liquid Glass. Tắt chế độ sẽ khôi phục.
    function setPowerSaverMode(on) {
        if (on === powerSaverMode)
            return;
        powerSaverMode = on;
        if (on) {
            _prevGlass = GlassService.enabled;
            GlassService.setEnabled(false);
            setEffects(false);
            if (hasPowerProfiles)
                setPowerProfile("power-saver");
        } else {
            GlassService.setEnabled(_prevGlass);
            setEffects(true);
            if (hasPowerProfiles)
                setPowerProfile("balanced");
        }
    }
}
