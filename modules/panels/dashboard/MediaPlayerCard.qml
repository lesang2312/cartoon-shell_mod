import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.modules.panels.settings.audio as Audio

// Dashboard media card shares the same player surface as Audio Settings.
Item {
    id: root
    property real animationProgress: 0
    Layout.preferredHeight: ScalerService.s(250)
    Layout.fillWidth: true

    Audio.NowPlayingCard {
        anchors.fill: parent
        opacity: root.animationProgress > 0.2 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }
    }
}
