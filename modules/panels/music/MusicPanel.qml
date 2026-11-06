import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.commons
import qs.components
import qs.modules.panels.settings.audio as Audio
import "." as Com

PanelWindow {
    id: root

    property real animationProgress: 0
    SequentialAnimation on animationProgress {
        running: true
        NumberAnimation {
            from: 0
            to: 2
            duration: 1000
            easing.type: Easing.Linear
        }
    }

    implicitWidth: ScalerService.s(500)
    implicitHeight: ScalerService.s(350)
    focusable: true

    anchors {
        top: Settings.bar.position === "top"
        bottom: Settings.bar.position === "bottom"
        left: Settings.bar.position === "top" || Settings.bar.position === "bottom" || Settings.bar.position === "left"
        right: Settings.bar.position === "right"
    }
    margins {
        top: Settings.bar.position === "top" ? ScalerService.s(10) : 0
        bottom: Settings.bar.position === "bottom" ? ScalerService.s(10) : 0
        left: (Settings.bar.position === "top" || Settings.bar.position === "bottom") ? ScalerService.s(400) : ScalerService.s(10)
        right: Settings.bar.position === "right" ? ScalerService.s(10) : 0
    }

    exclusiveZone: 0
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
        border.color: theme.button.border
        color: glassBg.active ? "transparent" : theme.primary.background
        GlassPanel { id: glassBg }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(16)
            spacing: ScalerService.s(10)

            Com.MusicHeader {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(34)
                animationProgress: root.animationProgress
            }

            // Use the exact same Now Playing surface as Settings.
            Audio.NowPlayingCard {
                Layout.fillWidth: true
                compact: false
                visualizerMode: "long"
            }
        }

        Loader {
            anchors.fill: parent
            active: true
            sourceComponent: StarField {
                starCount: 10
                shootingStarCount: 2
            }
        }
    }
}
