pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons

// Dịch tự động toàn bộ chữ trên giao diện sang ngôn ngữ đang chọn.
//
//   AutoTranslateService.t("Cài đặt")   -> "Settings" / "Configuración" / ... (nếu đã có bản dịch)
//
// - t() trả về NGAY chuỗi gốc nếu chưa có bản dịch, đồng thời xếp chuỗi vào hàng đợi; vài giây sau
//   scripts/translate.py dịch theo lô, ghi cache ~/.cache/cartoon-shell/i18n/auto_<lang>.json,
//   service nạp lại cache và mọi binding gọi t() tự cập nhật.
// - Tự nhận ngôn ngữ nguồn, nên chuỗi tiếng Việt/Anh lẫn lộn đều về một ngôn ngữ.
// - t() idempotent: chuỗi đã là bản dịch thì trả nguyên (bọc hai lần cũng không sao).
// - Tắt bằng Settings.behavior.autoTranslate (Cài đặt → Chung → Ngôn ngữ & khu vực).
Singleton {
  id: root

  readonly property bool enabled: Settings.behavior.autoTranslate
  readonly property string lang: LanguageService.currentLanguage || "en"

  // idle | translating | error
  property string state: "idle"
  property string errorCode: ""
  property int done: 0
  property int total: 0
  property int cachedCount: 0

  // Bản dịch hiện tại: { "chuỗi gốc": "bản dịch" }, và tập các bản dịch (để t() idempotent)
  property var map: ({})
  property var outs: ({})

  readonly property string cachePath: Directories.shellCache + "/i18n/auto_" + lang + ".json"
  readonly property string script: Directories.scriptsPath + "/translate.py"
  readonly property string catalogPath: Quickshell.shellPath("assets/i18n/source_strings.json")

  // Hàng đợi (object thường, cố ý không phải property để việc ghi không kích hoạt binding)
  property var _pending: ({})
  property var _failed: ({})
  property var _batch: []
  property bool _bulk: false

  readonly property var _viChars: /[ăâđêôơưàáạảãằắặẳẵầấậẩẫèéẹẻẽềếệểễìíịỉĩòóọỏõồốộổỗờớợởỡùúụủũừứựửữỳýỵỷỹ]/i
  readonly property var _letter: /[A-Za-zÀ-￿]/
  readonly property var _ident: /^[a-z0-9_.\-\/]*[_.\-\/0-9][a-z0-9_.\-\/]*$/

  function _worth(s) {
    if (s.length < 2 || s.length > 300) return false;
    if (!_letter.test(s)) return false;
    const t = s.trim();
    if (t.length < 2 || _ident.test(t) || t.indexOf("://") >= 0 || "/~#@$".indexOf(t[0]) >= 0) return false;
    if (t.indexOf("{") >= 0 || t.indexOf("}") >= 0) return false;
    if (lang === "en" && !/[^\x00-\x7F]/.test(s)) return false;
    if (lang === "vi" && _viChars.test(s)) return false;
    return true;
  }

  // ===== API chính =====
  function t(s) {
    if (!enabled || typeof s !== "string" || s === "") return s;
    const v = map[s];
    if (v !== undefined) return v;
    if (outs[s] === true) return s;
    // Khoảng trắng đầu/cuối không tính vào khóa (" hours" và "hours" là một)
    const ws = /^(\s*)([\s\S]*?)(\s*)$/.exec(s);
    if (ws[1] !== "" || ws[3] !== "") return ws[2] === "" ? s : ws[1] + t(ws[2]) + ws[3];
    // "14 minutes" / "Page 3": tách số, chỉ dịch phần chữ để khỏi sinh bản dịch riêng cho từng giá trị
    const lead = /^(\d+(?:[.,]\d+)?\s+)(\D.*)$/.exec(s);
    if (lead) return lead[1] + t(lead[2]);
    const trail = /^(\D*[A-Za-z\u00C0-\uFFFF]\D*?)(\s*:?\s*\d+(?:[.,]\d+)?%?)$/.exec(s);
    if (trail) return t(trail[1]) + trail[2];
    if (!_worth(s) || _failed[s] === true) return s;
    if (_pending[s] === undefined) {
      _pending[s] = true;
      flushTimer.restart();
    }
    return s;
  }

  // Dịch toàn bộ danh mục chuỗi đi kèm (assets/i18n/source_strings.json) một lượt
  function translateAll() {
    if (proc.running) return;
    _bulk = true;
    _run(["--catalog", catalogPath]);
  }

  function clearCache() {
    Quickshell.execDetached(["rm", "-f", cachePath]);
    map = ({});
    outs = ({});
    cachedCount = 0;
    _failed = ({});
  }

  // ===== Nội bộ =====
  property var _bulkDone: ({})

  function _run(args) {
    console.log("[AutoTranslate] chạy", lang, args[0], args[0] === "--json" ? "" : args[1]);
    errorCode = "";
    done = 0;
    total = 0;
    state = "translating";
    proc.command = ["python3", "-I", script, lang, cachePath].concat(args);
    proc.running = true;
  }

  function _flush() {
    if (!enabled || proc.running) return;
    const keys = Object.keys(_pending).slice(0, 150);
    if (keys.length === 0) return;
    for (const k of keys) delete _pending[k];
    _batch = keys;
    // JSON thuần ASCII để truyền qua argv không lo mã hóa
    const json = JSON.stringify(keys).replace(/[\u007f-￿]/g, c => "\\u" + ("0000" + c.charCodeAt(0).toString(16)).slice(-4));
    _bulk = false;
    _run(["--json", json]);
  }

  function _apply(text) {
    let obj = {};
    try {
      obj = JSON.parse(text || "{}") || {};
    } catch (e) {
      obj = {};
    }
    const o = {};
    let n = 0;
    for (const k in obj) {
      o[obj[k]] = true;
      n++;
    }
    outs = o;
    map = obj;
    cachedCount = n;
    // Lần đầu mỗi ngôn ngữ: dịch luôn cả danh mục chuỗi (nền) để giao diện đồng bộ ngay, không đợi từng panel mở ra
    if (enabled && _bulkDone[lang] !== true) {
      _bulkDone[lang] = true;
      bulkTimer.restart();
    }
  }

  onLangChanged: {
    // đổi ngôn ngữ: bỏ bản dịch cũ ngay, nạp cache của ngôn ngữ mới
    map = ({});
    outs = ({});
    cachedCount = 0;
    _pending = ({});
    _failed = ({});
    errorCode = "";
  }

  FileView {
    id: cacheFile
    path: root.cachePath
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root._apply(text())
    onLoadFailed: root._apply("{}")
  }

  Process {
    id: proc
    stderr: SplitParser {
      onRead: line => console.warn("[AutoTranslate] stderr:", line)
    }
    stdout: SplitParser {
      onRead: line => {
        const i = line.indexOf("=");
        if (i <= 0) return;
        if (line.indexOf("progress=") !== 0) console.log("[AutoTranslate]", line);
        const k = line.substring(0, i), v = line.substring(i + 1).trim();
        if (k === "progress") {
          const p = v.split("/");
          root.done = parseInt(p[0]) || 0;
          root.total = parseInt(p[1]) || 0;
        } else if (k === "error") {
          root.errorCode = v;
        }
      }
    }
    onExited: exitCode => {
      console.log("[AutoTranslate] xong, exit =", exitCode);
      cacheFile.reload();
      if (exitCode === 0) {
        root.state = "idle";
        root.errorCode = "";
      } else {
        root.state = "error";
        if (root.errorCode === "") root.errorCode = "python";
        // Đừng hỏi lại ngay: đánh dấu cả lô là lỗi, thử lại sau 10 phút
        for (const k of root._batch) root._failed[k] = true;
        retryTimer.restart();
      }
      root._batch = [];
      if (Object.keys(root._pending).length > 0) flushTimer.restart();
    }
  }

  // Gom các chuỗi mới xuất hiện (mở panel -> hàng chục chuỗi cùng lúc) thành một lần gọi
  Timer {
    id: bulkTimer
    interval: 4000
    onTriggered: {
      if (!root.enabled) return;
      if (proc.running) restart();
      else root.translateAll();
    }
  }

  Timer {
    id: flushTimer
    interval: 1200
    onTriggered: root._flush()
  }

  Timer {
    id: retryTimer
    interval: 10 * 60 * 1000
    onTriggered: {
      for (const k in root._failed) root._pending[k] = true;
      root._failed = ({});
      flushTimer.restart();
    }
  }
}
