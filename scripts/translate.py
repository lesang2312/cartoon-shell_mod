#!/usr/bin/env python3
"""Dịch chuỗi giao diện sang ngôn ngữ đích và lưu vào file cache JSON.

    translate.py LANG CACHE_PATH --json '["Xin chào", "Settings"]'
    translate.py LANG CACHE_PATH --catalog assets/i18n/source_strings.json

- Nguồn dịch: endpoint web của Google Translate (không cần khóa API). Có thể đổi bằng biến môi trường
  CARTOON_TRANSLATE_ENDPOINT (cùng định dạng "client=gtx"), ví dụ để trỏ tới server riêng/kiểm thử.
- Tự nhận ngôn ngữ nguồn (sl=auto) nên chuỗi tiếng Việt/Anh lẫn lộn đều về đúng một ngôn ngữ.
- Cache là {"chuỗi gốc": "bản dịch"}; chuỗi không cần dịch được lưu y nguyên để lần sau khỏi hỏi lại.
- Mạng lỗi thì KHÔNG ghi gì vào cache (để lần sau thử lại) và thoát mã 2.

Đầu ra (mỗi dòng key=value): progress=<xong>/<tổng>, rồi status=done|error và error=<mã>.
"""
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

ENDPOINT = os.environ.get("CARTOON_TRANSLATE_ENDPOINT", "https://translate.googleapis.com/translate_a/single")
WORKERS = 4
MAX_LEN = 300

# mã ngôn ngữ của shell -> mã của Google
LANG_MAP = {"zh": "zh-CN", "he": "iw", "no": "no", "jp": "ja"}

# Tên riêng / phím / thuật ngữ giữ nguyên
KEEP = {
    "ctrl", "alt", "shift", "super", "enter", "esc", "tab", "kitty", "hyprland", "wi-fi", "wifi", "bluetooth",
    "cpu", "ram", "gpu", "cartoon shell", "quickshell", "matugen", "nmcli", "github", "ok", "dns", "ip",
    "tiếng việt", "english", "中文", "日本語", "한국어", "русский", "हिन्दी", "español", "português", "français",
    "deutsch", "italiano", "العربية", "türkçe", "nederlands", "polski", "svenska", "ไทย", "українська", "norsk",
    "dansk", "suomi", "indonesia", "čeština", "ελληνικά", "עברית", "română", "magyar", "български", "slovenčina",
    "liquid glass", "sakura", "gruvbox", "nord", "dracula", "macchiato", "tokyo storm", "one dark", "classic",
}

VI_CHARS = re.compile(r"[ăâđêôơưĂÂĐÊÔƠƯàáạảãằắặẳẵầấậẩẫèéẹẻẽềếệểễìíịỉĩòóọỏõồốộổỗờớợởỡùúụủũừứựửữỳýỵỷỹ]")
LETTER = re.compile(r"[A-Za-zÀ-￿]")
IDENT = re.compile(r"^[a-z0-9_.\-/]*[_./\-0-9][a-z0-9_.\-/]*$")


def wanted(s, lang):
    """True nếu chuỗi đáng gửi đi dịch."""
    if not s or len(s) > MAX_LEN or len(s.strip()) < 2:
        return False
    if not LETTER.search(s):
        return False
    t = s.strip()
    if IDENT.match(t) or "://" in t or t[0] in "/~#@$" or "{" in t or "}" in t or "%1" in t:
        return False
    if t.lower() in KEEP:
        return False
    if lang == "en" and all(ord(c) < 128 for c in s):
        return False  # đã là tiếng Anh (ASCII)
    if lang == "vi" and VI_CHARS.search(s):
        return False  # đã là tiếng Việt
    return True


def load_cache(path):
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except (OSError, ValueError):
        return {}


def save_cache(path, cache):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(cache, f, ensure_ascii=False, indent=0, sort_keys=True)
    os.replace(tmp, path)


class NetworkError(Exception):
    pass


HEADERS = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"}
FALLBACK = "https://clients5.google.com/translate_a/t"  # endpoint dự phòng
BATCH_CHARS = 1200
BATCH_ITEMS = 20


def _post_main(text, target):
    """Dịch một khối văn bản (có thể nhiều dòng) bằng POST để không vướng giới hạn độ dài URL."""
    url = ENDPOINT + "?" + urllib.parse.urlencode({"client": "gtx", "sl": "auto", "tl": target, "dt": "t"})
    body = urllib.parse.urlencode({"q": text}).encode("utf-8")
    req = urllib.request.Request(url, data=body, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=20) as r:
        data = json.loads(r.read().decode("utf-8"))
    return "".join(seg[0] for seg in data[0] if seg and seg[0])


