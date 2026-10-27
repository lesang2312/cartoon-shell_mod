import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import "." as Com
import qs.services
import qs.commons
import qs.components

// Trình chỉnh sửa 1 ô của App Grid (overlay phủ lên Dashboard).
//   Bước 1: chọn mở APP hay WEB  (+ tên tự đặt tự động, vẫn sửa tay được)
//   Bước 2: chọn ảnh hiển thị    (gợi ý từ ~/.config/quickshell/cartoon-shell/icons,
//                                  hoặc "Browse…" chọn ảnh bất kỳ, hoặc "Auto" = icon của app/web)
Item {
    id: root
    visible: false
    z: 100

    // ---- trạng thái đang sửa ----
    property int slotIndex: -1
    property string mode: "app"          // "app" | "web"
    property string appId: ""            // DesktopEntry.id
    property string appIconName: ""      // icon theme của app (dùng cho "Auto")
    property string webUrl: ""
    property string nameText: ""
    property bool nameEdited: false      // true = người dùng tự gõ tên -> không auto nữa
    property string iconPath: ""         // "" = Auto
    property string search: ""
    property bool waitingPicker: false

    readonly property string iconsDir: Quickshell.shellDir + "/icons"
    readonly property string fontName: "ComicShannsMono Nerd Font"
    // Khi Liquid Glass bật: các ô/nút bên trong là lớp trắng mờ trong suốt để thấy kính phía sau
    readonly property color ctrlBg: glassCard.active ? Qt.rgba(1, 1, 1, 0.12) : theme.button.background

    // ======================= Tên tự động =======================
    function hostOf(u) {
        const m = /^(?:[a-z][a-z0-9+.-]*:\/\/)?([^\/?#:\s]+)/i.exec((u || "").trim());
        return m ? m[1].toLowerCase() : "";
    }
    function normalizeUrl(u) {
        const s = (u || "").trim();
        if (s === "")
            return "";
        return /^[a-z][a-z0-9+.-]*:\/\//i.test(s) ? s : "https://" + s;
    }
    // youtube.com -> Youtube | mail.google.com -> Google | bbc.co.uk -> Bbc
    function nameFromUrl(u) {
        let h = hostOf(u).replace(/^www\./, "");
        if (h === "" || h.indexOf(".") < 0)
            return "";
        const p = h.split(".");
        const second = ["co", "com", "org", "net", "gov", "edu", "ac"];
        let label = p[p.length - 2];
        if (p.length >= 3 && second.indexOf(label) >= 0 && p[p.length - 1].length === 2)
            label = p[p.length - 3];
        return label.charAt(0).toUpperCase() + label.slice(1);
    }
    function faviconFor(u) {
        const h = hostOf(u);
        return h.indexOf(".") > 0 ? "https://www.google.com/s2/favicons?domain=" + h + "&sz=128" : "";
    }
    readonly property string autoName: mode === "web" ? nameFromUrl(webUrl) : (appName)
    property string appName: ""
    readonly property string autoIcon: mode === "web" ? faviconFor(webUrl) : appIconName
    readonly property string previewIcon: iconPath !== "" ? iconPath : autoIcon
    readonly property string shownName: nameEdited ? nameText : autoName
    readonly property bool canSave: mode === "web" ? hostOf(webUrl).indexOf(".") > 0 : appId !== ""

    // ======================= Mở / đóng =======================
    function openFor(index) {
        const a = Settings.dashboard.appGrid || [];
        const e = a[index] || {};
        slotIndex = index;
        search = "";
        waitingPicker = false;

        const type = e.type ? e.type : (e.name ? "app" : "");
        mode = type === "web" ? "web" : "app";
        appId = mode === "app" ? (e.target || e.name || "") : "";
        appName = "";
        appIconName = mode === "app" ? (e.autoIcon || "") : "";
        webUrl = mode === "web" ? (e.target || "") : "";
        iconPath = e.icon || "";

        // Tên cũ khác tên auto => coi như người dùng đã tự đặt
        nameText = e.name || "";
        nameEdited = false;
        if (mode === "app" && appId !== "") {
            const de = DesktopEntries.heuristicLookup(appId);
            if (de) {
                appName = de.name || "";
                if (appIconName === "")
                    appIconName = de.icon || "";
            }
        }
        if (nameText !== "" && nameText.toLowerCase() !== autoName.toLowerCase())
            nameEdited = true;

        visible = true;
        scope.forceActiveFocus();
        if (mode === "web")
            urlInput.forceActiveFocus();
        else
            searchInput.forceActiveFocus();
    }

    function close() {
        visible = false;
        waitingPicker = false;
    }

    function writeSlots(mutate) {
        const cur = Settings.dashboard.appGrid || [];
        const out = [];
        for (let i = 0; i < 9; i++)
            out.push(cur[i] || ({}));
        mutate(out);
        Settings.dashboard.appGrid = out;
    }

    function save() {
        if (!canSave)
            return;
        const target = mode === "web" ? normalizeUrl(webUrl) : appId;
        const entry = {
            "type": mode,
            "target": target,
            "name": shownName !== "" ? shownName : target,
            "icon": iconPath,
            "autoIcon": autoIcon
        };
        writeSlots(function (arr) {
            arr[slotIndex] = entry;
        });
        close();
    }

    function clearSlot() {
        writeSlots(function (arr) {
            arr[slotIndex] = ({});
        });
        close();
    }

    // Ảnh chọn từ file picker chung của shell
    Connections {
        target: PhotoPickerService
        function onImageChosen(fileUrl) {
            if (!root.waitingPicker)
                return;
            root.waitingPicker = false;
            root.iconPath = decodeURIComponent(String(fileUrl).replace(/^file:\/\//, ""));
        }
    }

    // ======================= UI =======================
    FocusScope {
        id: scope
        anchors.fill: parent
        Keys.onEscapePressed: root.close()

        // nền mờ, bấm ra ngoài = huỷ
        Rectangle {
            anchors.fill: parent
            color: "#99000000"
            radius: ScalerService.s(Settings.appearance.radius1)
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(parent.width - ScalerService.s(40), ScalerService.s(600))
            height: Math.min(parent.height - ScalerService.s(24), ScalerService.s(560))
            radius: ScalerService.s(Settings.appearance.radius1)
            color: glassCard.active ? "transparent" : theme.primary.background
            border.color: glassCard.active ? Qt.rgba(1, 1, 1, 0.34) : theme.button.border
            border.width: glassCard.active ? ScalerService.s(1) : ScalerService.s(2)

            // Liquid Glass cho hộp chỉnh App Grid
            GlassPanel {
                id: glassCard
            }

            MouseArea {
                anchors.fill: parent
            }   // chặn click xuyên xuống nền

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: ScalerService.s(16)
                spacing: ScalerService.s(8)

                // ---------- Tiêu đề + preview ----------
                RowLayout {
                    Layout.fillWidth: true
                    spacing: ScalerService.s(10)

                    Rectangle {
                        Layout.preferredWidth: ScalerService.s(46)
                        Layout.preferredHeight: ScalerService.s(46)
                        radius: ScalerService.s(14)
                        color: root.ctrlBg
                        border.color: theme.button.border
                        border.width: 1
                        Com.AppGridImage {
                            anchors.centerIn: parent
                            width: parent.width * 0.7
                            height: parent.height * 0.7
                            source: root.previewIcon
                            fallbackText: root.shownName
                            fallbackColor: theme.primary.dim_foreground
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: "App Grid · " + (root.slotIndex + 1)
                            color: theme.primary.foreground
                            font.pixelSize: ScalerService.s(20)
                            font.bold: true
                            font.family: root.fontName
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.shownName !== "" ? root.shownName : "—"
                            color: theme.primary.dim_foreground
                            font.pixelSize: ScalerService.s(13)
                            font.family: root.fontName
                            elide: Text.ElideRight
                        }
                    }
                }

                // ---------- Bước 1: App / Web ----------
                Text {
                    text: "1 · Open an app or a website"
                    color: theme.primary.foreground
                    font.pixelSize: ScalerService.s(14)
                    font.bold: true
                    font.family: root.fontName
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: ScalerService.s(8)
                    Repeater {
                        model: [
                            {
                                "key": "app",
                                "label": "  App"
                            },
                            {
                                "key": "web",
                                "label": "󰖟  Web"
                            }
                        ]
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: ScalerService.s(34)
                            radius: height / 2
                            readonly property bool on: root.mode === modelData.key
                            color: on ? theme.normal.blue : root.ctrlBg
                            border.color: theme.button.border
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: parent.on ? theme.primary.background : theme.primary.foreground
                                font.pixelSize: ScalerService.s(14)
                                font.bold: true
                                font.family: root.fontName
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.mode = modelData.key;
                                    if (root.mode === "web")
                                        urlInput.forceActiveFocus();
                                    else
                                        searchInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                // Vùng nội dung bước 1 (cao cố định)
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScalerService.s(140)

                    // ----- APP: tìm + danh sách -----
                    ColumnLayout {
                        anchors.fill: parent
                        visible: root.mode === "app"
                        spacing: ScalerService.s(6)

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: ScalerService.s(32)
                            radius: ScalerService.s(10)
                            color: root.ctrlBg
                            border.color: searchInput.activeFocus ? theme.normal.blue : theme.button.border
                            border.width: 1
                            TextInput {
                                id: searchInput
                                anchors.fill: parent
                                anchors.leftMargin: ScalerService.s(10)
                                anchors.rightMargin: ScalerService.s(10)
                                verticalAlignment: TextInput.AlignVCenter
                                color: theme.primary.foreground
                                font.pixelSize: ScalerService.s(13)
                                font.family: root.fontName
                                clip: true
                                text: root.search
                                onTextChanged: root.search = text
                                Keys.onEscapePressed: root.close()
                                Text {
                                    visible: parent.text === ""
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Search apps…"
                                    color: theme.primary.dim_foreground
                                    font: parent.font
                                }
                            }
                        }

                        ListView {
                            id: appList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: ScalerService.s(3)
                            boundsBehavior: Flickable.StopAtBounds
                            model: {
                                const q = root.search.toLowerCase();
                                const v = DesktopEntries.applications.values;
                                const arr = [];
                                for (let i = 0; i < v.length; i++) {
                                    const e = v[i];
                                    if (e.noDisplay)
                                        continue;
                                    const n = (e.name || "").toLowerCase();
                                    const id = (e.id || "").toLowerCase();
                                    if (q === "" || n.indexOf(q) >= 0 || id.indexOf(q) >= 0)
                                        arr.push(e);
                                }
                                arr.sort(function (a, b) {
                                    return (a.name || "").toLowerCase().localeCompare((b.name || "").toLowerCase());
                                });
                                return arr;
                            }

                            delegate: Rectangle {
                                width: appList.width
                                height: ScalerService.s(32)
                                radius: ScalerService.s(8)
                                readonly property bool picked: root.appId === modelData.id
                                color: picked ? Qt.alpha(theme.normal.blue, 0.3) : (rowMouse.containsMouse ? Qt.alpha(root.ctrlBg, 0.8) : "transparent")
                                border.color: picked ? theme.normal.blue : "transparent"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: ScalerService.s(8)
                                    anchors.rightMargin: ScalerService.s(8)
                                    spacing: ScalerService.s(8)
                                    Com.AppGridImage {
                                        Layout.preferredWidth: ScalerService.s(22)
                                        Layout.preferredHeight: ScalerService.s(22)
                                        source: modelData.icon || ""
                                        fallbackText: modelData.name
                                        fallbackColor: theme.primary.dim_foreground
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: theme.primary.foreground
                                        font.pixelSize: ScalerService.s(13)
                                        font.family: root.fontName
                                        elide: Text.ElideRight
                                    }
                                }
                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.appId = modelData.id;
                                        root.appName = modelData.name || "";
                                        root.appIconName = modelData.icon || "";
                                        // chọn app khác => quay lại tên tự động
                                        root.nameEdited = false;
                                    }
                                }
                            }
                        }
                    }

                    // ----- WEB: nhập URL -----
                    ColumnLayout {
                        anchors.fill: parent
                        visible: root.mode === "web"
                        spacing: ScalerService.s(6)

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: ScalerService.s(36)
                            radius: ScalerService.s(10)
                            color: root.ctrlBg
                            border.color: urlInput.activeFocus ? theme.normal.blue : theme.button.border
                            border.width: 1
                            TextInput {
                                id: urlInput
                                anchors.fill: parent
                                anchors.leftMargin: ScalerService.s(10)
                                anchors.rightMargin: ScalerService.s(10)
                                verticalAlignment: TextInput.AlignVCenter
                                color: theme.primary.foreground
                                font.pixelSize: ScalerService.s(14)
                                font.family: root.fontName
                                clip: true
                                inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoPredictiveText
                                text: root.webUrl
                                onTextChanged: {
                                    root.webUrl = text;
                                    // đổi URL => tên tự cập nhật theo (trừ khi bạn đã tự gõ tên)
                                }
                                Keys.onReturnPressed: root.save()
                                Keys.onEscapePressed: root.close()
                                Text {
                                    visible: parent.text === ""
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "youtube.com  hoặc  https://…"
                                    color: theme.primary.dim_foreground
                                    font: parent.font
                                }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Tên và icon sẽ tự lấy theo tên miền (vd. youtube.com → Youtube). Bạn vẫn sửa tay được bên dưới."
                            color: theme.primary.dim_foreground
                            font.pixelSize: ScalerService.s(12)
                            font.family: root.fontName
                            wrapMode: Text.WordWrap
                        }
                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }

                // ---------- Tên (tự động) ----------
                RowLayout {
                    Layout.fillWidth: true
                    spacing: ScalerService.s(8)
                    Text {
                        text: "Name"
                        color: theme.primary.foreground
                        font.pixelSize: ScalerService.s(14)
                        font.bold: true
                        font.family: root.fontName
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScalerService.s(32)
                        radius: ScalerService.s(10)
                        color: root.ctrlBg
                        border.color: nameInput.activeFocus ? theme.normal.blue : theme.button.border
                        border.width: 1
                        TextInput {
                            id: nameInput
                            anchors.fill: parent
                            anchors.leftMargin: ScalerService.s(10)
                            anchors.rightMargin: ScalerService.s(60)
                            verticalAlignment: TextInput.AlignVCenter
                            color: theme.primary.foreground
                            font.pixelSize: ScalerService.s(13)
                            font.family: root.fontName
                            clip: true
                            // Hiện tên tự động, gõ vào = chuyển sang tên tự đặt
                            text: root.shownName
                            onTextEdited: {
                                root.nameText = text;
                                root.nameEdited = true;
                            }
                            Keys.onReturnPressed: root.save()
                            Keys.onEscapePressed: root.close()
                        }
                        // Nhãn Auto / nút quay lại auto
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: ScalerService.s(6)
                            width: autoLabel.implicitWidth + ScalerService.s(14)
                            height: ScalerService.s(20)
                            radius: height / 2
                            color: root.nameEdited ? theme.normal.yellow : theme.normal.green
                            Text {
                                id: autoLabel
                                anchors.centerIn: parent
                                text: root.nameEdited ? "↺ Auto" : "Auto"
                                color: theme.primary.background
                                font.pixelSize: ScalerService.s(11)
                                font.bold: true
                                font.family: root.fontName
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: root.nameEdited
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.nameEdited = false
                            }
                        }
                    }
                }

                // ---------- Bước 2: Ảnh ----------
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "2 · Image"
                        color: theme.primary.foreground
                        font.pixelSize: ScalerService.s(14)
                        font.bold: true
                        font.family: root.fontName
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "gợi ý từ ~/.config/quickshell/cartoon-shell/icons"
                        color: theme.primary.dim_foreground
                        font.pixelSize: ScalerService.s(11)
                        font.family: root.fontName
                        elide: Text.ElideMiddle
                    }
                }

                Flickable {
                    id: imgFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: ScalerService.s(64)
                    clip: true
                    contentWidth: width
                    contentHeight: imgFlow.height
                    boundsBehavior: Flickable.StopAtBounds

                    Flow {
                        id: imgFlow
                        width: imgFlick.width
                        spacing: ScalerService.s(8)

                        // Auto: dùng icon của app / favicon của web
                        Rectangle {
                            width: ScalerService.s(54)
                            height: ScalerService.s(54)
                            radius: ScalerService.s(14)
                            readonly property bool picked: root.iconPath === ""
                            color: root.ctrlBg
                            border.color: picked ? theme.normal.green : theme.button.border
                            border.width: picked ? 3 : 1
                            Column {
                                anchors.centerIn: parent
                                spacing: 0
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "✨"
                                    font.pixelSize: ScalerService.s(18)
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Auto"
                                    color: theme.primary.foreground
                                    font.pixelSize: ScalerService.s(10)
                                    font.family: root.fontName
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.iconPath = ""
                            }
                        }

                        // Browse: mở file picker chung của shell
                        Rectangle {
                            width: ScalerService.s(54)
                            height: ScalerService.s(54)
                            radius: ScalerService.s(14)
                            color: root.ctrlBg
                            border.color: root.waitingPicker ? theme.normal.blue : theme.button.border
                            border.width: root.waitingPicker ? 3 : 1
                            Column {
                                anchors.centerIn: parent
                                spacing: 0
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "📁"
                                    font.pixelSize: ScalerService.s(18)
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Browse"
                                    color: theme.primary.foreground
                                    font.pixelSize: ScalerService.s(10)
                                    font.family: root.fontName
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.waitingPicker = true;
                                    PhotoPickerService.openImagePicker();
                                }
                            }
                        }

                        // Ảnh đã chọn nhưng nằm ngoài thư mục icons
                        Rectangle {
                            visible: root.iconPath !== "" && root.iconPath.indexOf(root.iconsDir + "/") !== 0
                            width: visible ? ScalerService.s(54) : 0
                            height: ScalerService.s(54)
                            radius: ScalerService.s(14)
                            color: root.ctrlBg
                            border.color: theme.normal.green
                            border.width: 3
                            Com.AppGridImage {
                                anchors.centerIn: parent
                                width: parent.width * 0.72
                                height: parent.height * 0.72
                                source: root.iconPath
                                fallbackText: "?"
                                fallbackColor: theme.primary.dim_foreground
                            }
                        }

                        // Gợi ý: toàn bộ ảnh trong thư mục icons
                        Repeater {
                            model: FolderListModel {
                                folder: "file://" + root.iconsDir
                                nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.svg", "*.webp"]
                                showDirs: false
                                sortField: FolderListModel.Name
                            }
                            Rectangle {
                                width: ScalerService.s(54)
                                height: ScalerService.s(54)
                                radius: ScalerService.s(14)
                                readonly property bool picked: root.iconPath === filePath
                                color: tileMouse.containsMouse ? Qt.alpha(root.ctrlBg, 0.8) : root.ctrlBg
                                border.color: picked ? theme.normal.green : theme.button.border
                                border.width: picked ? 3 : 1
                                Com.AppGridImage {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.72
                                    height: parent.height * 0.72
                                    source: filePath
                                    fallbackText: fileName
                                    fallbackColor: theme.primary.dim_foreground
                                }
                                MouseArea {
                                    id: tileMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.iconPath = filePath
                                }
                            }
                        }
                    }
                }

                // ---------- Nút ----------
                RowLayout {
                    Layout.fillWidth: true
                    spacing: ScalerService.s(8)

                    Rectangle {
                        Layout.preferredWidth: ScalerService.s(96)
                        Layout.preferredHeight: ScalerService.s(36)
                        radius: height / 2
                        color: root.ctrlBg
                        border.color: theme.normal.red
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "🗑  Clear"
                            color: theme.normal.red
                            font.pixelSize: ScalerService.s(13)
                            font.family: root.fontName
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.clearSlot()
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        Layout.preferredWidth: ScalerService.s(96)
                        Layout.preferredHeight: ScalerService.s(36)
                        radius: height / 2
                        color: root.ctrlBg
                        border.color: theme.button.border
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: theme.primary.foreground
                            font.pixelSize: ScalerService.s(13)
                            font.family: root.fontName
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }
                    Rectangle {
                        Layout.preferredWidth: ScalerService.s(110)
                        Layout.preferredHeight: ScalerService.s(36)
                        radius: height / 2
                        color: root.canSave ? theme.normal.green : root.ctrlBg
                        opacity: root.canSave ? 1 : 0.5
                        Text {
                            anchors.centerIn: parent
                            text: "✓  Save"
                            color: root.canSave ? theme.primary.background : theme.primary.dim_foreground
                            font.pixelSize: ScalerService.s(13)
                            font.bold: true
                            font.family: root.fontName
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: root.canSave
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.save()
                        }
                    }
                }
            }
        }
    }
}
