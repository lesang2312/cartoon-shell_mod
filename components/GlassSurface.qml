import QtQuick
import qs.services

// Background Liquid Glass dùng cho từng nút, tile hoặc hàng danh sách nằm trong panel có GlassBackdrop.
// Đặt component này làm con đầu tiên của tile/row; nội dung (icon, text...) đặt sau nó để nằm phía trên kính.
Item {
    id: root

    property real radius: 16
    property color fallbackColor: "#24283a"
    // Tông xanh than hợp với các tile/nút tiện ích; đổi tintColor nếu muốn theo màu theme.
    property color tintColor: Qt.rgba(0.12, 0.14, 0.22, 1)
    property real tintAmount: 0.30
    property real tintStrength: 0.70
    property real frost: 1.45
    property real rim: GlassService.rimStrength
    property real saturation: 1.08
    property real thickness: -1
    property bool forceClear: false
    property bool forceOpaque: false

    readonly property bool glassActive: glassFill.active

    // Nền dự phòng khi Liquid Glass đang tắt, chưa có wallpaper hoặc renderer không hỗ trợ shader.
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.fallbackColor
        visible: !glassFill.active
    }

    // Phần kính thực tế: tự tìm GlassBackdrop gần nhất qua GlassFill.
    GlassFill {
        id: glassFill
        anchors.fill: parent
        radius: root.radius
        tintColor: root.tintColor
        tintAmount: root.tintAmount
        tintStrength: root.tintStrength
        frost: root.frost
        rim: root.rim
        saturation: root.saturation
        thickness: root.thickness
        forceClear: root.forceClear
        forceOpaque: root.forceOpaque
    }
}
