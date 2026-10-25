import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var listAppCpu: []

    Process {
        id: cpuProcess

        // Mẫu 1 giây từ /proc (xem scripts/cpu_top.sh) thay cho `ps pcpu` (trung bình trọn đời, tự liệt kê chính nó)
        command: ["bash", Quickshell.shellDir + "/scripts/cpu_top.sh"]

        running: false

        stdout: StdioCollector {
            onTextChanged: {
                try {
                    const data = JSON.parse(text.trim());

                    if (Array.isArray(data))
                        root.listAppCpu = data;
                } catch (e) {
                    console.log("Parse CPU process error:", e);
                }
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.visible
        triggeredOnStart: true

        onTriggered: {
            if (!cpuProcess.running)
                cpuProcess.running = true;
        }
    }
}