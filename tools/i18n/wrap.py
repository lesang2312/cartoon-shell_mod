#!/usr/bin/env python3
"""Bọc mọi chuỗi chữ cứng trong giao diện bằng AutoTranslateService.t("...") — an toàn & chạy lại được.

    python3 tools/i18n/wrap.py [--dry-run]

Chạy ở thư mục gốc shell. Chỉ sửa modules/ và components/. Chuỗi đã bọc thì bỏ qua (idempotent).
Prop `name` của CustomText/ButtonText/HeaderSettings KHÔNG bọc ở nơi gọi vì component tự dịch.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qmlscan as Q

ROOTS = ["modules", "components"]


def process(path, dry):
    with open(path, encoding="utf-8") as f:
        lines = f.readlines()
    cands = Q.candidates(lines)
    changed = 0
    edits = {}
    for idx, prop, ctx, col, rhs in cands:
        if prop == "name":
            continue  # component tự dịch
        sites = Q.literal_sites(rhs)
        if not sites:
            continue
        new = rhs
        for s, e, tok in reversed(sites):
            new = new[:s] + "AutoTranslateService.t(" + tok + ")" + new[e:]
            changed += 1
        edits[idx] = (col, rhs, new)
    if not edits or dry:
        return changed
    for idx, (col, rhs, new) in edits.items():
        line = lines[idx]
        pos = line.index(rhs, col)
        lines[idx] = line[:pos] + new + line[pos + len(rhs):]
    # bảo đảm có import qs.services
    if not any(re.match(r"\s*import\s+qs\.services\b", l) for l in lines):
        last = -1
        for i, l in enumerate(lines):
            s = l.strip()
            if s.startswith("import "):
                last = i
            elif s and not s.startswith("//") and not s.startswith("pragma") and last >= 0:
                break
        lines.insert(last + 1, "import qs.services\n")
    with open(path, "w", encoding="utf-8") as f:
        f.writelines(lines)
    return changed


def main():
    dry = "--dry-run" in sys.argv
    total = files = 0
    for root in ROOTS:
        for d, _, fs in os.walk(root):
            for fn in sorted(fs):
                if fn.endswith(".qml"):
                    n = process(os.path.join(d, fn), dry)
                    if n:
                        files += 1
                        total += n
    print(("[dry-run] " if dry else "") + "bọc %d chuỗi trong %d file" % (total, files))


if __name__ == "__main__":
    main()
