import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.components

// Hộp thoại "Configure New Shortcut" phong cách cute (kính mờ pastel, tai mèo,
// nhãn đa ngôn ngữ Anh • Việt • Trung • Hàn).
// Dùng thay cho addDialog cổ điển khi Settings.appearance.dialogStyle === "cute".
Dialog {
  id: dlg

  // ---- API ----
  property string categoryId: ""
  property var anchorItem: null
  property string pendingKey: ""
  property string keyConflictText: ""
  property bool runInTerminal: false

  // Phát ra khi người dùng bấm Save và dữ liệu hợp lệ.
  signal saveRequested(string actionName, string command, string key, bool inTerminal)

  function resetFields() {
    actionNameField.text = "";
    cmdField.text = "";
    pendingKey = "";
    keyConflictText = "";
    runInTerminal = false;
  }

  // ---- Bảng màu pastel ----
  readonly property color cText: "#ffffff"
  readonly property color cSub: "#e6e9ff"
  readonly property color cPink: "#ff8fb1"
  readonly property color cLilac: "#b59bff"
  readonly property color cBlue: "#7aa8ff"
  readonly property string fontFamily: "ComicShannsMono Nerd Font"

  modal: true
  anchors.centerIn: parent
  padding: ScalerService.s(26)
  topPadding: ScalerService.s(22)

  enter: Transition {
    NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
    NumberAnimation { property: "scale"; from: 0.85; to: 1.0; duration: 260; easing.type: Easing.OutBack }
  }
  exit: Transition {
    NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 130; easing.type: Easing.InCubic }
    NumberAnimation { property: "scale"; from: 1.0; to: 0.92; duration: 130; easing.type: Easing.InCubic }
  }

  Overlay.modal: Rectangle {
    color: "#33203a66"
  }

  // ---- Thành phần dùng lại ----
  // Nhãn: icon tròn gradient + tiêu đề + dòng phụ đa ngôn ngữ.
  component CuteLabel: RowLayout {
    property string icon: ""
    property color iconColor: dlg.cBlue
    property string title: ""
    property string sub: ""
    spacing: ScalerService.s(12)
    Layout.fillWidth: true

    Rectangle {
      Layout.preferredWidth: ScalerService.s(42)
      Layout.preferredHeight: ScalerService.s(42)
      radius: width / 2
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.lighter(iconColor, 1.25) }
        GradientStop { position: 1.0; color: iconColor }
      }
      border.width: ScalerService.s(2)
      border.color: "#aaffffff"
      Text {
        anchors.centerIn: parent
        text: icon
        color: "white"
        font.pixelSize: ScalerService.s(20)
      }
    }
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 0
      Text {
        text: title
        color: dlg.cText
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        font { family: dlg.fontFamily; pixelSize: ScalerService.s(16); bold: true }
      }
      Text {
        text: sub
        color: dlg.cSub
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        font { family: dlg.fontFamily; pixelSize: ScalerService.s(11) }
      }
    }
  }

  // Ô nhập kiểu viên thuốc.
  component CutePill: TextField {
    property string leadIcon: ""
    Layout.fillWidth: true
    implicitHeight: ScalerService.s(46)
    color: dlg.cText
    placeholderTextColor: "#b3ffffff"
    font { family: dlg.fontFamily; pixelSize: ScalerService.s(15) }
    leftPadding: ScalerService.s(46)
    rightPadding: ScalerService.s(14)
    selectionColor: dlg.cPink
    background: Rectangle {
      radius: height / 2
      color: "#2effffff"
      border.width: ScalerService.s(2)
      border.color: parent.activeFocus ? dlg.cPink : "#80ffffff"
      Behavior on border.color { ColorAnimation { duration: 120 } }
      Text {
        anchors.left: parent.left
        anchors.leftMargin: ScalerService.s(16)
        anchors.verticalCenter: parent.verticalCenter
        text: leadIcon
        font.pixelSize: ScalerService.s(16)
        color: "white"
      }
    }
  }

  // ---- Nền: kính pastel + tai mèo ----
  background: Item {
    // Thân kính
    Rectangle {
      anchors.fill: parent
      radius: ScalerService.s(30)
      gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: "#f0707fdc" }
        GradientStop { position: 1.0; color: "#f09a7fd6" }
      }
      border.width: ScalerService.s(2)
      border.color: "#b3ffffff"
    }
    // Viền sáng bên trong
    Rectangle {
      anchors.fill: parent
      anchors.margins: ScalerService.s(5)
      radius: ScalerService.s(26)
      color: "transparent"
      border.width: ScalerService.s(1)
      border.color: "#33ffffff"
    }

    // Mèo ló đầu (góc trên trái)
    CuteCat { x: ScalerService.s(34); y: -ScalerService.s(26) }
    Text {
      x: ScalerService.s(128); y: -ScalerService.s(14)
      text: "✦"; color: dlg.cPink
      font.pixelSize: ScalerService.s(18)
      SequentialAnimation on opacity {
        loops: Animation.Infinite; running: dlg.visible
        NumberAnimation { to: 0.3; duration: 700 }
        NumberAnimation { to: 1.0; duration: 700 }
      }
    }

    // Dấu chân mèo góc dưới trái
    Text {
      anchors.left: parent.left; anchors.bottom: parent.bottom
      anchors.leftMargin: ScalerService.s(16); anchors.bottomMargin: ScalerService.s(10)
      text: "🐾"; font.pixelSize: ScalerService.s(16); opacity: 0.85
    }
  }

  contentItem: ColumnLayout {
    spacing: ScalerService.s(16)
    implicitWidth: Math.min(dlg.anchorItem ? dlg.anchorItem.width * 0.92 : ScalerService.s(560), ScalerService.s(560))

    // ---- Header ----
    RowLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(14)

      Rectangle {
        Layout.preferredWidth: ScalerService.s(52)
        Layout.preferredHeight: ScalerService.s(52)
        radius: ScalerService.s(16)
        color: "#33ffffff"
        border.width: ScalerService.s(1); border.color: "#66ffffff"
        Text { anchors.centerIn: parent; text: "🚀"; font.pixelSize: ScalerService.s(26) }
      }
      Rectangle { Layout.preferredWidth: ScalerService.s(2); Layout.preferredHeight: ScalerService.s(46); color: "#99ffffff" }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        Text {
          text: LanguageService.t("shortcuts", "configure_new")
          color: dlg.cText; Layout.fillWidth: true; wrapMode: Text.WordWrap
          font { family: dlg.fontFamily; pixelSize: ScalerService.s(24); bold: true }
        }
        Text {
          text: "Cấu hình phím tắt mới  •  新建快捷方式  •  새로운 바로가기 설정"
          color: dlg.cSub; Layout.fillWidth: true; wrapMode: Text.WordWrap
          font { family: dlg.fontFamily; pixelSize: ScalerService.s(12) }
        }
      }
      // Nút đóng
      Rectangle {
        Layout.preferredWidth: ScalerService.s(34); Layout.preferredHeight: ScalerService.s(34)
        Layout.alignment: Qt.AlignTop
        radius: width / 2
        color: closeMouse.containsMouse ? "#66ffffff" : "#33ffffff"
        border.width: ScalerService.s(2); border.color: "#b3ffffff"
        scale: closeMouse.pressed ? 0.9 : 1.0
        Behavior on scale { NumberAnimation { duration: 100 } }
        Text { anchors.centerIn: parent; text: "✕"; color: "white"; font { pixelSize: ScalerService.s(15); bold: true } }
        MouseArea {
          id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          onClicked: { dlg.resetFields(); dlg.reject(); }
        }
      }
    }

    // ---- Khung nội dung ----
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: body.implicitHeight + ScalerService.s(32)
      radius: ScalerService.s(22)
      color: "#1fffffff"
      border.width: ScalerService.s(1); border.color: "#4dffffff"

      ColumnLayout {
        id: body
        anchors.fill: parent
        anchors.margins: ScalerService.s(16)
        spacing: ScalerService.s(10)

        CuteLabel {
          icon: "⚙"; iconColor: dlg.cBlue
          title: LanguageService.t("shortcuts", "action_name")
          sub: "Tên hành động  •  动作名称  •  작업 이름"
        }
        CutePill { id: actionNameField; leadIcon: "✎"; placeholderText: LanguageService.t("shortcuts", "action_placeholder") }

        CuteLabel {
          Layout.topMargin: ScalerService.s(6)
          icon: "❯_"; iconColor: dlg.cLilac
          title: LanguageService.t("shortcuts", "command")
          sub: "Lệnh / Ứng dụng thực thi  •  命令 / 应用程序路径  •  명령어 / 실행 파일"
        }
        CutePill { id: cmdField; leadIcon: "📁"; placeholderText: LanguageService.t("shortcuts", "command_placeholder") }

        CuteLabel {
          Layout.topMargin: ScalerService.s(6)
          icon: "⚡"; iconColor: dlg.cPink
          title: LanguageService.t("shortcuts", "assign_key")
          sub: "Gán phím tắt  •  设置快捷键  •  단축키 지정"
        }
        RowLayout {
          Layout.fillWidth: true
          spacing: ScalerService.s(10)
          KeyCaptureBadge {
            categoryId: dlg.categoryId
            shortcutId: "__pending_add__"
            currentKey: dlg.pendingKey
            editable: true
            onKeyCaptured: (newKey) => {
              const conflict = KeybindsService.findConflict(newKey, dlg.categoryId, "__pending_add__");
              if (conflict) {
                dlg.pendingKey = "";
                dlg.keyConflictText = "⚠️ " + LanguageService.t("shortcuts", "key_conflict") + conflict.action;
              } else {
                dlg.pendingKey = newKey;
                dlg.keyConflictText = "";
              }
            }
          }
          Text {
            visible: dlg.pendingKey === "" && dlg.keyConflictText === ""
            text: LanguageService.t("shortcuts", "capture_hint")
            color: dlg.cSub; opacity: 0.8
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            font { family: dlg.fontFamily; pixelSize: ScalerService.s(11) }
          }
        }
        Text {
          visible: dlg.keyConflictText !== ""
          text: dlg.keyConflictText
          color: "#ffd2dc"
          wrapMode: Text.WordWrap; Layout.fillWidth: true
          font { family: dlg.fontFamily; pixelSize: ScalerService.s(12); bold: true }
        }

        // Chạy trong terminal
        RowLayout {
          Layout.fillWidth: true
          Layout.topMargin: ScalerService.s(6)
          spacing: ScalerService.s(12)

          Rectangle {
            Layout.preferredWidth: ScalerService.s(34); Layout.preferredHeight: ScalerService.s(34)
            Layout.alignment: Qt.AlignTop
            radius: ScalerService.s(10)
            color: dlg.runInTerminal ? dlg.cBlue : "#26ffffff"
            border.width: ScalerService.s(2); border.color: "#b3ffffff"
            Behavior on color { ColorAnimation { duration: 120 } }
            Text { anchors.centerIn: parent; visible: dlg.runInTerminal; text: "✓"; color: "white"; font { pixelSize: ScalerService.s(20); bold: true } }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: dlg.runInTerminal = !dlg.runInTerminal }
          }
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
              text: LanguageService.t("shortcuts", "run_terminal")
              color: dlg.cText; Layout.fillWidth: true; wrapMode: Text.WordWrap
              font { family: dlg.fontFamily; pixelSize: ScalerService.s(14); bold: true }
            }
            Text {
              text: "Chạy trong Terminal (Kitty)  •  在终端中运行  •  터미널에서 실행"
              color: dlg.cSub; Layout.fillWidth: true; wrapMode: Text.WordWrap
              font { family: dlg.fontFamily; pixelSize: ScalerService.s(11) }
            }
          }
          TapHandler { onTapped: dlg.runInTerminal = !dlg.runInTerminal }
        }
      }
    }

    // ---- Nút Cancel / Save ----
    RowLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(16)

      Rectangle {
        Layout.fillWidth: true; Layout.preferredWidth: 1
        implicitHeight: ScalerService.s(58)
        radius: ScalerService.s(22)
        color: cancelMouse.containsMouse ? "#40ffffff" : "#26ffffff"
        border.width: ScalerService.s(2); border.color: "#99ffffff"
        scale: cancelMouse.pressed ? 0.96 : 1.0
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 120 } }
        RowLayout {
          anchors.centerIn: parent; spacing: ScalerService.s(10)
          Text { text: "✕"; color: "white"; font { pixelSize: ScalerService.s(20); bold: true } }
          ColumnLayout {
            spacing: 0
            Text { text: LanguageService.t("shortcuts", "cancel"); color: dlg.cText; font { family: dlg.fontFamily; pixelSize: ScalerService.s(17); bold: true } }
            Text { text: "Hủy bỏ  •  取消  •  취소"; color: dlg.cSub; font { family: dlg.fontFamily; pixelSize: ScalerService.s(10) } }
          }
        }
        MouseArea {
          id: cancelMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          onClicked: { dlg.resetFields(); dlg.reject(); }
        }
      }

      Rectangle {
        Layout.fillWidth: true; Layout.preferredWidth: 1
        implicitHeight: ScalerService.s(58)
        radius: ScalerService.s(22)
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: saveMouse.containsMouse ? "#9cc0ff" : "#86aefc" }
          GradientStop { position: 1.0; color: saveMouse.containsMouse ? "#c3a8ff" : "#ab94f5" }
        }
        border.width: ScalerService.s(2); border.color: "#d9ffffff"
        scale: saveMouse.pressed ? 0.96 : 1.0
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
        RowLayout {
          anchors.centerIn: parent; spacing: ScalerService.s(10)
          Text { text: "✓"; color: "white"; font { pixelSize: ScalerService.s(22); bold: true } }
          ColumnLayout {
            spacing: 0
            Text { text: LanguageService.t("shortcuts", "save"); color: "white"; font { family: dlg.fontFamily; pixelSize: ScalerService.s(17); bold: true } }
            Text { text: "Lưu  •  保存  •  저장"; color: dlg.cSub; font { family: dlg.fontFamily; pixelSize: ScalerService.s(10) } }
          }
        }
        MouseArea {
          id: saveMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (actionNameField.text.trim() === "" || cmdField.text.trim() === "") {
              dlg.keyConflictText = "⚠️ " + LanguageService.t("shortcuts", "required_fields");
              return;
            }
            dlg.saveRequested(actionNameField.text, cmdField.text,
                              dlg.pendingKey !== "" ? dlg.pendingKey : "Unbound",
                              dlg.runInTerminal);
            dlg.resetFields();
            dlg.accept();
          }
        }
      }
    }
  }
}
