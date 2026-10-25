import QtQuick
import qs.components
import qs.services

// Wrapper for an existing directory row (Documents / Downloads / Musics /
// Pictures / ~/.config / ~/.local). Existing icon, label, hover/click handlers
// stay as children; only the row background is replaced by this glass surface.
Item {
    id: root

    default property alias contentData: foreground.data

    property real radius: 12
    property color fallbackColor: "#24283a"
    property color tintColor: Qt.rgba(0.12, 0.14, 0.22, 1)
    property real tintAmount: 0.24
    property real tintStrength: 0.62
    property real frost: 1.2
    property real rim: GlassService.rimStrength
    property real saturation: 1.05
    property real thickness: -1
    property color outlineColor: "#9eafd8"
    property real outlineWidth: 1.1
    property bool forceClear: false
    property bool forceOpaque: false

    GlassSurface {
        anchors.fill: parent
        radius: root.radius
        fallbackColor: root.fallbackColor
        tintColor: root.tintColor
        tintAmount: root.tintAmount
        tintStrength: root.tintStrength
        frost: root.frost
        rim: root.rim
        saturation: root.saturation
        thickness: root.thickness
        forceClear: root.forceClear
        forceOpaque: root.forceOpaque
        z: 0
    }

    Item {
        id: foreground
        anchors.fill: parent
        z: 1
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: root.outlineWidth
        border.color: root.outlineColor
        antialiasing: true
        z: 2
    }
}
