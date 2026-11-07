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
    // Arch (Style 2) has a shorter horizontal bar, so use a denser layout there.
    property bool archBar: false
    property real progress: Players.getProgress()
    readonly property var player: Players.mprisPlayer
    readonly property bool playing: player ? player.isPlaying : false
    readonly property color accent: theme.button.text
    // Scale every music control to the actual inner bar height. No fixed minimum
    // diameter: a minimum larger than the available height caused the vinyl/logo
    // to protrude beyond short bars on some display scales.
    readonly property real contentMargin: archBar
        ? Math.max(0, Math.min(ScalerService.s(3), height * 0.055))
        : Math.max(0, Math.min(ScalerService.s(5), height * 0.07))
    readonly property real usableControlHeight: Math.max(0, height - contentMargin * 2 - ScalerService.s(4))
    readonly property real miniDiscSize: archBar
        ? Math.min(ScalerService.s(vertical ? 30 : 25), usableControlHeight * 0.82)
        : Math.min(ScalerService.s(vertical ? 38 : 34), usableControlHeight)
    readonly property real sideButtonSize: archBar
        ? Math.min(ScalerService.s(16), miniDiscSize * 0.72)
        : Math.min(ScalerService.s(20), miniDiscSize * 0.60)
    readonly property real mainButtonSize: archBar
        ? Math.min(ScalerService.s(19), miniDiscSize * 0.86)
        : Math.min(ScalerService.s(24), miniDiscSize * 0.70)

    // A final safety boundary for album art, text and controls in every bar style.
    clip: true

    implicitWidth: vertical ? ScalerService.s(62) : ScalerService.s(270)
    implicitHeight: vertical ? ScalerService.s(178) : ScalerService.s(58)

    Timer {
        interval: 900
        repeat: true
        running: root.player !== null && root.playing
        onTriggered: root.progress = Players.getProgress()
    }

    onPlayerChanged: root.progress = Players.getProgress()
    onPlayingChanged: root.progress = Players.getProgress()

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
        clip: true

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
        property bool available: false
        implicitWidth: diameter
        implicitHeight: diameter
        visible: diameter >= ScalerService.s(12)
        radius: width / 2
        color: area.containsMouse ? Qt.alpha(theme.button.text, 0.34)
                                  : Qt.alpha(theme.button.background, highlighted ? 0.9 : 0.68)
        opacity: available ? 1 : 0.42
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on opacity { NumberAnimation { duration: 120 } }

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
            enabled: parent.available
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (action === "prev") Players.previous();
                else if (action === "next") Players.next();
                else Players.playPause();
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.contentMargin
        spacing: Math.min(ScalerService.s(6), Math.max(0, root.contentMargin + ScalerService.s(1)))
        visible: !root.vertical

        MiniVinyl {
            diameter: root.miniDiscSize
            player: root.player
            isPlaying: root.playing
            ringColor: root.accent
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: root.archBar ? 0 : ScalerService.s(1)

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: root.archBar
                Layout.preferredHeight: root.archBar ? 0 : Math.min(ScalerService.s(17), Math.max(ScalerService.s(13), root.height - root.contentMargin * 2))
                clip: true
                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.player?.trackTitle || AutoTranslateService.t("No song playing")
                    color: theme.primary.foreground
                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(root.archBar ? 9 : (root.height < ScalerService.s(42) ? 10 : 11)); bold: true }
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
                Layout.preferredHeight: ScalerService.s(10)
                visible: !root.archBar && root.height >= ScalerService.s(48)
                text: root.player?.trackArtist || AutoTranslateService.t("Unknown Artist")
                color: theme.primary.dim_foreground
                font { family: Settings.appearance.font; pixelSize: ScalerService.s(8) }
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.fillWidth: true
                visible: !root.archBar && root.height >= ScalerService.s(52)
                Layout.preferredHeight: ScalerService.s(2)
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
            TransportButton { action: "prev"; diameter: root.sideButtonSize; isPlaying: root.playing; available: !!root.player }
            TransportButton { action: "play"; diameter: root.mainButtonSize; highlighted: true; isPlaying: root.playing; available: !!root.player }
            TransportButton { action: "next"; diameter: root.sideButtonSize; isPlaying: root.playing; available: !!root.player }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.archBar
            ? Math.min(ScalerService.s(3), Math.max(0, root.height * 0.025))
            : Math.min(ScalerService.s(5), Math.max(0, root.height * 0.04))
        spacing: root.archBar
            ? Math.min(ScalerService.s(3), Math.max(0, root.height * 0.025))
            : Math.min(ScalerService.s(5), Math.max(0, root.height * 0.035))
        visible: root.vertical

        MiniVinyl {
            diameter: Math.min(ScalerService.s(root.archBar ? 30 : 38), Math.max(0, Math.min(parent.width - (root.archBar ? ScalerService.s(4) : 0), parent.height - ScalerService.s(2))))
            player: root.player
            isPlaying: root.playing
            ringColor: root.accent
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            text: root.player?.trackTitle || AutoTranslateService.t("No song playing")
            color: theme.primary.foreground
            horizontalAlignment: Text.AlignHCenter
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(root.archBar ? 8 : 9); bold: true }
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
            text: root.player?.trackArtist || AutoTranslateService.t("Unknown Artist")
            color: theme.primary.dim_foreground
            horizontalAlignment: Text.AlignHCenter
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(8) }
            elide: Text.ElideRight
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(root.archBar ? 2 : 3)
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
            diameter: ScalerService.s(root.archBar ? 21 : 26)
            highlighted: true
            isPlaying: root.playing
            available: !!root.player
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
