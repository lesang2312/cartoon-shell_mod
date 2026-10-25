pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int diskPercents: 0
    property int consumers: 0

    function acquire() {
        consumers = Math.max(0, consumers) + 1;
    }

    function release() {
        consumers = Math.max(0, consumers - 1);
        if (consumers === 0 && diskProcess.running)
            diskProcess.running = false;
    }

    Process {
        id: diskProcess
        running: false
        command: ["df", "-P", "/"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length < 2)
                    return;
                const match = lines[1].trim().split(/\s+/);
                if (match.length >= 5) {
                    const value = Number(String(match[4]).replace("%", ""));
                    if (Number.isFinite(value))
                        root.diskPercents = Math.max(0, Math.min(100, Math.round(value)));
                }
            }
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: root.consumers > 0
        triggeredOnStart: true
        onTriggered: {
            if (root.consumers > 0 && !diskProcess.running)
                diskProcess.running = true;
        }
    }
}
