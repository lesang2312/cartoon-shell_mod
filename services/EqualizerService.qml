pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons

// Trạng thái + điều khiển Equalizer 10 băng tần. Backend: scripts/eq.py (PipeWire filter-chain).
Singleton {
    id: root

    readonly property var freqLabels: ["31", "63", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    readonly property var presetNames: ["Flat", "Bass", "Treble", "Vocal", "Pop", "Rock", "Jazz", "Classic"]
    readonly property var presets: ({
            "Flat": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            "Bass": [7, 6, 5, 3, 1, 0, 0, 0, 0, 0],
            "Treble": [0, 0, 0, 0, 0, 1, 3, 5, 6, 7],
            "Vocal": [-2, -2, -1, 1, 3, 4, 4, 2, 0, -1],
            "Pop": [-1, 2, 4, 5, 3, 0, -1, -1, 2, 3],
            "Rock": [5, 4, 2, -1, -2, -1, 2, 4, 5, 5],
            "Jazz": [3, 2, 1, 2, -2, -2, 0, 1, 2, 3],
            "Classic": [0, 0, 0, 0, 0, 0, -3, -3, -3, -5]
        })

    property var bands: parseBands(Settings.audio.eqBands)
    property string preset: Settings.audio.eqPreset
    property bool enabled: Settings.audio.eqEnabled
    property bool justSaved: false
    property string lastError: ""

    function parseBands(str) {
        const a = String(str).split(",").map(x => parseFloat(x));
        const out = [];
        for (let i = 0; i < 10; i++)
            out.push(isNaN(a[i]) ? 0 : Math.max(-12, Math.min(12, a[i])));
        return out;
    }

    function setPreset(name) {
        if (!presets[name])
            return;
        bands = presets[name].slice();
        preset = name;
        commit();
    }

    // Trả về tên preset trùng với bộ gain hiện tại, hoặc "Custom".
    function detectPreset(b) {
        for (let n = 0; n < presetNames.length; n++) {
            const p = presets[presetNames[n]];
            let same = true;
            for (let i = 0; i < 10; i++) {
                if (Math.abs(p[i] - b[i]) > 0.01) {
                    same = false;
                    break;
                }
            }
            if (same)
                return presetNames[n];
        }
        return "Custom";
    }

    function setBand(index, value) {
        const b = bands.slice();
        b[index] = Math.max(-12, Math.min(12, Math.round(value * 2) / 2));
        bands = b;
        preset = detectPreset(b);
        commit();
    }

    function setEnabled(v) {
        Settings.audio.eqEnabled = v;
        commit();
    }

    function commit() {
        Settings.audio.eqBands = bands.join(",");
        Settings.audio.eqPreset = preset;
        applyTimer.restart();
    }

    Timer {
        id: applyTimer
        interval: 300
        onTriggered: root.runApply()
    }

    // eq.py đang chạy mà có thay đổi mới => đợi chạy xong rồi áp dụng lại (trước đây lệnh mới bị bỏ rơi).
    property bool pendingApply: false
    function runApply() {
        if (runner.running) {
            pendingApply = true;
            return;
        }
        runner.command = ["python3", Quickshell.shellDir + "/scripts/eq.py", "apply", Settings.audio.eqEnabled ? "1" : "0"].concat(root.bands.map(g => String(g)));
        runner.running = true;
    }

    Process {
        id: runner
        stdout: StdioCollector {
            id: out
        }
        onExited: code => {
            if (root.pendingApply) {
                root.pendingApply = false;
                root.runApply();
                return;
            }
            root.lastError = code === 0 ? "" : (out.text.trim() || "eq.py failed");
            if (code === 0) {
                root.justSaved = true;
                savedTimer.restart();
            }
        }
    }

    Timer {
        id: savedTimer
        interval: 1800
        onTriggered: root.justSaved = false
    }
}
