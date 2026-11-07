import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.commons
import qs.services
import qs.components

// Thẻ lịch sử clipboard: tìm kiếm, ↑/↓ chọn, Enter hoặc bấm để chép, × để xóa một mục, "Xóa tất cả".
FocusScope {
    id: card

    property var theme: ThemeService.theme
    property bool open: false
    signal closeRequested

    property var entries: []        // [{ id, text, image }]
    property string query: ""
    property bool missing: false    // chưa cài cliphist
    property bool loaded: false
    property bool wipeArmed: false
    property int current: 0

    readonly property color accent: theme.button.text
    readonly property var shown: {
        const q = query.trim().toLowerCase();
        return q === "" ? entries : entries.filter(e => e.text.toLowerCase().indexOf(q) >= 0);
    }

    width: ScalerService.s(400)
    height: Math.min(ScalerService.s(520), (Screen.height > 0 ? Screen.height : 900) - ScalerService.s(112))

    // ---------- dữ liệu ----------
    function parse(text) {
        if (text.indexOf("__MISSING__") === 0) {
            missing = true;
            entries = [];
            loaded = true;
            return;
        }
        missing = false;
        const out = [];
        for (const line of text.split("\n")) {
            const tab = line.indexOf("\t");
            if (tab <= 0)
                continue;
            const id = line.slice(0, tab);
            let body = line.slice(tab + 1);
            const m = body.match(/^\[\[ binary data (.+?) \]\]$/);
            if (m)
                out.push({ id: id, text: "Ảnh  ·  " + m[1], image: true });
            else {
                body = body.replace(/\s+/g, " ").trim();
                if (body !== "")
                    out.push({ id: id, text: body, image: false });
            }
            if (out.length >= 150)
                break;
        }
        entries = out;
        loaded = true;
        current = 0;
    }

    function refresh() {
        wipeArmed = false;
        search.text = "";
        current = 0;
        if (!listProc.running)
            listProc.running = true;
        enter.restart();
        search.forceActiveFocus();
    }

    function pick(i) {
        if (i < 0 || i >= shown.length)
            return;
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$0" | wl-copy', shown[i].id]);
        closeRequested();
    }

    function remove(i) {
        if (i < 0 || i >= shown.length)
            return;
        const id = shown[i].id;
        Quickshell.execDetached(["sh", "-c", 'cliphist list | awk -F"\\t" -v id="$0" \'$1==id\' | cliphist delete', id]);
        entries = entries.filter(e => e.id !== id);
        current = Math.max(0, Math.min(current, shown.length - 1));
    }

    function wipe() {
        Quickshell.execDetached(["cliphist", "wipe"]);
        entries = [];
        wipeArmed = false;
    }

    onOpenChanged: if (open)
        refresh()

    Process {
        id: listProc
        command: ["sh", "-c", 'command -v cliphist >/dev/null 2>&1 || { echo __MISSING__; exit 0; }; cliphist list 2>/dev/null']
        stdout: StdioCollector {
            onStreamFinished: card.parse(text)
        }
    }

    Timer {
        id: wipeTimer
        interval: 2500
        onTriggered: card.wipeArmed = false
    }

    ParallelAnimation {
        id: enter
        NumberAnimation { target: bg; property: "opacity"; from: 0; to: 1; duration: 160 }
        NumberAnimation { target: bg; property: "scale"; from: 0.95; to: 1; duration: 220; easing.type: Easing.OutBack }
    }

    // ---------- giao diện ----------
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: ScalerService.s(Settings.appearance.radius1)
        color: glass.active ? "transparent" : card.theme.primary.background
        border.width: glass.active ? ScalerService.s(1) : ScalerService.s(2)
        border.color: glass.active ? Qt.rgba(1, 1, 1, 0.30) : card.theme.button.border

        GlassPanel {
            id: glass
            tint: 0.05
            frostAmount: 0.16
            rim: 0.78
        }

        // chặn click lọt ra nền (nền sẽ đóng panel)
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(16)
            spacing: ScalerService.s(10)

            // tiêu đề
            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(8)
                Text {
                    text: ""
                    color: card.accent
                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(18) }
                }
                Text {
                    Layout.fillWidth: true
                    text: AutoTranslateService.t("Bảng nhớ tạm") + (card.entries.length > 0 ? "  ·  " + card.entries.length : "")
                    color: card.theme.primary.foreground
                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(16); bold: true }
                }
                Rectangle {
                    visible: card.entries.length > 0
                    implicitWidth: wipeText.implicitWidth + ScalerService.s(22)
                    implicitHeight: ScalerService.s(28)
                    radius: height / 2
                    color: card.wipeArmed ? card.theme.normal.red : (wipeMa.containsMouse ? Qt.alpha(card.theme.normal.red, 0.28) : Qt.alpha(card.theme.button.background, 0.7))
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Text {
                        id: wipeText
                        anchors.centerIn: parent
                        text: card.wipeArmed ? AutoTranslateService.t("Bấm lần nữa để xóa") : AutoTranslateService.t("Xóa tất cả")
                        color: card.wipeArmed ? card.theme.primary.background : card.theme.primary.foreground
                        font { family: Settings.appearance.font; pixelSize: ScalerService.s(12); weight: Font.Medium }
                    }
                    MouseArea {
                        id: wipeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (card.wipeArmed) {
                                card.wipe();
                                wipeTimer.stop();
                            } else {
                                card.wipeArmed = true;
                                wipeTimer.restart();
                            }
                        }
                    }
                }
            }

            // ô tìm kiếm
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(38)
                radius: height / 2
                color: Qt.alpha("#000000", 0.25)
                border.width: ScalerService.s(1)
                border.color: search.activeFocus ? card.accent : Qt.alpha(card.theme.primary.foreground, 0.18)

                Text {
                    x: ScalerService.s(14)
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    color: card.theme.primary.dim_foreground
                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(13) }
                }
                TextInput {
                    id: search
                    anchors.fill: parent
                    anchors.leftMargin: ScalerService.s(38)
                    anchors.rightMargin: ScalerService.s(14)
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    focus: true
                    color: card.theme.primary.foreground
                    selectionColor: card.accent
                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(14) }
                    onTextChanged: {
                        card.query = text;
                        card.current = 0;
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            card.closeRequested();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            card.current = Math.min(card.shown.length - 1, card.current + 1);
                            list.positionViewAtIndex(card.current, ListView.Contain);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            card.current = Math.max(0, card.current - 1);
                            list.positionViewAtIndex(card.current, ListView.Contain);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            card.pick(card.current);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
                            card.remove(card.current);
                            event.accepted = true;
                        }
                    }
                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: search.text === ""
                        text: AutoTranslateService.t("Tìm trong lịch sử…")
                        color: card.theme.primary.dim_foreground
                        font: search.font
                    }
                }
            }

            // danh sách
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: ScalerService.s(6)
                model: card.shown
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool sel: index === card.current
                    width: list.width
                    height: Math.max(ScalerService.s(44), label.implicitHeight + ScalerService.s(20))
                    radius: ScalerService.s(Settings.appearance.radius3 + 4)
                    color: sel ? Qt.alpha(card.theme.button.background_select, 0.95)
                               : (rowMa.containsMouse ? Qt.alpha(card.theme.button.background_select, 0.7) : Qt.alpha(card.theme.button.background, 0.6))
                    border.width: sel ? ScalerService.s(1) : 0
                    border.color: card.accent
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: card.current = row.index
                        onClicked: card.pick(row.index)
                    }

                    Text {
                        id: label
                        anchors.left: parent.left
                        anchors.right: del.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: ScalerService.s(12)
                        anchors.rightMargin: ScalerService.s(6)
                        text: (row.modelData.image ? "  " : "") + row.modelData.text
                        color: row.modelData.image ? card.accent : card.theme.primary.foreground
                        wrapMode: Text.WrapAnywhere
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        font { family: Settings.appearance.font; pixelSize: ScalerService.s(13) }
                    }

                    Rectangle {
                        id: del
                        anchors.right: parent.right
                        anchors.rightMargin: ScalerService.s(8)
                        anchors.verticalCenter: parent.verticalCenter
                        width: ScalerService.s(26)
                        height: width
                        radius: width / 2
                        opacity: (row.sel || rowMa.containsMouse || delMa.containsMouse) ? 1 : 0
                        color: delMa.containsMouse ? card.theme.normal.red : "transparent"
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: delMa.containsMouse ? card.theme.primary.background : card.theme.primary.dim_foreground
                            font { pixelSize: ScalerService.s(17); bold: true }
                        }
                        MouseArea {
                            id: delMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: card.remove(row.index)
                        }
                    }
                }

                // trạng thái rỗng / thiếu công cụ
                Text {
                    anchors.centerIn: parent
                    width: parent.width - ScalerService.s(30)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    visible: card.shown.length === 0
                    text: card.missing ? AutoTranslateService.t("Chưa cài cliphist.\nCài: sudo pacman -S cliphist wl-clipboard")
                        : !card.loaded ? "Đang tải…"
                        : card.query !== "" ? "Không có mục nào khớp."
                        : "Chưa có gì.\nSao chép chữ hoặc ảnh, chúng sẽ hiện ở đây."
                    color: card.missing ? card.theme.normal.yellow : card.theme.primary.dim_foreground
                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(13) }
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: AutoTranslateService.t("↑ ↓ chọn   ·   Enter / bấm để chép   ·   Shift+Del xóa mục   ·   Esc đóng")
                color: card.theme.primary.dim_foreground
                font { family: Settings.appearance.font; pixelSize: ScalerService.s(10) }
            }
        }
    }
}
