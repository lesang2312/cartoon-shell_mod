import QtQuick
import QtQuick.Effects

// Cartoon Shell — màn hình đăng nhập SDDM (Qt 6), phong cách kính mờ tối giản.
// Gồm: màn hình chào mừng (logo) rồi thẻ đăng nhập kính mờ trên hình nền làm mờ.
Item {
    id: root

    // ---------- cấu hình (theme.conf) ----------
    function cfg(name, def) {
        if (typeof config === "undefined" || config === null)
            return def;
        var v = config[name];
        return (v === undefined || v === null || v === "") ? def : v;
    }

    readonly property string lang: String(cfg("lang", "vi"))
    readonly property bool vi: lang !== "en"
    readonly property color accent: cfg("accent", "#FFB347")
    readonly property real blurAmount: Math.max(0, Math.min(1, parseFloat(cfg("blur", 0.0))))
    readonly property int splashDuration: parseInt(cfg("splashDuration", 2600))
    readonly property string customFont: String(cfg("font", ""))
    readonly property string fontFamily: customFont !== "" ? customFont : "Inter"

    readonly property real s: Math.max(0.6, height / 768)
    readonly property bool preview: typeof sddm === "undefined" || sddm === null
    // Renderer phần mềm không vẽ được MultiEffect -> bỏ blur, dùng nền mờ đơn giản
    readonly property bool fx: GraphicsInfo.api !== GraphicsInfo.Software

    // ---------- trạng thái ----------
    property int phase: splashDuration > 0 ? 0 : 1      // 0 = chào mừng, 1 = đăng nhập
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property string errorMessage: ""
    property bool loggingIn: false
    property bool leaving: false          // đăng nhập xong: mờ dần giao diện, chỉ còn hình nền (liền mạch với phiên)
    property bool picking: false          // đang mở bảng chọn avatar

    // ảnh đại diện chọn ngay tại màn hình đăng nhập (lưu theo từng tên đăng nhập)
    readonly property var presetAvatars: ["presets/p1.png", "presets/p2.png", "presets/p3.png", "presets/p4.png", "presets/p5.png",
                                          "presets/p6.png", "presets/p7.png", "presets/p8.png", "presets/p9.png"]
    property var avatarChoices: ({})
    property var store: null
    property var gallery: null            // ảnh tự chọn trong avatars/gallery (shell tự thêm mỗi khi bạn đổi avatar)
    property bool addHint: false
    readonly property string chosenAvatar: avatarChoices[userLogin] || ""
    readonly property string avatarSource: chosenAvatar !== "" ? chosenAvatar : "avatars/" + userLogin

    // Lưu lựa chọn vào file cấu hình của user "sddm" (greeter không ghi được vào thư mục theme).
    // Tạo bằng createQmlObject trong try/catch: thiếu module cũng không làm hỏng theme.
    function loadStore() {
        var loc = preview ? "file:///tmp/cartoon-sddm-preview.conf" : "file:///var/lib/sddm/.config/cartoon-shell-sddm.conf";
        try {
            store = Qt.createQmlObject('import QtCore\nSettings { location: "' + loc + '"; category: "avatars"; property string data: "{}" }', root, "store");
            avatarChoices = JSON.parse(store.data || "{}");
        } catch (e) {
            console.log("cartoon theme: không lưu được lựa chọn avatar:", e);
            store = null;
        }
    }

    function loadGallery() {
        try {
            gallery = Qt.createQmlObject('import Qt.labs.folderlistmodel\nFolderListModel { folder: "' + Qt.resolvedUrl("avatars/gallery")
                + '"; nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.gif"]; showDirs: false; sortField: FolderListModel.Time; sortReversed: true }', root, "gallery");
        } catch (e) {
            console.log("cartoon theme: không đọc được thư viện avatar:", e);
            gallery = null;
        }
    }

    function chooseAvatar(path) {
        var c = {};
        for (var k in avatarChoices) c[k] = avatarChoices[k];
        if (path) c[userLogin] = path; else delete c[userLogin];
        avatarChoices = c;
        if (store) {
            try { store.data = JSON.stringify(c); } catch (e) { }
        }
        picking = false;
        addHint = false;
    }

    readonly property string userLogin: userHelper.currentItem ? userHelper.currentItem.uLogin : (preview ? "user" : "")
    readonly property string userName: userHelper.currentItem && userHelper.currentItem.uName !== "" ? userHelper.currentItem.uName : (preview ? "Bạn" : userLogin)
    readonly property string userIcon: userHelper.currentItem ? userHelper.currentItem.uIcon : ""
    readonly property string sessionName: sessionHelper.currentItem && sessionHelper.currentItem.sName !== "" ? sessionHelper.currentItem.sName : (preview ? "Hyprland" : "")
    readonly property int userCount: (typeof userModel !== "undefined" && userModel !== null) ? userModel.count : 1
    readonly property int sessionCount: (typeof sessionModel !== "undefined" && sessionModel !== null) ? sessionModel.count : 1

    property date now: new Date()

    function tr(viText, enText) { return vi ? viText : enText; }

    function greeting() {
        var h = now.getHours();
        if (h < 5)  return tr("Khuya rồi", "Late night");
        if (h < 11) return tr("Chào buổi sáng", "Good morning");
        if (h < 14) return tr("Chào buổi trưa", "Good noon");
        if (h < 18) return tr("Chào buổi chiều", "Good afternoon");
        return tr("Chào buổi tối", "Good evening");
    }

    readonly property var viDays: ["Chủ nhật", "Thứ hai", "Thứ ba", "Thứ tư", "Thứ năm", "Thứ sáu", "Thứ bảy"]
    function dateText(d) {
        if (vi)
            return viDays[d.getDay()] + ", " + d.getDate() + " tháng " + (d.getMonth() + 1);
        return Qt.formatDate(d, "dddd, MMMM d");
    }

    function skipSplash() {
        if (phase === 0) {
            splashTimer.stop();
            phase = 1;
            pwd.forceActiveFocus();
        }
    }

    function doLogin() {
        if (root.loggingIn || pwd.text === "")
            return;
        if (root.preview) {
            root.loggingIn = true;
            return;
        }
        sddm.login(root.userLogin, pwd.text, root.sessionIndex);
    }

    function power(kind) {
        if (root.preview)
            return;
        if (kind === "sleep")       sddm.suspend();
        else if (kind === "reboot") sddm.reboot();
        else if (kind === "off")    sddm.powerOff();
    }

    // ---------- mô hình dữ liệu ẩn (đọc user / session) ----------
    ListView {
        id: sessionHelper
        model: typeof sessionModel !== "undefined" ? sessionModel : null
        currentIndex: root.sessionIndex
        width: 1; height: 1; opacity: 0; interactive: false
        delegate: Item { property string sName: model.name || "" }
    }
    ListView {
        id: userHelper
        model: typeof userModel !== "undefined" ? userModel : null
        currentIndex: root.userIndex
        width: 1; height: 1; opacity: 0; interactive: false
        delegate: Item {
            property string uName: model.realName || model.name || ""
            property string uLogin: model.name || ""
            property string uIcon: model.icon ? String(model.icon) : ""
        }
    }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    Timer {
        id: splashTimer
        interval: Math.max(500, root.splashDuration)
        running: root.splashDuration > 0
        onTriggered: root.skipSplash()
    }
    Timer { interval: 250; running: true; onTriggered: pwd.forceActiveFocus() }
    Timer { id: errTimer; interval: 3500; onTriggered: root.errorMessage = "" }
    Timer { id: leaveTimer; interval: 500; onTriggered: root.leaving = true }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() {
            root.loggingIn = false;
            root.errorMessage = root.tr("Sai mật khẩu, thử lại nhé", "Wrong password, try again");
            pwd.text = "";
            shake.restart();
            errTimer.restart();
        }
        function onLoginSucceeded() {
            root.errorMessage = "";
            root.loggingIn = true;
            root.picking = false;
            leaveTimer.start();
        }
    }

    // ======================================================================
    //  NỀN: hình nền làm mờ + lớp tối nhẹ
    // ======================================================================
    Item {
        id: bgLayer
        anchors.fill: parent

        // nền dự phòng khi chưa có hình nền
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1B2A4A" }
                GradientStop { position: 0.55; color: "#3A2F5B" }
                GradientStop { position: 1.0; color: "#5B3A4E" }
            }
        }

        // hình nền: file "wallpaper" cạnh Main.qml (cartoon-shell tự đồng bộ khi bạn đổi hình nền)
        Image {
            id: wall
            anchors.fill: parent
            source: "wallpaper"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }
        MultiEffect {
            anchors.fill: parent
            source: wall
            visible: root.fx && wall.status === Image.Ready && root.blurAmount > 0.01
            blurEnabled: true
            blurMax: 64
            blur: root.blurAmount
            saturation: 0.1
        }
        // phủ tối nhẹ để chữ trắng luôn dễ đọc (tắt dần khi đăng nhập xong -> giống hệt nền phiên)
        Rectangle {
            anchors.fill: parent
            opacity: root.leaving ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutCubic } }
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.22) }
                GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.06) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.34) }
            }
        }
    }

    // ======================================================================
    //  GIAO DIỆN ĐĂNG NHẬP
    // ======================================================================
    Item {
        id: ui
        anchors.fill: parent
        opacity: (root.phase === 1 && !root.leaving) ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: root.leaving ? 600 : 500; easing.type: Easing.OutCubic } }

        // đồng hồ kiểu iPhone: ngày nhỏ ở trên, giờ rất lớn đậm bên dưới
        Column {
            id: clockCol
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.height * 0.07 + (root.phase === 1 ? 0 : 24 * root.s)
            spacing: -6 * root.s
            Behavior on y { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.dateText(root.now)
                font.family: root.fontFamily
                font.pixelSize: 24 * root.s
                font.weight: Font.DemiBold
                color: Qt.rgba(1, 1, 1, 0.82)
                layer.enabled: root.fx
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#000000"; shadowOpacity: 0.25; shadowBlur: 0.5; shadowVerticalOffset: 1 }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(root.now, "h:mm")
                font.family: root.fontFamily
                font.pixelSize: 148 * root.s
                font.weight: Font.Bold
                font.letterSpacing: -4 * root.s
                color: Qt.rgba(1, 1, 1, 0.94)
                layer.enabled: root.fx
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#000000"; shadowOpacity: 0.30; shadowBlur: 0.7; shadowVerticalOffset: 4 }
            }
        }

        // ---------- thẻ đăng nhập kính mờ ----------
        Item {
            id: cardWrap
            width: 380 * root.s
            height: cardCol.implicitHeight + 56 * root.s
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.height * 0.43 + (root.phase === 1 ? 0 : 30 * root.s)
            Behavior on y { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

            transform: Translate { id: shakeT }
            SequentialAnimation {
                id: shake
                NumberAnimation { target: shakeT; property: "x"; to: 14 * root.s; duration: 55 }
                NumberAnimation { target: shakeT; property: "x"; to: -14 * root.s; duration: 55 }
                NumberAnimation { target: shakeT; property: "x"; to: 9 * root.s; duration: 55 }
                NumberAnimation { target: shakeT; property: "x"; to: -9 * root.s; duration: 55 }
                NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 55 }
            }

            // nền mờ phía sau thẻ (backdrop blur)
            ShaderEffectSource {
                id: backdrop
                anchors.fill: parent
                sourceItem: bgLayer
                sourceRect: Qt.rect(cardWrap.x, cardWrap.y, cardWrap.width, cardWrap.height)
                visible: false
            }
            Rectangle {
                id: cardMask
                anchors.fill: parent
                radius: 28 * root.s
                visible: false
                layer.enabled: true
            }
            MultiEffect {
                anchors.fill: parent
                visible: root.fx
                source: backdrop
                blurEnabled: true
                blurMax: 64
                blur: 1.0
                brightness: -0.04
                saturation: 0.2
                maskEnabled: true
                maskSource: cardMask
            }
            // kính: phủ trắng trong suốt + viền mảnh
            Rectangle {
                anchors.fill: parent
                radius: 28 * root.s
                color: root.fx ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0.08, 0.08, 0.12, 0.62)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.24)
            }

            Column {
                id: cardCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 28 * root.s
                spacing: 16 * root.s

                Avatar {
                    id: avatar
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 92 * root.s; height: width
                    source: root.avatarSource
                    fallbackSource: root.userIcon
                    name: root.userName
                    accent: root.accent
                    fontFamily: root.fontFamily
                    SequentialAnimation on scale {
                        running: root.loggingIn
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.06; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.97; duration: 600; easing.type: Easing.InOutSine }
                    }

                    // bấm vào avatar để đổi ảnh
                    MouseArea {
                        id: avatarMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !root.loggingIn
                        onClicked: root.picking = !root.picking
                    }
                    Rectangle {
                        width: 28 * root.s; height: width; radius: width / 2
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: -2 * root.s
                        anchors.bottomMargin: -2 * root.s
                        color: root.accent
                        border.width: 2 * root.s
                        border.color: Qt.rgba(1, 1, 1, 0.9)
                        scale: avatarMa.containsMouse ? 1.12 : 1
                        Behavior on scale { NumberAnimation { duration: 120 } }
                        Icon {
                            anchors.centerIn: parent
                            width: 14 * root.s; height: width
                            path: "<path d='M12 20h9'/><path d='M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z'/>"
                            tint: "#2A1B05"
                            strokeWidth: 2.2
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 3 * root.s
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: root.userName
                        font.family: root.fontFamily
                        font.pixelSize: 24 * root.s
                        font.weight: Font.DemiBold
                        color: "#FFFFFF"
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: root.errorMessage !== "" ? root.errorMessage
                              : (root.loggingIn ? root.tr("Đang đăng nhập…", "Signing in…")
                                                : root.tr("Nhập mật khẩu để tiếp tục", "Enter your password to continue"))
                        font.family: root.fontFamily
                        font.pixelSize: 13.5 * root.s
                        color: root.errorMessage !== "" ? "#FF8A8A" : Qt.rgba(1, 1, 1, 0.66)
                    }
                }

                // ô mật khẩu
                Rectangle {
                    id: pwdBox
                    width: parent.width
                    height: 52 * root.s
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, pwd.activeFocus ? 0.18 : 0.12)
                    border.width: pwd.activeFocus || root.errorMessage !== "" ? 1.5 : 1
                    border.color: root.errorMessage !== "" ? "#FF8A8A"
                                  : (pwd.activeFocus ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.95) : Qt.rgba(1, 1, 1, 0.28))
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 22 * root.s
                        visible: pwd.text.length === 0
                        text: root.tr("Mật khẩu", "Password")
                        font.family: root.fontFamily
                        font.pixelSize: 16 * root.s
                        color: Qt.rgba(1, 1, 1, 0.5)
                    }

                    // chấm mật khẩu
                    Row {
                        id: dots
                        anchors.verticalCenter: parent.verticalCenter
                        x: 22 * root.s
                        spacing: 7 * root.s
                        Repeater {
                            model: Math.min(pwd.text.length, 20)
                            delegate: Rectangle {
                                id: dot
                                required property int index
                                width: 9 * root.s; height: width; radius: width / 2
                                color: "#FFFFFF"
                                scale: 0.3
                                opacity: 0
                                Component.onCompleted: pop.start()
                                ParallelAnimation {
                                    id: pop
                                    NumberAnimation { target: dot; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 2 }
                                    NumberAnimation { target: dot; property: "opacity"; to: 1; duration: 140 }
                                }
                            }
                        }
                    }

                    TextInput {
                        id: pwd
                        anchors.fill: parent
                        anchors.leftMargin: 22 * root.s
                        anchors.rightMargin: 60 * root.s
                        echoMode: TextInput.Password
                        color: "transparent"
                        selectionColor: "transparent"
                        selectedTextColor: "transparent"
                        cursorDelegate: Item { width: 0; height: 0 }
                        font.pixelSize: 16 * root.s
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        enabled: !root.loggingIn
                        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                        Keys.onPressed: function (event) { if (root.phase === 0) root.skipSplash(); }
                        Keys.onEscapePressed: { if (root.picking) root.picking = false; else text = ""; }
                        onTextChanged: if (root.errorMessage !== "") root.errorMessage = ""
                        onAccepted: root.doLogin()
                    }

                    // nút mũi tên đăng nhập
                    Rectangle {
                        id: goBtn
                        width: 40 * root.s; height: width; radius: width / 2
                        anchors.right: parent.right
                        anchors.rightMargin: 6 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.accent
                        opacity: pwd.text.length > 0 && !root.loggingIn ? 1 : 0.35
                        scale: goMa.pressed ? 0.92 : (goMa.containsMouse ? 1.06 : 1)
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                        Behavior on scale { NumberAnimation { duration: 120 } }
                        Icon {
                            anchors.centerIn: parent
                            width: 20 * root.s; height: width
                            path: "<path d='M5 12h14'/><path d='M13 6l6 6-6 6'/>"
                            tint: "#2A1B05"
                            strokeWidth: 2.2
                        }
                        MouseArea {
                            id: goMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.doLogin()
                        }
                    }
                }

                // người dùng + phiên
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10 * root.s
                    GlassButton {
                        unit: root.s
                        label: root.userName
                        fontFamily: root.fontFamily; pixelSize: 13 * root.s
                        iconPath: "<circle cx='12' cy='8' r='4'/><path d='M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7'/>"
                        iconSize: 16
                        interactive: root.userCount > 1 && !root.loggingIn
                        onClicked: root.userIndex = (root.userIndex + 1) % root.userCount
                    }
                    GlassButton {
                        unit: root.s
                        label: root.sessionName
                        fontFamily: root.fontFamily; pixelSize: 13 * root.s
                        iconPath: "<rect x='3' y='4' width='18' height='13' rx='3'/><path d='M8 21h8M12 17v4'/>"
                        iconSize: 16
                        interactive: root.sessionCount > 1 && !root.loggingIn
                        onClicked: root.sessionIndex = (root.sessionIndex + 1) % root.sessionCount
                    }
                }
            }
        }

        // ---------- nút nguồn ----------
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 34 * root.s
            spacing: 16 * root.s

            Repeater {
                model: [
                    { kind: "sleep",  viT: "Ngủ",           enT: "Sleep",     icon: "<path d='M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z'/>" },
                    { kind: "reboot", viT: "Khởi động lại", enT: "Restart",   icon: "<path d='M20 11a8 8 0 1 0-2.3 5.7'/><path d='M20 4v7h-7'/>" },
                    { kind: "off",    viT: "Tắt máy",       enT: "Shut down", icon: "<path d='M12 3v9'/><path d='M18.4 6.6a9 9 0 1 1-12.8 0'/>" }
                ]
                delegate: Item {
                    required property var modelData
                    width: 52 * root.s; height: 52 * root.s
                    GlassButton {
                        id: pb
                        unit: root.s; round: true
                        iconPath: modelData.icon
                        onClicked: root.power(modelData.kind)
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 8 * root.s
                        text: root.tr(modelData.viT, modelData.enT)
                        font.family: root.fontFamily; font.pixelSize: 12.5 * root.s
                        color: "#FFFFFF"
                        opacity: pb.hovered ? 0.95 : 0
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                    }
                }
            }
        }
    }

    // ======================================================================
    //  BẢNG CHỌN AVATAR
    // ======================================================================
    Item {
        id: picker
        anchors.fill: parent
        z: 40
        opacity: root.picking ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        MouseArea { anchors.fill: parent; onClicked: root.picking = false }
        Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.35) }

        Rectangle {
            id: pickerCard
            width: 400 * root.s
            height: pickerCol.implicitHeight + 48 * root.s
            anchors.centerIn: parent
            radius: 28 * root.s
            color: Qt.rgba(0.10, 0.10, 0.15, 0.86)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.24)
            scale: root.picking ? 1 : 0.94
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent }   // chặn bấm xuyên

            Column {
                id: pickerCol
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 24 * root.s
                spacing: 16 * root.s

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.tr("Chọn ảnh đại diện", "Choose your avatar")
                    font.family: root.fontFamily; font.pixelSize: 18 * root.s; font.weight: Font.DemiBold
                    color: "#FFFFFF"
                }

                Grid {
                    id: grid
                    columns: 5
                    columnSpacing: 12 * root.s
                    rowSpacing: 20 * root.s
                    anchors.horizontalCenter: parent.horizontalCenter
                    readonly property real cell: (pickerCol.width - 4 * columnSpacing) / 5

                    // ô đầu: tự động (ảnh từ shell / hệ thống / chữ cái đầu)
                    Item {
                        width: grid.cell; height: width
                        Avatar {
                            anchors.fill: parent
                            anchors.margins: 3 * root.s
                            source: "avatars/" + root.userLogin
                            fallbackSource: root.userIcon
                            name: root.userName
                            accent: root.accent
                            fontFamily: root.fontFamily
                        }
                        Rectangle {
                            anchors.fill: parent; radius: width / 2; color: "transparent"
                            border.width: 2.5 * root.s
                            border.color: root.chosenAvatar === "" ? root.accent : "transparent"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.bottom
                            anchors.topMargin: 3 * root.s
                            text: root.tr("Tự động", "Auto")
                            font.family: root.fontFamily; font.pixelSize: 11 * root.s
                            color: Qt.rgba(1, 1, 1, 0.7)
                        }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.chooseAvatar("") }
                    }

                    // ảnh tự chọn của bạn (mới nhất trước)
                    Repeater {
                        model: root.gallery
                        delegate: Item {
                            id: customTile
                            required property string fileName
                            readonly property string path: "avatars/gallery/" + fileName
                            width: grid.cell; height: width
                            scale: cma.containsMouse ? 1.08 : 1
                            Behavior on scale { NumberAnimation { duration: 120 } }
                            Avatar {
                                anchors.fill: parent
                                anchors.margins: 3 * root.s
                                source: customTile.path
                                name: "?"
                                accent: root.accent
                            }
                            Rectangle {
                                anchors.fill: parent; radius: width / 2; color: "transparent"
                                border.width: 2.5 * root.s
                                border.color: root.chosenAvatar === customTile.path ? root.accent : "transparent"
                            }
                            MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.chooseAvatar(customTile.path) }
                        }
                    }

                    // ô "+": hướng dẫn thêm ảnh của riêng bạn
                    Item {
                        width: grid.cell; height: width
                        Rectangle {
                            anchors.fill: parent; anchors.margins: 3 * root.s
                            radius: width / 2
                            color: Qt.rgba(1, 1, 1, plusMa.containsMouse ? 0.18 : 0.08)
                            border.width: 1.5 * root.s
                            border.color: Qt.rgba(1, 1, 1, 0.45)
                            Icon {
                                anchors.centerIn: parent
                                width: parent.width * 0.42; height: width
                                path: "<path d='M12 5v14M5 12h14'/>"
                                tint: "#FFFFFF"
                                strokeWidth: 2
                            }
                        }
                        MouseArea { id: plusMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.addHint = !root.addHint }
                    }

                    Repeater {
                        model: root.presetAvatars
                        delegate: Item {
                            required property string modelData
                            width: grid.cell; height: width
                            scale: pma.containsMouse ? 1.08 : 1
                            Behavior on scale { NumberAnimation { duration: 120 } }
                            Image {
                                anchors.fill: parent
                                anchors.margins: 3 * root.s
                                source: modelData
                                sourceSize.width: 160; sourceSize.height: 160
                                fillMode: Image.PreserveAspectFit
                                smooth: true; mipmap: true
                            }
                            Rectangle {
                                anchors.fill: parent; radius: width / 2; color: "transparent"
                                border.width: 2.5 * root.s
                                border.color: root.chosenAvatar === modelData ? root.accent : "transparent"
                            }
                            MouseArea { id: pma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.chooseAvatar(modelData) }
                        }
                    }
                }
                Text {
                    width: parent.width
                    visible: root.addHint
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: root.tr("Muốn dùng ảnh của riêng bạn? Sau khi đăng nhập, đổi avatar trong Dashboard của shell — ảnh sẽ tự xuất hiện ở đây. Hoặc chép ảnh vào thư mục avatars/gallery của theme.",
                                  "Want your own picture? After signing in, change your avatar in the shell Dashboard — it will appear here. Or copy images into the theme's avatars/gallery folder.")
                    font.family: root.fontFamily; font.pixelSize: 12.5 * root.s
                    color: Qt.rgba(1, 1, 1, 0.75)
                }
                Item { width: 1; height: 12 * root.s }   // chỗ cho nhãn "Tự động"
            }
        }
    }

    // ======================================================================
    //  MÀN HÌNH CHÀO MỪNG (logo)
    // ======================================================================
    Item {
        id: splash
        anchors.fill: parent
        z: 50
        opacity: root.phase === 0 ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutCubic } }

        // lớp tối làm nổi logo
        Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.28) }

        MouseArea { anchors.fill: parent; onClicked: root.skipSplash() }

        // vầng sáng sau logo
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.height * 0.46 - height / 2
            width: root.height * 0.62; height: width; radius: width / 2
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20)
            visible: root.fx
            layer.enabled: root.fx
            layer.effect: MultiEffect { blurEnabled: true; blurMax: 64; blur: 1.0 }
            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { to: 1.12; duration: 2400; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.94; duration: 2400; easing.type: Easing.InOutSine }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 22 * root.s

            Image {
                id: logo
                anchors.horizontalCenter: parent.horizontalCenter
                source: "logo.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                height: root.height * 0.46
                width: height * (sourceSize.height > 0 ? sourceSize.width / sourceSize.height : 0.76)
                opacity: 0
                scale: 0.88
                transformOrigin: Item.Center
                property real t: 0
                NumberAnimation on t { from: 0; to: Math.PI * 2 * 40; duration: 120000; loops: Animation.Infinite }
                NumberAnimation on opacity { from: 0; to: 1; duration: 700; easing.type: Easing.OutCubic }
                NumberAnimation on scale { from: 0.88; to: 1; duration: 900; easing.type: Easing.OutCubic }
                // nhấp nhô rất nhẹ
                transform: Translate { y: Math.sin(logo.t * 1.4) * 5 * root.s }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6 * root.s
                opacity: 0
                NumberAnimation on opacity { from: 0; to: 1; duration: 700; easing.type: Easing.OutCubic }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.tr("Xin chào, ", "Welcome, ") + root.userName
                    font.family: root.fontFamily
                    font.pixelSize: 34 * root.s
                    font.weight: Font.Light
                    color: "#FFFFFF"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.greeting()
                    font.family: root.fontFamily
                    font.pixelSize: 16 * root.s
                    color: Qt.rgba(1, 1, 1, 0.72)
                }
            }
        }

        // ba chấm tải
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 56 * root.s
            spacing: 10 * root.s
            Repeater {
                model: 3
                delegate: Rectangle {
                    required property int index
                    width: 8 * root.s; height: width; radius: width / 2
                    color: root.accent
                    opacity: 0.3
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        PauseAnimation { duration: index * 180 }
                        NumberAnimation { to: 1; duration: 360; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.3; duration: 360; easing.type: Easing.InOutSine }
                        PauseAnimation { duration: (2 - index) * 180 }
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24 * root.s
            text: root.tr("Chạm hoặc nhấn phím bất kỳ để tiếp tục", "Tap or press any key to continue")
            font.family: root.fontFamily; font.pixelSize: 13 * root.s
            color: Qt.rgba(1, 1, 1, 0.55)
        }
    }

    Component.onCompleted: {
        loadStore();
        loadGallery();
        if (typeof keyboard !== "undefined" && keyboard !== null)
            keyboard.numLock = true;
        pwd.forceActiveFocus();
    }
}
