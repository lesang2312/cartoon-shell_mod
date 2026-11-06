import QtQuick
import qs.modules.panels.settings.audio as Audio

Item {
    property real animationProgress: 0

    Audio.NowPlayingMiniCard {
        anchors.fill: parent
        vertical: true
        embedded: true
    }
}
