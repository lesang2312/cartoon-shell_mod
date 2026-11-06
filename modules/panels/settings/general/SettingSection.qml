import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons

// Thẻ nhóm dùng chung cho các tab Settings -> General (Session / Notifications / Privacy).
// Tiêu đề nhóm + các dòng cài đặt; tự hiện dần sau appearAt (0..1 ~ 500ms).
Rectangle {
    id: sec

    property var theme: ThemeService.theme
    property string title: ""
    property real appearAt: 0.3
    property bool shown: false
    readonly property color accent: theme.button.text
    readonly property color accent2: Qt.hsla((Math.max(0, accent.hslHue) + 0.09) % 1, accent.hslSaturation, Math.max(0.52, Math.min(0.78, accent.hslLightness)), 1)
    default property alias content: body.data

    Layout.fillWidth: true
    implicitHeight: body.implicitHeight + ScalerService.s(36) + head.implicitHeight + ScalerService.s(12)
    radius: ScalerService.s(Settings.appearance.radius2)
    color: Qt.alpha(theme.primary.dim_background, 0.6)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
    border.color: theme.button.border
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 260 } }
    transform: Translate {
        y: sec.shown ? 0 : ScalerService.s(10)
        Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    }

    Timer {
        interval: Math.round(sec.appearAt * 500)
        running: true
        onTriggered: sec.shown = true
    }

    Row {
        id: head
        x: ScalerService.s(18)
        y: ScalerService.s(16)
        spacing: ScalerService.s(8)
        Rectangle {
            width: ScalerService.s(4)
            height: ScalerService.s(16)
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            gradient: Gradient {
                GradientStop { position: 0.0; color: sec.accent }
                GradientStop { position: 1.0; color: sec.accent2 }
            }
        }
        Text {
            text: sec.title
            color: sec.accent
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(13); bold: true; letterSpacing: 0.5 }
        }
    }

    ColumnLayout {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: head.bottom
        anchors.margins: ScalerService.s(18)
        anchors.topMargin: ScalerService.s(12)
        spacing: ScalerService.s(14)
    }
}
