import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components

// Ô số liệu: icon, giá trị lớn, nhãn
Rectangle {
  id: root
  property string icon: ""
  property string label: ""
  property string value: "--"
  property string unit: ""
  property color accent: theme.button.text

  Layout.fillWidth: true
  Layout.preferredWidth: 1
  implicitHeight: ScalerService.s(84)
  radius: ScalerService.s(Settings.appearance.radius2)
  color: Qt.alpha(theme.button.background, 0.22)
  border.width: ScalerService.s(1)
  border.color: theme.button.border

  ColumnLayout {
    anchors.centerIn: parent
    spacing: ScalerService.s(2)
    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: ScalerService.s(4)
      IconText {
        name: root.icon
        size: "xs"
        textColor: root.accent
      }
      CustomText {
        name: root.label
        size: "xs"
        textColor: theme.primary.dim_foreground
      }
    }
    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: ScalerService.s(4)
      CustomText {
        name: root.value
        size: "normal"
        isBold: true
        textColor: root.accent
      }
      CustomText {
        Layout.alignment: Qt.AlignBottom
        name: root.unit
        size: "xs"
        textColor: theme.primary.dim_foreground
      }
    }
  }
}
