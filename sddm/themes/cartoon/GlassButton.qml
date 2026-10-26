import QtQuick

// Nút kính mờ: nền trắng trong suốt, viền mảnh, sáng lên khi rê chuột
Item {
    id: btn
    property real unit: 1
    property string label: ""
    property string iconPath: ""
    property string fontFamily: ""
    property real pixelSize: 14
    property bool round: false
    property bool interactive: true
    property bool dim: false
    property color tint: "#FFFFFF"
    property color fill: "#FFFFFF"
    property real fillAlpha: 0.12
    property real iconSize: 22
    signal clicked()

    readonly property bool hovered: ma.containsMouse && interactive
    readonly property bool pressed: ma.pressed && interactive

    implicitWidth: round ? 52 * unit : row.implicitWidth + 32 * unit
    implicitHeight: round ? 52 * unit : 38 * unit
    width: implicitWidth
    height: implicitHeight
    opacity: dim ? 0.5 : 1
    scale: pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(btn.fill.r, btn.fill.g, btn.fill.b, btn.hovered ? btn.fillAlpha + 0.12 : btn.fillAlpha)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, btn.hovered ? 0.45 : 0.22)
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8 * btn.unit
        Icon {
            visible: btn.iconPath !== ""
            path: btn.iconPath
            tint: btn.tint
            width: btn.iconSize * btn.unit; height: width
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: btn.label !== ""
            text: btn.label
            font.family: btn.fontFamily
            font.pixelSize: btn.pixelSize
            font.weight: Font.Medium
            color: btn.tint
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: btn.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (btn.interactive) btn.clicked()
    }
}
