#!/usr/bin/env bash
# Cartoon Shell updater.
#
#   update.sh check [SHELL_DIR]
#   update.sh apply [SHELL_DIR] [REMOTE_SHA] [REMOTE_BRANCH]
#
# The commit SHA is the primary source of truth. VERSION is read from the
# installed files for display and as a fallback signal for stale installs.
set -uo pipefail

REPO="${CARTOON_SHELL_REPO:-lesang2312/cartoon-shell_mod}"
REPO_URL="https://github.com/${REPO}"
API_URL="https://api.github.com/repos/${REPO}"
RAW_URL="https://raw.githubusercontent.com/${REPO}"
CMD="${1:-check}"
SHELL_DIR="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MARK="$SHELL_DIR/.installed_commit"
BACKUP_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cartoon-shell/backups"
UPDATE_TMP_DIR=""

out() { printf '%s\n' "$*"; }
fail() { out "error=$1"; out "status=error"; exit 1; }
is_sha() { [[ "${1:-}" =~ ^[0-9a-f]{40}$ ]]; }
is_branch() { [[ "${1:-}" =~ ^[A-Za-z0-9._/-]+$ && "$1" != *..* && "$1" != /* && "$1" != */ ]]; }
is_git_checkout() {
  command -v git >/dev/null 2>&1 && git -C "$SHELL_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

# Resolve default branch and SHA as one snapshot. Do not hard-code main/master.
remote_info() {
  local listing branch sha repo_json encoded_branch

  if command -v git >/dev/null 2>&1; then
    listing=$(timeout 20 git ls-remote --symref "$REPO_URL" HEAD 2>/dev/null || true)
    branch=$(printf '%s\n' "$listing" | awk '$1 == "ref:" && $3 == "HEAD" { sub(/^refs\/heads\//, "", $2); print $2; exit }')
    sha=$(printf '%s\n' "$listing" | awk '$2 == "HEAD" && $1 ~ /^[0-9a-f]{40}$/ { print $1; exit }')
    if is_branch "$branch" && is_sha "$sha"; then
      printf '%s\n%s\n' "$branch" "$sha"
      return 0
    fi
  fi

  command -v curl >/dev/null 2>&1 || return 1
  repo_json=$(curl -fsSL -m 15 -H 'Accept: application/vnd.github+json' \
    -H 'X-GitHub-Api-Version: 2022-11-28' "$API_URL" 2>/dev/null) || return 1
  if command -v python3 >/dev/null 2>&1; then
    branch=$(printf '%s' "$repo_json" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("default_branch", ""))' 2>/dev/null || true)
  else
    branch=$(printf '%s' "$repo_json" | sed -n 's/.*"default_branch"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
  fi
  is_branch "$branch" || return 1
  encoded_branch=$(printf '%s' "$branch" | sed 's|/|%2F|g')
  sha=$(curl -fsSL -m 15 -H 'Accept: application/vnd.github.sha' \
    -H 'X-GitHub-Api-Version: 2022-11-28' "$API_URL/commits/$encoded_branch" 2>/dev/null | tr -d '[:space:]') || return 1
  is_sha "$sha" || return 1
  printf '%s\n%s\n' "$branch" "$sha"
}

assert_remote_snapshot() {
  local expected_branch="$1" expected_sha="$2" info current_branch current_sha
  info=$(remote_info) || fail "network"
  current_branch=$(printf '%s\n' "$info" | sed -n '1p')
  current_sha=$(printf '%s\n' "$info" | sed -n '2p')
  [ "$current_branch" = "$expected_branch" ] && [ "$current_sha" = "$expected_sha" ] || fail "stale_remote"
}

local_sha() {
  local sha=""
  if is_git_checkout; then
    sha=$(git -C "$SHELL_DIR" rev-parse HEAD 2>/dev/null || true)
  elif [ -f "$MARK" ]; then
    sha=$(tr -d '[:space:]' <"$MARK")
  fi
  is_sha "$sha" && printf '%s' "$sha"
}

read_version_file() {
  local file="$1" value
  [ -f "$file" ] || return 0
  value=$(head -n1 "$file" | tr -d ' \r\n\t' | sed 's/^[vV]//')
  [[ "$value" =~ ^[0-9][A-Za-z0-9._+-]*$ ]] && printf '%s' "$value"
}

local_version() {
  # Report what is actually installed on disk. Reading VERSION from Git HEAD
  # can mask a stale/modified installed VERSION file and disagree with the UI.
  local value=""
  value=$(read_version_file "$SHELL_DIR/VERSION")
  [ -n "$value" ] || value=$(read_version_file "$SHELL_DIR/version.txt")
  printf '%s' "$value"
}

version_is_newer() {
  local candidate="${1:-}" current="${2:-}" highest
  [[ "$candidate" =~ ^[0-9][A-Za-z0-9._+-]*$ && "$current" =~ ^[0-9][A-Za-z0-9._+-]*$ ]] || return 1
  [ "$candidate" != "$current" ] || return 1
  command -v sort >/dev/null 2>&1 || return 1
  highest=$(printf '%s\n%s\n' "$candidate" "$current" | sort -V | tail -n1)
  [ "$highest" = "$candidate" ]
}

# Read the version from the exact commit SHA being checked, not from the
# moving branch name (the branch may advance between the check and this read).
remote_version() {
  local sha="$1" file tmp code value
  is_sha "$sha" || return 1
  command -v curl >/dev/null 2>&1 || return 1
  tmp=$(mktemp) || return 1
  for file in VERSION version.txt; do
    code=$(curl -sS -L -m 15 -o "$tmp" -w '%{http_code}' \
      "$RAW_URL/$sha/$file" 2>/dev/null) || code="000"
    if [ "$code" = "200" ]; then
      value=$(head -n1 "$tmp" | tr -d ' \r\n\t' | sed 's/^[vV]//')
      rm -f "$tmp"
      [[ "$value" =~ ^[0-9][A-Za-z0-9._+-]*$ ]] || return 1
      printf '%s' "$value"
      return 0
    fi
    [ "$code" = "404" ] || { rm -f "$tmp"; return 1; }
  done
  rm -f "$tmp"
  return 3
}

commit_message() {
  command -v curl >/dev/null 2>&1 || return 0
  command -v python3 >/dev/null 2>&1 || return 0
  curl -fsSL -m 8 "$API_URL/commits/$1" 2>/dev/null |
    python3 -I -c 'import sys,json
try:
    m=json.load(sys.stdin)["commit"]["message"].strip().splitlines()[0]
    print(m[:160].replace("\\r", " ").replace("\\n", " "))
except Exception:
    pass' 2>/dev/null
}

do_check() {
  local info remote_branch remote local_ lv rv fetched
  info=$(remote_info) || fail "network"
  remote_branch=$(printf '%s\n' "$info" | sed -n '1p')
  remote=$(printf '%s\n' "$info" | sed -n '2p')
  is_branch "$remote_branch" && is_sha "$remote" || fail "network"

  local_=$(local_sha) || local_=""
  lv=$(local_version)
  rv=$(remote_version "$remote" 2>/dev/null) || rv=""

  out "local_version=$lv"
  out "remote_version=$rv"
  out "remote_branch=$remote_branch"
  out "remote=$remote"
  out "local=$local_"

  if [ -z "$local_" ]; then
    # An unknown install must never be silently declared current. A verified
    # SHA is supplied so the apply step can install exactly this snapshot.
    out "message=Installed revision unknown; reinstalling the latest verified commit is recommended."
    out "status=available"
    return 0
  fi

  # Version is a second safety signal. This catches stale VERSION files even
  # when a packaged .git directory incorrectly makes HEAD look current.
  if [ -n "$rv" ] && { [ -z "$lv" ] || version_is_newer "$rv" "$lv"; }; then
    out "message=$(commit_message "$remote" | tr '\r\n' '  ')"
    out "status=available"
    return 0
  fi

  if [ "$local_" = "$remote" ]; then
    # When both commits are identical, require a successful remote VERSION
    # read before claiming "up to date" if this installation has a version.
    # Otherwise a blocked/missing raw VERSION endpoint could hide a mismatch.
    if [ -n "$lv" ] && [ -z "$rv" ]; then fail "network"; fi
    out "status=uptodate"
    return 0
  fi

  if is_git_checkout; then
    # Fetch only the resolved default branch; then ensure it is still the SHA
    # reported above. A moving branch causes a retry, not a false result.
    git -C "$SHELL_DIR" fetch --quiet --no-tags "$REPO_URL" "refs/heads/$remote_branch" 2>/dev/null || fail "network"
    fetched=$(git -C "$SHELL_DIR" rev-parse FETCH_HEAD 2>/dev/null || true)
    [ "$fetched" = "$remote" ] || fail "stale_remote"

    # A local checkout that already contains the remote commit is not behind.
    if git -C "$SHELL_DIR" merge-base --is-ancestor "$remote" "$local_" 2>/dev/null; then
      out "status=uptodate"
      return 0
    fi
  fi

  out "message=$(commit_message "$remote" | tr '\r\n' '  ')"
  out "status=available"
}

make_backup() {
  mkdir -p "$BACKUP_DIR" || return 1
  local f="$BACKUP_DIR/cartoon-shell-$(date +%Y%m%d-%H%M%S).tar.gz"
  tar -czf "$f" --exclude=.git -C "$(dirname "$SHELL_DIR")" "$(basename "$SHELL_DIR")" 2>/dev/null || return 1
  out "backup=$f"
  ls -1t "$BACKUP_DIR"/cartoon-shell-*.tar.gz 2>/dev/null | tail -n +4 | xargs -r rm -f --
}

do_apply() {
  local remote="${3:-}" remote_branch="${4:-}" info current fetched tmp

  # When invoked manually with no pin, resolve one. When a SHA was supplied,
  # require its matching branch instead of silently switching to a new HEAD.
  if [ -z "$remote" ] && [ -z "$remote_branch" ]; then
    info=$(remote_info) || fail "network"
    remote_branch=$(printf '%s\n' "$info" | sed -n '1p')
    remote=$(printf '%s\n' "$info" | sed -n '2p')
  elif ! is_sha "$remote" || ! is_branch "$remote_branch"; then
    fail "usage"
  fi
  is_sha "$remote" && is_branch "$remote_branch" || fail "network"
  assert_remote_snapshot "$remote_branch" "$remote"

  if is_git_checkout; then
    # Never silently accept a dirty working tree, even when HEAD already
    # equals the remote SHA (for example, a locally edited VERSION file).
    if [ -n "$(git -C "$SHELL_DIR" status --porcelain 2>/dev/null)" ]; then
      fail "local_changes"
    fi

    out "step=fetch"
    git -C "$SHELL_DIR" fetch --quiet --no-tags "$REPO_URL" "refs/heads/$remote_branch" 2>&1 || fail "fetch"
    fetched=$(git -C "$SHELL_DIR" rev-parse FETCH_HEAD 2>/dev/null || true)
    [ "$fetched" = "$remote" ] || fail "stale_remote"

    current=$(git -C "$SHELL_DIR" rev-parse HEAD 2>/dev/null || true)
    [ "$current" = "$remote" ] && { out "status=done"; return 0; }

    # Clean Git installs update by fast-forward only.
    out "step=merge"
    git -C "$SHELL_DIR" merge --ff-only --no-edit FETCH_HEAD 2>&1 || fail "git_conflict"
    [ "$(git -C "$SHELL_DIR" rev-parse HEAD 2>/dev/null)" = "$remote" ] || fail "stale_remote"
    out "status=done"
    return 0
  fi

  # Non-Git install: backup, then download the exact checked SHA.
  command -v curl >/dev/null 2>&1 || fail "no_curl"
  command -v tar >/dev/null 2>&1 || fail "no_tar"
  UPDATE_TMP_DIR=$(mktemp -d) || fail "tmp"
  tmp="$UPDATE_TMP_DIR"
  trap 'if [ -n "$UPDATE_TMP_DIR" ]; then rm -rf -- "$UPDATE_TMP_DIR"; fi' EXIT

  out "step=backup"
  make_backup || fail "backup"

  out "step=download"
  curl -fsSL -m 180 "https://codeload.github.com/${REPO}/tar.gz/${remote}" -o "$tmp/src.tar.gz" || fail "download"

  out "step=extract"
  mkdir -p "$tmp/src"
  tar -xzf "$tmp/src.tar.gz" -C "$tmp/src" --strip-components=1 || fail "extract"
  [ -f "$tmp/src/shell.qml" ] || fail "invalid_archive"
  # Recheck after the download so a branch move during transfer cannot install
  # an old snapshot while the UI still claims it is the latest one.
  assert_remote_snapshot "$remote_branch" "$remote"

  out "step=install"
  if command -v rsync >/dev/null 2>&1; then
    # --checksum is intentional: archive extraction and existing files can
    # share size + second-level mtime while their contents differ.
    rsync -a --checksum --exclude='.git' "$tmp/src/" "$SHELL_DIR/" || fail "install"
  else
    cp -a "$tmp/src/." "$SHELL_DIR/" || fail "install"
  fi
  printf '%s\n' "$remote" >"$MARK" || fail "install"
  out "status=done"
}

case "$CMD" in
  check) do_check ;;
  apply) do_apply "$@" ;;
  *) fail "usage" ;;
esac
