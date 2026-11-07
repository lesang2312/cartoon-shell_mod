"""Quét file QML để tìm các chuỗi chữ hiển thị cần dịch (dùng chung cho wrap.py và extract.py).

Quy tắc an toàn: chỉ xét dòng dạng `thuộc_tính: biểu_thức` nằm trực tiếp trong một đối tượng QML
(hoặc literal object cho nhóm thuộc tính nhãn), và chỉ đụng tới chuỗi nằm ở cấp 0 của biểu thức,
đứng một mình / sau `?` `:` `+` `||` `??` — không bao giờ đụng vào đối số hàm, phép so sánh, tên icon.
"""
import re

# thuộc tính chứa chữ hiển thị
TEXT_PROPS = {"text", "title", "desc", "description", "subtitle", "label", "placeholderText",
              "confirmText", "hint", "tooltip", "header", "emptyText", "statusText"}
# trong literal object chỉ nhận các nhãn rõ ràng (không nhận `name` vì hay là id)
OBJ_PROPS = {"label", "title", "text", "desc", "description", "subtitle", "hint", "tooltip"}
# kiểu mà thuộc tính text/title... KHÔNG phải chữ hiển thị
EXCLUDE_TYPES = {"IconText", "IconImage", "TextInput", "TextField", "TextEdit", "TextArea", "Image",
                 "AnimatedImage", "ListElement", "Process", "FileView", "Timer", "Connections", "Variants",
                 "Shortcut", "Instantiator", "JsonObject", "JsonAdapter", "CircularUsage", "KeyCaptureBadge",
                 "ButtonIconText", "Settings"}
# kiểu mà `name` là chữ hiển thị (bản thân component đã tự dịch bằng AutoTranslateService.t)
NAME_TEXT_TYPES = {"CustomText", "ButtonText", "HeaderSettings"}

LETTER = re.compile(r"[A-Za-zÀ-￿]")
IDENT = re.compile(r"^[a-z0-9_.\-/]*[_./\-0-9][a-z0-9_.\-/]*$")
LINE_RE = re.compile(r"^(\s*)([A-Za-z_]\w*)\s*:\s*(.*?)\s*$")
WRAPPED_RE = re.compile(r'AutoTranslateService\.t\(\s*("(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\')\s*\)')


def eligible(content):
    """content: nội dung chuỗi đã bỏ dấu nháy (còn escape)."""
    s = content
    if len(s.strip()) < 2 or len(s) > 300 or not LETTER.search(s):
        return False
    t = s.strip()
    if IDENT.match(t) or "://" in t or t[0] in "/~#@$" or "{" in t or "}" in t:
        return False
    return True


def decode(token):
    """Token chuỗi QML (có nháy) -> giá trị Python."""
    q, body = token[0], token[1:-1]
    body = re.sub(r"\\(.)", lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), body)
    return body


def blank_strings(line):
    """Thay nội dung chuỗi bằng khoảng trắng, cắt comment `//` — để đếm ngoặc/nhận kiểu."""
    out, i, n, q = [], 0, len(line), None
    while i < n:
        c = line[i]
        if q:
            if c == "\\":
                out.append("  ")
                i += 2
                continue
            if c == q:
                q = None
                out.append(c)
            else:
                out.append(" ")
        else:
            if c in "\"'`":
                q = c
                out.append(c)
            elif c == "/" and i + 1 < n and line[i + 1] == "/":
                break
            else:
                out.append(c)
        i += 1
    return "".join(out)


def owner_of(before):
    b = before.strip()
    if b == "" or b.endswith(("(", "[", ",", "=", "?", "||", "&&", "+")):
        return "obj"
    if b.endswith((":", "=>", ")")):
        return "js"
    m = re.search(r"([A-Za-z_][\w.]*)(?:\s+on\s+[\w.]+)?\s*$", b)
    if not m:
        return "js"
    name = m.group(1)
    last = name.split(".")[-1]
    if last[:1].isupper():
        return last
    if name in ("else", "try", "finally", "do"):
        return "js"
    return "group"


def literal_sites(rhs):
    """Các chuỗi ở cấp 0 của rhs đủ điều kiện bọc: [(start, end, token)]."""
    sites, depth, i, n = [], 0, 0, len(rhs)
    while i < n:
        c = rhs[i]
        if c in "\"'":
            j = i + 1
            while j < n and rhs[j] != c:
                j += 2 if rhs[j] == "\\" else 1
            tok = rhs[i:j + 1]
            if depth == 0 and j < n:
                prev = rhs[:i].rstrip()
                nxt = rhs[j + 1:].lstrip()
                prev_ok = prev == "" or prev.endswith(("?", ":", "+", "||", "??")) and not prev.endswith(("++",))
                next_ok = nxt == "" or nxt[0] in ":+;" or nxt.startswith("//")
                if prev_ok and next_ok and eligible(tok[1:-1]):
                    sites.append((i, j + 1, tok))
            i = j + 1
            continue
        if c == "`":
            j = rhs.find("`", i + 1)
            i = (j if j >= 0 else n) + 1
            continue
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        i += 1
    return sites


def candidates(lines):
    """Duyệt file, trả về [(line_idx, prop, ctx, rhs_col, rhs)] cho các dòng thuộc tính chữ."""
    stack, out, in_block = [], [], False
    for idx, raw in enumerate(lines):
        line = raw.rstrip("\n")
        if in_block:
            if "*/" in line:
                in_block = False
                line = line.split("*/", 1)[1]
            else:
                continue
        if "/*" in line and "*/" not in line.split("/*", 1)[1]:
            in_block = True
            line = line.split("/*", 1)[0]
        code = blank_strings(line)

        m = LINE_RE.match(line)
        if m and stack:
            prop, rhs = m.group(2), m.group(3)
            rhs_clean = rhs.rstrip(",").rstrip()
            top = stack[-1]
            ok_type = top[:1].isupper() and top not in EXCLUDE_TYPES
            ctx = None
            if ok_type and (prop in TEXT_PROPS or (prop == "name" and top in NAME_TEXT_TYPES)):
                ctx = top
            elif top == "obj" and prop in OBJ_PROPS:
                ctx = "obj"
            if ctx and rhs_clean and not rhs_clean[0] in "{[" and not rhs_clean.endswith(("?", "+", "(", "{", "[", ":", "||", "&&")):
                col = line.index(rhs, m.end(2))
                out.append((idx, prop, ctx, col, rhs_clean))

        seg = 0
        for k, ch in enumerate(code):
            if ch == "{":
                stack.append(owner_of(code[seg:k]))
                seg = k + 1
            elif ch == "}":
                if stack:
                    stack.pop()
                seg = k + 1
            elif ch == ";":
                seg = k + 1
    return out
