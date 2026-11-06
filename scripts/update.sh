#!/usr/bin/env bash
# Cartoon Shell updater.
#
#   update.sh check [SHELL_DIR]   -> in ra các dòng key=value (status, local, remote, message)
#   update.sh apply [SHELL_DIR] [REMOTE_SHA]
#                                 -> cập nhật shell, in tiến trình "step=..." rồi "status=done|error"
#
# Cách so sánh phiên bản: dùng mã commit của nhánh mặc định trên GitHub.
#  - Nếu SHELL_DIR là một git clone: so với `git rev-parse HEAD`, cập nhật bằng `git merge --ff-only`.
#  - Nếu không: mã commit đã cài nằm trong file SHELL_DIR/.installed_commit (do script này ghi).
#    Lần đầu chưa có file => ghi nhận bản hiện tại làm mốc (status=baseline), không báo update giả.
set -uo pipefail

REPO="${CARTOON_SHELL_REPO:-lesang2312/cartoon-shell_mod}"
REPO_URL="https://github.com/${REPO}"
CMD="${1:-check}"
SHELL_DIR="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MARK="$SHELL_DIR/.installed_commit"
BACKUP_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cartoon-shell/backups"

out() { printf '%s\n' "$*"; }
fail() { out "error=$1"; out "status=error"; exit 1; }

is_sha() { [[ "$1" =~ ^[0-9a-f]{40}$ ]]; }

remote_sha() {
  local sha=""
  if command -v git >/dev/null 2>&1; then
    sha=$(timeout 20 git ls-remote "$REPO_URL" HEAD 2>/dev/null | cut -f1 | head -n1)
  fi
  if ! is_sha "$sha" && command -v curl >/dev/null 2>&1; then
    sha=$(curl -fsSL -m 15 -H 'Accept: application/vnd.github.sha' \
      "https://api.github.com/repos/${REPO}/commits/HEAD" 2>/dev/null | tr -d '[:space:]')
  fi
  is_sha "$sha" && printf '%s' "$sha"
}

local_sha() {
  local sha=""
  if [ -d "$SHELL_DIR/.git" ] && command -v git >/dev/null 2>&1; then
    sha=$(git -C "$SHELL_DIR" rev-parse HEAD 2>/dev/null)
  elif [ -f "$MARK" ]; then
    sha=$(tr -d '[:space:]' <"$MARK")
  fi
  is_sha "$sha" && printf '%s' "$sha"
}

# Dòng đầu của commit message (không bắt buộc, thất bại thì bỏ qua)
commit_message() {
  command -v curl >/dev/null 2>&1 || return 0
  command -v python3 >/dev/null 2>&1 || return 0
  curl -fsSL -m 8 "https://api.github.com/repos/${REPO}/commits/$1" 2>/dev/null |
    python3 -I -c 'import sys,json
try:
    m=json.load(sys.stdin)["commit"]["message"].strip().splitlines()[0]
    print(m[:160])
except Exception:
    pass' 2>/dev/null
}

do_check() {
  local remote local_
  remote=$(remote_sha) || fail "network"
  local_=$(local_sha) || local_=""

  out "remote=$remote"
  out "local=$local_"

  if [ -z "$local_" ]; then
    # Chưa biết đang ở commit nào (cài từ file zip): ghi mốc để lần sau so sánh
    printf '%s\n' "$remote" >"$MARK" 2>/dev/null
    out "status=baseline"
    return 0
  fi

  if [ "$local_" = "$remote" ]; then
    out "status=uptodate"
    return 0
  fi

  # Git clone đang đi trước remote (remote là tổ tiên của HEAD) => không có gì để cập nhật
  if [ -d "$SHELL_DIR/.git" ] &&
     git -C "$SHELL_DIR" cat-file -e "${remote}^{commit}" 2>/dev/null &&
     git -C "$SHELL_DIR" merge-base --is-ancestor "$remote" "$local_" 2>/dev/null; then
    out "status=uptodate"
    return 0
  fi

  out "message=$(commit_message "$remote" | tr '\r\n' '  ')"
  out "status=available"
}

make_backup() {
  mkdir -p "$BACKUP_DIR" || return 1
  local f="$BACKUP_DIR/cartoon-shell-$(date +%Y%m%d-%H%M%S).tar.gz"
  tar -czf "$f" --exclude=.git -C "$(dirname "$SHELL_DIR")" "$(basename "$SHELL_DIR")" 2>/dev/null || return 1
  out "backup=$f"
  # chỉ giữ 3 bản sao lưu gần nhất
  ls -1t "$BACKUP_DIR"/cartoon-shell-*.tar.gz 2>/dev/null | tail -n +4 | xargs -r rm -f --
}

do_apply() {
  local remote="${3:-}"
  is_sha "$remote" || remote=$(remote_sha) || fail "network"

  # ---- Git clone: chỉ fast-forward, không bao giờ đè thay đổi cục bộ ----
  if [ -d "$SHELL_DIR/.git" ] && command -v git >/dev/null 2>&1; then
    out "step=fetch"
    git -C "$SHELL_DIR" fetch --quiet "$REPO_URL" HEAD 2>&1 || fail "fetch"
    out "step=merge"
    if ! git -C "$SHELL_DIR" merge --ff-only FETCH_HEAD 2>&1; then
      fail "git_conflict"
    fi
    out "status=done"
    return 0
  fi

  # ---- Không phải git: tải tarball đúng commit đã kiểm tra, sao lưu rồi chép đè ----
  command -v curl >/dev/null 2>&1 || fail "no_curl"
  command -v tar  >/dev/null 2>&1 || fail "no_tar"

  local tmp
  tmp=$(mktemp -d) || fail "tmp"
  trap "rm -rf '$tmp'" EXIT

  out "step=backup"
  make_backup || fail "backup"

  out "step=download"
  curl -fsSL -m 180 "https://codeload.github.com/${REPO}/tar.gz/${remote}" -o "$tmp/src.tar.gz" || fail "download"

  out "step=extract"
  mkdir -p "$tmp/src"
  tar -xzf "$tmp/src.tar.gz" -C "$tmp/src" --strip-components=1 || fail "extract"
  [ -f "$tmp/src/shell.qml" ] || fail "invalid_archive"

  out "step=install"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude='.git' "$tmp/src/" "$SHELL_DIR/" || fail "install"
  else
    cp -a "$tmp/src/." "$SHELL_DIR/" || fail "install"
  fi
  printf '%s\n' "$remote" >"$MARK"

  out "status=done"
}

case "$CMD" in
  check) do_check ;;
  apply) do_apply "$@" ;;
  *) fail "usage" ;;
esac
