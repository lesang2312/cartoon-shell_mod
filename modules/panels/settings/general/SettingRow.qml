import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons

// Một dòng cài đặt: tên + mô tả bên trái, điều khiển bên phải
RowLayout {
    id: sr

    property var theme: ThemeService.theme
    property string title: ""
    property string desc: ""
    property bool dimmed: false
    default property alias control: slot.data

    Layout.fillWidth: true
    spacing: ScalerService.s(14)
    opacity: dimmed ? 0.45 : 1
    Behavior on opacity { NumberAnimation { duration: 200 } }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(2)
        Text {
            Layout.fillWidth: true
            text: sr.title
            color: sr.theme.primary.foreground
            elide: Text.ElideRight
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(15); bold: true }
        }
        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: sr.desc
            wrapMode: Text.WordWrap
            color: sr.theme.primary.dim_foreground
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(11) }
        }
    }
    Row {
        id: slot
        Layout.alignment: Qt.AlignVCenter
        spacing: ScalerService.s(10)
    }
}
