import QtQuick
import QtQuick.Layouts
import Qt.labs.settings as LabsSettings
import qs.commons
import qs.components
import qs.services

Item {
    id: root
    implicitWidth: ScalerService.s(320)
    implicitHeight: ScalerService.s(286)

    property string imageSource: ""
    LabsSettings.Settings {
        id: store
        category: "cartoon_shell_photo_frame"
        property string savedImage: ""
    }

    function alphaColor(value, alpha) {
        const c = Qt.color(value);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    Component.onCompleted: root.imageSource = store.savedImage || ""

    Connections {
        target: PhotoPickerService
        function onImageChosen(fileUrl) {
            root.imageSource = String(fileUrl);
            store.savedImage = root.imageSource;
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: ScalerService.s(20)
        color: root.alphaColor(theme.primary.background, glass.active ? 0.78 : 0.95)
        border.color: Qt.rgba(0.88, 0.92, 1.0, 0.9)
        border.width: ScalerService.s(1.5)
        clip: true

        GlassPanel {
            id: glass
            tint: 0.28
            frostAmount: 0.16
            rim: 0.82
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(11)
            spacing: ScalerService.s(8)

            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(7)

                Rectangle {
                    Layout.preferredWidth: ScalerService.s(32)
                    Layout.preferredHeight: ScalerService.s(32)
                    radius: ScalerService.s(10)
                    color: "#34476A"
                    border.color: "#91B8FF"
                    Text {
                        anchors.centerIn: parent
                        text: "▧"
                        color: "#FFFFFF"
                        font.pixelSize: ScalerService.s(18)
                        font.bold: true
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text { text: "Photo Frame"; color: "#F8FAFF"; font.pixelSize: ScalerService.s(15); font.bold: true }
                    Text { text: "Your favorite memory ♡"; color: "#D0D9EE"; font.pixelSize: ScalerService.s(9) }
                }
                Rectangle {
                    Layout.preferredWidth: ScalerService.s(74)
                    Layout.preferredHeight: ScalerService.s(29)
                    radius: ScalerService.s(9)
                    color: "#344B70"
                    border.color: "#9BBEFF"
                    Text { anchors.centerIn: parent; text: "Chọn ảnh +"; color: "#FFFFFF"; font.pixelSize: ScalerService.s(9); font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: PhotoPickerService.openImagePicker()
                    }
                }
            }

            Rectangle {
                id: photoViewport
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: ScalerService.s(150)
                radius: ScalerService.s(14)
                color: "#20283A"
                border.color: Qt.rgba(0.80, 0.86, 1.0, 0.48)
                clip: true

                Image {
                    id: displayedImage
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(2)
                    source: root.imageSource
                    visible: root.imageSource !== "" && status === Image.Ready
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                }

                Column {
                    anchors.centerIn: parent
                    spacing: ScalerService.s(7)
                    visible: !displayedImage.visible
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: displayedImage.status === Image.Error ? "⚠" : "♡"
                        color: displayedImage.status === Image.Error ? "#FF9BA9" : "#A9C6FF"
                        font.pixelSize: ScalerService.s(34)
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: displayedImage.status === Image.Error ? "Không mở được ảnh này" : "Chạm ‘Chọn ảnh’ để trưng bày"
                        color: "#E4EAF8"
                        font.pixelSize: ScalerService.s(10)
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.imageSource === ""
                        text: "PNG · JPG · WEBP"
                        color: "#AAB8D4"
                        font.pixelSize: ScalerService.s(9)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: root.imageSource === "" ? "Chưa chọn ảnh" : "Ảnh được lưu tự động"
                    color: "#D0D9EE"
                    font.pixelSize: ScalerService.s(9)
                    elide: Text.ElideMiddle
                }
                Rectangle {
                    visible: root.imageSource !== ""
                    Layout.preferredWidth: ScalerService.s(54)
                    Layout.preferredHeight: ScalerService.s(23)
                    radius: ScalerService.s(7)
                    color: "#4A2D42"
                    border.color: "#D887AE"
                    Text { anchors.centerIn: parent; text: "Xóa ảnh"; color: "#FFFFFF"; font.pixelSize: ScalerService.s(9) }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.imageSource = "";
                            store.savedImage = "";
                        }
                    }
                }
            }
        }
    }
}
