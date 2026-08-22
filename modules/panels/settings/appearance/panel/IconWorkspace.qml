import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import qs.services
import qs.components
import qs.commons

ColumnLayout {
    id: root
    property real animationProgress: 0
    spacing: ScalerService.s(15)

    // Header với title và description
    RowLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(10)

        CustomText {
            name: "Icon Workspace"
            isBold: true
            Layout.fillWidth: true
        }
    }

    // Quét thư mục assets/workspace, mỗi thư mục con = 1 bộ icon workspace
    // Chỉ cần thư mục có active.png (trạng thái đang chọn) và exsis.png (trạng thái bình thường)
    FolderListModel {
        id: workspaceFolders
        folder: "file://" + Directories.assetsPath + "/workspace"
        showDirs: true
        showFiles: false
        showDotAndDotDot: false
        showHidden: false
        sortField: FolderListModel.Name
    }

    // Grid hiển thị các icon, số ô = số thư mục con quét được
    GridLayout {
        Layout.fillWidth: true
        columns: Math.min(8, Math.floor(root.width / ScalerService.s(50)))
        rowSpacing: ScalerService.s(8)
        columnSpacing: ScalerService.s(8)

        Repeater {
            model: workspaceFolders

            delegate: Item {
                id: delegateItem
                required property string fileName
                readonly property bool selected: Settings.bar.iconWorkspace === fileName

                Layout.fillWidth: true
                Layout.preferredHeight: width

                Rectangle {
                    id: container
                    implicitWidth: 0
                    anchors.centerIn: delegateItem
                    implicitHeight: 0
                    SequentialAnimation on implicitWidth {
                        running: root.animationProgress > 0.2

                        PauseAnimation {
                            duration: index * 15
                        }

                        NumberAnimation {
                            to: delegateItem.width
                            duration: 500
                            easing.type: Easing.OutCubic
                        }
                    }
                    SequentialAnimation on implicitHeight {
                        running: root.animationProgress > 0.2

                        PauseAnimation {
                            duration: index * 15
                        }

                        NumberAnimation {
                            to: delegateItem.height
                            duration: 500
                            easing.type: Easing.OutCubic
                        }
                    }
                    anchors.margins: ScalerService.s(2)
                    radius: ScalerService.s(12)

                    color: {
                        if (delegateItem.selected) {
                            return Qt.alpha(theme.button.text, 0.15);
                        }
                        return mouseArea.containsMouse ? Qt.alpha(theme.button.background_select, 0.4) : Qt.alpha(theme.button.background, 0.2);
                    }

                    border.color: {
                        if (delegateItem.selected) {
                            return Qt.alpha(theme.button.text, 0.8);
                        }
                        return mouseArea.containsPress ? Qt.alpha(theme.button.border_select, 0.6) : Qt.alpha(theme.button.border, 0.3);
                    }
                    border.width: ScalerService.s(2)

                    // Animation cho border và background
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                    Behavior on border.color {
                        ColorAnimation {
                            duration: 200
                        }
                    }

                    // active.png khi đang được chọn, exsis.png khi bình thường
                    IconImage {
                        anchors.centerIn: parent
                        path: `workspace/${delegateItem.fileName}/active.png`
                    }

                    // Mouse area
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            SoundService.playSound("pick");
                            Settings.bar.styleWorkspace = "image";
                            Settings.bar.iconWorkspace = delegateItem.fileName;
                        }
                    }
                }
            }
        }
    }
}
