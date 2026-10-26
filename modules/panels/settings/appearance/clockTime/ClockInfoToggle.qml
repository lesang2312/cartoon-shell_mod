import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components

Item {
  implicitHeight: row.implicitHeight
  RowLayout {
    id: row
    width: parent.width
    spacing: ScalerService.s(10)

    Text {
      text: lang.appearance?.clock_info_label || "Hiện pin, thời tiết, wifi:"
      color: theme.primary.foreground
      font.family: "ComicShannsMono Nerd Font"
      font.pixelSize: ScalerService.s(16)
      Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
    }
    Item { Layout.fillWidth: true }
    CustomToggleSwitch {
      adapter: Settings.clock.showInfo
      onClicked: Settings.clock.showInfo = !Settings.clock.showInfo
    }
  }
}
