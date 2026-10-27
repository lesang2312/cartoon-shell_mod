import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import qs.commons
import qs.services
import qs.components
import "."
import "../../widget/" as Com

// Thanh kiểu Windows 11: Weather bên trái | cụm giữa (Start, Search, Workspaces, Music, Widgets)
// | bên phải: tray, ngôn ngữ, cụm Quick Settings (wifi/âm lượng/pin), ngày giờ (Calendar)
RowLayout {
    id: root
    property real animationProgress: 0

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var weatherCur: (WeatherService.dataModel && WeatherService.dataModel.current && WeatherService.dataModel.current.condition) ? WeatherService.dataModel.current : null

    function getIcon(volPercent) {
        if (volPercent < 10)
            return "volume_mute";
        if (volPercent < 60)
            return "volume_down";
        return "volume_up";
    }
    function getBatteryIcon(level, status) {
        if (status === "Charging")
            return "battery_android_frame_bolt";
        if (level <= 0)
            return "battery_android_frame_1";
        if (level <= 1 / 7)
            return "battery_android_frame_2";
        if (level <= 2 / 7)
            return "battery_android_frame_3";
        if (level <= 3 / 7)
            return "battery_android_frame_4";
        if (level <= 4 / 7)
            return "battery_android_frame_5";
        if (level <= 5 / 7)
            return "battery_android_frame_6";
        return "battery_android_frame_full";
    }

    SequentialAnimation on animationProgress {
        running: true
        NumberAnimation {
            from: 0
            to: 1
            duration: 500
            easing.type: Easing.Linear
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        CustomRectangle {
            GlassPanel {
                id: glassBg
            }
            color: glassBg.active ? "transparent" : theme.primary.background
            anchors.centerIn: parent
            implicitWidth: root.animationProgress > 0.1 ? parent.width : 0
            implicitHeight: root.animationProgress > 0.1 ? parent.height : 0

            // Viền trên mảnh giống taskbar Win11
            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: ScalerService.s(1)
                color: Qt.rgba(1, 1, 1, 0.12)
            }

            // ---- Trái: thời tiết (Win11 Widgets) ----
            TaskButton {
                id: weatherBtn
                anchors.left: parent.left
                anchors.leftMargin: ScalerService.s(8)
                anchors.verticalCenter: parent.verticalCenter
                panelName: "weather"
                visible: root.weatherCur !== null
                implicitHeight: ScalerService.s(42)

                IconImage {
                    path: root.weatherCur ? WeatherService.getWeatherIcon(root.weatherCur.condition.code, root.weatherCur.is_day) : ""
                    size: "normal"
                }
                ColumnLayout {
                    spacing: 0
                    CustomText {
                        name: root.weatherCur ? `${root.weatherCur.temp_c}°C` : ""
                        size: "xs"
                        isBold: true
                    }
                    CustomText {
                        name: root.weatherCur ? root.weatherCur.condition.text.slice(0, 14) : ""
                        size: "2xs"
                        textColor: theme.primary.dim_foreground
                    }
                }
            }

            // ---- Giữa: Start, Search, Workspaces, Music, Dashboard ----
            RowLayout {
                id: centerGroup
                anchors.centerIn: parent
                spacing: ScalerService.s(6)

                TaskButton {
                    panelName: "launcher"
                    IconImage {
                        path: "launcher/win11.svg"
                        size: "normal"
                    }
                }

                // Ô tìm kiếm: bấm mở launcher (có ô search)
                TaskButton {
                    panelName: "launcher"
                    implicitWidth: ScalerService.s(190)
                    baseColor: Qt.rgba(1, 1, 1, 0.08)
                    hoverColor: Qt.rgba(1, 1, 1, 0.16)
                    border.width: ScalerService.s(1)
                    border.color: Qt.rgba(1, 1, 1, 0.14)
                    radius: height / 2
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: ScalerService.s(8)
                        IconText {
                            name: "search"
                            size: "small"
                            textColor: theme.primary.dim_foreground
                        }
                        CustomText {
                            name: lang.launcher?.search || "Search"
                            size: "xs"
                            textColor: theme.primary.dim_foreground
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }

                // Workspaces (như Task View)
                Rectangle {
                    Layout.preferredHeight: ScalerService.s(34)
                    Layout.preferredWidth: wsRow.implicitWidth + ScalerService.s(24)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    color: Qt.rgba(1, 1, 1, 0.06)
                    Com.WorkspaceSectionHorizontal {
                        id: wsRow
                        anchors.centerIn: parent
                    }
                }

                TaskButton {
                    panelName: "music"
                    IconText {
                        name: Players.mprisPlayer && Players.mprisPlayer.isPlaying ? "graphic_eq" : "music_note"
                        size: "small"
                        textColor: theme.button.text
                    }
                }

                TaskButton {
                    panelName: "dashboard"
                    IconText {
                        name: "widgets"
                        size: "small"
                        textColor: theme.primary.foreground
                    }
                }
            }

            // ---- Phải ----
            RowLayout {
                anchors.right: parent.right
                anchors.rightMargin: ScalerService.s(8)
                anchors.verticalCenter: parent.verticalCenter
                spacing: ScalerService.s(2)

                // Khay hệ thống (hidden icons)
                TaskButton {
                    panelName: "tray"
                    visible: TrayService.hasTray
                    IconText {
                        name: "keyboard_arrow_up"
                        size: "small"
                    }
                }

                // Ngôn ngữ / cờ
                TaskButton {
                    panelName: "flag"
                    CustomText {
                        name: (Settings.appearance.countryFlag || "vn").toUpperCase()
                        size: "xs"
                        isBold: true
                    }
                }

                // Cụm Quick Settings: wifi + âm lượng + pin
                TaskButton {
                    panelName: "quickSettings"
                    IconText {
                        name: NetworkService.wifi_icon_text_1
                        size: "small"
                    }
                    IconText {
                        name: {
                            if (!root.sink || root.sink.audio.muted)
                                return "volume_off";
                            return root.getIcon(Math.round(root.sink.audio.volume * 100));
                        }
                        size: "small"
                    }
                    IconText {
                        size: "small"
                        name: UPower.displayDevice.isLaptopBattery ? root.getBatteryIcon(UPower.displayDevice.percentage, UPowerDeviceState.toString(UPower.displayDevice.state)) : "battery_android_question"
                    }
                    CustomText {
                        visible: UPower.displayDevice.isLaptopBattery
                        size: "xs"
                        name: Math.round(UPower.displayDevice.percentage * 100) + "%"
                    }
                }

                // Ngày giờ -> Calendar
                TaskButton {
                    panelName: "calendar"
                    implicitHeight: ScalerService.s(42)
                    ColumnLayout {
                        spacing: 0
                        CustomText {
                            name: DateTimeService.currentTime
                            Layout.alignment: Qt.AlignRight
                            size: "xs"
                        }
                        CustomText {
                            name: DateTimeService.currentDate1
                            Layout.alignment: Qt.AlignRight
                            size: "xs"
                        }
                    }
                }

                // "Show desktop" sliver ở mép phải như Win11
                Rectangle {
                    Layout.preferredWidth: ScalerService.s(5)
                    Layout.fillHeight: true
                    color: sliverArea.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                    HoverHandler {
                        id: sliverArea
                    }
                    TapHandler {
                        onTapped: VisibleService.closeAllPanels()
                    }
                }
            }
        }
    }
}
