import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components

// Nút bật/tắt hiệu ứng Liquid Glass (Settings -> Appearance -> Theme).
// Trạng thái lưu tại Settings.appearance.liquidGlass.
RowLayout {
    id: root
    Layout.fillWidth: true
    spacing: ScalerService.s(12)

    ColumnLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(2)

        CustomText {
            name: lang.appearance?.liquid_glass_label || "Liquid Glass:"
            size: "small"
            isBold: true
        }

        CustomText {
            Layout.fillWidth: true
            name: lang.appearance?.liquid_glass_desc || "Nền kính lỏng trong suốt, khúc xạ hình nền cho các panel."
            size: "xs"
            textColor: theme.primary.dim_foreground
            wrapMode: Text.WordWrap
        }
    }

    CustomToggleSwitch {
        adapter: GlassService.enabled
        onClicked: GlassService.toggle()
    }
}
