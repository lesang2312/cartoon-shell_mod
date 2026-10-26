import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.components
import qs.services

// Ô Quick Settings kiểu Win11. Nếu hasDetail = true thì tách đôi: bấm trái = bật/tắt, bấm mũi tên phải = mở chi tiết.
Rectangle {
    id: tile

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    property bool hasDetail: false
    property bool available: true

    signal toggled
    signal detailRequested

    readonly property color fg: checked ? theme.primary.background : theme.primary.foreground
    readonly property color fgDim: checked ? Qt.alpha(theme.primary.background, 0.75) : theme.primary.dim_foreground

    Layout.fillWidth: true
    Layout.preferredHeight: ScalerService.s(60)
    radius: ScalerService.s(8)
    opacity: available ? 1 : 0.45
    color: checked ? theme.button.text : (mainArea.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.08))
    border.width: ScalerService.s(1)
    border.color: checked ? Qt.alpha(theme.button.text, 0.6) : Qt.rgba(1, 1, 1, 0.1)
    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    // Vùng chính (bật/tắt)
    Item {
        id: mainPart
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            right: tile.hasDetail ? chevronPart.left : parent.right
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: ScalerService.s(12)
            anchors.rightMargin: ScalerService.s(6)
            spacing: ScalerService.s(10)

            IconText {
                name: tile.icon
                size: "small"
                textColor: tile.fg
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                CustomText {
                    Layout.fillWidth: true
                    name: tile.title
                    size: "xs"
                    isBold: true
                    textColor: tile.fg
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                CustomText {
                    Layout.fillWidth: true
                    name: tile.subtitle
                    size: "2xs"
                    textColor: tile.fgDim
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        MouseArea {
            id: mainArea
            anchors.fill: parent
            enabled: tile.available
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                SoundService.playSound("pick");
                tile.toggled();
            }
        }
    }

    // Vạch ngăn + mũi tên chi tiết
    Item {
        id: chevronPart
        visible: tile.hasDetail
        width: tile.hasDetail ? ScalerService.s(38) : 0
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                topMargin: ScalerService.s(8)
                bottomMargin: ScalerService.s(8)
            }
            width: ScalerService.s(1)
            color: Qt.alpha(tile.fg, 0.3)
        }
        IconText {
            anchors.centerIn: parent
            name: "chevron_right"
            size: "small"
            textColor: tile.fg
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                SoundService.playSound("pick");
                tile.detailRequested();
            }
        }
    }
}
