import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons

// Dòng chọn nhanh: tiêu đề + mô tả, bên dưới là dãy chip (chip đang chọn sáng gradient)
ColumnLayout {
    id: cr

    property var theme: ThemeService.theme
    property string title: ""
    property string desc: ""
    property var options: []        // [{ v: 5, l: "5 phút" }, ...]
    property var current: 0
    property bool dimmed: false
    readonly property color accent: theme.button.text
    readonly property color accent2: Qt.hsla((Math.max(0, accent.hslHue) + 0.09) % 1, accent.hslSaturation, Math.max(0.52, Math.min(0.78, accent.hslLightness)), 1)
    signal picked(var v)

    Layout.fillWidth: true
    spacing: ScalerService.s(8)
    opacity: dimmed ? 0.45 : 1
    Behavior on opacity { NumberAnimation { duration: 200 } }

    Text {
        text: cr.title
        color: cr.theme.primary.foreground
        font { family: Settings.appearance.font; pixelSize: ScalerService.s(15); bold: true }
    }
    Text {
        Layout.fillWidth: true
        visible: text !== ""
        text: cr.desc
        wrapMode: Text.WordWrap
        color: cr.theme.primary.dim_foreground
        font { family: Settings.appearance.font; pixelSize: ScalerService.s(11) }
    }
    Flow {
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height
        spacing: ScalerService.s(6)
        Repeater {
            model: cr.options
            delegate: Rectangle {
                id: chip
                required property var modelData
                readonly property bool sel: modelData.v === cr.current
                width: chipText.implicitWidth + ScalerService.s(24)
                height: ScalerService.s(32)
                radius: height / 2
                color: sel ? "transparent" : (chipMa.containsMouse ? Qt.alpha(cr.theme.button.background_select, 0.85) : Qt.alpha(cr.theme.button.background, 0.65))
                Behavior on color { ColorAnimation { duration: 140 } }
                scale: chipMa.pressed ? 0.94 : 1
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    opacity: chip.sel ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 220 } }
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: cr.accent }
                        GradientStop { position: 1.0; color: cr.accent2 }
                    }
                }
                Text {
                    id: chipText
                    anchors.centerIn: parent
                    text: chip.modelData.l
                    color: chip.sel ? cr.theme.primary.background : cr.theme.primary.foreground
                    Behavior on color { ColorAnimation { duration: 180 } }
                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(12); bold: chip.sel }
                }
                MouseArea {
                    id: chipMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: cr.picked(chip.modelData.v)
                }
            }
        }
    }
}
