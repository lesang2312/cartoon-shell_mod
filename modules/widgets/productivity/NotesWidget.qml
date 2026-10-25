import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.settings as LabsSettings
import qs.commons
import qs.components
import qs.services

Item {
    id: root
    implicitWidth: ScalerService.s(380)
    implicitHeight: ScalerService.s(294)

    property string noteText: ""
    property bool ready: false
    LabsSettings.Settings {
        id: store
        category: "cartoon_shell_sticky_notes"
        property string savedNote: ""
    }

    function alphaColor(value, alpha) {
        const c = Qt.color(value);
        return Qt.rgba(c.r, c.g, c.b, c.a * alpha);
    }

    Component.onCompleted: {
        root.noteText = store.savedNote || "";
        root.ready = true;
    }
    Component.onDestruction: store.savedNote = root.noteText

    Timer {
        id: saveTimer
        interval: 350
        repeat: false
        onTriggered: store.savedNote = root.noteText
    }

    Rectangle {
        anchors.fill: parent
        radius: ScalerService.s(18)
        color: root.alphaColor(theme.primary.background, glass.active ? 0.72 : 0.92)
        border.color: Qt.rgba(0.88, 0.92, 1.0, 0.90)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 1
        clip: true
        GlassPanel { id: glass; tint: 0.28; frostAmount: 0.16; rim: 0.82 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(12)
            spacing: ScalerService.s(8)

            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(6)
                Text { text: "✎"; color: theme.normal.yellow; font.pixelSize: ScalerService.s(21) }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text { text: "Sticky note"; color: theme.button.text; font.pixelSize: ScalerService.s(16); font.bold: true }
                    Text { text: "Tự lưu · ghi chú riêng của bạn"; color: theme.primary.dim_foreground; font.pixelSize: ScalerService.s(10) }
                }
                Rectangle {
                    Layout.preferredWidth: ScalerService.s(55)
                    Layout.preferredHeight: ScalerService.s(26)
                    radius: ScalerService.s(8)
                    color: root.alphaColor(theme.normal.red, 0.14)
                    border.color: root.alphaColor(theme.normal.red, 0.3)
                    Text { anchors.centerIn: parent; text: "Xóa"; color: theme.button.text; font.pixelSize: ScalerService.s(10) }
                    MouseArea { anchors.fill: parent; onClicked: { root.noteText = ""; editor.text = ""; store.savedNote = "" } }
                }
            }

            TextArea {
                id: editor
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: root.noteText
                placeholderText: "Viết ý tưởng, việc cần nhớ, link quan trọng...\n\nNội dung sẽ tự lưu khi bạn dừng gõ."
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                color: "#F8FAFF"
                selectedTextColor: theme.primary.background
                selectionColor: theme.normal.blue
                font.pixelSize: ScalerService.s(12)
                background: Rectangle {
                    radius: ScalerService.s(12)
                    color: Qt.rgba(1, 1, 1, 0.09)
                    border.color: root.alphaColor(theme.button.border, 0.58)
                }
                onTextChanged: {
                    if (!root.ready)
                        return;
                    root.noteText = text;
                    saveTimer.restart();
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "♡  Your little space"; color: theme.primary.dim_foreground; font.pixelSize: ScalerService.s(10); Layout.fillWidth: true }
                Text { text: root.noteText.length + " ký tự"; color: theme.primary.dim_foreground; font.pixelSize: ScalerService.s(10) }
            }
        }
    }
}
