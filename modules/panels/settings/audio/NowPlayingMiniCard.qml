import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.components
import qs.commons

// Compact derivative of NowPlayingCard for bar layouts.
// Keeps the same vinyl, accent ring, progress line and transport controls.
Item {
    id: root

    property bool vertical: false
    property bool embedded: false
    property real progress: Players.getProgress()
    readonly property var player: Players.mprisPlayer
    readonly property bool playing: player ? player.isPlaying : false
    readonly property color accent: theme.button.text

    implicitWidth: vertical ? ScalerService.s(62) : ScalerService.s(270)
    implicitHeight: vertical ? ScalerService.s(178) : ScalerService.s(58)

    Timer {
        interval: 700
        repeat: true
        running: true
        onTriggered: root.progress = Players.getProgress()
    }

    Rectangle {
        anchors.fill: parent
        radius: ScalerService.s(Settings.appearance.radius2)
        color: root.embedded ? "transparent" : Qt.alpha(theme.primary.dim_background, 0.58)
        border.width: root.embedded || !Settings.appearance.enableBorder ? 0 : ScalerService.s(1)
        border.color: theme.button.border
    }

    // Small reusable vinyl artwork.
    component MiniVinyl: Item {
        id: vinyl
        property real diameter: ScalerService.s(42)
        property var player: null
        property bool isPlaying: false
        property color ringColor: "white"
        width: diameter
        height: diameter

        Item {
            anchors.fill: parent
            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: 12000
                loops: Animation.Infinite
                running: vinyl.isPlaying && !Settings.behavior.reduceMotion
            }
            ClippingRectangle {
                anchors.fill: parent
                radius: width / 2
                color: theme.primary.dim_background
                border.width: ScalerService.s(2)
                border.color: vinyl.ringColor
                Image {
                    id: miniArt
                    anchors.fill: parent
                    source: Players.getArtUrl(vinyl.player)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                }
                Repeater {
                    model: miniArt.status === Image.Ready ? 0 : [0.82, 0.62]
                    delegate: Rectangle {
                        required property real modelData
                        anchors.centerIn: parent
                        width: parent.width * modelData
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.alpha(theme.primary.foreground, 0.12)
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.18
                    height: width
                    radius: width / 2
                    color: theme.primary.background
                    border.width: 1
                    border.color: Qt.alpha(vinyl.ringColor, 0.75)
                }
            }
        }
    }

    component TransportButton: Rectangle {
        property string action: "play"
        property int diameter: ScalerService.s(24)
        property bool isPlaying: false
        property bool highlighted: false
        implicitWidth: diameter
        implicitHeight: diameter
        radius: width / 2
        color: area.containsMouse ? Qt.alpha(theme.button.text, 0.34)
                                  : Qt.alpha(theme.button.background, highlighted ? 0.9 : 0.68)
        Behavior on color { ColorAnimation { duration: 120 } }

        IconText {
            anchors.centerIn: parent
            name: action === "prev" ? "skip_previous"
                : action === "next" ? "skip_next"
                : isPlaying ? "pause" : "play_arrow"
            size: "xs"
            textColor: theme.primary.foreground
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (action === "prev") Players.previous();
                else if (action === "next") Players.next();
                else Players.playPause();
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: ScalerService.s(6)
        spacing: ScalerService.s(8)
        visible: !root.vertical

        MiniVinyl {
            diameter: ScalerService.s(40)
            player: root.player
            isPlaying: root.playing
            ringColor: root.accent
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: ScalerService.s(1)

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(17)
                clip: true
                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.player?.trackTitle || "No song playing"
                    color: theme.primary.foreground
                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(11); bold: true }
                    elide: Text.ElideRight
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SoundService.playSound("pick");
                        VisibleService.togglePanel("music");
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.player?.trackArtist || "Unknown Artist"
                color: theme.primary.dim_foreground
                font { family: Settings.appearance.font; pixelSize: ScalerService.s(9) }
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(3)
                radius: height / 2
                color: Qt.alpha(theme.primary.foreground, 0.16)
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.progress))
                    height: parent.height
                    radius: parent.radius
                    color: root.accent
                    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }
            }
        }

        RowLayout {
            spacing: ScalerService.s(2)
            Layout.alignment: Qt.AlignVCenter
            TransportButton { action: "prev"; diameter: ScalerService.s(22); isPlaying: root.playing }
            TransportButton { action: "play"; diameter: ScalerService.s(26); highlighted: true; isPlaying: root.playing }
            TransportButton { action: "next"; diameter: ScalerService.s(22); isPlaying: root.playing }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: ScalerService.s(6)
        spacing: ScalerService.s(5)
        visible: root.vertical

        MiniVinyl {
            diameter: Math.min(ScalerService.s(44), parent.width)
            player: root.player
            isPlaying: root.playing
            ringColor: root.accent
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            text: root.player?.trackTitle || "No song playing"
            color: theme.primary.foreground
            horizontalAlignment: Text.AlignHCenter
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(9); bold: true }
            elide: Text.ElideRight
            maximumLineCount: 1
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    SoundService.playSound("pick");
                    VisibleService.togglePanel("music");
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.player?.trackArtist || "Unknown Artist"
            color: theme.primary.dim_foreground
            horizontalAlignment: Text.AlignHCenter
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(8) }
            elide: Text.ElideRight
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(3)
            radius: height / 2
            color: Qt.alpha(theme.primary.foreground, 0.16)
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.progress))
                height: parent.height
                radius: parent.radius
                color: root.accent
            }
        }

        TransportButton {
            action: "play"
            diameter: ScalerService.s(26)
            highlighted: true
            isPlaying: root.playing
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
