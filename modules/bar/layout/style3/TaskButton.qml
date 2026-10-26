import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.components
import qs.services

// Nút kiểu taskbar Win11: nền sáng nhẹ khi hover, hơi tối khi nhấn, vạch nhỏ phía dưới khi panel đang mở
Rectangle {
    id: btn

    property string panelName: ""
    readonly property bool panelOpen: panelName !== "" && VisibleService.getPanelVisible(panelName)
    property color baseColor: "transparent"
    property color hoverColor: Qt.rgba(1, 1, 1, 0.12)
    signal activated
    default property alias content: holder.data

    implicitHeight: ScalerService.s(38)
    implicitWidth: holder.implicitWidth + ScalerService.s(16)
    radius: ScalerService.s(6)
    color: area.pressed ? Qt.rgba(1, 1, 1, 0.06) : ((area.containsMouse || panelOpen) ? hoverColor : baseColor)
    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    RowLayout {
        id: holder
        anchors.centerIn: parent
        spacing: ScalerService.s(8)
    }

    Rectangle {
        visible: btn.panelOpen
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: ScalerService.s(1)
        width: ScalerService.s(14)
        height: ScalerService.s(3)
        radius: height / 2
        color: theme.button.text
    }

    MouseArea {
        id: area
        anchors.fill: parent
        z: 10
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            console.log("[Win11Bar] click ->", btn.panelName);
            SoundService.playSound("pick");
            if (btn.panelName !== "")
                VisibleService.togglePanel(btn.panelName);
            btn.activated();
        }
    }
}
