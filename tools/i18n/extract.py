#!/usr/bin/env python3
"""Trích toàn bộ chuỗi cần dịch ra assets/i18n/source_strings.json (nút "Dịch toàn bộ ngay" dùng file này).

    python3 tools/i18n/extract.py

Nguồn: mọi AutoTranslateService.t("..."), mọi chuỗi chữ cứng chưa bọc (nếu có), prop `name` của
CustomText/ButtonText/HeaderSettings, các chuỗi tiếng Anh dự phòng trong LanguageService/I18nService.
Chạy lại sau khi thêm chuỗi mới để danh mục luôn đầy đủ (không chạy cũng không sao: chuỗi mới vẫn được
dịch lúc hiển thị lần đầu).
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qmlscan as Q

OUT = "assets/i18n/source_strings.json"
found = set()


def add(s):
    s = s.strip() if s else s
    if s and Q.eligible(s):
        found.add(s)


for root in ("modules", "components", "services"):
    for d, _, fs in os.walk(root):
        for fn in fs:
            if not fn.endswith(".qml"):
                continue
            text = open(os.path.join(d, fn), encoding="utf-8").read()
            for m in Q.WRAPPED_RE.finditer(text):
                add(Q.decode(m.group(1)))
            if root == "services":
                continue
            lines = text.splitlines(True)
            for idx, prop, ctx, col, rhs in Q.candidates(lines):
                if prop == "name":
                    for s, e, tok in Q.literal_sites(rhs):
                        v = Q.decode(tok).strip()
                        if v.islower() and " " not in v:
                            continue  # từ thường đơn lẻ ở `name` thường là tên icon (ButtonText dùng font icon)
                        add(v)
                else:
                    for s, e, tok in Q.literal_sites(rhs):
                        add(Q.decode(tok))


def quoted_values(block):
    return [Q.decode(m.group(0)) for m in re.finditer(r'"(?:[^"\\]|\\.)*"', block)]


# Chuỗi Anh dự phòng trong LanguageService (khóa viết không nháy nên mọi chuỗi có nháy đều là giá trị)
ls = open("services/LanguageService.qml", encoding="utf-8").read()
m = re.search(r"readonly property var fallbackTranslations: \(\{(.*?)\n  \}\)", ls, re.S)
if m:
    for v in quoted_values(m.group(1)):
        add(v)

# Bản tiếng Anh trong I18nService
i18 = open("services/I18nService.qml", encoding="utf-8").read()
m = re.search(r"\ben: \{(.*?)\n        \},", i18, re.S)
if m:
    for v in quoted_values(m.group(1)):
        add(v)

out = sorted(found)
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=1)
print("đã ghi %d chuỗi vào %s" % (len(out), OUT))
