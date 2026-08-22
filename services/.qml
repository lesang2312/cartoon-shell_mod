pragma Singleton
import QtQuick
import Qt.labs.settings
import Quickshell.Io

QtObject {
  id: root

  // reminders lưu dạng: { "yyyy-MM-dd": [ { id, time: "HH:mm", text, notified } ] }
  property var reminders: ({})

  // --- Lưu trữ bền vững (không cần tự quản lý file JSON) ---
  property Settings store: Settings {
    category: "cartoon_shell_reminders"
    property string data: "{}"
  }

  Component.onCompleted: {
    try {
      root.reminders = JSON.parse(store.data) || {};
    } catch (e) {
      root.reminders = {};
    }
  }

  function save() {
    store.data = JSON.stringify(root.reminders);
  }

  function dateKey(d) {
    return Qt.formatDate(d, "yyyy-MM-dd");
  }

  function getRemindersForDate(d) {
    const list = root.reminders[dateKey(d)];
    return list ? list : [];
  }

  function hasReminders(d) {
    return getRemindersForDate(d).length > 0;
  }

  function addReminder(d, time, text) {
    const key = dateKey(d);
    const list = root.reminders[key] ? root.reminders[key].slice() : [];
    list.push({
        id: Date.now().toString() + "-" + Math.floor(Math.random() * 10000),
        time: time,
        text: text,
        notified: false
    });
    // Sắp xếp theo giờ cho dễ nhìn
    list.sort(function (a, b) {
      return a.time < b.time ? -1 : (a.time > b.time ? 1 : 0);
    });
    const updated = Object.assign({}, root.reminders);
    updated[key] = list;
    root.reminders = updated;
    save();
  }

  function removeReminder(d, reminderId) {
    const key = dateKey(d);
    if (!root.reminders[key])
    return;
    const updated = Object.assign({}, root.reminders);
    updated[key] = root.reminders[key].filter(function (r) {
      return r.id !== reminderId;
    });
    if (updated[key].length === 0)
    delete updated[key];
    root.reminders = updated;
    save();
  }

  // --- Kiểm tra định kỳ và bắn thông báo ---
  property Timer checkTimer: Timer {
    interval: 30000 // 30s
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.checkDue()
  }

  function checkDue() {
    const now = new Date();
    const key = dateKey(now);
    const list = root.reminders[key];
    if (!list || list.length === 0)
    return;

    const nowHM = Qt.formatTime(now, "HH:mm");
    let changed = false;
    const updatedList = list.map(function (r) {
      if (!r.notified && r.time <= nowHM) {
        root.fireNotification(r.time, r.text);
        changed = true;
        return Object.assign({}, r, {
            notified: true
        });
      }
      return r;
    });

    if (changed) {
      const updated = Object.assign({}, root.reminders);
      updated[key] = updatedList;
      root.reminders = updated;
      save();
    }
  }

  property Process notifyProc: Process {}

  function fireNotification(time, text) {
    notifyProc.command = ["notify-send", "-a", "Lịch", "-i", "appointment-soon", "Lời nhắc " + time, text];
    notifyProc.running = true;
  }
}
