import QtQuick
import qs.services

// Đầu mèo trắng dễ thương (tai hồng, má hồng). Kích thước gốc 84x46, co giãn bằng `unit`.
Item {
  id: cat
  property real unit: 1.0
  property color earInner: "#ff8fb1"
  property color ink: "#3a3f7a"
  readonly property real u: ScalerService.s(1) * unit

  width: 84 * u
  height: 46 * u

  Rectangle {
    x: 6 * u; y: -2 * u; width: 22 * u; height: 22 * u
    radius: 5 * u; rotation: 45; color: "white"
    Rectangle { anchors.centerIn: parent; width: parent.width * 0.5; height: width; radius: 3 * u; color: cat.earInner }
  }
  Rectangle {
    x: 56 * u; y: -2 * u; width: 22 * u; height: 22 * u
    radius: 5 * u; rotation: 45; color: "white"
    Rectangle { anchors.centerIn: parent; width: parent.width * 0.5; height: width; radius: 3 * u; color: cat.earInner }
  }
  Rectangle {
    x: 0; y: 6 * u; width: parent.width; height: 40 * u; radius: 20 * u; color: "white"
    Rectangle { x: 20 * u; y: 15 * u; width: 7 * u; height: 9 * u; radius: width / 2; color: cat.ink }
    Rectangle { x: 57 * u; y: 15 * u; width: 7 * u; height: 9 * u; radius: width / 2; color: cat.ink }
    Rectangle { x: 11 * u; y: 24 * u; width: 10 * u; height: 6 * u; radius: height / 2; color: "#99ff8fb1" }
    Rectangle { x: 63 * u; y: 24 * u; width: 10 * u; height: 6 * u; radius: height / 2; color: "#99ff8fb1" }
    Text { anchors.horizontalCenter: parent.horizontalCenter; y: 17 * u; text: "ω"; color: cat.ink; font { pixelSize: 13 * u; bold: true } }
  }
}
