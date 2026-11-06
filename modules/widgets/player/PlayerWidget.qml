import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.modules.panels.settings.audio as Audio

// Widget uses the same Now Playing card as Settings and the Music popup.
Item {
    id: root
    // A shorter base width keeps the widget readable at normal desktop scale.
    // The compact card reduces the vinyl, typography and transport controls together.
    implicitWidth: ScalerService.s(336)
    // Fit the widget frame to the actual compact player content. The previous
    // fixed 216px height left a large empty strip below the transport controls.
    implicitHeight: playerCard.implicitHeight

    Audio.NowPlayingCard {
        id: playerCard
        x: 0
        y: 0
        width: parent.width
        height: implicitHeight
        compact: true
        visualizerMode: "short"
    }
}
