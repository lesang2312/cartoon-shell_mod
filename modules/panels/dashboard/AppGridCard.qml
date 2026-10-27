import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import "." as Com
import qs.services
import qs.components
import qs.commons

Item {
    id: root

    Layout.preferredWidth: ScalerService.s(220)
    Layout.preferredHeight: ScalerService.s(220)

    property real animationProgress: 0
    signal editRequested(int index)
    Rectangle {
        GlassPanel { id: glassBg1 }
        anchors.centerIn: parent
        implicitWidth: root.animationProgress > 0.35 ? parent.width : 0
        implicitHeight: root.animationProgress > 0.35 ? parent.height : 0
        Behavior on implicitHeight {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
        Behavior on implicitWidth {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
        color: glassBg1.active ? "transparent" : theme.primary.background
        border.color: theme.button.border
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0

        GridLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(20)
            columns: 3
            rows: 3
            columnSpacing: ScalerService.s(15)
            rowSpacing: ScalerService.s(15)

            Repeater {
                // Luôn đủ 9 ô (ô thiếu = ô trống, bấm để gán)
                model: {
                    const a = Settings.dashboard.appGrid || [];
                    const out = [];
                    for (let i = 0; i < 9; i++)
                        out.push(a[i] || ({}));
                    return out;
                }

                Com.AppIcon {
                    entry: modelData
                    bgColor: theme.button.background
                    animationProgress: root.animationProgress
                    revealThreshold: 0.5 + (index * 0.1)
                    onEditRequested: root.editRequested(index)
                }
            }
        }
    }
}
