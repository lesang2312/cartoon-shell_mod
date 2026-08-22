import QtQuick
import qs.services
import qs.components

Item {
  id: header
  // Đặt sàn tối thiểu ScalerService.s(44): nếu CustomText/CloseButton là
  // component tuỳ biến không forward đúng implicitHeight (trả về 0 hoặc quá
  // nhỏ), header vẫn không co lại gần 0 -> tránh text tràn đè xuống nội dung
  // bên dưới (KeyBindDisplay).
  implicitHeight: Math.max(headerText.implicitHeight, closeButton.implicitHeight, ScalerService.s(44)) + ScalerService.s(12)

  CustomText {
    id: headerText
    anchors.centerIn: parent // Đã sửa thành căn giữa

    name: "All keyboard shortcuts in Hyprland"
    size: "large"
    isBold: true
  }

  CloseButton {
    id: closeButton
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    onClicked: VisibleService.togglePanel("keybind")
  }
}