import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components

// Chọn kiểu giao diện toàn shell (Settings -> Appearance -> Theme).
// Lưu tại Settings.appearance.dialogStyle: "classic" | "cute".
// Cute = preset đồng bộ: theme Sakura, bo góc lớn, bật viền, hộp thoại + trang trí mèo.
RowLayout {
    id: root
    spacing: ScalerService.s(12)

    function applyStyle(id) {
        const a = Settings.appearance;
        a.dialogStyle = id;
        if (id === "cute") {
            a.dynamic = false;
            a.theme = "sakura";
            a.radius1 = 30;
            a.radius2 = 22;
            a.radius3 = 14;
            a.enableBorder = true;
        } else {
            a.radius1 = 22;
            a.radius2 = 16;
            a.radius3 = 8;
            a.enableBorder = false;
        }
    }

    CustomText {
        name: lang.appearance?.dialog_style_label || "Kiểu giao diện:"
        size: "small"
        isBold: true
        Layout.preferredWidth: ScalerService.s(150)
    }

    Row {
        spacing: ScalerService.s(12)
        Layout.fillWidth: true

        Repeater {
            model: [
                { id: "classic", label: "Classic", icon: "▭" },
                { id: "cute", label: "Cute 🐱", icon: "✿" }
            ]
            delegate: Rectangle {
                required property var modelData
                readonly property bool selected: Settings.appearance.dialogStyle === modelData.id
                width: ScalerService.s(120)
                height: ScalerService.s(44)
                radius: ScalerService.s(Settings.appearance.radius3)
                color: selected ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6)
                border.width: ScalerService.s(2)
                border.color: selected || mouse.containsMouse ? theme.button.border_select : theme.button.border
                scale: mouse.containsPress ? 0.96 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }

                CustomText {
                    anchors.centerIn: parent
                    name: modelData.label
                    size: "small"
                    isBold: parent.selected
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.applyStyle(modelData.id)
                }
            }
        }
    }
}
