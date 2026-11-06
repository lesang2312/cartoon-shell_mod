import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components
import qs.commons

// Settings -> General -> Date & Time
//  - Đồng hồ trực tiếp (có vệt giây chạy mượt)
//  - Định dạng 24h / 12h (áp dụng cho Settings.clock.timeFormat => thanh bar + widget đồng hồ)
//  - Đồng bộ giờ tự động (NTP) qua timedatectl
//  - Chọn múi giờ có tìm kiếm qua timedatectl
Item {
    id: root

    readonly property color accent: theme.button.text
    readonly property color accent2: Qt.hsla((Math.max(0, accent.hslHue) + 0.09) % 1, accent.hslSaturation, Math.max(0.52, Math.min(0.78, accent.hslLightness)), 1)
    readonly property bool is12h: Settings.clock.timeFormat === "12h"

    // ---- trạng thái hệ thống ----
    property string timezone: ""
    property bool ntpEnabled: false
    property bool ntpSynced: false
    property string statusMsg: ""      // thông báo sau khi đổi
    property bool statusIsError: false
    property bool busy: false
    property var allZones: []
    property string filter: ""
    readonly property var zones: {
        const q = filter.trim().toLowerCase().replace(/ /g, "_");
        if (q === "")
            return allZones;
        return allZones.filter(z => z.toLowerCase().indexOf(q) >= 0);
    }

    property real animationProgress: 0
    NumberAnimation on animationProgress {
        from: 0
        to: 1
        duration: 500
        running: true
    }

    function refresh() {
        stateProc.running = true;
    }
    // Chạy thẳng timedatectl (được nếu đã có rule polkit). Bị từ chối => hỏi mật khẩu rồi chạy bằng sudo -S.
    property var pendingArgs: []
    property bool askPass: false
    property bool passWrong: false

    function setTimezone(tz) {
        if (busy || tz === timezone)
            return;
        runAction(["set-timezone", tz]);
    }
    function setNtp(v) {
        if (busy)
            return;
        runAction(["set-ntp", v ? "true" : "false"]);
    }
    function runAction(args) {
        busy = true;
        statusMsg = "";
        askPass = false;
        pendingArgs = args;
        actProc.command = ["timedatectl", "--no-ask-password"].concat(args);
        actProc.running = true;
    }
    function submitPassword(pw) {
        if (pw === "" || busy)
            return;
        busy = true;
        passWrong = false;
        sudoProc.pw = pw;
        // read lấy 1 dòng mật khẩu từ stdin rồi đóng ống => sudo gặp EOF sau lần thử đầu, sai thì thoát ngay.
        // LC_ALL=C để thông báo lỗi của sudo luôn bằng tiếng Anh, dễ nhận diện.
        sudoProc.command = ["sh", "-c", 'IFS= read -r pw; printf "%s\\n" "$pw" | LC_ALL=C sudo -S -p "" -k timedatectl "$@"', "sh"].concat(pendingArgs);
        sudoProc.running = true;
    }
    function finish(ok, text) {
        busy = false;
        if (ok) {
            askPass = false;
            statusIsError = false;
            statusMsg = pendingArgs[0] === "set-timezone" ? "Đã đặt múi giờ " + pendingArgs[1] + ". Khởi động lại Quickshell để đồng hồ cập nhật hoàn toàn." : (pendingArgs[1] === "true" ? "Đã bật đồng bộ giờ tự động." : "Đã tắt đồng bộ giờ tự động.");
            pendingArgs = [];
        } else {
            statusIsError = true;
            statusMsg = (text || "").trim() || "Thao tác không thành công.";
        }
        refresh();
    }
    function fmtOffset(d) {
        const m = -d.getTimezoneOffset();
        const sign = m >= 0 ? "+" : "−";
        const a = Math.abs(m);
        const hh = String(Math.floor(a / 60)).padStart(2, "0");
        const mm = String(a % 60).padStart(2, "0");
        return "UTC" + sign + hh + ":" + mm;
    }

    onTimezoneChanged: if (filter === "" && allZones.length > 0)
        Qt.callLater(() => list.positionViewAtIndex(Math.max(0, allZones.indexOf(timezone) - 2), ListView.Beginning))

    Component.onCompleted: {
        refresh();
        zonesProc.running = true;
    }

    Process {
        id: stateProc
        command: ["timedatectl", "show", "-p", "Timezone", "-p", "NTP", "-p", "NTPSynchronized"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i < 0)
                        continue;
                    const k = line.slice(0, i), v = line.slice(i + 1).trim();
                    if (k === "Timezone")
                        root.timezone = v;
                    else if (k === "NTP")
                        root.ntpEnabled = v === "yes";
                    else if (k === "NTPSynchronized")
                        root.ntpSynced = v === "yes";
                }
            }
        }
    }
    Process {
        id: zonesProc
        command: ["timedatectl", "list-timezones"]
        stdout: StdioCollector {
            onStreamFinished: root.allZones = text.split("\n").map(s => s.trim()).filter(s => s !== "")
        }
    }
    // Kết quả được xử lý sau ~150ms để StdioCollector kịp đọc hết stderr (trước đây text có thể còn rỗng khi onExited chạy).
    property int actCode: 0
    property int sudoCode: 0
    Timer {
        id: actSettle
        interval: 150
        onTriggered: {
            if (!root.busy)
                return;                     // đã bị watchdog hủy
            if (root.actCode === 0) {
                root.finish(true, "");
                return;
            }
            const t = actErr.text.trim();
            // không có thông điệp lạ nào khác => coi như thiếu quyền và hỏi mật khẩu
            if (t === "" || /authenticat|denied|not authorized|polkit|permission/i.test(t)) {
                root.busy = false;
                root.passWrong = false;
                root.askPass = true;
                root.statusMsg = "";
            } else {
                root.finish(false, t);
            }
        }
    }
    Timer {
        id: sudoSettle
        interval: 150
        onTriggered: {
            if (!root.busy)
                return;
            const t = sudoErr.text.trim();
            if (root.sudoCode === 0) {
                root.finish(true, "");
            } else if (t === "" || /incorrect password|try again|Sorry|no password was provided|a password is required|authentication failure/i.test(t)) {
                root.busy = false;
                root.passWrong = true;      // sai mật khẩu => giữ hộp mở để nhập lại
            } else {
                root.askPass = false;
                root.finish(false, t || ("sudo thoát với mã " + root.sudoCode + " (tài khoản có quyền sudo không?)."));
            }
        }
    }
    // chống treo: quá 10 giây không xong thì hủy và báo lỗi
    Timer {
        interval: 10000
        running: root.busy
        onTriggered: {
            actProc.running = false;
            sudoProc.running = false;
            root.busy = false;
            root.statusIsError = true;
            root.statusMsg = "Hết thời gian chờ, thao tác bị hủy.";
        }
    }
    Process {
        id: actProc
        stderr: StdioCollector {
            id: actErr
        }
        onExited: code => {
            root.actCode = code;
            actSettle.restart();
        }
    }
    Process {
        id: sudoProc
        property string pw: ""
        stdinEnabled: true
        stderr: StdioCollector {
            id: sudoErr
        }
        onRunningChanged: {
            if (running) {
                write(pw + "\n");
                pw = "";
            }
        }
        onExited: code => {
            root.sudoCode = code;
            sudoSettle.restart();
        }
    }

    // làm mới trạng thái NTP định kỳ khi đang mở trang
    Timer {
        interval: 20000
        repeat: true
        running: !root.busy
        onTriggered: root.refresh()
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
        onDateChanged: {
            heroBar.frac = clock.date.getSeconds() / 60;
        }
    }

    // ============================================================
    ScrollView {
        id: scroll
        anchors.fill: parent
        anchors.margins: ScalerService.s(20)
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: scroll.availableWidth
            spacing: ScalerService.s(16)

            HeaderSettings {
                name: lang?.general?.date_time || "Date & Time"
                opacity: root.animationProgress > 0.1 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            Rectangle {
                Layout.fillWidth: true
                height: ScalerService.s(1)
                color: theme.primary.foreground
                opacity: root.animationProgress > 0.2 ? 0.2 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // ================= Đồng hồ trực tiếp =================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: heroCol.implicitHeight + ScalerService.s(40)
                radius: ScalerService.s(Settings.appearance.radius2)
                color: Qt.alpha(theme.primary.dim_background, 0.6)
                border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
                border.color: theme.button.border
                opacity: root.animationProgress > 0.3 ? 1 : 0
                scale: root.animationProgress > 0.3 ? 1 : 0.97
                Behavior on opacity { NumberAnimation { duration: 260 } }
                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

                ColumnLayout {
                    id: heroCol
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(20)
                    spacing: ScalerService.s(10)

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: ScalerService.s(8)
                        Text {
                            id: bigTime
                            text: root.is12h ? ((clock.date.getHours() % 12 || 12) + Qt.formatTime(clock.date, ":mm:ss")) : Qt.formatTime(clock.date, "HH:mm:ss")
                            color: root.accent
                            font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(58); bold: true }
                        }
                        Text {
                            visible: root.is12h
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: ScalerService.s(10)
                            text: Qt.formatTime(clock.date, "AP")
                            color: root.accent2
                            font { family: Settings.appearance.font; pixelSize: ScalerService.s(20); bold: true }
                        }
                    }

                    // vệt giây chạy mượt trong 60 giây
                    Rectangle {
                        id: heroTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScalerService.s(5)
                        radius: height / 2
                        color: Qt.alpha("#ffffff", 0.08)
                        Rectangle {
                            id: heroBar
                            property real frac: 0
                            height: parent.height
                            radius: height / 2
                            width: Math.max(height, parent.width * frac)
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: root.accent2 }
                                GradientStop { position: 1.0; color: root.accent }
                            }
                            // chỉ trượt ngắn mỗi giây rồi đứng yên => không bắt kính vẽ lại liên tục
                            Behavior on frac {
                                enabled: heroBar.frac > 0.02
                                NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: DateTimeService.currentDay + ", " + Qt.formatDate(clock.date, "dd/MM/yyyy")
                        color: theme.primary.foreground
                        font { family: Settings.appearance.font; pixelSize: ScalerService.s(16); weight: Font.DemiBold }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: ScalerService.s(8)

                        Rectangle {
                            implicitWidth: tzChip.implicitWidth + ScalerService.s(20)
                            implicitHeight: ScalerService.s(26)
                            radius: height / 2
                            color: Qt.alpha(theme.button.background, 0.7)
                            border.width: ScalerService.s(1)
                            border.color: theme.button.border
                            Text {
                                id: tzChip
                                anchors.centerIn: parent
                                text: (root.timezone || "…") + "  ·  " + root.fmtOffset(clock.date)
                                color: theme.primary.foreground
                                font { family: Settings.appearance.font; pixelSize: ScalerService.s(11); weight: Font.Medium }
                            }
                        }
                        Rectangle {
                            implicitWidth: ntpChip.implicitWidth + ScalerService.s(34)
                            implicitHeight: ScalerService.s(26)
                            radius: height / 2
                            color: Qt.alpha(theme.button.background, 0.7)
                            border.width: ScalerService.s(1)
                            border.color: theme.button.border
                            Rectangle {
                                x: ScalerService.s(11)
                                anchors.verticalCenter: parent.verticalCenter
                                width: ScalerService.s(8)
                                height: width
                                radius: width / 2
                                color: root.ntpSynced ? "#6ee7a0" : (root.ntpEnabled ? "#ffd166" : theme.primary.dim_foreground)
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                            Text {
                                id: ntpChip
                                anchors.verticalCenter: parent.verticalCenter
                                x: ScalerService.s(24)
                                text: root.ntpSynced ? "Đã đồng bộ" : (root.ntpEnabled ? "Đang đồng bộ…" : "Đồng bộ tắt")
                                color: theme.primary.foreground
                                font { family: Settings.appearance.font; pixelSize: ScalerService.s(11); weight: Font.Medium }
                            }
                        }
                    }
                }
            }

            // ================= Định dạng giờ =================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: fmtRow.implicitHeight + ScalerService.s(36)
                radius: ScalerService.s(Settings.appearance.radius2)
                color: Qt.alpha(theme.primary.dim_background, 0.6)
                border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
                border.color: theme.button.border
                opacity: root.animationProgress > 0.5 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 260 } }

                RowLayout {
                    id: fmtRow
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(18)
                    spacing: ScalerService.s(14)

                    ColumnLayout {
                        spacing: ScalerService.s(2)
                        Text {
                            text: "Định dạng giờ"
                            color: theme.primary.foreground
                            font { family: Settings.appearance.font; pixelSize: ScalerService.s(15); bold: true }
                        }
                        Text {
                            text: "Áp dụng cho thanh bar và đồng hồ"
                            color: theme.primary.dim_foreground
                            font { family: Settings.appearance.font; pixelSize: ScalerService.s(11) }
                        }
                    }
                    Item { Layout.fillWidth: true }

                    // bộ chọn có ô sáng trượt
                    Rectangle {
                        id: seg
                        readonly property real cellW: ScalerService.s(92)
                        implicitWidth: cellW * 2 + ScalerService.s(8)
                        implicitHeight: ScalerService.s(44)
                        radius: height / 2
                        color: Qt.alpha(theme.button.background, 0.6)

                        Rectangle {
                            id: segPill
                            y: ScalerService.s(4)
                            height: parent.height - ScalerService.s(8)
                            width: seg.cellW
                            radius: height / 2
                            x: ScalerService.s(4) + (root.is12h ? seg.cellW : 0)
                            Behavior on x { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: root.accent }
                                GradientStop { position: 1.0; color: root.accent2 }
                            }
                        }
                        Repeater {
                            model: [
                                { key: "24h", title: "24 giờ", sample: Qt.formatTime(clock.date, "HH:mm") },
                                { key: "12h", title: "12 giờ", sample: Qt.formatTime(clock.date, "h:mm AP") }
                            ]
                            delegate: Item {
                                id: cell
                                required property var modelData
                                required property int index
                                readonly property bool sel: Settings.clock.timeFormat === modelData.key
                                x: ScalerService.s(4) + index * seg.cellW
                                y: ScalerService.s(4)
                                width: seg.cellW
                                height: seg.height - ScalerService.s(8)
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 0
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: cell.modelData.title
                                        color: cell.sel ? theme.primary.background : theme.primary.foreground
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                        font { family: Settings.appearance.font; pixelSize: ScalerService.s(13); bold: true }
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: cell.modelData.sample
                                        color: cell.sel ? Qt.alpha(theme.primary.background, 0.75) : theme.primary.dim_foreground
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                        font { family: Settings.appearance.font; pixelSize: ScalerService.s(10) }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.clock.timeFormat = cell.modelData.key
                                }
                            }
                        }
                    }
                }
            }

            // ================= Đồng bộ giờ tự động =================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: ntpRow.implicitHeight + ScalerService.s(36)
                radius: ScalerService.s(Settings.appearance.radius2)
                color: Qt.alpha(theme.primary.dim_background, 0.6)
                border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
                border.color: theme.button.border
                opacity: root.animationProgress > 0.6 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 260 } }

                RowLayout {
                    id: ntpRow
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(18)
                    spacing: ScalerService.s(14)
                    ColumnLayout {
                        spacing: ScalerService.s(2)
                        Text {
                            text: "Đồng bộ giờ tự động"
                            color: theme.primary.foreground
                            font { family: Settings.appearance.font; pixelSize: ScalerService.s(15); bold: true }
                        }
                        Text {
                            text: "Lấy giờ chính xác từ máy chủ thời gian (NTP)"
                            color: theme.primary.dim_foreground
                            font { family: Settings.appearance.font; pixelSize: ScalerService.s(11) }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    CustomToggleSwitch {
                        adapter: root.ntpEnabled
                        opacity: root.busy ? 0.5 : 1
                        onClicked: root.setNtp(!root.ntpEnabled)
                    }
                }
            }

            // ================= Múi giờ =================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: tzCol.implicitHeight + ScalerService.s(36)
                radius: ScalerService.s(Settings.appearance.radius2)
                color: Qt.alpha(theme.primary.dim_background, 0.6)
                border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
                border.color: theme.button.border
                opacity: root.animationProgress > 0.7 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 260 } }

                ColumnLayout {
                    id: tzCol
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(18)
                    spacing: ScalerService.s(10)

                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: ScalerService.s(2)
                            Text {
                                text: "Múi giờ"
                                color: theme.primary.foreground
                                font { family: Settings.appearance.font; pixelSize: ScalerService.s(15); bold: true }
                            }
                            Text {
                                text: "Hiện tại: " + (root.timezone || "…")
                                color: root.accent
                                font { family: Settings.appearance.font; pixelSize: ScalerService.s(11); weight: Font.Medium }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: root.zones.length + " vùng"
                            color: theme.primary.dim_foreground
                            font { family: Settings.appearance.font; pixelSize: ScalerService.s(11) }
                        }
                    }

                    // ô tìm kiếm
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScalerService.s(38)
                        radius: height / 2
                        color: Qt.alpha(theme.button.background, 0.6)
                        border.width: ScalerService.s(1.5)
                        border.color: search.activeFocus ? root.accent : "transparent"
                        Behavior on border.color { ColorAnimation { duration: 180 } }
                        TextField {
                            id: search
                            anchors.fill: parent
                            anchors.leftMargin: ScalerService.s(14)
                            anchors.rightMargin: ScalerService.s(14)
                            placeholderText: "Tìm múi giờ… (vd: Saigon, Tokyo, New_York)"
                            palette.text: theme.primary.foreground
                            palette.placeholderText: theme.primary.dim_foreground
                            font.pixelSize: ScalerService.s(13)
                            font.family: Settings.appearance.font
                            selectByMouse: true
                            background: Item {}
                            onTextChanged: root.filter = text
                        }
                    }

                    // danh sách
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScalerService.s(230)
                        radius: ScalerService.s(14)
                        color: Qt.alpha("#000000", 0.18)
                        clip: true

                        ListView {
                            id: list
                            anchors.fill: parent
                            anchors.margins: ScalerService.s(6)
                            model: root.zones
                            clip: true
                            spacing: ScalerService.s(2)
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                            }
                            // cuộn tới múi giờ hiện tại khi danh sách đầy đủ vừa tải xong
                            onCountChanged: if (root.filter === "" && root.timezone !== "")
                                Qt.callLater(() => list.positionViewAtIndex(Math.max(0, root.allZones.indexOf(root.timezone) - 2), ListView.Beginning))

                            delegate: Rectangle {
                                id: item
                                required property string modelData
                                readonly property bool cur: modelData === root.timezone
                                width: ListView.view.width - ScalerService.s(8)
                                height: ScalerService.s(34)
                                radius: ScalerService.s(10)
                                color: cur ? Qt.alpha(root.accent, 0.22) : (ma.containsMouse ? Qt.alpha(theme.button.background_select, 0.6) : "transparent")
                                Behavior on color { ColorAnimation { duration: 130 } }

                                Rectangle {
                                    visible: item.cur
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: ScalerService.s(6)
                                    width: ScalerService.s(4)
                                    height: parent.height * 0.5
                                    radius: width / 2
                                    color: root.accent
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: ScalerService.s(18)
                                    text: item.modelData.replace(/_/g, " ")
                                    color: item.cur ? root.accent : theme.primary.foreground
                                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(13); bold: item.cur }
                                }
                                Text {
                                    visible: item.cur
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right
                                    anchors.rightMargin: ScalerService.s(12)
                                    text: "✓"
                                    color: root.accent
                                    font { pixelSize: ScalerService.s(14); bold: true }
                                }
                                MouseArea {
                                    id: ma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setTimezone(item.modelData)
                                }
                            }

                            Text {
                                visible: list.count === 0
                                anchors.centerIn: parent
                                text: root.allZones.length === 0 ? "Đang tải danh sách…" : "Không tìm thấy múi giờ phù hợp"
                                color: theme.primary.dim_foreground
                                font { family: Settings.appearance.font; pixelSize: ScalerService.s(12) }
                            }
                        }
                    }

                }
            }

            Item { Layout.preferredHeight: ScalerService.s(36) }
        }
    }


    // ================= Thông báo kết quả (nổi, luôn nhìn thấy) =================
    Timer {
        id: toastTimer
        interval: 7000
        onTriggered: root.statusMsg = ""
    }
    onStatusMsgChanged: if (statusMsg !== "")
        toastTimer.restart()

    Rectangle {
        id: toast
        z: 19
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: ScalerService.s(26)
        width: Math.min(parent.width - ScalerService.s(40), ScalerService.s(460))
        height: toastText.implicitHeight + ScalerService.s(24)
        radius: ScalerService.s(14)
        visible: opacity > 0.01 && !root.askPass
        opacity: root.statusMsg !== "" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }
        color: Qt.alpha(theme.primary.dim_background, 0.96)
        border.width: ScalerService.s(2)
        border.color: root.statusIsError ? theme.normal.red : root.accent
        Text {
            id: toastText
            anchors.fill: parent
            anchors.margins: ScalerService.s(12)
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignVCenter
            text: (root.statusIsError ? "\u26A0 " : "\u2713 ") + root.statusMsg
            color: root.statusIsError ? theme.normal.red : root.accent
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(12) }
        }
    }

    // ================= Hộp nhập mật khẩu (khi không có polkit agent) =================
    Rectangle {
        id: passBox
        z: 20
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.askPass ? ScalerService.s(26) : -height - ScalerService.s(10)
        width: Math.min(parent.width - ScalerService.s(40), ScalerService.s(440))
        implicitHeight: passCol.implicitHeight + ScalerService.s(32)
        height: implicitHeight
        radius: ScalerService.s(16)
        color: Qt.alpha(theme.primary.dim_background, 0.96)
        border.width: ScalerService.s(2)
        border.color: root.passWrong ? theme.normal.red : root.accent
        visible: anchors.bottomMargin > -height
        transform: Translate { id: shake }
        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: shake; property: "x"; to: -ScalerService.s(12); duration: 50 }
            NumberAnimation { target: shake; property: "x"; to: ScalerService.s(12); duration: 80 }
            NumberAnimation { target: shake; property: "x"; to: -ScalerService.s(8); duration: 70 }
            NumberAnimation { target: shake; property: "x"; to: ScalerService.s(8); duration: 70 }
            NumberAnimation { target: shake; property: "x"; to: 0; duration: 60 }
        }
        Connections {
            target: root
            function onPassWrongChanged() {
                if (root.passWrong) {
                    shakeAnim.restart();
                    passField.text = "";
                    passField.forceActiveFocus();
                }
            }
        }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 340; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
        onVisibleChanged: if (visible) { passField.text = ""; passField.forceActiveFocus(); }

        ColumnLayout {
            id: passCol
            anchors.fill: parent
            anchors.margins: ScalerService.s(16)
            spacing: ScalerService.s(8)

            Text {
                text: "\uD83D\uDD12  Cần quyền quản trị"
                color: root.accent
                font { family: Settings.appearance.font; pixelSize: ScalerService.s(14); bold: true }
            }
            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: root.passWrong ? "\u26A0 Mật khẩu không đúng. Hãy nhập lại." : "Nhập mật khẩu sudo để áp dụng. Mật khẩu chỉ dùng một lần, không được lưu."
                color: root.passWrong ? theme.normal.red : theme.primary.dim_foreground
                font { family: Settings.appearance.font; pixelSize: ScalerService.s(11) }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(38)
                radius: height / 2
                color: Qt.alpha(theme.button.background, 0.7)
                TextField {
                    id: passField
                    anchors.fill: parent
                    anchors.leftMargin: ScalerService.s(14)
                    anchors.rightMargin: ScalerService.s(14)
                    echoMode: TextInput.Password
                    enabled: !root.busy
                    placeholderText: "Mật khẩu"
                    palette.text: theme.primary.foreground
                    palette.placeholderText: theme.primary.dim_foreground
                    font.pixelSize: ScalerService.s(13)
                    font.family: Settings.appearance.font
                    background: Item {}
                    onAccepted: {
                        root.submitPassword(text);
                        text = "";
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(8)
                Item { Layout.fillWidth: true }
                Rectangle {
                    implicitWidth: cancelT.implicitWidth + ScalerService.s(26)
                    implicitHeight: ScalerService.s(32)
                    radius: height / 2
                    color: cancelMa.containsMouse ? Qt.alpha(theme.button.background_select, 0.9) : Qt.alpha(theme.button.background, 0.7)
                    Text { id: cancelT; anchors.centerIn: parent; text: "Hủy"; color: theme.primary.foreground; font { family: Settings.appearance.font; pixelSize: ScalerService.s(12) } }
                    MouseArea { id: cancelMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.askPass = false; root.pendingArgs = []; } }
                }
                Rectangle {
                    implicitWidth: okT.implicitWidth + ScalerService.s(26)
                    implicitHeight: ScalerService.s(32)
                    radius: height / 2
                    opacity: root.busy ? 0.5 : 1
                    color: root.accent
                    Text { id: okT; anchors.centerIn: parent; text: root.busy ? "Đang áp dụng…" : "Xác nhận"; color: theme.primary.background; font { family: Settings.appearance.font; pixelSize: ScalerService.s(12); bold: true } }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.submitPassword(passField.text); passField.text = ""; } }
                }
            }
        }
    }
}
