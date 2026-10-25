import QtQuick
import QtQuick.Controls
import Quickshell.Wayland
import QtQuick.Layouts
import Quickshell
import qs.commons
import qs.components
import qs.services
import "." as Com

Item {
    id: root
    implicitWidth: ScalerService.s(480)
    implicitHeight: ScalerService.s(270)
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
        color: Qt.rgba(Qt.color(theme.primary.background).r, Qt.color(theme.primary.background).g, Qt.color(theme.primary.background).b, glassBg.active ? 0.48 : 0.88)
        GlassPanel { id: glassBg; tint: 0.28; frostAmount: 0.16; rim: 0.82 }
        border.color: Qt.rgba(0.86, 0.91, 1.0, 0.88)
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(15)
            spacing: ScalerService.s(10)
            // Album art and info section
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(130)
                spacing: ScalerService.s(20)

                // Album art
                Com.AlbumArt {
                    animationProgress: root.animationProgress
                }

                // Song info
                Com.SongInfo {
                    animationProgress: root.animationProgress
                }
            }

            // Controls
            Com.MusicControls {
                animationProgress: root.animationProgress
            }
            Com.MusicProgressBar {
                animationProgress: root.animationProgress
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
