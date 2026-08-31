import QtQuick
import QtQuick.Controls
import Quickshell.Wayland
import QtQuick.Layouts
import Quickshell
import qs.commons
import qs.components
import qs.services
import qs.services.ram
import qs.services.cpu

Item {
    id: root
    //anchors.fill: parent
    implicitWidth: ScalerService.s(480)
    implicitHeight: ScalerService.s(260)
    property real animationProgress: 0
    SequentialAnimation on animationProgress {
        running: true

        NumberAnimation {
            from: 0
            to: 1
            duration: 500
            easing.type: Easing.Linear
        }
    }
    Rectangle {
        anchors.centerIn: parent
        implicitWidth: root.animationProgress > 0 ? parent.width : 0
        implicitHeight: root.animationProgress > 0 ? parent.height : 0
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
        color: theme.primary.background
        border.color: theme.button.border
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
        clip: true
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(10)
            spacing: ScalerService.s(5)

            CustomText {
                name: "System usage"
                size: "xl"
                isBold: true
                fontFamily: "Lilex Nerd Font"
                textColor: theme.button.text
                elide: Text.ElideRight
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.maximumWidth: parent.width
                horizontalAlignment: Text.AlignHCenter
            }
            
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: ScalerService.s(8)
                CircularUsage {
                    title: "Cpu"
                    value: CpuSimpleService.cpuPercent
                    progressColor: theme.normal.red
                    Layout.preferredWidth: ScalerService.s(150)
                    Layout.preferredHeight: ScalerService.s(180)
                    Layout.minimumWidth: 0
                    Layout.minimumHeight: 0
                    clip: true
                }
                CircularUsage {
                    title: "Ram"
                    value: RamSimpleService.ramPercent
                    progressColor: theme.normal.green
                    Layout.preferredWidth: ScalerService.s(150)
                    Layout.preferredHeight: ScalerService.s(180)
                    Layout.minimumWidth: 0
                    Layout.minimumHeight: 0
                    clip: true
                }
                CircularUsage {
                    title: "Disk"
                    value: DiskService.diskPercents
                    progressColor: theme.normal.blue
                    Layout.preferredWidth: ScalerService.s(150)
                    Layout.preferredHeight: ScalerService.s(180)
                    Layout.minimumWidth: 0
                    Layout.minimumHeight: 0
                    clip: true
                }
            }
            Item {
                Layout.fillHeight: true
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
