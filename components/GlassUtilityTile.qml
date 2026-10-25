import QtQuick
import qs.components
import qs.services

// Wrapper for an existing utility tile (Share / Sleep / Restart / Power).
// Keep the tile's existing icon, handlers and child content unchanged: move those
// existing children inside this component when replacing the original background Rectangle.
Item {
    id: root

    default property alias contentData: foreground.data

    property real radius: 20
    property color fallbackColor: "#24283a"
    property color tintColor: Qt.rgba(0.12, 0.14, 0.22, 1)
    property real tintAmount: 0.30
    property real tintStrength: 0.70
    property real frost: 1.45
    property real rim: GlassService.rimStrength
    property real saturation: 1.08
    property real thickness: -1
    property color outlineColor: "#b7c9ee"
    property real outlineWidth: 1.5
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
