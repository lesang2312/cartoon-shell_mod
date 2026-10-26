import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components

Item {
  id: root
  implicitHeight: row.implicitHeight

  readonly property var styles: [
    { key: "current", label: lang.appearance?.clock_style_current || "Hiện tại" },
    { key: "iphone", label: lang.appearance?.clock_style_iphone || "iPhone" },
    { key: "pixel", label: lang.appearance?.clock_style_pixel || "Pixel" }
  ]

  RowLayout {
    id: row
    width: parent.width
    spacing: ScalerService.s(12)

    Text {
      text: lang.appearance?.clock_style_label || "Kiểu đồng hồ:"
      color: theme.primary.foreground
      font.family: "ComicShannsMono Nerd Font"
      font.pixelSize: ScalerService.s(16)
      Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
    }

    Item { Layout.fillWidth: true }

    Repeater {
      model: root.styles
      delegate: ButtonText {
        required property var modelData
        readonly property bool selected: Settings.clock.style === modelData.key

        Layout.preferredHeight: ScalerService.s(40)
        Layout.preferredWidth: ScalerService.s(100)

        name: modelData.label
        size: "xs"
        color: selected ? theme.button.background_select : theme.button.background
        textColor: selected ? theme.button.text : theme.primary.dim_foreground
        border.color: selected ? theme.button.border_select : theme.primary.foreground

        onClicked: Settings.clock.style = modelData.key
      }
    }
  }
}
