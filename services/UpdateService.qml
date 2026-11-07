pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons

// Kiểm tra / thông báo / áp dụng bản cập nhật Cartoon Shell từ GitHub.
// Logic mạng + file nằm trong scripts/update.sh; service này chỉ điều khiển và giữ trạng thái cho UI.
Singleton {
  id: root

  // idle | checking | uptodate | available | updating | done | error
  property string state: "idle"
  property string localCommit: ""
  property string remoteCommit: ""
  property string remoteBranch: ""
  property string message: ""        // dòng đầu commit message mới nhất (nếu lấy được)
  property string errorCode: ""
  property string stepKey: ""        // step_fetch, step_download, ...
  property string backupPath: ""
  property double lastCheck: 0       // ms epoch

  readonly property bool hasUpdate: state === "available"
  readonly property bool busy: state === "checking" || state === "updating"
  readonly property string script: Directories.scriptsPath + "/update.sh"
  readonly property string shortLocal: localCommit !== "" ? localCommit.substring(0, 7) : ""
  readonly property string shortRemote: remoteCommit !== "" ? remoteCommit.substring(0, 7) : ""

  // VERSION hiển thị bản đang cài và bắt lỗi số phiên bản local bị cũ;
  // commit SHA vẫn là tín hiệu chính để xác định code đã đồng bộ hay chưa.
  property string version: ""
  property string remoteVersion: ""
  FileView {
    id: versionFile
    path: Quickshell.shellPath("VERSION")
    watchChanges: true
    printErrors: false
    // Fallback for the initial UI only. The updater's check result is the
    // authoritative installed version and must not be overwritten by a late
    // FileView load (which caused 1.0.0/1.5.6 display races).
    onLoaded: {
      if (root.version === "")
        root.version = text().trim().split("\n")[0].trim().replace(/^[vV]/, "")
    }
  }

  property bool _manual: false
  property bool _started: false

  function tr(key) { return LanguageService.t("update", key); }

  function init() {
    if (_started) return;
    _started = true;
    startupTimer.start();
  }

  // manual = true: người dùng bấm nút (luôn báo lại kết quả, không phụ thuộc "đã báo rồi")
  function check(manual) {
    if (busy) return;
    root._manual = manual === true;
    root.errorCode = "";
    root.message = "";
    root.remoteCommit = "";
    root.remoteBranch = "";
    root.remoteVersion = "";
    root.state = "checking";
    checkProc.running = true;
  }

  function apply() {
    if (busy || state !== "available") return;
    if (!/^[0-9a-f]{40}$/.test(root.remoteCommit) || root.remoteBranch === "") {
      root.errorCode = "stale_remote";
      root.state = "error";
      return;
    }
    root.errorCode = "";
    root.stepKey = "";
    root.backupPath = "";
    root.state = "updating";
    applyProc.command = ["bash", root.script, "apply", Quickshell.shellDir, root.remoteCommit, root.remoteBranch];
    applyProc.running = true;
  }

  function reloadShell() {
    Quickshell.reload(true);
  }

  function errorText() {
    const k = "err_" + root.errorCode;
    const txt = tr(k);
    return txt === k ? tr("err_generic") : txt;
  }

  // Parse các dòng key=value từ script
  function _parse(text) {
    const r = {};
    for (const line of (text || "").split("\n")) {
      const i = line.indexOf("=");
      if (i > 0) r[line.substring(0, i)] = line.substring(i + 1).trim();
    }
    return r;
  }

  function _notify() {
    // Đi qua NotificationServer của chính shell nên hiện bằng popup có sẵn
    let body = tr("notify_body");
    if (root.message !== "") body = root.message + "\n" + body;
    Quickshell.execDetached(["notify-send", "-a", "Cartoon Shell", "-i", "software-update-available", tr("notify_title"), body]);
  }

  Process {
    id: checkProc
    command: ["bash", root.script, "check", Quickshell.shellDir]
    stdout: StdioCollector {}
    onExited: exitCode => {
      const r = root._parse(stdout.text);
      root.lastCheck = Date.now();
      if (r.local !== undefined) root.localCommit = r.local;
      if (r.remote !== undefined) root.remoteCommit = r.remote;
      if (r.remote_branch !== undefined) root.remoteBranch = r.remote_branch;
      if (r.local_version !== undefined) root.version = r.local_version;
      root.remoteVersion = r.remote_version || "";
      root.message = r.message || "";

      // A non-zero process result is never presented as a successful check,
      // even if partial output was printed before the failure.
      if (exitCode !== 0 || !r.status) {
        root.errorCode = r.error || "network";
        root.state = "error";
      } else if (r.status === "available") {
        root.state = "available";
        // Chỉ báo 1 lần cho mỗi commit; kiểm tra thủ công thì giao diện đã hiện sẵn
        if (!root._manual && Settings.behavior.updateLastNotified !== root.remoteCommit) {
          Settings.behavior.updateLastNotified = root.remoteCommit;
          root._notify();
        }
      } else if (r.status === "uptodate") {
        root.state = "uptodate";
      } else {
        root.errorCode = r.error || "network";
        root.state = "error";
      }
    }
  }

  Process {
    id: applyProc
    stdout: SplitParser {
      onRead: line => {
        const i = line.indexOf("=");
        if (i <= 0) return;
        const k = line.substring(0, i), v = line.substring(i + 1).trim();
        if (k === "step") root.stepKey = "step_" + v;
        else if (k === "backup") root.backupPath = v;
        else if (k === "error") root.errorCode = v;
        else if (k === "status") {
          if (v === "done") root.state = "done";
          else if (v === "error") root.state = "error";
        }
      }
    }
    onExited: exitCode => {
      if (exitCode !== 0 || root.state !== "done") {
        root.errorCode = root.errorCode || "generic";
        root.state = "error";
        return;
      }
      root.localCommit = root.remoteCommit;
      if (root.remoteVersion !== "") root.version = root.remoteVersion;
    }
  }

  // Kiểm tra lần đầu sau khi shell lên (đợi mạng + tránh làm chậm khởi động)
  Timer {
    id: startupTimer
    interval: 20000
    onTriggered: {
      if (Settings.behavior.updateAutoCheck) root.check(false);
      periodicTimer.start();
    }
  }

  Timer {
    id: periodicTimer
    interval: 2 * 60 * 60 * 1000
    repeat: true
    onTriggered: if (Settings.behavior.updateAutoCheck && !root.busy && root.state !== "done") root.check(false)
  }
}
