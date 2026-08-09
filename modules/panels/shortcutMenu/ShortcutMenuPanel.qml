import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.services
import qs.components
import qs.commons
import "." as Com

PanelWindow {
    id: root

    implicitWidth: ScalerService.s(250)
    implicitHeight: ScalerService.s(400)
    property real animationProgress: 0
    property real xMargins: 0
    property real yMargins: 0
    SequentialAnimation on animationProgress {
        running: true

        NumberAnimation {
            from: 0
            to: 1
            duration: 500
            easing.type: Easing.Linear
        }
    }

    anchors {
        left: true
        top: true
    }

    margins {
        left: root.xMargins
        top: root.yMargins
    }

    color: "transparent"
    focusable: true
    WifiService {
        id: wifiManager
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
                circleCount: 4
            }
        }
        color: theme.primary.background
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
        border.color: theme.button.border
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(16)
            spacing: ScalerService.s(12)
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(32)
                RowLayout {
                    spacing: ScalerService.s(12)

                    Item {
                        Layout.preferredHeight: ScalerService.s(28)
                        Layout.preferredWidth: ScalerService.s(28)
                        Image {
                            source: "image://icon/kitty"
                            anchors.fill: parent
                            anchors.margins: ScalerService.s(2)

                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                        }
                    }
                    CustomText {
                        name: "Terminal"
                        size: "small"
                        isBold: true
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }
        Loader {
            anchors.fill: parent

            active: !heightAnim.running && !widthAnim.running

            sourceComponent: StarField {
                starCount: 10
                shootingStarCount: 3
            }
        }
    }
}
