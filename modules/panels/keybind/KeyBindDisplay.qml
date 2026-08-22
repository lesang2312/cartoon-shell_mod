import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.components
import Quickshell
import Quickshell.Io

Item {
  id: rootView
  anchors.fill: parent
  property string pendingCategoryId: ""
  property string pendingShortcutId: ""

  Process { id: pyRunnerConflict }

  Connections {
    target: KeybindsService
    function onConflictDetected(existingCategoryId, existingShortcutId, existingKey) {
      conflictDialog.categoryId = rootView.pendingCategoryId;
      conflictDialog.shortcutId = rootView.pendingShortcutId;
      conflictDialog.newKey = existingKey;
      conflictDialog.open();
    }
  }

  function columnCategories(colIndex) {
    return KeybindsService.categories.filter((_, i) => i % 3 === colIndex);
  }

  ScrollView {
    id: scrollViewDisplay
    anchors.fill: parent
    anchors.margins: ScalerService.s(16)
    clip: true
    contentHeight: mainLayout.implicitHeight
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
      id: mainLayout
      width: scrollViewDisplay.availableWidth
      spacing: ScalerService.s(16)

      // Đã bỏ title "⌨️ Keybind Quick View" ở đây: header ngoài
      // (KeyBindHeader.qml -> "All keyboard shortcuts in Hyprland") đã hiển
      // thị title rồi, để cả 2 gây đè chữ lên nhau khi header co lại nhỏ hơn
      // nội dung thật. Divider + dòng hướng dẫn vẫn giữ nguyên bên dưới.
      Rectangle {
        Layout.fillWidth: true; height: ScalerService.s(1)
        color: theme.primary.foreground; opacity: 0.3
        Layout.topMargin: ScalerService.s(6)
      }

      Text {
        text: "💡 View only · Remove shortcuts here · Edit keys in Settings → Shortcuts · 🔒 = locked"
        color: theme.primary.foreground; opacity: 0.7
        font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(13) }
        Layout.fillWidth: true; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
      }

      RowLayout {
        Layout.fillWidth: true; Layout.fillHeight: true; spacing: ScalerService.s(16)
        Repeater {
          model: 3
          delegate: ColumnLayout {
            spacing: ScalerService.s(16); Layout.fillWidth: true; Layout.alignment: Qt.AlignTop
            Repeater {
              model: rootView.columnCategories(index)
              delegate: ShortcutCategoryPanel { 
                categoryData: modelData
                readOnly: true
                allowDelete: false
                dialogAnchorItem: rootView
                onEditInitiated: (catId, scId) => {
                  rootView.pendingCategoryId = catId;
                  rootView.pendingShortcutId = scId;
                }
              }
            }
            Item { Layout.fillHeight: true }
          }
        }
      }
      Item { Layout.fillHeight: true; Layout.preferredHeight: ScalerService.s(20) }
    }
  }

  Dialog {
    id: conflictDialog
    property string categoryId: ""
    property string shortcutId: ""
    property string newKey: ""

    parent: rootView
    modal: true
    anchors.centerIn: parent
    padding: ScalerService.s(20)

    enter: Transition {
      NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
      NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 160; easing.type: Easing.OutBack }
    }
    exit: Transition {
      NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 120; easing.type: Easing.InCubic }
      NumberAnimation { property: "scale"; from: 1.0; to: 0.92; duration: 120; easing.type: Easing.InCubic }
    }

    background: Rectangle {
      color: theme.primary.dim_background; radius: ScalerService.s(12)
      border.width: ScalerService.s(2); border.color: theme.normal.black
    }

    contentItem: ColumnLayout {
      spacing: ScalerService.s(15); width: ScalerService.s(340)

      Text {
        text: "⚠️ Shortcut Conflict"
        color: "#ff4444"
        font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(18); bold: true }
        Layout.alignment: Qt.AlignHCenter
      }

      Text {
        text: "The key combination \"" + conflictDialog.newKey + "\" is already assigned.\nDo you want to overwrite it?"
        color: theme.primary.foreground
        font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(14) }
        wrapMode: Text.WordWrap; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
      }

      RowLayout {
        Layout.fillWidth: true; Layout.topMargin: ScalerService.s(10); spacing: ScalerService.s(10)
        
        Rectangle {
          Layout.fillWidth: true; implicitHeight: ScalerService.s(38)
          color: theme.button.background; radius: ScalerService.s(6)
          border.width: ScalerService.s(1); border.color: theme.button.border
          Text { anchors.centerIn: parent; text: "Cancel"; color: theme.primary.foreground; font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(14) } }
          MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: { KeybindsService.cancelEdit(); conflictDialog.reject(); }
          }
        }
        
        Rectangle {
          Layout.fillWidth: true; implicitHeight: ScalerService.s(38)
          color: "#ff4444"; radius: ScalerService.s(6)
          Text { anchors.centerIn: parent; text: "Overwrite"; color: theme.primary.background; font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(14); bold: true } }
          MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: {
              KeybindsService.updateShortcut(conflictDialog.categoryId, conflictDialog.shortcutId, conflictDialog.newKey, true);
              let pyCmd = "python3 ~/.config/quickshell/cartoon-shell/update_keybinds.py update '" + conflictDialog.categoryId + "' '" + conflictDialog.shortcutId + "' '" + conflictDialog.newKey + "'";
              pyRunnerConflict.command = ["bash", "-c", pyCmd];
              pyRunnerConflict.running = true;
              conflictDialog.accept();
            }
          }
        }
      }
    }
  }
}