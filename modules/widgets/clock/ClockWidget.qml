import QtQuick
import QtQuick.Controls
import Quickshell.Wayland
import QtQuick.Layouts
import Quickshell
import qs.commons
import qs.components
import qs.services

Item {
    id: root
    implicitWidth: ScalerService.s(480)
    implicitHeight: ScalerService.s(250)
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

        RowLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(20)
            spacing: ScalerService.s(20)

            ColumnLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(20)

                CustomText {
                    Layout.fillWidth: true
                    name: WeatherService.dataModel.current.condition.text
                    size: "small"
                    color: theme.primary.dim_foreground
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    Layout.alignment: Qt.AlignHCenter
                }
                RowLayout {
                    spacing: 0
                    IconImage {
                        path: WeatherService.getWeatherIcon(WeatherService.dataModel.current.condition.code, WeatherService.dataModel.current.is_day)
                        size: "normal"
                    }
                    CustomText {
                        name: `${WeatherService.dataModel.current.temp_c}` || "Đang tải..."
                        Layout.alignment: Qt.AlignHCenter
                        size: "xl"
                        isBold: true
                    }
                    CustomText {
                        textColor: theme.button.text
                        name: "°C"
                    }
                }
                CustomText {
                    Layout.fillWidth: true
                    name: WeatherService.location
                    size: "small"
                    color: theme.primary.dim_foreground
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(20)

                CustomText {
                    id: textCurrentDate
                    Layout.fillWidth: true
                    name: DateTimeService.currentDate
                    Layout.alignment: Qt.AlignHCenter
                    size: "small"
                    color: theme.primary.dim_foreground
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                CustomText {
                    name: DateTimeService.currentTime
                    isBold: true
                    size: "xl"
                    Layout.alignment: Qt.AlignHCenter
                }
                CustomText {
                    Layout.fillWidth: true
                    name: `Feels like: ${WeatherService.dataModel.current.feelslike_c}°C`
                    color: theme.primary.dim_foreground
                    size: "small"
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
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
