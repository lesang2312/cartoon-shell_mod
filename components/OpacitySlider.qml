import QtQuick
import QtQuick.Controls
import qs.commons
import qs.components
import qs.services

Slider {
    id: root
    from: 0
    to: 100
    enabled: true

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: ScalerService.s(220)
        implicitHeight: ScalerService.s(10)
        width: root.availableWidth
        height: implicitHeight
        radius: ScalerService.s(6)
        color: theme.button.background

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: ScalerService.s(6)
            color: "#4FC3F7"
            Behavior on width {
                NumberAnimation { duration: root.pressed ? 0 : 300; easing.type: Easing.OutCubic }
            }
        }
    }

    handle: CustomRectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: root.pressed ? ScalerService.s(22) : ScalerService.s(19)
        implicitHeight: root.pressed ? ScalerService.s(22) : ScalerService.s(19)
        radius: implicitWidth / 2
        color: theme.primary.background
        border.color: theme.button.dim_foreground
        border.width: ScalerService.s(1)

        Rectangle {
            anchors.centerIn: parent
            width: root.pressed ? ScalerService.s(12) : ScalerService.s(10)
            height: width
            radius: width / 2
            color: "#4FC3F7"
            Behavior on width { NumberAnimation { duration: 150 } }
        }
    }
}
