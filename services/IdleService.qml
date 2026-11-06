pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.commons
import qs.services

// Tự khóa / tự ngủ khi không thao tác (ext-idle-notify của Wayland qua IdleMonitor).
// "Giữ máy thức" tắt cả hai bộ đếm. Cài đặt: Settings -> General -> Behavior.
Singleton {
    id: root

    readonly property bool keepAwake: Settings.behavior.keepAwake

    // gọi từ shell.qml để singleton được khởi tạo
    function init() {
    }

    IdleMonitor {
        enabled: !root.keepAwake && Settings.behavior.lockAfterMin > 0
        timeout: Math.max(1, Settings.behavior.lockAfterMin * 60)
        onIsIdleChanged: if (isIdle)
            CompositorService.lock()
    }

    IdleMonitor {
        enabled: !root.keepAwake && Settings.behavior.suspendAfterMin > 0
        timeout: Math.max(1, Settings.behavior.suspendAfterMin * 60)
        onIsIdleChanged: if (isIdle) {
            CompositorService.lock();
            CompositorService.suspend();
        }
    }

    // Tắt màn hình khi rảnh; có thao tác thì bật lại (Settings -> General -> Session)
    IdleMonitor {
        enabled: !root.keepAwake && Settings.behavior.monitorOffAfterMin > 0
        timeout: Math.max(1, Settings.behavior.monitorOffAfterMin * 60)
        onIsIdleChanged: if (isIdle)
            CompositorService.monitorsOff()
        else
            CompositorService.monitorsOn()
    }
}
