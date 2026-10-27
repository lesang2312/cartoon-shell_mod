import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import Quickshell
import "." as Com
import qs.services
import qs.commons

// 1 ô trong App Grid.
//  - Click trái : mở app / web đã gán (ô trống -> mở trình chỉnh sửa)
//  - Click phải : mở trình chỉnh sửa (chọn App/Web + chọn ảnh)
Rectangle {
    id: root

    // Dữ liệu của ô: { type: "app"|"web", target, name, icon, autoIcon }
    property var entry: ({})
    property color bgColor: "white"
    property real animationProgress: 0
    property real revealThreshold: 0.6

    // Tương thích dữ liệu cũ: { icon, name }
    readonly property string entryType: entry && entry.type ? entry.type : (entry && entry.name ? "app" : "")
    readonly property string entryTarget: entry && entry.target ? entry.target : (entry && entry.name ? entry.name : "")
    readonly property string entryName: entry && entry.name ? entry.name : ""
    readonly property string entryIcon: entry && entry.icon ? entry.icon : (entry && entry.autoIcon ? entry.autoIcon : "")
    readonly property bool isEmpty: entryType === "" || entryTarget === ""

    signal editRequested

    function launch() {
        if (root.isEmpty) {
            root.editRequested();
            return;
        }
        if (root.entryType === "web") {
            Quickshell.execDetached(["xdg-open", root.entryTarget]);
            return;
        }
        const de = DesktopEntries.heuristicLookup(root.entryTarget);
        if (de)
            de.execute();
        else
            Quickshell.execDetached(["sh", "-c", root.entryTarget]);
    }

    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: ScalerService.s(18)
    color: bgColor
    border.color: theme.button.border
    border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
    opacity: root.animationProgress > revealThreshold ? 1 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }

    Com.AppGridImage {
        anchors.centerIn: parent
        width: parent.width * 0.6
        height: parent.height * 0.6
        source: root.entryIcon
        fallbackText: root.isEmpty ? "+" : root.entryName
        fallbackColor: theme.primary.dim_foreground
        opacity: root.animationProgress > revealThreshold + 0.5 ? 1 : (root.isEmpty ? 0.6 : 0)
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onEntered: root.scale = 1.05
        onExited: root.scale = 1.0
        onClicked: function (ev) {
            if (ev.button === Qt.RightButton)
                root.editRequested();
            else
                root.launch();
        }
    }

    // Tooltip tên (tự đặt) + gợi ý chuột phải
    Rectangle {
        visible: mouse.containsMouse && !root.isEmpty
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: ScalerService.s(4)
        width: hint.implicitWidth + ScalerService.s(10)
        height: hint.implicitHeight + ScalerService.s(4)
        radius: height / 2
        color: Qt.alpha(theme.primary.background, 0.9)
        border.color: theme.button.border
        border.width: 1
        Text {
            id: hint
            anchors.centerIn: parent
            text: root.entryName
            color: theme.primary.foreground
            font.pixelSize: ScalerService.s(10)
            font.family: "ComicShannsMono Nerd Font"
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.width - ScalerService.s(16))
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }
}
