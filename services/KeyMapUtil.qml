// services/KeyMapUtil.qml
// Singleton — đăng ký trong qmldir: singleton KeyMapUtil 1.0 KeyMapUtil.qml
pragma Singleton
import QtQuick

QtObject {
  id: root

  // Tên phím "đặc biệt" khớp với cú pháp trong keybindings.lua gốc
  readonly property var specialKeys: ({})

  function _keyName(key) {
    switch (key) {
      case Qt.Key_Return:
      case Qt.Key_Enter:      return "RETURN";
      case Qt.Key_Space:      return "SPACE";
      case Qt.Key_Left:       return "left";
      case Qt.Key_Right:      return "right";
      case Qt.Key_Up:         return "up";
      case Qt.Key_Down:       return "down";
      case Qt.Key_Tab:        return "TAB";
      case Qt.Key_Backspace:  return "BACKSPACE";
      case Qt.Key_Delete:     return "DELETE";
      case Qt.Key_Escape:     return "ESCAPE";
      case Qt.Key_Print:      return "PRINT";

      // Media / multimedia keys -> tên XF86 dùng trong hl.bind
      case Qt.Key_VolumeUp:         return "XF86AudioRaiseVolume";
      case Qt.Key_VolumeDown:       return "XF86AudioLowerVolume";
      case Qt.Key_VolumeMute:       return "XF86AudioMute";
      case Qt.Key_MicMute:          return "XF86AudioMicMute";
      case Qt.Key_MediaNext:        return "XF86AudioNext";
      case Qt.Key_MediaPrevious:    return "XF86AudioPrev";
      case Qt.Key_MediaPlay:        return "XF86AudioPlay";
      case Qt.Key_MediaPause:       return "XF86AudioPause";
      case Qt.Key_MediaTogglePlayPause: return "XF86AudioPlay";
      case Qt.Key_MonBrightnessUp:  return "XF86MonBrightnessUp";
      case Qt.Key_MonBrightnessDown:return "XF86MonBrightnessDown";

      default:
        // Chữ cái, số, F1-F12... event.text đã là ký tự đúng (vd "A", "1")
        if (key >= Qt.Key_A && key <= Qt.Key_Z) return String.fromCharCode(key);
        if (key >= Qt.Key_0 && key <= Qt.Key_9) return String.fromCharCode(key);
        if (key >= Qt.Key_F1 && key <= Qt.Key_F35) return "F" + (key - Qt.Key_F1 + 1);
        return null;
    }
  }

  // Các phím "standalone" (media keys, PRINT...) không cần/không nên
  // kèm modifier trong hl — giữ đúng convention của file gốc.
  readonly property var standaloneKeys: [
    "XF86AudioRaiseVolume", "XF86AudioLowerVolume", "XF86AudioMute", "XF86AudioMicMute",
    "XF86AudioNext", "XF86AudioPrev", "XF86AudioPlay", "XF86AudioPause",
    "XF86MonBrightnessUp", "XF86MonBrightnessDown", "PRINT"
  ]

  // Modifier bitmask that a "normal" key (letters, digits, F-keys, arrows...)
  // must be combined with. Without this guard it was possible to accidentally
  // rebind a shortcut to a bare key with NO modifier at all — e.g. pressing
  // just "L" while editing the "Lock Screen" badge would produce the combo
  // string "L" and get written straight to keybinds.json. hl.bind() then
  // registers that as a truly global bind on the raw "L" keypress, so simply
  // *typing* the letter "l" anywhere (browser, terminal, chat...) would fire
  // Lock Screen. This is the root cause of the "any keypress locks the
  // screen" bug. Standalone keys (media keys, PRINT) are exempt since they
  // are hardware keys that are never combined with a modifier.
  readonly property int requiredModifierMask: Qt.MetaModifier | Qt.ControlModifier | Qt.AltModifier | Qt.ShiftModifier

  function buildComboString(key, modifiers) {
    const name = _keyName(key);
    if (!name) return null;

    if (standaloneKeys.indexOf(name) !== -1) return name;

    // Reject bare keys with zero modifiers held — see requiredModifierMask above.
    if (!(modifiers & requiredModifierMask)) return null;

    const parts = [];
    if (modifiers & Qt.MetaModifier)    parts.push("SUPER");
    if (modifiers & Qt.ControlModifier) parts.push("CTRL");
    if (modifiers & Qt.AltModifier)     parts.push("ALT");
    if (modifiers & Qt.ShiftModifier)   parts.push("SHIFT");
    parts.push(name);
    return parts.join(" + ");
  }

  function buildMouseComboString(button, modifiers) {
    let code = null;
    if (button === Qt.LeftButton) code = 272;
    else if (button === Qt.RightButton) code = 273;
    else if (button === Qt.MiddleButton) code = 274;
    if (code === null) return null;

    // Same guard as buildComboString(): a bare mouse click with no modifier
    // would become a global bind on that raw click, firing on every click
    // anywhere on the desktop.
    if (!(modifiers & requiredModifierMask)) return null;

    const parts = [];
    if (modifiers & Qt.MetaModifier)    parts.push("SUPER");
    if (modifiers & Qt.ControlModifier) parts.push("CTRL");
    if (modifiers & Qt.AltModifier)     parts.push("ALT");
    if (modifiers & Qt.ShiftModifier)   parts.push("SHIFT");
    parts.push("mouse:" + code);
    return parts.join(" + ");
  }

  // --- Display-only formatting -------------------------------------------
  // Maps the raw tokens stored in keybinds.json / used by hl.bind() to
  // friendlier labels for the badge UI. Purely cosmetic — never used for
  // writing or matching keys, so it can't ever desync the actual bind.
  readonly property var _friendlyNames: ({
    "SUPER": "Super", "CTRL": "Ctrl", "ALT": "Alt", "SHIFT": "Shift",
    "RETURN": "Enter", "SPACE": "Space", "TAB": "Tab",
    "BACKSPACE": "Backspace", "DELETE": "Del", "ESCAPE": "Esc", "PRINT": "PrtSc",
    "left": "←", "right": "→", "up": "↑", "down": "↓",
    "mouse:272": "🖱 Click", "mouse:273": "🖱 Right-click", "mouse:274": "🖱 Middle-click",
    "XF86AudioRaiseVolume": "🔊 Vol +", "XF86AudioLowerVolume": "🔉 Vol −",
    "XF86AudioMute": "🔇 Mute", "XF86AudioMicMute": "🎙 Mic Mute",
    "XF86AudioNext": "⏭ Next", "XF86AudioPrev": "⏮ Prev",
    "XF86AudioPlay": "⏯ Play/Pause", "XF86AudioPause": "⏯ Play/Pause",
    "XF86MonBrightnessUp": "☀️ Bright +", "XF86MonBrightnessDown": "🔅 Bright −"
  })

  function friendlyKeyPart(part) {
    return root._friendlyNames[part] !== undefined ? root._friendlyNames[part] : part;
  }

  // Splits a stored combo string ("SUPER + SHIFT + L") into an array of
  // display-ready chip labels (["Super", "Shift", "L"]). Used by
  // KeyCaptureBadge to render each part as its own "keycap".
  function displayParts(keyString) {
    if (!keyString) return [];
    return keyString.split(" + ").map(friendlyKeyPart);
  }
}

