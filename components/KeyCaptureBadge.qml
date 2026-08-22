import QtQuick
import QtQuick.Layouts
import qs.services

Rectangle {
  id: root

  property string categoryId: ""
  property string shortcutId: ""
  property string currentKey: ""
  property bool editable: true
  property string pendingCombo: "" 

  readonly property string editId: KeybindsService.editIdFor(categoryId, shortcutId)
  readonly property bool listening: KeybindsService.activeEditId === root.editId
  property bool showModifierHint: false
  property bool hovered: false

  readonly property var _parts: KeyMapUtil.displayParts(root.currentKey)

  signal keyCaptured(string newKey)

  Timer {
    id: modifierHintTimer
    interval: 1400
    onTriggered: root.showModifierHint = false
  }

  readonly property real minBadgeWidth: ScalerService.s(150)
  readonly property real maxBadgeWidth: ScalerService.s(300)

  Layout.preferredWidth: Math.max(root.minBadgeWidth, Math.min(root.maxBadgeWidth, chipRow.implicitWidth + ScalerService.s(24)))
  Layout.minimumWidth: root.minBadgeWidth
  Layout.maximumWidth: root.maxBadgeWidth
  Layout.preferredHeight: ScalerService.s(36)
  Layout.alignment: Qt.AlignVCenter

  radius: ScalerService.s(9)
  color: {
    if (root.showModifierHint) return theme.normal.red;
    if (root.listening) return theme.normal.yellow;
    if (root.hovered && root.editable) return Qt.lighter(theme.normal.blue, 1.15);
    return theme.normal.blue; 
  }
  opacity: root.editable ? 1.0 : 0.6
  border.width: (root.listening || root.showModifierHint) ? ScalerService.s(2) : ScalerService.s(1)
  border.color: (root.listening || root.showModifierHint) ? theme.normal.white : theme.button.border

  Behavior on color { ColorAnimation { duration: 120 } }
  Behavior on opacity { NumberAnimation { duration: 120 } }

  SequentialAnimation {
    running: root.listening
    loops: Animation.Infinite
    NumberAnimation { target: root; property: "border.width"; to: ScalerService.s(3); duration: 550; easing.type: Easing.InOutQuad }
    NumberAnimation { target: root; property: "border.width"; to: ScalerService.s(1.5); duration: 550; easing.type: Easing.InOutQuad }
  }

  RowLayout {
    id: chipRow
    anchors.centerIn: parent
    spacing: ScalerService.s(4)
    visible: !root.listening && !root.showModifierHint && root.pendingCombo === ""

    Repeater {
      model: root._parts
      delegate: RowLayout {
        spacing: ScalerService.s(4)

        Rectangle {
          radius: ScalerService.s(5)
          color: Qt.rgba(0, 0, 0, 0.18)
          border.width: ScalerService.s(1)
          border.color: Qt.rgba(1, 1, 1, 0.14)
          Layout.preferredHeight: ScalerService.s(22)
          Layout.preferredWidth: chipLabel.implicitWidth + ScalerService.s(12)

          Text {
            id: chipLabel
            anchors.centerIn: parent
            text: modelData
            color: theme.primary.background
            font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(12); bold: true }
          }
        }

        Text {
          visible: index < root._parts.length - 1
          text: "+"
          color: theme.primary.background
          opacity: 0.65
          font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(12) }
        }
      }
    }

    Text {
      visible: !root.editable
      text: "🔒"
      font.pixelSize: ScalerService.s(12)
      Layout.leftMargin: ScalerService.s(2)
    }
  }

  Text {
    anchors.centerIn: parent
    visible: root.listening || root.showModifierHint || root.pendingCombo !== ""
    text: root.showModifierHint ? "⚠️ Modifier required" : (root.pendingCombo !== "" ? root.pendingCombo : "● Press new shortcut…")
    color: theme.primary.background
    font { family: "ComicShannsMono Nerd Font"; pixelSize: ScalerService.s(12); bold: true }
  }

  MouseArea {
    id: clickArea
    anchors.fill: parent
    enabled: root.editable
    hoverEnabled: true
    cursorShape: root.editable ? Qt.PointingHandCursor : Qt.ArrowCursor
    onEntered: root.hovered = true
    onExited: root.hovered = false
    onClicked: {
      KeybindsService.requestEdit(root.categoryId, root.shortcutId);
      keyGrabber.forceActiveFocus();
    }
  }

  FocusScope {
    id: keyGrabber
    anchors.fill: parent
    visible: root.listening

    Keys.onPressed: (event) => {
      if (!root.listening) return;

      if (event.key === Qt.Key_Escape) {
        KeybindsService.cancelEdit();
        event.accepted = true;
        return;
      }

      const pureModifiers = [Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R];
      if (pureModifiers.indexOf(event.key) !== -1) {
        root.pendingCombo = KeyMapUtil.buildPartialComboString(event.modifiers);
        event.accepted = true;
        return;
      }

      const combo = KeyMapUtil.buildComboString(event.key, event.modifiers);
      if (combo) {
        root.showModifierHint = false;
        root.pendingCombo = "";
        root.keyCaptured(combo);
      } else if (!(event.modifiers & KeyMapUtil.requiredModifierMask)) {
        root.showModifierHint = true;
        modifierHintTimer.restart();
      }
      event.accepted = true;
    }
    
    Keys.onReleased: (event) => {
      if (!root.listening) return;
      const pureModifiers = [Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R];
      if (pureModifiers.indexOf(event.key) !== -1) {
        root.pendingCombo = KeyMapUtil.buildPartialComboString(event.modifiers);
      }
    }

    onActiveFocusChanged: {
      if (!activeFocus && root.listening) {
        KeybindsService.cancelEdit();
      }
    }

    MouseArea {
      anchors.fill: parent
      enabled: root.listening
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onPressed: (mouse) => {
        const combo = KeyMapUtil.buildMouseComboString(mouse.button, mouse.modifiers);
        if (combo) {
          root.keyCaptured(combo);
        }
      }
    }
  }

  onListeningChanged: {
    if (!listening) {
      showModifierHint = false;
      pendingCombo = "";
      modifierHintTimer.stop();
    }
  }
}