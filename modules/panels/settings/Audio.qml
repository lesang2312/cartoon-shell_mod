// Settings -> Audio: trình phát + equalizer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.components
import "./audio" as Com

Item {
  ScrollView {
    id: scroll
    anchors.fill: parent
    anchors.margins: ScalerService.s(20)
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    ColumnLayout {
      width: scroll.availableWidth
      spacing: ScalerService.s(16)

      HeaderSettings {
        name: "Audio Settings"
      }

      Rectangle {
        Layout.fillWidth: true
        height: ScalerService.s(1)
        color: theme.primary.foreground
        opacity: 0.2
      }

      Com.NowPlayingCard {}
      Com.EqualizerCard {}

      Item { Layout.preferredHeight: ScalerService.s(36) }  // chừa chỗ cho phần trang trí đáy panel
    }
  }
}
