import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.services
import qs.commons
import "." as Com
import qs.components

PanelWindow {
  id: root

  // Cho phép panel nhận focus bàn phím khi cần (TextField, Popup...)
  // Không có dòng này thì layer-shell mặc định chặn hết input bàn phím.
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  // Chỉ dùng như cờ "đã sẵn sàng hiển thị" (được đọc dạng boolean ở dưới), nên không cần
  // animate mượt 0->1 trong 1000ms như trước (animation đó chạy vô ích vì nơi dùng chỉ
  // so sánh > 0). Việc "phồng to" mượt mà đã do Behavior on implicitWidth/Height đảm nhiệm.
  property bool ready: false
  Component.onCompleted: ready = true

  implicitWidth: ScalerService.s(500)
  implicitHeight: ScalerService.s(500)

  anchors {
    top: Settings.bar.position === "top"
    bottom: Settings.bar.position === "bottom"
    left: Settings.bar.position === "top" || Settings.bar.position === "bottom" || Settings.bar.position === "left"
    right: Settings.bar.position === "right"
  }

  // Offset trái mong muốn khi bar nằm top/bottom (để panel không dính sát mép trái).
  // Được kẹp (clamp) theo độ rộng màn hình thực tế bên dưới để không đẩy panel tràn
  // ra ngoài màn hình trên các màn hình nhỏ hơn ~800 + độ rộng panel.
  readonly property real desiredLeftOffset: ScalerService.s(800)
  readonly property real maxLeftOffset: {
    const screenWidth = root.screen ? root.screen.width : 1920;
    return Math.max(ScalerService.s(10), screenWidth - implicitWidth - ScalerService.s(10));
  }

  margins {
    top: Settings.bar.position === "top" ? ScalerService.s(10) : 0
    bottom: Settings.bar.position === "bottom" ? ScalerService.s(10) : 0
    left: (Settings.bar.position === "top" || Settings.bar.position === "bottom") ? Math.min(desiredLeftOffset, maxLeftOffset) : ScalerService.s(10)
    right: Settings.bar.position === "right" ? ScalerService.s(10) : 0
  }
  exclusiveZone: 0
  color: "transparent"

  // Background layer với các hình tròn di chuyển

  // Main content layer
  Rectangle {
    anchors.centerIn: parent
    implicitWidth: root.ready ? parent.width : 0
    implicitHeight: root.ready ? parent.height : 0

    color: theme.primary.background
    border.color: theme.button.border
    radius: ScalerService.s(Settings.appearance.radius1)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0

    Behavior on implicitHeight {
      NumberAnimation {
        id: heightAnim
        duration: 500
        easing.type: Easing.OutCubic
      }
    }
    Behavior on implicitWidth {
      NumberAnimation {
        id: widthAnim
        duration: 500
        easing.type: Easing.OutCubic
      }
    }
    Loader {
      anchors.fill: parent

      active: !heightAnim.running && !widthAnim.running

      sourceComponent: FloatingCircles {
        circleColor: theme.button.text
        anchors.fill: parent
        circleCount: 2
        minOpacity: 0.02
        maxOpacity: 0.04
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: ScalerService.s(20)
      spacing: ScalerService.s(16)

      Com.CalendarHeader {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(40)
      }

      Com.CalendarDislay {
        Layout.alignment: Qt.AlignHCenter
      }
    }
    Loader {
      anchors.fill: parent

      active: !heightAnim.running && !widthAnim.running

      sourceComponent: StarField {
        starCount: 10
        shootingStarCount: 2
      }
    }
  }
}
