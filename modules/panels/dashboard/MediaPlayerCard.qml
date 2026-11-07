import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.services
import qs.components
import qs.modules.panels.settings.audio as Audio

// Dashboard media card: dùng bản compact của Now Playing (đĩa nhỏ, nút gọn) để vừa đúng khung 220px
// cùng hàng với App Grid; bản đầy đủ cao hơn khung nên bị các ô bên dưới che.
Item {
    id: root
    property real animationProgress: 0
    Layout.preferredHeight: ScalerService.s(220)
    Layout.fillWidth: true

    Audio.NowPlayingCard {
        anchors.fill: parent
        compact: true
        visualizerMode: "short"
        useLiquidGlass: true
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
        border.color: theme.button.border
        opacity: root.animationProgress > 0.2 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }
    }
}
