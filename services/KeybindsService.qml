pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property var categories: kbFile.adapter ? kbFile.adapter.categories : []
  readonly property string mainMod: kbFile.adapter ? kbFile.adapter.mainMod : "SUPER"

  signal shortcutUpdated(string categoryId, string shortcutId, string newKey)
  signal shortcutRemoved(string categoryId, string shortcutId)
  signal shortcutAdded(string categoryId, string shortcutId)
  signal conflictDetected(string existingCategoryId, string existingShortcutId, string existingKey)
  signal reloadTriggered()

  property string activeEditId: ""

  function editIdFor(categoryId, shortcutId) {
    return categoryId + "/" + shortcutId;
  }

  function requestEdit(categoryId, shortcutId) {
    root.activeEditId = root.editIdFor(categoryId, shortcutId);
    activeEditTimeout.restart();
  }

  function cancelEdit() {
    root.activeEditId = "";
    activeEditTimeout.stop();
  }

  Timer {
    id: activeEditTimeout
    interval: 15000
    onTriggered: root.cancelEdit()
  }

  FileView {
    id: kbFile
    path: Quickshell.env("HOME") + "/.config/quickshell/cartoon-shell/data/keybinds.json"
    watchChanges: true
    onFileChanged: reload()

    adapter: JsonAdapter {
      property string mainMod: "SUPER"
      property var categories: []
    }
  }

  Process {
    id: hyprReloadProc
    command: ["hyprctl", "reload"]
    onExited: root.reloadTriggered()
  }

  function _triggerReload() {
    hyprReloadProc.running = true;
  }

  function findConflict(newKey, ignoreCategoryId, ignoreShortcutId) {
    for (const cat of root.categories) {
      for (const sc of cat.shortcuts) {
        if (sc.key === newKey && !(cat.id === ignoreCategoryId && sc.id === ignoreShortcutId)) {
          return { categoryId: cat.id, shortcutId: sc.id, action: sc.action };
        }
      }
    }
    return null;
  }

  function _clone(obj) {
    const copy = {};
    for (const k in obj) copy[k] = obj[k];
    return copy;
  }

  function updateShortcut(categoryId, shortcutId, newKey, allowOverwrite) {
    const conflict = findConflict(newKey, categoryId, shortcutId);
    if (conflict && !allowOverwrite) {
      root.conflictDetected(conflict.categoryId, conflict.shortcutId, newKey);
      return false;
    }

    const oldCats = kbFile.adapter.categories;
    let found = false;

    const newCats = oldCats.map((cat) => {
      if (cat.id !== categoryId) return cat;
      const newShortcuts = cat.shortcuts.map((sc) => {
        if (sc.id !== shortcutId) return sc;
        if (sc.editable === false) return sc;
        found = true;
        const clonedSc = _clone(sc);
        clonedSc.key = newKey;
        return clonedSc;
      });
      const clonedCat = _clone(cat);
      clonedCat.shortcuts = newShortcuts;
      return clonedCat;
    });

    if (!found) return false;

    kbFile.adapter.categories = newCats;
    kbFile.writeAdapter();
    kbFile.reload();
    root._triggerReload();
    root.activeEditId = "";
    root.shortcutUpdated(categoryId, shortcutId, newKey);
    return true;
  }
  
  function removeShortcut(categoryId, shortcutId) {
    const oldCats = kbFile.adapter.categories;
    let found = false;

    const newCats = oldCats.map((cat) => {
      if (cat.id !== categoryId) return cat;
      const newShortcuts = cat.shortcuts.filter((sc) => {
        if (sc.id !== shortcutId) return true;
        if (sc.locked === true) return true; // không cho xoá shortcut bị khoá
        found = true;
        return false;
      });
      const clonedCat = _clone(cat);
      clonedCat.shortcuts = newShortcuts;
      return clonedCat;
    });

    if (!found) return false;

    kbFile.adapter.categories = newCats;
    kbFile.writeAdapter();
    kbFile.reload();
    root._triggerReload();
    root.shortcutRemoved(categoryId, shortcutId);
    return true;
  }

  function addNewShortcut(categoryId, shortcutId, key, action, command) {
    const oldCats = kbFile.adapter.categories;
    let found = false;

    const newCats = oldCats.map((cat) => {
      if (cat.id !== categoryId) return cat;
      found = true;
      const clonedCat = _clone(cat);
      const newShortcuts = [];
      for (let i = 0; i < cat.shortcuts.length; i++) {
        newShortcuts.push(cat.shortcuts[i]);
      }
      newShortcuts.push({
        id: shortcutId,
        key: key,
        action: action,
        type: "exec_cmd",
        args: command ? [command] : [],
        locked: false
      });
      clonedCat.shortcuts = newShortcuts;
      return clonedCat;
    });

    if (!found) return false;

    kbFile.adapter.categories = newCats;
    kbFile.writeAdapter();
    kbFile.reload();
    root._triggerReload();
    root.shortcutAdded(categoryId, shortcutId);
    return true;
  }
}