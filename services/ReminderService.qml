pragma Singleton
import QtQuick
import Qt.labs.settings
import Quickshell.Io

QtObject {
  id: root

  // Cấu hình số phút báo trước
  readonly property int noticeMinutes: 10

  // reminders lưu dạng: { "yyyy-MM-dd": [ { id, time: "HH:mm", text, soundUrl, notified10m, notified } ] }
  property var reminders: ({})

  // Hàng đợi Báo trước 10p
  property var noticeQueue: []
  readonly property var activeNotice: noticeQueue.length > 0 ? noticeQueue[0] : null

  // Hàng đợi Báo thức chính
  property var alarmQueue: []
  readonly property var activeAlarm: alarmQueue.length > 0 ? alarmQueue[0] : null

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
    root.checkDue();
  }

  function save() {
    store.data = JSON.stringify(root.reminders);
  }

  function dateKey(d) {
    return Qt.formatDate(d, "yyyy-MM-dd");
  }

  function getRemindersForDate(d) {
    const list = root.reminders[dateKey(d)];
    if (!list)
      return [];
    return list.map(function (r) {
      return Object.assign({
        soundUrl: "",
        notified10m: false,
        notified: false
      }, r);
    });
  }

  function hasReminders(d) {
    return getRemindersForDate(d).length > 0;
  }

  function addReminder(d, time, text, soundUrl) {
    const key = dateKey(d);
    const list = root.reminders[key] ? root.reminders[key].slice() : [];
    list.push({
        id: Date.now().toString() + "-" + Math.floor(Math.random() * 10000),
        time: time,
        text: text,
        soundUrl: soundUrl || "",
        notified10m: false,
        notified: false
    });
    list.sort(function (a, b) {
      return a.time < b.time ? -1 : (a.time > b.time ? 1 : 0);
    });
    const updated = Object.assign({}, root.reminders);
    updated[key] = list;
    root.reminders = updated;
    save();
    root.checkDue(); // Kiểm tra ngay lập tức khi vừa thêm lời nhắc
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

  // Quét mỗi 1 giây (1000ms) để báo thức kêu chuẩn từng giây
  property Timer checkTimer: Timer {
    interval: 1000
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

    const nowMinutes = now.getHours() * 60 + now.getMinutes();
    let changed = false;

    const updatedList = list.map(function (r) {
      const parts = r.time.split(":");
      const targetMinutes = parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10);
      const diff = targetMinutes - nowMinutes;

      let updatedR = Object.assign({}, r);

      // 1. Báo trước (khi còn từ 1 phút đến noticeMinutes)
      if (diff > 0 && diff <= root.noticeMinutes && !updatedR.notified10m) {
        root.enqueueNotice(r.id, r.time, r.text);
        updatedR.notified10m = true;
        changed = true;
      }

      // 2. Báo thức chính (khi đã đến giờ diff <= 0)
      if (diff <= 0 && !updatedR.notified) {
        if (diff >= -5) { // Quá giờ dưới 5 phút vẫn cho kêu
          root.enqueueAlarm(r.id, r.time, r.text, r.soundUrl);
        }
        updatedR.notified10m = true;
        updatedR.notified = true;
        changed = true;
      }

      return updatedR;
    });

    if (changed) {
      const updated = Object.assign({}, root.reminders);
      updated[key] = updatedList;
      root.reminders = updated;
      save();
    }
  }

  function enqueueNotice(id, time, text) {
    root.noticeQueue = root.noticeQueue.concat([{
        id: id,
        time: time,
        text: text
    }]);
  }

  function dismissNotice() {
    if (root.noticeQueue.length === 0)
      return;
    root.noticeQueue = root.noticeQueue.slice(1);
  }

  property Process soundProc: Process {}

  function enqueueAlarm(id, time, text, soundUrl) {
    const wasEmpty = root.alarmQueue.length === 0;
    root.alarmQueue = root.alarmQueue.concat([{
        id: id,
        time: time,
        text: text,
        soundUrl: soundUrl || ""
    }]);
    if (wasEmpty)
      root.playSound(soundUrl);
  }

  function playSound(soundUrl) {
    if (soundProc.running)
      soundProc.running = false;

    const path = (soundUrl && soundUrl.length > 0) ? soundUrl.toString().replace(/^file:\/\//, "") : "";
    const playCmd = path.length > 0 ? "p=\"$1\"; if command -v mpv >/dev/null 2>&1; then exec mpv --no-video --really-quiet -- \"$p\"; elif command -v ffplay >/dev/null 2>&1; then exec ffplay -nodisp -autoexit -loglevel quiet -- \"$p\"; else exec paplay -- \"$p\"; fi" : "if command -v canberra-gtk-play >/dev/null 2>&1; then exec canberra-gtk-play -i alarm-clock-elapsed; else exec paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga; fi";

    soundProc.command = ["sh", "-c", playCmd, "_", path];
    soundProc.running = true;
  }

  function dismissAlarm() {
    if (soundProc.running)
      soundProc.running = false;
    if (root.alarmQueue.length === 0)
      return;
    const rest = root.alarmQueue.slice(1);
    root.alarmQueue = rest;
    if (rest.length > 0)
      root.playSound(rest[0].soundUrl);
  }
}