def _get_fallback(text, target):
    q = urllib.parse.urlencode({"client": "dict-chrome-ex", "sl": "auto", "tl": target, "q": text})
    with urllib.request.urlopen(urllib.request.Request(FALLBACK + "?" + q, headers=HEADERS), timeout=20) as r:
        data = json.loads(r.read().decode("utf-8"))
    first = data[0]
    return first[0] if isinstance(first, list) else first


def fetch(text, target):
    """Thử endpoint chính rồi dự phòng, có chờ lùi khi bị giới hạn tần suất."""
    last = None
    fetchers = [_post_main] + ([_get_fallback] if "CARTOON_TRANSLATE_ENDPOINT" not in os.environ else [])
    for attempt in range(4):
        for f in fetchers:
            try:
                return f(text, target)
            except urllib.error.HTTPError as e:
                last = "HTTP %s" % e.code
            except (urllib.error.URLError, TimeoutError, OSError, ValueError, IndexError, TypeError, KeyError) as e:
                last = "%s: %s" % (type(e).__name__, e)
        time.sleep(2.0 * (attempt + 1))
    raise NetworkError(str(last))


def split_ws(text):
    core = text.strip()
    return text[: len(text) - len(text.lstrip())], core, text[len(text.rstrip()):]


def translate_batch(items, target):
    """items: list chuỗi gốc. Trả về {gốc: dịch}. Dịch cả lô bằng 1 request; lệch số dòng thì dịch lẻ."""
    cores = [split_ws(t)[1] for t in items]
    result = {}
    if len(items) > 1 and not any("\n" in c for c in cores):
        out = fetch("\n".join(cores), target)
        lines = [ln.strip() for ln in out.split("\n")]
        if len(lines) == len(items) and all(lines):
            for t, ln in zip(items, lines):
                lead, core, trail = split_ws(t)
                result[t] = lead + ln + trail
            return result
    for t in items:  # lẻ từng chuỗi (lô 1 chuỗi, có xuống dòng, hoặc lệch dòng)
        lead, core, trail = split_ws(t)
        result[t] = lead + ((fetch(core, target) or core).strip()) + trail
    return result


def make_batches(todo):
    batches, cur, size = [], [], 0
    for s in todo:
        if cur and (len(cur) >= BATCH_ITEMS or size + len(s) > BATCH_CHARS):
            batches.append(cur)
            cur, size = [], 0
        cur.append(s)
        size += len(s)
    if cur:
        batches.append(cur)
    return batches


def main(argv):
    if len(argv) < 4:
        print("error=usage\nstatus=error")
        return 1
    lang, cache_path = argv[1], argv[2]
    mode, payload = argv[3], (argv[4] if len(argv) > 4 else "")
    try:
        if mode == "--json":
            strings = json.loads(payload)
        elif mode == "--catalog":
            with open(payload, encoding="utf-8") as f:
                strings = json.load(f)
        else:
            raise ValueError(mode)
        strings = [s for s in strings if isinstance(s, str)]
    except (OSError, ValueError):
        print("error=input\nstatus=error")
        return 1

    target = LANG_MAP.get(lang, lang)
    cache = load_cache(cache_path)
    todo = []
    for s in dict.fromkeys(strings):  # bỏ trùng, giữ thứ tự
        if s in cache:
            continue
        if wanted(s, lang):
            todo.append(s)
        else:
            cache[s] = s  # không cần dịch: nhớ để khỏi hỏi lại

    total, done, failed, bad = len(todo), 0, False, 0
    print("progress=0/%d" % total, flush=True)
    if todo:
        with ThreadPoolExecutor(max_workers=2) as ex:
            futs = {ex.submit(translate_batch, b, target): b for b in make_batches(todo)}
            for fut in as_completed(futs):
                try:
                    cache.update(fut.result())
                    done += len(futs[fut])
                    bad = 0
                    save_cache(cache_path, cache)
                    print("progress=%d/%d" % (done, total), flush=True)
                except NetworkError as e:
                    failed = True
                    bad += 1
                    print("detail=%s" % e, flush=True)
                    if bad >= 3:  # mất mạng/bị chặn hẳn: dừng, lần sau thử lại
                        for f in futs:
                            f.cancel()
                        break
    save_cache(cache_path, cache)
    print("progress=%d/%d" % (done, total), flush=True)
    if failed:
        print("error=network\nstatus=error", flush=True)
        return 2
    print("status=done", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
