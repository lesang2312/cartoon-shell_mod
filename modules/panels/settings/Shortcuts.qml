import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.components
import Quickshell
import Quickshell.Io

Item {
  id: rootView
  // Không dùng anchors.fill ở đây: Shortcuts.qml được nhúng trực tiếp làm con
  // của StackLayout trong SettingsPanel, và StackLayout tự set width/height
  // cho item con trực tiếp. Anchors + layout-managed size cùng lúc gây ra
  // "undefined behavior" (log Quickshell cảnh báo đúng lỗi này) -> layout lệch,
  // không cân đối. StackLayout sẽ tự resize Item này, ScrollView bên trong vẫn
  // anchors.fill vào Item (không managed bởi layout) nên vẫn full khít bình thường.
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

  ScrollView {
    id: scrollView
    anchors.fill: parent
    anchors.margins: ScalerService.s(20)
    clip: true
    contentHeight: mainLayout.implicitHeight
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
      id: mainLayout
      width: scrollView.availableWidth
      spacing: ScalerService.s(16)

      Text {
        text: "⌨️ Hyprland Shortcuts"
        color: theme.primary.foreground
        font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(24); bold: true }
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: ScalerService.s(10)
      }

      Rectangle {
        Layout.fillWidth: true; height: ScalerService.s(1)
        color: theme.primary.foreground; opacity: 0.3
      }

      Text {
        text: "💡 Click a shortcut to edit, then press key combination · Esc to cancel · 🔒 = locked"
        color: theme.primary.foreground; opacity: 0.7
        font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(13) }
        Layout.fillWidth: true; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
      }

      Repeater {
        model: KeybindsService.categories
        delegate: ShortcutCategoryPanel { 
          categoryData: modelData 
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
              let pyCmd = "python3 ~/.config/quickshell/cartoon-shell/scripts/update_keybinds.py update '" + conflictDialog.categoryId + "' '" + conflictDialog.shortcutId + "' '" + conflictDialog.newKey + "'";
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