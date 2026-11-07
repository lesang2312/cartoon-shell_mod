// components/Settings/PanelPositionSelector.qml
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons
import "." as Com

ColumnLayout {
    id: root
    spacing: ScalerService.s(20)
    Layout.fillWidth: true

    CustomText {
        text: root.lang?.appearance?.panel_position || AutoTranslateService.t("Panel Position")
        isBold: true
    }

    GridLayout {
        columns: 2
        rowSpacing: ScalerService.s(15)
        columnSpacing: ScalerService.s(15)
        Layout.fillWidth: true

        // Component cho mỗi option
        Repeater {
            model: [
                {
                    id: "top",
                    label: root.lang?.appearance?.top || AutoTranslateService.t("Top"),
                    isHorizontal: true,
                    barPosition: "top"
                },
                {
                    id: "bottom",
                    label: root.lang?.appearance?.bottom || AutoTranslateService.t("Bottom"),
                    isHorizontal: true,
                    barPosition: "bottom"
                },
                {
                    id: "left",
                    label: root.lang?.appearance?.left || AutoTranslateService.t("Left"),
                    isHorizontal: false,
                    barPosition: "left"
                },
                {
                    id: "right",
                    label: root.lang?.appearance?.right || AutoTranslateService.t("Right"),
                    isHorizontal: false,
                    barPosition: "right"
                }
            ]

            delegate: Com.PositionOption {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(80)

                optionId: modelData.id
                label: modelData.label
                isHorizontal: modelData.isHorizontal
                position: modelData.barPosition
                isSelected: Settings.bar.position === modelData.barPosition

                onClicked: {
                    SoundService.playSound("pick");
                    Settings.bar.position = position;
                }
            }
        }
    }
}
