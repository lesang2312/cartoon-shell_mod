import QtQuick
import qs.services

// Dùng làm nền kính cho một panel dạng Rectangle:
//
//   Rectangle {
//       id: panelRect
//       color: glassBg.active ? "transparent" : theme.primary.background
//       radius: ...
//       GlassPanel { id: glassBg }
//       ...
//   }
//
// Bán kính bo góc tự lấy từ Rectangle cha. Khi tắt Liquid Glass (hoặc chưa có hình nền)
// `active` = false nên Rectangle vẽ lại màu nền đặc như cũ.
GlassBackdrop {
    anchors.fill: parent
    z: -1   // nằm dưới viền của Rectangle cha để border vẫn hiện
    radius: (parent && parent.radius !== undefined) ? parent.radius : 0
}
