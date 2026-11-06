import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.components
import qs.commons
import Quickshell
import Quickshell.Io

ColumnLayout {
  id: root
  property var categoryData: ({ title: "", shortcuts: [] })
  property bool readOnly: false
  property bool allowDelete: !readOnly
  // Item dùng làm tâm để center dialog (mặc định null -> fallback Overlay.overlay).
  // Truyền rootView của Shortcuts.qml / KeyBindDisplay.qml vào đây để dialog
  // center đúng theo vùng content, không bị lệch vì sidebar bên cạnh.
  property var dialogAnchorItem: null

  signal editInitiated(string catId, string scId)

  Layout.fillWidth: true
  spacing: ScalerService.s(12)

  Process { id: pyRunner }

  // Escape 1 chuỗi để nhét an toàn vào trong dấu nháy đơn của bash -c.
  // Cần vì action/command người dùng tự gõ, nếu chứa dấu ' sẽ làm gãy pyCmd.
  function _shQuote(s) {
    return "'" + String(s).replace(/'/g, "'\\''") + "'";
  }

  Rectangle {
    Layout.fillWidth: true
    height: ScalerService.s(46)
    color: Qt.alpha(theme.primary.dim_background, 0.72)
    radius: ScalerService.s(10)
    border.width: ScalerService.s(1)
    border.color: Qt.rgba(0.88, 0.93, 1.0, 0.48)

    Text {
      anchors.centerIn: parent
      text: root.categoryData.title
      color: theme.primary.foreground
      font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(16); bold: true }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: ScalerService.s(8)

    Repeater {
      model: root.categoryData.shortcuts

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: Math.max(ScalerService.s(55), rowContent.implicitHeight + ScalerService.s(20))
        color: Qt.alpha(theme.button.background, 0.52)
        radius: ScalerService.s(8)
        border.width: ScalerService.s(1)
        border.color: Qt.rgba(0.88, 0.93, 1.0, 0.68)

        RowLayout {
          id: rowContent
          anchors.fill: parent
          anchors.margins: ScalerService.s(12)
          spacing: ScalerService.s(14)

          KeyCaptureBadge {
            Layout.alignment: Qt.AlignVCenter
            categoryId: root.categoryData.id
            shortcutId: modelData.id
            currentKey: modelData.key
            editable: !root.readOnly && modelData.editable !== false && modelData.locked !== true

            onKeyCaptured: (newKey) => {
              if (root.readOnly) return;
              root.editInitiated(root.categoryData.id, modelData.id);
              
              KeybindsService.updateShortcut(root.categoryData.id, modelData.id, newKey, false);
              let pyCmd = "python3 ~/.config/quickshell/cartoon-shell/scripts/update_keybinds.py update '" + root.categoryData.id + "' '" + modelData.id + "' '" + newKey + "'";
              pyRunner.command = ["bash", "-c", pyCmd];
              pyRunner.running = true;
            }
          }

          Text {
            text: modelData.action
            color: "#FFFFFF"
            font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(14) }
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
          }

          Rectangle {
            id: deleteBtn
            Layout.alignment: Qt.AlignVCenter
            width: ScalerService.s(32); height: ScalerService.s(32)
            radius: ScalerService.s(8)
            visible: root.allowDelete && modelData.locked !== true
            color: delMouse.containsMouse ? "#ff4444" : Qt.alpha(theme.button.background, 0.9)
            border.width: ScalerService.s(1)
            border.color: delMouse.containsMouse ? "#ff4444" : theme.button.border
            scale: delMouse.pressed ? 0.9 : 1.0

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

            Text {
              anchors.centerIn: parent
              text: "✕"
              color: delMouse.containsMouse ? theme.primary.background : "#ff6b6b"
              font { pixelSize: ScalerService.s(15); bold: true }
              Behavior on color { ColorAnimation { duration: 120 } }
            }
            MouseArea {
              id: delMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                // Cập nhật model local trước để UI phản ánh ngay lập tức
                // (giống pattern của updateShortcut ở KeyCaptureBadge phía trên)
                KeybindsService.removeShortcut(root.categoryData.id, modelData.id);

                let pyCmd = "python3 ~/.config/quickshell/cartoon-shell/scripts/update_keybinds.py delete '" + root.categoryData.id + "' '" + modelData.id + "'";
                pyRunner.command = ["bash", "-c", pyCmd];
                pyRunner.running = true;
              }
            }
          }
        }
      }
    }
    
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: ScalerService.s(42)
      visible: !root.readOnly
      color: Qt.alpha(theme.button.background, 0.28)
      radius: ScalerService.s(8)
      border.width: ScalerService.s(1)
      border.color: addMouse.containsMouse ? theme.normal.blue : theme.button.border
      opacity: addMouse.containsMouse ? 1.0 : 0.7
      scale: addMouse.pressed ? 0.97 : 1.0

      Behavior on border.color { ColorAnimation { duration: 120 } }
      Behavior on opacity { NumberAnimation { duration: 120 } }
      Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

      RowLayout {
        anchors.centerIn: parent
        spacing: ScalerService.s(8)
        Text { text: "➕"; color: theme.primary.foreground; font.pixelSize: ScalerService.s(13) }
        Text {
          text: LanguageService.t("shortcuts", "add_new")
          color: theme.primary.foreground
          font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(13); bold: true }
        }
      }

      MouseArea {
        id: addMouse; anchors.fill: parent; hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (Settings.appearance.dialogStyle === "cute") ? cuteDialog.open() : addDialog.open()
      }
    }
  }

  // Lưu shortcut mới (dùng chung cho dialog cổ điển và dialog cute).
  function addShortcut(actionName, command, key, inTerminal) {
    let s_id = "custom_" + Date.now();
    let finalCmd = inTerminal
      ? ("kitty --hold -e bash -c " + root._shQuote(command))
      : command;

    // Cập nhật model ngay lập tức -> cả 2 bảng hiển thị refresh liền.
    KeybindsService.addNewShortcut(root.categoryData.id, s_id, key, actionName, finalCmd);

    let pyCmd = "python3 ~/.config/quickshell/cartoon-shell/scripts/update_keybinds.py add "
      + root._shQuote(root.categoryData.id) + " "
      + root._shQuote(s_id) + " "
      + root._shQuote(key) + " "
      + root._shQuote(actionName) + " "
      + root._shQuote(finalCmd);
    pyRunner.command = ["bash", "-c", pyCmd];
    pyRunner.running = true;
  }

  CuteShortcutDialog {
    id: cuteDialog
    parent: root.dialogAnchorItem ? root.dialogAnchorItem : root
    anchorItem: root.dialogAnchorItem
    categoryId: root.categoryData.id
    onSaveRequested: (name, cmd, key, inTerm) => root.addShortcut(name, cmd, key, inTerm)
  }

  Dialog {
    id: addDialog
    // Set thẳng parent vào Item mong muốn (không dùng Overlay.overlay vì dự án
    // dùng PanelWindow, không phải ApplicationWindow -> Overlay.overlay không
    // tồn tại đúng nghĩa, khiến anchors.centerIn tính toán sai toạ độ).
    parent: root.dialogAnchorItem ? root.dialogAnchorItem : root
    modal: true
    anchors.centerIn: parent
    padding: ScalerService.s(20)

    property string pendingKey: ""
    property string keyConflictText: ""
    property bool runInTerminal: false

    function resetFields() {
      actionNameField.text = "";
      cmdField.text = "";
      addDialog.pendingKey = "";
      addDialog.keyConflictText = "";
      addDialog.runInTerminal = false;
    }

    enter: Transition {
      NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
      NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 160; easing.type: Easing.OutBack }
    }
    exit: Transition {
      NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 120; easing.type: Easing.InCubic }
      NumberAnimation { property: "scale"; from: 1.0; to: 0.92; duration: 120; easing.type: Easing.InCubic }
    }

    Overlay.modal: Rectangle {
      color: "#00000066"
      Behavior on opacity { NumberAnimation { duration: 140 } }
    }

    background: Rectangle {
      color: Qt.alpha(theme.primary.dim_background, 0.74)
      radius: ScalerService.s(16)
      border.width: ScalerService.s(1)
      border.color: theme.button.border
    }

    contentItem: ColumnLayout {
      spacing: ScalerService.s(15)
      width: Math.min(root.dialogAnchorItem ? root.dialogAnchorItem.width * 0.88 : ScalerService.s(380), ScalerService.s(420))

      Text {
        text: LanguageService.t("shortcuts", "configure_new")
        color: theme.primary.foreground
        font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(18); bold: true }
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: ScalerService.s(10)
      }

      Text { text: LanguageService.t("shortcuts", "action_name"); color: theme.primary.foreground; font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(13) } }
      TextField {
        id: actionNameField
        Layout.fillWidth: true
        placeholderText: LanguageService.t("shortcuts", "action_placeholder")
        color: theme.primary.foreground
        font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(14) }
        leftPadding: ScalerService.s(10); rightPadding: ScalerService.s(10)
        background: Rectangle {
          color: Qt.alpha(theme.button.background, 0.34); radius: ScalerService.s(9)
          border.width: ScalerService.s(1); border.color: actionNameField.activeFocus ? theme.button.border_select : theme.button.border
        }
      }

      Text {
        text: LanguageService.t("shortcuts", "command")
        color: theme.primary.foreground
        font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(13) }
        Layout.topMargin: ScalerService.s(10)
      }
      TextField {
        id: cmdField
        Layout.fillWidth: true
        placeholderText: LanguageService.t("shortcuts", "command_placeholder")
        color: theme.primary.foreground
        font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(14) }
        leftPadding: ScalerService.s(10); rightPadding: ScalerService.s(10)
        background: Rectangle {
          color: Qt.alpha(theme.button.background, 0.34); radius: ScalerService.s(9)
          border.width: ScalerService.s(1); border.color: cmdField.activeFocus ? theme.button.border_select : theme.button.border
        }
      }

      Text {
        text: LanguageService.t("shortcuts", "assign_key")
        color: theme.primary.foreground
        font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(13) }
        Layout.topMargin: ScalerService.s(10)
      }

      RowLayout {
        Layout.fillWidth: true; spacing: ScalerService.s(10)

        KeyCaptureBadge {
          categoryId: root.categoryData.id
          shortcutId: "__pending_add__"
          currentKey: addDialog.pendingKey
          editable: true

          onKeyCaptured: (newKey) => {
            const conflict = KeybindsService.findConflict(newKey, root.categoryData.id, "__pending_add__");
            if (conflict) {
              addDialog.pendingKey = "";
              addDialog.keyConflictText = "⚠️ " + LanguageService.t("shortcuts", "key_conflict") + conflict.action;
            } else {
              addDialog.pendingKey = newKey;
              addDialog.keyConflictText = "";
            }
          }
        }

        Text {
          visible: addDialog.pendingKey === "" && addDialog.keyConflictText === ""
          text: LanguageService.t("shortcuts", "capture_hint")
          color: theme.primary.foreground; opacity: 0.6
          font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(11) }
        }
      }

      Text {
        visible: addDialog.keyConflictText !== ""
        text: addDialog.keyConflictText
        color: "#ff4444"
        wrapMode: Text.WordWrap; Layout.fillWidth: true
        font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(11) }
      }

      RowLayout {
        Layout.fillWidth: true; Layout.topMargin: ScalerService.s(8); spacing: ScalerService.s(8)

        Rectangle {
          id: terminalCheck
          width: ScalerService.s(18); height: ScalerService.s(18)
          radius: ScalerService.s(4)
          color: addDialog.runInTerminal ? theme.normal.blue : theme.button.background
          border.width: ScalerService.s(1); border.color: theme.button.border
          Text {
            anchors.centerIn: parent
            visible: addDialog.runInTerminal
            text: "✓"; color: theme.primary.background
            font { pixelSize: ScalerService.s(12); bold: true }
          }
          MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: addDialog.runInTerminal = !addDialog.runInTerminal
          }
        }
        Text {
          text: LanguageService.t("shortcuts", "run_terminal")
          color: theme.primary.foreground
          wrapMode: Text.WordWrap; Layout.fillWidth: true
          font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(12) }
          MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: addDialog.runInTerminal = !addDialog.runInTerminal
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true; Layout.topMargin: ScalerService.s(15); spacing: ScalerService.s(10)

        Rectangle {
          Layout.fillWidth: true; implicitHeight: ScalerService.s(38)
          color: theme.button.background; radius: ScalerService.s(6)
          border.width: ScalerService.s(1)
          border.color: cancelMouse.containsMouse ? theme.normal.blue : theme.button.border
          scale: cancelMouse.pressed ? 0.96 : 1.0
          Behavior on border.color { ColorAnimation { duration: 120 } }
          Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
          Text { anchors.centerIn: parent; text: LanguageService.t("shortcuts", "cancel"); color: theme.primary.foreground; font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(14) } }
          MouseArea {
            id: cancelMouse
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: { addDialog.resetFields(); addDialog.reject(); }
          }
        }

        Rectangle {
          Layout.fillWidth: true; implicitHeight: ScalerService.s(38)
          color: theme.normal.blue; radius: ScalerService.s(6)
          opacity: saveMouse.containsMouse ? 1.0 : 0.9
          scale: saveMouse.pressed ? 0.96 : 1.0
          Behavior on opacity { NumberAnimation { duration: 120 } }
          Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
          Text { anchors.centerIn: parent; text: LanguageService.t("shortcuts", "save"); color: theme.primary.background; font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(14); bold: true } }
          MouseArea {
            id: saveMouse
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (actionNameField.text.trim() === "" || cmdField.text.trim() === "") {
                addDialog.keyConflictText = "⚠️ " + LanguageService.t("shortcuts", "required_fields");
              } else {
                let s_id = "custom_" + Date.now();
                let finalKey = addDialog.pendingKey !== "" ? addDialog.pendingKey : "Unbound";
                let finalCmd = addDialog.runInTerminal
                  ? ("kitty --hold -e bash -c " + root._shQuote(cmdField.text))
                  : cmdField.text;

                // Cập nhật model ngay lập tức -> cả 2 bảng hiển thị (đều bind vào
                // KeybindsService.categories) refresh liền, không phải chờ FileView.
                KeybindsService.addNewShortcut(root.categoryData.id, s_id, finalKey, actionNameField.text, finalCmd);

                let pyCmd = "python3 ~/.config/quickshell/cartoon-shell/scripts/update_keybinds.py add "
                  + root._shQuote(root.categoryData.id) + " "
                  + root._shQuote(s_id) + " "
                  + root._shQuote(finalKey) + " "
                  + root._shQuote(actionNameField.text) + " "
                  + root._shQuote(finalCmd);
                pyRunner.command = ["bash", "-c", pyCmd];
                pyRunner.running = true;

                addDialog.resetFields();
                addDialog.accept();
              }
            }
          }
        }
      }
    }
  }
}