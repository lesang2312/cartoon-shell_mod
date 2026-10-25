pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int cpuPercent: 0
    property var cpuHistory: []
    property int maxHistoryLength: 50
    property double previousTotal: -1
    property double previousIdle: -1

    // Read /proc/stat directly; avoid an awk/vmstat child process for every sample.
    Process {
        id: cpuProcess
        command: ["cat", "/proc/stat"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const firstLine = text.split("\n", 1)[0].trim();
                const fields = firstLine.split(/\s+/);
                if (fields.length < 5 || fields[0] !== "cpu")
                    return;

                // Linux counters: user nice system idle iowait irq softirq steal.
                // Exclude guest/guest_nice because they are already included in user/nice.
                const counters = fields.slice(1, 9).map(Number);
                if (counters.length < 8 || counters.some(v => !Number.isFinite(v)))
                    return;

                const total = counters.reduce((sum, v) => sum + v, 0);
                const idle = counters[3] + counters[4];

                if (root.previousTotal >= 0 && root.previousIdle >= 0) {
                    const totalDelta = total - root.previousTotal;
                    const idleDelta = idle - root.previousIdle;
                    if (totalDelta > 0) {
                        const value = Math.max(0, Math.min(100,
                            100 * (totalDelta - idleDelta) / totalDelta));
                        root.cpuPercent = Math.round(value);

                        const history = root.cpuHistory.slice();
                        history.push({ usage: value });
                        if (history.length > root.maxHistoryLength)
                            history.shift();
                        root.cpuHistory = history;
                    }
                }

                root.previousTotal = total;
                root.previousIdle = idle;
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!cpuProcess.running)
                cpuProcess.running = true;
        }
    }
}
