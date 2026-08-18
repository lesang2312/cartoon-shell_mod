import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import QtQuick.Effects
import qs.modules.bar
import qs.commons
import qs.services
import qs.services.ram
import qs.services.cpu
import qs.components
import Quickshell.Services.Pipewire
import "../../widget/" as Com

ColumnLayout {
    id: root
    property real animationProgress: 0

    readonly property var sink: Pipewire.defaultAudioSink
    property real currentBrightness: BrightnessService.currentBrightness

    function getBrightnessIcon() {
        if (currentBrightness <= 0)
            return "brightness_1";
        if (currentBrightness <= 1 / 7)
            return "brightness_2";
        if (currentBrightness <= 2 / 7)
            return "brightness_3";
        if (currentBrightness <= 3 / 7)
            return "brightness_4";
        if (currentBrightness <= 4 / 7)
            return "brightness_5";
        if (currentBrightness <= 5 / 7)
            return "brightness_6";
        return "brightness_7";
    }

    function getBatteryIcon(level, status) {
        if (status === "Charging") {
            return "battery_android_frame_bolt";
        }

        if (level <= 0) {
            return "battery_android_frame_1";
        } else if (level <= 1 / 7) {
            return "battery_android_frame_2";
        } else if (level <= 2 / 7) {
            return "battery_android_frame_3";
        } else if (level <= 3 / 7) {
            return "battery_android_frame_4";
        } else if (level <= 4 / 7) {
            return "battery_android_frame_5";
        } else if (level <= 5 / 7) {
            return "battery_android_frame_6";
        } else {
            return "battery_android_frame_full";
        }
    }

    function changeVolume(delta) {
        if (!sink)
            return;
        var newVol = Math.min(1.5, Math.max(0, sink.audio.volume + delta));
        sink.audio.volume = newVol;
        if (sink.audio.muted && delta > 0)
            sink.audio.muted = false;
    }

    function toggleMute() {
        if (sink)
            sink.audio.muted = !sink.audio.muted;
    }

    function getIcon(volPercent) {
        if (volPercent < 10)
            return "volume_mute";
        if (volPercent < 60)
            return "volume_down";
        return "volume_up";
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
        Layout.preferredHeight: ScalerService.s(5)
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        CustomRectangle {
            color: theme.primary.background
            radius: ScalerService.s(Settings.appearance.radius2)
            border.color: theme.button.border
            border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0

            anchors.fill: parent
            visible: root.animationProgress > 0.1

            ColumnLayout {
                spacing: ScalerService.s(12)
                anchors.margins: ScalerService.s(2)
                anchors.fill: parent

                Item {
                    Layout.preferredHeight: ScalerService.s(0)
                }

                ButtonIconText {
                    fontFamily: "Symbols Nerd Font"
                    name: "󰣇"
                    textColor: theme.button.text
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: {
                        VisibleService.togglePanel("launcher");
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                CustomRectangle {
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(30)
                    implicitHeight: ScalerService.s(55)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    Layout.alignment: Qt.AlignHCenter

                    ColumnLayout {
                        id: contentRam
                        anchors.centerIn: parent
                        IconText {
                            name: ""
                            fontFamily: "Symbols Nerd Font"
                            textColor: theme.normal.green
                            size: "xs"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        CustomText {
                            size: "xs"
                            name: RamSimpleService.ramPercent + "%"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                CustomRectangle {
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(30)
                    implicitHeight: ScalerService.s(55)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    Layout.alignment: Qt.AlignHCenter

                    ColumnLayout {
                        id: contentCpu
                        anchors.centerIn: parent
                        IconText {
                            name: ""
                            fontFamily: "Symbols Nerd Font"
                            textColor: theme.normal.red
                            size: "xs"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        CustomText {
                            size: "xs"
                            name: CpuSimpleService.cpuPercent + "%"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                ColumnLayout {
                    id: controlsRow
                    spacing: ScalerService.s(2)
                    Layout.alignment: Qt.AlignHCenter

                    ButtonIconText {
                        name: "skip_previous"
                        size: "normal"
                        textColor: theme.normal.blue
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: Players?.mprisPlayer.previous()
                    }
                    ButtonIconText {
                        name: Players.mprisPlayer && Players.mprisPlayer.isPlaying ? "pause" : "play_arrow"
                        size: "normal"
                        Layout.alignment: Qt.AlignHCenter
                        textColor: theme.normal.green
                        onClicked: Players?.mprisPlayer.togglePlaying()
                    }
                    ButtonIconText {
                        name: "skip_next"
                        size: "normal"
                        textColor: theme.normal.blue
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: Players?.mprisPlayer.next()
                    }
                }

                CustomRectangle {
                    Layout.preferredHeight: ScalerService.s(240)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(30)

                    Layout.alignment: Qt.AlignHCenter

                    Com.WorkspaceSectionVertical {
                        anchors.centerIn: parent
                    }
                }

                ColumnLayout {
                    spacing: ScalerService.s(5)
                    Layout.alignment: Qt.AlignHCenter

                    CustomText {
                        size: "small"
                        name: `${DateTimeService.currentHour}`
                        Layout.alignment: Qt.AlignHCenter
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Item {
                            Layout.fillWidth: true
                        }
                        CustomRectangle {
                            Layout.preferredWidth: ScalerService.s(25)
                            Layout.preferredHeight: ScalerService.s(2)
                            color: theme.primary.foreground
                            radius: ScalerService.s(Settings.appearance.radius2)
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                    }

                    CustomText {
                        size: "small"
                        name: `${DateTimeService.currentMinus}`
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                CustomRectangle {
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(30)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    implicitHeight: ScalerService.s(55)
                    Layout.alignment: Qt.AlignHCenter

                    ColumnLayout {
                        id: contentBri
                        anchors.centerIn: parent
                        IconText {
                            name: root.getBrightnessIcon()
                            textColor: theme.button.text
                            Layout.alignment: Qt.AlignHCenter
                            size: "small"
                        }
                        CustomText {
                            name: Math.floor(BrightnessService.currentBrightness * 100) + "%"
                            Layout.alignment: Qt.AlignHCenter
                            size: "xs"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        propagateComposedEvents: true
                        cursorShape: Qt.PointingHandCursor

                        onWheel: wheel => {
                            let step = 0.05;

                            SoundService.playSound("pop");
                            if (wheel.angleDelta.y > 0)
                                BrightnessService.changeBright(step);
                            else if (wheel.angleDelta.y < 0)
                                BrightnessService.changeBright(-step);
                        }

                        onPressed: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                toggleMute();
                                mouse.accepted = true;
                            } else {
                                mouse.accepted = false;
                            }
                        }
                    }
                }

                CustomRectangle {
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(30)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    implicitHeight: ScalerService.s(55)
                    Layout.alignment: Qt.AlignHCenter

                    ColumnLayout {
                        id: contentVlo
                        anchors.centerIn: parent
                        IconText {
                            size: "small"
                            name: {
                                if (!sink || sink.audio.muted)
                                    return "volume_off";
                                return getIcon(Math.round(sink.audio.volume * 100));
                            }
                            Layout.alignment: Qt.AlignHCenter
                            textColor: theme.button.text
                        }
                        CustomText {
                            name: sink ? Math.round(sink.audio.volume * 100) + "%" : "0%"
                            Layout.alignment: Qt.AlignHCenter
                            size: "xs"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        propagateComposedEvents: true
                        cursorShape: Qt.PointingHandCursor

                        onWheel: wheel => {
                            let step = 0.05;

                            SoundService.playSound("pop");
                            if (wheel.angleDelta.y > 0)
                                changeVolume(step);
                            else if (wheel.angleDelta.y < 0)
                                changeVolume(-step);
                        }

                        onPressed: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                toggleMute();
                                mouse.accepted = true;
                            } else {
                                mouse.accepted = false;
                            }
                        }
                    }
                }

                CustomRectangle {
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(30)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    implicitHeight: ScalerService.s(60)
                    Layout.alignment: Qt.AlignHCenter

                    ColumnLayout {
                        anchors.centerIn: parent
                        IconText {
                            size: "small"
                            name: UPower.displayDevice.isLaptopBattery ? getBatteryIcon(UPower.displayDevice.percentage, UPowerDeviceState.toString(UPower.displayDevice.state)) : "battery_android_question"
                            textColor: UPower.displayDevice.isLaptopBattery ? theme.button.text : theme.normal.red
                            Layout.alignment: Qt.AlignHCenter
                        }
                        CustomText {
                            visible: UPower.displayDevice.isLaptopBattery
                            name: Math.round(UPower.displayDevice.percentage * 100) + "%"
                            size: "xs"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        propagateComposedEvents: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                CustomRectangle {
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(30)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    implicitHeight: ScalerService.s(70)
                    Layout.alignment: Qt.AlignHCenter

                    ColumnLayout {
                        anchors.centerIn: parent
                        IconText {
                            name: NetworkService.wifi_icon_text_2
                            size: "small"
                            textColor: theme.button.text
                            Layout.alignment: Qt.AlignHCenter
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    SoundService.playSound("pick");
                                    VisibleService.togglePanel("wifi");
                                }
                            }
                        }
                        IconText {
                            name: "bluetooth"
                            size: "small"
                            textColor: theme.button.text
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                ButtonIconText {
                    fontFamily: "Symbols Nerd Font"
                    name: "󰐥"
                    textColor: theme.normal.red
                    Layout.alignment: Qt.AlignHCenter
                }

                Item {
                    Layout.preferredHeight: ScalerService.s(0)
                }
            }
        }
    }

    Item {
        Layout.preferredHeight: ScalerService.s(5)
    }
}
