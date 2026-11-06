#!/usr/bin/env bash
# Top 10 tiến trình theo CPU *tức thời* (mẫu 1 giây từ /proc), % của 1 nhân như `top`.
# `ps -o pcpu` chỉ là trung bình từ lúc tiến trình khởi động nên: tiến trình mới sinh (chính `ps`)
# hiện 300%, còn qs hiện số trung bình cũ. Tiến trình chỉ xuất hiện ở 1 trong 2 mẫu (gồm cat/awk/ps
# của script này) bị loại tự động.
export LC_ALL=C
hz=$(getconf CLK_TCK 2>/dev/null || echo 100)
s1=$(cat /proc/[0-9]*/stat 2>/dev/null)
sleep 1
s2=$(cat /proc/[0-9]*/stat 2>/dev/null)
awk -v hz="$hz" '
function parse(line,   o, i, rest, n, f) {
    o = index(line, "(")
    if (!match(line, /\) [^)]*$/) || o == 0) return 0
    i = RSTART
    PID = substr(line, 1, o - 2)
    NAME = substr(line, o + 1, i - o - 1)
    rest = substr(line, i + 2)
    n = split(rest, f, " ")
    T = f[12] + f[13]
    RSS = f[22] * 4 / 1024
    return 1
}
FNR == NR { if (parse($0)) t1[PID] = T; next }
{ if (parse($0) && (PID in t1)) {
    gsub(/["\\]/, "", NAME)
    printf "%d\t%.1f\t%.1f\t%s\n", PID, (T - t1[PID]) / hz * 100, RSS, NAME
  } }
' <(printf '%s\n' "$s1") <(printf '%s\n' "$s2") \
| sort -t$'\t' -k2,2 -nr | head -n 10 \
| awk -F'\t' 'BEGIN{printf "["} {printf "%s{\"pid\":%d,\"name\":\"%s\",\"cpu\":%.1f,\"mem\":%.1f}", (NR>1?",":""), $1, $4, $2, $3} END{print "]"}'
