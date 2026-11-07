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
REPO_URL="${CARTOON_SHELL_GIT_URL:-https://github.com/${REPO}}"
API_URL="https://api.github.com/repos/${REPO}"
RAW_URL="https://raw.githubusercontent.com/${REPO}"
CMD="${1:-check}"
SHELL_DIR="${2:-${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/cartoon-shell}"
SHELL_DIR="${SHELL_DIR%/}"
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
  local f="$BACKUP_DIR/cartoon-shell-$(date +%Y%m%d-%H%M%S)-$$.tar.gz"
  tar -czf "$f" -C "$(dirname "$SHELL_DIR")" "$(basename "$SHELL_DIR")" 2>/dev/null || return 1
  out "backup=$f"
  ls -1t "$BACKUP_DIR"/cartoon-shell-*.tar.gz 2>/dev/null | tail -n +4 | xargs -r rm -f --
}

restore_previous_install() {
  local reason="$1" rollback_dir="${2:-}" had_old="${3:-0}"
  out "step=restore"
  rm -rf -- "$SHELL_DIR" 2>/dev/null || true
  if [ "$had_old" = "1" ] && [ -n "$rollback_dir" ] && [ -d "$rollback_dir/old" ]; then
    if ! mv -- "$rollback_dir/old" "$SHELL_DIR"; then
      out "error=restore_failed"
      out "status=error"
      out "message=The new clone failed and the previous folder could not be restored automatically. The backup is preserved at $rollback_dir/old."
      exit 1
    fi
  fi
  [ -z "$rollback_dir" ] || rm -rf -- "$rollback_dir" 2>/dev/null || true
  fail "$reason"
}

do_apply() {
  local remote="${3:-}" remote_branch="${4:-}" info current_sha current_branch actual
  local parent base rollback_dir="" had_old=0

  # The installed shell is replaced by a fresh clone of the exact default
  # branch snapshot that was shown by the preceding check.
  if [ -z "$remote" ] && [ -z "$remote_branch" ]; then
    info=$(remote_info) || fail "network"
    remote_branch=$(printf '%s\n' "$info" | sed -n '1p')
    remote=$(printf '%s\n' "$info" | sed -n '2p')
  elif ! is_sha "$remote" || ! is_branch "$remote_branch"; then
    fail "usage"
  fi
  is_sha "$remote" && is_branch "$remote_branch" || fail "network"

  # Never allow an updater argument to remove an unrelated directory.
  case "$SHELL_DIR" in
    /*/cartoon-shell) ;;
    *) fail "unsafe_target" ;;
  esac
  [ ! -L "$SHELL_DIR" ] || fail "unsafe_target"

  command -v git >/dev/null 2>&1 || fail "no_git"
  command -v tar >/dev/null 2>&1 || fail "no_tar"
  parent=$(dirname -- "$SHELL_DIR")
  base=$(basename -- "$SHELL_DIR")
  mkdir -p -- "$parent" || fail "install"

  # Verify the same remote snapshot before touching the old installation.
  info=$(remote_info) || fail "network"
  current_branch=$(printf '%s\n' "$info" | sed -n '1p')
  current_sha=$(printf '%s\n' "$info" | sed -n '2p')
  [ "$current_branch" = "$remote_branch" ] && [ "$current_sha" = "$remote" ] || fail "stale_remote"

  if [ -e "$SHELL_DIR" ]; then
    [ -d "$SHELL_DIR" ] || fail "unsafe_target"
    out "step=backup"
    make_backup || fail "backup"
    had_old=1

    # Keep the original directory in a same-filesystem holding folder until
    # the clone has been verified. The archive in ~/.cache is the durable backup.
    rollback_dir=$(mktemp -d "$parent/.${base}.rollback.XXXXXX") || fail "tmp"
    mv -- "$SHELL_DIR" "$rollback_dir/old" || {
      rm -rf -- "$rollback_dir"
      fail "backup"
    }
  else
    out "step=backup"
    out "backup="
  fi

  out "step=clone"
  if ! git clone --quiet --single-branch --branch "$remote_branch" "$REPO_URL" "$SHELL_DIR"; then
    restore_previous_install "clone" "$rollback_dir" "$had_old"
  fi

  out "step=verify"
  actual=$(git -C "$SHELL_DIR" rev-parse HEAD 2>/dev/null || true)
  if [ "$actual" != "$remote" ] || [ ! -f "$SHELL_DIR/shell.qml" ] || [ ! -f "$SHELL_DIR/VERSION" ]; then
    restore_previous_install "stale_remote" "$rollback_dir" "$had_old"
  fi

  # Confirm that the default branch did not move while git clone was running.
  info=$(remote_info) || restore_previous_install "network" "$rollback_dir" "$had_old"
  current_branch=$(printf '%s\n' "$info" | sed -n '1p')
  current_sha=$(printf '%s\n' "$info" | sed -n '2p')
  if [ "$current_branch" != "$remote_branch" ] || [ "$current_sha" != "$remote" ]; then
    restore_previous_install "stale_remote" "$rollback_dir" "$had_old"
  fi

  out "step=cleanup"
  [ -z "$rollback_dir" ] || rm -rf -- "$rollback_dir"
  out "status=done"
}

case "$CMD" in
  check) do_check ;;
  apply) do_apply "$@" ;;
  *) fail "usage" ;;
esac
