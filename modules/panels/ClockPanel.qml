import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import QtQuick.Controls
import qs.services
import qs.components
import qs.commons
import "clock"

PanelWindow {
  id: root
  WlrLayershell.exclusiveZone: 0   // không chiếm không gian ứng dụng

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  margins {
    top: ScalerService.s(10)
    bottom: ScalerService.s(10)
    left: ScalerService.s(10)
    right: ScalerService.s(10)
  }

  implicitWidth: layout.implicitWidth
  implicitHeight: layout.implicitHeight

  WlrLayershell.layer: WlrLayer.Bottom

  color: "transparent"

  ColumnLayout {
    id: layout
    anchors.centerIn: parent
    spacing: ScalerService.s(8)

    // Chọn kiểu đồng hồ theo Settings.clock.style: "current" | "iphone" | "pixel"
    Loader {
      id: content
      Layout.alignment: Qt.AlignHCenter
      sourceComponent: {
        switch (Settings.clock.style) {
        case "iphone":
          return iphoneClock;
        case "pixel":
          return pixelClock;
        default:
          return currentClock;
        }
      }
    }

    ClockInfoRow {
      visible: Settings.clock.showInfo
      Layout.alignment: Qt.AlignHCenter
    }
  }

  Component { id: currentClock; ClockCurrent {} }
  Component { id: iphoneClock; ClockIphone {} }
  Component { id: pixelClock; ClockPixel {} }
}
