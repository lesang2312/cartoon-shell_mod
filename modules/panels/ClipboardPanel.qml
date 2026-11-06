import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.commons
import qs.services
import "./" as C

// Cửa sổ lịch sử clipboard. Bấm ra ngoài hoặc Esc để đóng.
PanelWindow {
    id: win

    visible: ClipboardService.open
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "cartoon-clipboard"

    // Lớp phủ toàn màn hình chỉ để bắt click bên ngoài; thẻ được đặt riêng ở góc trên-phải.
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: ClipboardService.close()

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: ClipboardService.open ? 0.22 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }
    }

    C.ClipboardCard {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: ScalerService.s(56)
            rightMargin: ScalerService.s(72)
        }
        width: Math.min(ScalerService.s(400), Math.max(ScalerService.s(240), parent.width - ScalerService.s(104)))
        height: Math.min(ScalerService.s(520), Math.max(ScalerService.s(320), parent.height - ScalerService.s(112)))
        open: ClipboardService.open
        onCloseRequested: ClipboardService.close()
    }
}
