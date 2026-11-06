import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.commons
import qs.services

// Góc nóng: rê chuột vào một góc màn hình (giữ ~0.2 giây để tránh chạm nhầm) => mở/đóng launcher.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        readonly property string pos: Settings.behavior.hotCornerPos

        screen: modelData
        visible: Settings.behavior.hotCorner
        color: "transparent"
        implicitWidth: 6
        implicitHeight: 6
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "cartoon-hot-corner"

        anchors {
            top: win.pos.indexOf("top") === 0
            bottom: win.pos.indexOf("bottom") === 0
            left: win.pos.slice(-4) === "left"
            right: win.pos.slice(-5) === "right"
        }

        HoverHandler {
            id: hover
        }
        Timer {
            interval: 200
            running: hover.hovered
            onTriggered: VisibleService.togglePanel("launcher")
        }
    }
}
