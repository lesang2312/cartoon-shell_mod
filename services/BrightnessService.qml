pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real currentBrightness: 0.5
    property bool shouldShowOsd: false

    // Dùng thang tuyến tính (không -e4) để khớp với cách đọc lại giá trị (current/max).
    function changeBright(delta) {
        brightnessProcess.command = ["sh", "-c", `
          brightnessctl -n2 set ${delta > 0 ? "5%+" : "5%-"}
          qs ipc --path "${Quickshell.shellDir}" \
              call brightness set \
              "$(awk "BEGIN {print $(brightnessctl g)/$(brightnessctl m)}")"
          `];

        brightnessProcess.running = true;
    }

    // Gộp các lần kéo thanh trượt: chỉ giữ giá trị mới nhất, không spawn tiến trình chồng nhau.
    property real _pending: -1
    function setBright(value) {
        currentBrightness = value;
        shouldShowOsd = true;
        hideTimer.restart();
        _pending = value;
        if (!brightnessProcess.running)
            _flush();
    }
    function _flush() {
        if (_pending < 0)
            return;
        const v = _pending;
        _pending = -1;
        brightnessProcess.command = ["brightnessctl", "-n2", "set", Math.round(v * 100) + "%"];
        brightnessProcess.running = true;
    }

    Process {
        id: brightnessProcess
        running: false

        onExited: {
            if (root._pending >= 0)
                root._flush();
            else
                getBrightProcess.running = true;
        }
    }

    Component.onCompleted: {
        Qt.callLater(init);
    }

    function init() {
        getBrightProcess.running = true;
    }

    Process {
        id: getBrightProcess
        running: false

        command: ["bash", "-c", "awk \"BEGIN {print $(brightnessctl g)/$(brightnessctl m)}\""]

        stdout: StdioCollector {
            onTextChanged: {
                const value = parseFloat(text.trim());
                if (!isNaN(value)) {
                    root.currentBrightness = value;
                }
            }
        }
    }

    IpcHandler {
        target: "brightness"

        function set(value: real) {
            root.shouldShowOsd = true;
            root.currentBrightness = value;
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.shouldShowOsd = false
    }
}
