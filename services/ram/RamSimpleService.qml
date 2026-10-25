pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int ramPercent: 0
    property var ramHistory: []
    property int maxHistoryLength: 50

    Process {
        id: ramProcess
        command: ["cat", "/proc/meminfo"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let total = 0;
                let available = -1;
                const lines = text.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const match = lines[i].match(/^(MemTotal|MemAvailable):\s+(\d+)/);
                    if (!match)
                        continue;
                    const value = Number(match[2]);
                    if (match[1] === "MemTotal") total = value;
                    else if (match[1] === "MemAvailable") available = value;
                }
                if (total <= 0 || available < 0)
                    return;

                const usedPercent = Math.max(0, Math.min(100,
                    100 * (total - Math.min(total, available)) / total));
                root.ramPercent = Math.round(usedPercent);
                const history = root.ramHistory.slice();
                history.push({ usage: usedPercent });
                if (history.length > root.maxHistoryLength)
                    history.shift();
                root.ramHistory = history;
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!ramProcess.running)
                ramProcess.running = true;
        }
    }
}
