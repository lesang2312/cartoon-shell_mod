import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import Quickshell.Widgets
import qs.services
import qs.commons
import qs.components

Item {
    id: root

    property real animationProgress: 0
    // true khi đang gõ tên -> DashboardPanel bật nhận phím
    readonly property bool editing: fullnameEdit.editing || usernameEdit.editing

    Loader {
        source: "../../dialogs/FileDialog.qml"
        active: VisibleService.filedialog

        onLoaded: {
            item.visible = Qt.binding(function () {
                return VisibleService.filedialog;
            });

            item.fileOpened.connect(function (fileUrl) {
                Settings.dashboard.urlAvatar = fileUrl;
                VisibleService.togglePanel("filedialog");
            });
        }
    }

    Layout.fillWidth: true
    Layout.fillHeight: true

    // Cửa sổ cần một nhịp để được compositor cấp focus bàn phím, rồi mới focus ô nhập
    Timer {
        id: focusTimer
        interval: 120
        property var target: null
        onTriggered: {
            if (target) {
                target.forceActiveFocus();
                target.selectAll();
            }
        }
    }

    Rectangle {
        GlassPanel { id: glassBg1 }
        anchors.centerIn: parent
        implicitWidth: root.animationProgress > 0.05 ? parent.width : 0
        implicitHeight: root.animationProgress > 0.05 ? parent.height : 0
        color: glassBg1.active ? "transparent" : theme.primary.background
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
        border.color: theme.button.border

        Behavior on implicitHeight {
            NumberAnimation {
                id: heightAnim
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
        Behavior on implicitWidth {
            NumberAnimation {
                id: widthAnim
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
        Loader {
            anchors.fill: parent

            active: !heightAnim.running && !widthAnim.running

            sourceComponent: FloatingCircles {
                circleColor: theme.button.text
                anchors.fill: parent
                circleCount: 1
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(60)
            spacing: ScalerService.s(10)

            // Avatar
            Rectangle {
                id: avatarRoot

                Layout.alignment: Qt.AlignHCenter

                width: ScalerService.s(120)
                height: ScalerService.s(120)
                radius: ScalerService.s(60)

                color: "#2a2a2a"

                property bool hovered: false

                scale: hovered ? 1.05 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 120
                    }
                }

                ClippingRectangle {
                    id: albumArtContainer

                    opacity: root.animationProgress > 0.1 ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                    anchors.fill: parent
                    radius: width / 2

                    color: theme.primary.dim_background

                    border.color: theme.primary.foreground

                    border.width: mouseAreaAvt.containsMouse ? ScalerService.s(2) : ScalerService.s(1)

                    Behavior on border.width {
                        NumberAnimation {
                            duration: 120
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    Image {
                        anchors.fill: parent
                        source: Settings.dashboard.urlAvatar ? Settings.dashboard.urlAvatar : Directories.home + "/Downloads/111423869.png"
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                    }
                    Rectangle {
                        anchors.fill: parent

                        color: "black"
                        opacity: mouseAreaAvt.containsMouse ? 0.4 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }
                    IconText {
                        visible: avatarRoot.hovered ? true : false
                        name: "frame_person"

                        anchors.centerIn: parent

                        font.pixelSize: mouseAreaAvt.containsMouse ? ScalerService.s(58) : ScalerService.s(52)

                        Behavior on font.pixelSize {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseAreaAvt
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: VisibleService.togglePanel("filedialog")

                    onEntered: avatarRoot.hovered = true
                    onExited: avatarRoot.hovered = false
                }
            }

            // Tên + username: bấm vào để sửa (Enter = lưu, Esc = huỷ)
            Item {
                id: fullnameEdit
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: parent.width
                implicitWidth: Math.max(fullnameLabel.implicitWidth, ScalerService.s(60)) + ScalerService.s(26)
                implicitHeight: Math.max(fullnameLabel.implicitHeight, fullnameInput.implicitHeight) + ScalerService.s(6)
                opacity: root.animationProgress > 0.15 ? 1 : 0
                property bool editing: false

                function commit() {
                    if (!editing)
                        return;
                    editing = false;
                    const t = fullnameInput.text.trim();
                    if (t !== "")
                        Settings.dashboard.fullname = t;
                }

                CustomText {
                    id: fullnameLabel
                    anchors.centerIn: parent
                    visible: !fullnameEdit.editing
                    name: Settings.dashboard.fullname
                    textColor: theme.button.text
                    size: "xl"
                    isBold: true
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, fullnameEdit.width - ScalerService.s(26))
                }
                IconText {
                    visible: !fullnameEdit.editing && fullnameMouse.containsMouse
                    anchors.left: fullnameLabel.right
                    anchors.leftMargin: ScalerService.s(4)
                    anchors.verticalCenter: parent.verticalCenter
                    name: "edit"
                    font.pixelSize: ScalerService.s(16)
                }
                TextInput {
                    id: fullnameInput
                    anchors.centerIn: parent
                    width: parent.width - ScalerService.s(12)
                    visible: fullnameEdit.editing
                    horizontalAlignment: TextInput.AlignHCenter
                    color: theme.button.text
                    selectionColor: theme.normal.blue
                    font: fullnameLabel.font
                    maximumLength: 40
                    clip: true
                    selectByMouse: true
                    onAccepted: fullnameEdit.commit()
                    onActiveFocusChanged: if (!activeFocus)
                        fullnameEdit.commit()
                    Keys.onEscapePressed: fullnameEdit.editing = false
                }
                Rectangle {
                    visible: fullnameEdit.editing
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: parent.width - ScalerService.s(12)
                    height: ScalerService.s(2)
                    radius: 1
                    color: theme.normal.blue
                }
                MouseArea {
                    id: fullnameMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !fullnameEdit.editing
                    cursorShape: Qt.IBeamCursor
                    onClicked: {
                        fullnameInput.text = Settings.dashboard.fullname;
                        fullnameEdit.editing = true;
                        focusTimer.target = fullnameInput;
                        focusTimer.restart();
                    }
                }
            }

            Item {
                id: usernameEdit
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -ScalerService.s(12)
                Layout.maximumWidth: parent.width
                implicitWidth: Math.max(usernameLabel.implicitWidth, ScalerService.s(60)) + ScalerService.s(26)
                implicitHeight: Math.max(usernameLabel.implicitHeight, usernameInput.implicitHeight) + ScalerService.s(6)
                opacity: root.animationProgress > 0.2 ? 1 : 0
                property bool editing: false

                function commit() {
                    if (!editing)
                        return;
                    editing = false;
                    const t = usernameInput.text.trim();
                    if (t !== "")
                        Settings.dashboard.username = t;
                }

                CustomText {
                    id: usernameLabel
                    anchors.centerIn: parent
                    visible: !usernameEdit.editing
                    name: Settings.dashboard.username
                    textColor: theme.primary.dim_foreground
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, usernameEdit.width - ScalerService.s(26))
                }
                IconText {
                    visible: !usernameEdit.editing && usernameMouse.containsMouse
                    anchors.left: usernameLabel.right
                    anchors.leftMargin: ScalerService.s(4)
                    anchors.verticalCenter: parent.verticalCenter
                    name: "edit"
                    font.pixelSize: ScalerService.s(14)
                }
                TextInput {
                    id: usernameInput
                    anchors.centerIn: parent
                    width: parent.width - ScalerService.s(12)
                    visible: usernameEdit.editing
                    horizontalAlignment: TextInput.AlignHCenter
                    color: theme.primary.foreground
                    selectionColor: theme.normal.blue
                    font: usernameLabel.font
                    maximumLength: 40
                    clip: true
                    selectByMouse: true
                    onAccepted: usernameEdit.commit()
                    onActiveFocusChanged: if (!activeFocus)
                        usernameEdit.commit()
                    Keys.onEscapePressed: usernameEdit.editing = false
                }
                Rectangle {
                    visible: usernameEdit.editing
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: parent.width - ScalerService.s(12)
                    height: ScalerService.s(2)
                    radius: 1
                    color: theme.normal.blue
                }
                MouseArea {
                    id: usernameMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !usernameEdit.editing
                    cursorShape: Qt.IBeamCursor
                    onClicked: {
                        usernameInput.text = Settings.dashboard.username;
                        usernameEdit.editing = true;
                        focusTimer.target = usernameInput;
                        focusTimer.restart();
                    }
                }
            }
        }
    }
}
