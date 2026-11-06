import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel // Import module để đọc thư mục tự động
import qs.services
import qs.components
import qs.commons

ColumnLayout {
    id: root
    property real animationProgress: 0
    spacing: ScalerService.s(15)

    // Cần trỏ đúng đường dẫn đến thư mục chứa các folder icon (ví dụ: assets/workspace)
    // Bạn hãy điều chỉnh số lượng "../" cho khớp với cấu trúc thư mục thực tế của dự án.
    property string iconsFolderPath: Qt.resolvedUrl("../../../../../assets/workspace")

    RowLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(10)

        CustomText {
            name: LanguageService.t("icons", "workspace_icons")
            size: "small"
            isBold: true
            Layout.fillWidth: true
        }
    }

    // Tự động quét các folder nằm trong thư mục iconsFolderPath
    FolderListModel {
        id: imageFolderModel
        folder: root.iconsFolderPath
        showDirs: true
        showFiles: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name // Sắp xếp theo tên alpha-b
    }

    CustomText {
        Layout.fillWidth: true
        name: LanguageService.t("icons", "choose_workspace_icon")
        size: "xs"
        textColor: theme.primary.dim_foreground
        wrapMode: Text.WordWrap
    }

    GridLayout {
        Layout.fillWidth: true
        columns: Math.max(3, Math.min(7, Math.floor(root.width / ScalerService.s(64))))
        rowSpacing: ScalerService.s(8)
        columnSpacing: ScalerService.s(8)

        Repeater {
            // Sử dụng danh sách thư mục tự động quét được làm model
            model: imageFolderModel

            delegate: Item {
                id: delegateItem
                Layout.fillWidth: true
                Layout.preferredHeight: width + ScalerService.s(17)
                
                Rectangle {
                    id: container
                    implicitWidth: 0
                    implicitHeight: 0
                    anchors.top: delegateItem.top
                    anchors.horizontalCenter: delegateItem.horizontalCenter
                    property real currentOpacity: 0
                    width: implicitWidth
                    height: implicitHeight

                    SequentialAnimation on currentOpacity {
                        running: root.animationProgress > 0.2
                        PauseAnimation { duration: index * 15 }
                        NumberAnimation { to: 1; duration: 500; easing.type: Easing.OutCubic }
                    }
                    SequentialAnimation on implicitWidth {
                        running: root.animationProgress > 0.1
                        PauseAnimation { duration: index * 15 }
                        NumberAnimation { to: delegateItem.width; duration: 500; easing.type: Easing.OutCubic }
                    }
                    SequentialAnimation on implicitHeight {
                        running: root.animationProgress > 0.1
                        PauseAnimation { duration: index * 15 }
                        NumberAnimation { to: delegateItem.width; duration: 500; easing.type: Easing.OutCubic }
                    }

                    anchors.margins: ScalerService.s(2)
                    radius: ScalerService.s(12)
                    
                    // LƯU Ý: fileName là biến mặc định của FolderListModel, nó chứa tên của thư mục (vd: "pacman", "luffy")
                    color: Settings.bar.iconWorkspace === fileName ? Qt.alpha(theme.button.text, 0.6) : (mouseArea.containsMouse ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6))
                    border.color: Settings.bar.iconWorkspace === fileName ? Qt.alpha(theme.button.text, 0.6) : (mouseArea.containsPress ? Qt.alpha(theme.button.border_select, 0.6) : Qt.alpha(theme.button.border, 0.6))
                    border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    // Icon Image - Tự động trỏ path dựa vào tên thư mục
                    IconImage {
                        id: iconImage
                        anchors.centerIn: parent
                        path: `workspace/${fileName}/active.png`
                        opacity: container.currentOpacity
                        width: Math.min(container.width, ScalerService.s(42))
                        height: Math.min(container.height, ScalerService.s(42))
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            SoundService.playSound("pick");
                            // Vì bây giờ tất cả đều là ảnh, ta gán thẳng styleWorkspace = "image"
                            Settings.bar.styleWorkspace = "image";
                            Settings.bar.iconWorkspace = fileName;
                        }
                        onEntered: {
                            SoundService.playSound("hover");
                        }
                    }
                }
                CustomText {
                    anchors.top: container.bottom
                    anchors.topMargin: ScalerService.s(2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    name: String(fileName).replace(/[-_]/g, " ")
                    size: "2xs"
                    textColor: Settings.bar.iconWorkspace === fileName ? theme.button.text : theme.primary.dim_foreground
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }
        }
    }
}