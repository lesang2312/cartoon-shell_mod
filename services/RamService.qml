pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Keep this property for compatibility with existing panels. Both modes now use
    // the same reliable /proc/meminfo parser; the displayed values stay consistent.
    property bool useSimpleCalculation: true
    property int memPercent: 0
    property int memUsed: 0
    property int memTotal: 0
    property int memFree: 0
    property int buffers: 0
    property int cached: 0
    property int shmem: 0
    property int swapTotal: 0
    property int swapFree: 0
    property int swapUsed: 0
    property int swapPercent: 0

    Process {
        id: meminfoProcess
        command: ["cat", "/proc/meminfo"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const values = ({});
                const lines = text.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const match = lines[i].match(/^([A-Za-z_()]+):\s+(\d+)/);
                    if (match)
                        values[match[1]] = Number(match[2]);
                }

                const total = Number(values.MemTotal || 0);
                const available = Number(values.MemAvailable !== undefined
                    ? values.MemAvailable
                    : ((values.MemFree || 0) + (values.Buffers || 0) + (values.Cached || 0)
                       + (values.SReclaimable || 0) - (values.Shmem || 0)));
                if (total <= 0)
                    return;

                const safeAvailable = Math.max(0, Math.min(total, available));
                const used = Math.max(0, total - safeAvailable);
                root.memTotal = Math.round(total / 1024);
                root.memUsed = Math.round(used / 1024);
                root.memFree = Math.round(Number(values.MemFree || 0) / 1024);
                root.buffers = Math.round(Number(values.Buffers || 0) / 1024);
                root.cached = Math.round(Number(values.Cached || 0) / 1024);
                root.shmem = Math.round(Number(values.Shmem || 0) / 1024);
                root.memPercent = Math.max(0, Math.min(100, Math.round(100 * used / total)));

                const swapTotalKb = Number(values.SwapTotal || 0);
                const swapFreeKb = Number(values.SwapFree || 0);
                root.swapTotal = Math.round(swapTotalKb / 1024);
                root.swapFree = Math.round(swapFreeKb / 1024);
                root.swapUsed = Math.max(0, root.swapTotal - root.swapFree);
                root.swapPercent = swapTotalKb > 0
                    ? Math.max(0, Math.min(100, Math.round(100 * (swapTotalKb - swapFreeKb) / swapTotalKb)))
                    : 0;
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.visible && (!root.parent || (root.parent.visible && root.parent.width > 0 && root.parent.height > 0))
        triggeredOnStart: true
        onTriggered: {
            if (!meminfoProcess.running)
                meminfoProcess.running = true;
        }
    }
}
