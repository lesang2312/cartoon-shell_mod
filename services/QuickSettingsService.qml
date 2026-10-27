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

    // Profile nguồn hiện tại: "power-saver" | "balanced" | "performance"
    property string powerProfile: "balanced"
    // Hiệu ứng Hyprland (animation/blur/đổ bóng)
    property bool effectsEnabled: true
    // Chế độ tiết kiệm điện tổng hợp (profile + effects + Liquid Glass)
    property bool powerSaverMode: false
    property string _prevProfile: "balanced"
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
            pp=balanced; [ $hp = 1 ] && pp=$(powerprofilesctl get 2>/dev/null)
            ef=1; if command -v hyprctl >/dev/null 2>&1; then hyprctl getoption animations:enabled -j 2>/dev/null | grep -Eq '"int": *0' && ef=0; fi
            echo "$w $a $s $n $hp $hn \${pp:-balanced} $ef"
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
                if (p.length >= 8) {
                    root.powerProfile = p[6];
                    root.effectsEnabled = p[7] === "1";
                }
                // Người dùng đổi profile thủ công -> không còn ở chế độ tiết kiệm tổng hợp
                if (root.powerSaverMode && root.hasPowerProfiles && root.powerProfile !== "power-saver")
                    root.powerSaverMode = false;
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
    property var _queue: []
    Process {
        id: actionProc
        onExited: {
            NetworkService.updateWifi();
            root.refresh();
            if (root._queue.length > 0) {
                const next = root._queue.shift();
                actionProc.command = ["sh", "-c", next];
                actionProc.running = true;
            }
        }
    }
    function _run(cmd) {
        if (actionProc.running) {
            _queue.push(cmd);
            return;
        }
        actionProc.command = ["sh", "-c", cmd];
        actionProc.running = true;
    }

    // Tắt: animation/blur/đổ bóng. Bật: reload để nạp lại đúng cấu hình của người dùng.
    function _effectsCmd(on) {
        return on ? "hyprctl reload" : "hyprctl --batch 'keyword animations:enabled 0 ; keyword decoration:blur:enabled 0 ; keyword decoration:shadow:enabled 0 ; keyword decoration:drop_shadow 0'";
    }

    function setPowerProfile(id) {
        if (!hasPowerProfiles || ["power-saver", "balanced", "performance"].indexOf(id) < 0)
            return;
        powerProfile = id;
        batterySaver = id === "power-saver";
        if (powerSaverMode && id !== "power-saver")
            powerSaverMode = false;
        _run(`powerprofilesctl set ${id}`);
    }

    function setEffects(on) {
        effectsEnabled = on;
        _run(_effectsCmd(on));
    }

    function setPowerSaverMode(on) {
        if (on === powerSaverMode)
            return;
        const cmds = [];
        if (on) {
            _prevProfile = powerProfile === "power-saver" ? "balanced" : powerProfile;
            _prevGlass = GlassService.enabled;
            if (hasPowerProfiles) {
                powerProfile = "power-saver";
                batterySaver = true;
                cmds.push("powerprofilesctl set power-saver");
            }
            effectsEnabled = false;
            cmds.push(_effectsCmd(false));
            GlassService.setEnabled(false);
        } else {
            if (hasPowerProfiles) {
                powerProfile = _prevProfile;
                batterySaver = false;
                cmds.push(`powerprofilesctl set ${_prevProfile}`);
            }
            effectsEnabled = true;
            cmds.push(_effectsCmd(true));
            GlassService.setEnabled(_prevGlass);
        }
        powerSaverMode = on;
        _run(cmds.join("; ") + "; true");
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
