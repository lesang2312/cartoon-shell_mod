import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components

// Thẻ nhóm: tiêu đề + icon + nội dung (đặt con vào `content`)
Rectangle {
  id: root
  property string title: ""
  property string icon: ""
  default property alias content: body.data
  property alias headerRight: headerRightSlot.data

  Layout.fillWidth: true
  implicitHeight: col.implicitHeight + ScalerService.s(24)
  radius: ScalerService.s(Settings.appearance.radius2)
  color: Qt.alpha(theme.button.background, 0.22)
  border.width: ScalerService.s(1)
  border.color: theme.button.border

  ColumnLayout {
    id: col
    anchors.fill: parent
    anchors.margins: ScalerService.s(12)
    spacing: ScalerService.s(10)

    RowLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(8)
      IconText {
        visible: root.icon !== ""
        name: root.icon
        size: "small"
        textColor: theme.button.text
      }
      CustomText {
        name: root.title
        size: "small"
        isBold: true
      }
      Item {
        Layout.fillWidth: true
      }
      Row {
        id: headerRightSlot
        spacing: ScalerService.s(6)
      }
    }

    ColumnLayout {
      id: body
      Layout.fillWidth: true
      spacing: ScalerService.s(8)
    }
  }
}
