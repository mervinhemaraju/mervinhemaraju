#!/usr/bin/env bash
# cache-nuke: reclaim disk space by clearing developer and system caches.
#
# Usage: clear-cache.sh [options]
#   --dry-run        Show what would be removed and the sizes, change nothing
#   -y, --yes        Skip the confirmation prompt
#   --skip-targets   Keep Rust "target" directories under $PROJECTS / $PROJECTSEXT
#   --trash          Also empty the Trash
#   --system         Also run system-level cleanup (Linux only, uses sudo)
#   -h, --help       Show this help
#
# Compatible with the bash 3.2 that ships with macOS: no associative arrays,
# no mapfile.

set -euo pipefail

readonly OS="$(uname -s)"

DRY_RUN=false
ASSUME_YES=false
SKIP_TARGETS=false
INCLUDE_TRASH=false
INCLUDE_SYSTEM=false
WARNINGS=0

# Ordered list of cleanup sections. Each id needs a paths_<id> function that
# prints the paths it owns (one per line). A clean_<id> function is optional;
# without it the paths are simply removed.
readonly SECTIONS="go cargo targets brew npm pub infra syscache logs trash system"

if [[ -t 1 ]]; then
  C_BOLD=$'\033[1m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_DIM=$'\033[2m'
  C_RESET=$'\033[0m'
else
  C_BOLD=""
  C_GREEN=""
  C_YELLOW=""
  C_DIM=""
  C_RESET=""
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

usage() {
  sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

have() {
  command -v "$1" >/dev/null 2>&1
}

warn() {
  printf '%s! %s%s\n' "$C_YELLOW" "$*" "$C_RESET" >&2
  WARNINGS=$((WARNINGS + 1))
}

human_size() {
  awk -v kb="$1" 'BEGIN {
    split("KB MB GB TB", unit, " ")
    i = 1; v = kb
    while (v >= 1024 && i < 4) { v /= 1024; i++ }
    printf "%.1f %s", v, unit[i]
  }'
}

# Sum of the sizes (in KB) of newline-separated paths passed as $1.
paths_size_kb() {
  local total=0 p kb
  while IFS= read -r p; do
    [[ -n "$p" && -e "$p" ]] || continue
    # du exits non-zero on partially unreadable trees (protected dirs); the
    # readable part is still a valid size, so only the exit status is ignored.
    kb="$({ du -sk -- "$p" 2>/dev/null || true; } | awk '{print $1}')"
    total=$((total + ${kb:-0}))
  done <<<"$1"
  echo "$total"
}

# Print each argument that exists on disk.
emit() {
  local p
  for p in "$@"; do
    if [[ -e "$p" ]]; then
      printf '%s\n' "$p"
    fi
  done
}

# Print the direct children of $1, skipping names matching the glob patterns
# in the remaining arguments. Used to empty a directory without removing it.
emit_children() {
  local dir="$1" child name skip pat
  shift
  [[ -d "$dir" ]] || return 0
  while IFS= read -r child; do
    name="${child##*/}"
    skip=false
    for pat in "$@"; do
      # shellcheck disable=SC2254
      case "$name" in $pat) skip=true ;; esac
    done
    if [[ "$skip" == false ]]; then
      printf '%s\n' "$child"
    fi
  done < <(find "$dir" -mindepth 1 -maxdepth 1 2>/dev/null)
}

# Last line of defence against a bad path ever reaching rm -rf.
is_safe_path() {
  case "$1" in
    "" | "/" | "$HOME" | "$HOME/" | "$HOME/Library" | "$HOME/Projects") return 1 ;;
  esac
  [[ "$1" == /* ]]
}

remove_paths() {
  local p err
  while IFS= read -r p; do
    [[ -n "$p" ]] || continue
    if ! is_safe_path "$p"; then
      warn "refusing to remove unsafe path: '$p'"
      continue
    fi
    [[ -e "$p" ]] || continue
    if ! err="$(rm -rf -- "$p" 2>&1)"; then
      warn "could not fully remove $p: $(printf '%s' "$err" | head -n 1)"
    fi
  done <<<"$1"
}

# Run an external cleaner and report its failure instead of aborting the run.
run_tool() {
  local out
  if ! out="$("$@" 2>&1)"; then
    warn "'$*' failed: $(printf '%s' "$out" | tail -n 1)"
  fi
}

# ---------------------------------------------------------------------------
# Sections
# ---------------------------------------------------------------------------

section_title() {
  case "$1" in
    go) echo "Go (build, test and module caches)" ;;
    cargo) echo "Rust (cargo registry and git checkouts)" ;;
    targets) echo "Rust (target dirs in projects)" ;;
    brew) echo "Homebrew" ;;
    npm) echo "npm" ;;
    pub) echo "Dart / Flutter pub (hosted and git packages)" ;;
    infra) echo "Kubernetes and Terraform caches" ;;
    syscache) echo "User caches" ;;
    logs) echo "User logs" ;;
    trash) echo "Trash" ;;
    system) echo "System packages (apt, journal)" ;;
  esac
}

paths_go() {
  have go || return 0
  emit "$(go env GOCACHE)" "$(go env GOMODCACHE)"
}
clean_go() {
  run_tool go clean -cache -testcache -modcache
}

paths_cargo() {
  local home="${CARGO_HOME:-$HOME/.cargo}"
  emit "$home/registry/cache" "$home/registry/src" "$home/git/checkouts"
}

paths_targets() {
  [[ "$SKIP_TARGETS" == false ]] || return 0
  local root dir
  for root in "${PROJECTS:-$HOME/Projects}" "${PROJECTSEXT:-}"; do
    [[ -n "$root" && -d "$root" ]] || continue
    while IFS= read -r dir; do
      # Only Cargo output: Maven, sbt and others also use a "target" dir.
      if [[ -f "$dir/../Cargo.toml" ]]; then
        printf '%s\n' "$dir"
      fi
    done < <(find "$root" \( -name node_modules -o -name .git \) -prune -o -type d -name target -print -prune 2>/dev/null)
  done
  return 0
}

paths_brew() {
  have brew || return 0
  emit "$(brew --cache)"
}
clean_brew() {
  run_tool brew cleanup --prune=all -s
  remove_paths "$1"
}

paths_npm() {
  have npm || return 0
  emit "$(npm config get cache)"
}
clean_npm() {
  run_tool npm cache clean --force
}

# Only hosted/git packages: "dart pub cache clean" would also delete
# global_packages and bin, i.e. globally activated tools that are on PATH.
paths_pub() {
  local root="${PUB_CACHE:-$HOME/.pub-cache}"
  emit "$root/hosted" "$root/hosted-hashes" "$root/git"
}

paths_infra() {
  emit "$HOME/.kube/cache" "$HOME/.kube/http-cache"
  # Terraform errors out if TF_PLUGIN_CACHE_DIR is missing, so empty it only.
  emit_children "${TF_PLUGIN_CACHE_DIR:-$HOME/.terraform.d/plugin-cache}"
}

# Homebrew and go-build have their own sections; com.apple.* is system-owned
# and rebuilt unpredictably, so it is left alone on purpose.
paths_syscache() {
  emit_children "${XDG_CACHE_HOME:-$HOME/.cache}" "Homebrew" "go-build"
  if [[ "$OS" == "Darwin" ]]; then
    emit_children "$HOME/Library/Caches" "Homebrew" "go-build" "com.apple.*"
    emit_children "$HOME/Library/Developer/Xcode/DerivedData"
  fi
}

paths_logs() {
  if [[ "$OS" == "Darwin" ]]; then
    emit_children "$HOME/Library/Logs"
  fi
  return 0
}

paths_trash() {
  [[ "$INCLUDE_TRASH" == true ]] || return 0
  if [[ "$OS" == "Darwin" ]]; then
    emit_children "$HOME/.Trash"
  else
    emit_children "${XDG_DATA_HOME:-$HOME/.local/share}/Trash/files"
  fi
}

paths_system() {
  [[ "$INCLUDE_SYSTEM" == true && "$OS" == "Linux" ]] || return 0
  emit "/var/cache/apt/archives"
}
clean_system() {
  if have apt-get; then
    run_tool sudo apt-get clean
  fi
  if have journalctl; then
    run_tool sudo journalctl --vacuum-time=7d
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) DRY_RUN=true ;;
      -y | --yes) ASSUME_YES=true ;;
      --skip-targets) SKIP_TARGETS=true ;;
      --trash) INCLUDE_TRASH=true ;;
      --system) INCLUDE_SYSTEM=true ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        printf 'Unknown option: %s\n\n' "$1" >&2
        usage >&2
        exit 2
        ;;
    esac
    shift
  done
}

main() {
  parse_args "$@"

  local id paths kb total_kb=0 found=""
  local freed_kb total_freed_kb=0 after_kb

  printf '%sScanning caches...%s\n\n' "$C_BOLD" "$C_RESET"

  for id in $SECTIONS; do
    paths="$("paths_$id")"
    # The "system" section can have work to do even when no path is sized.
    if [[ -z "$paths" ]]; then
      continue
    fi
    kb="$(paths_size_kb "$paths")"
    total_kb=$((total_kb + kb))
    found="$found $id"
    printf '  %-48s %s%10s%s\n' "$(section_title "$id")" "$C_DIM" "$(human_size "$kb")" "$C_RESET"
  done

  if [[ -z "$found" ]]; then
    printf 'Nothing to clean.\n'
    return 0
  fi

  printf '\n  %s%-48s %10s%s\n\n' "$C_BOLD" "Total (upper bound)" "$(human_size "$total_kb")" "$C_RESET"

  if [[ "$DRY_RUN" == true ]]; then
    printf 'Dry run: nothing was removed.\n'
    return 0
  fi

  if [[ "$ASSUME_YES" == false ]]; then
    local answer
    read -r -p "Remove all of the above? [y/N] " answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
      printf 'Aborted.\n'
      return 0
    fi
    printf '\n'
  fi

  local before_kb
  for id in $found; do
    paths="$("paths_$id")"
    before_kb="$(paths_size_kb "$paths")"
    printf '%s==>%s %s\n' "$C_BOLD" "$C_RESET" "$(section_title "$id")"

    if declare -F "clean_$id" >/dev/null; then
      "clean_$id" "$paths"
    else
      remove_paths "$paths"
    fi

    after_kb="$(paths_size_kb "$paths")"
    freed_kb=$((before_kb - after_kb))
    if ((freed_kb < 0)); then
      freed_kb=0
    fi
    total_freed_kb=$((total_freed_kb + freed_kb))
    printf '    %sfreed %s%s\n' "$C_GREEN" "$(human_size "$freed_kb")" "$C_RESET"
  done

  printf '\n%sDone. Reclaimed about %s.%s\n' "$C_BOLD" "$(human_size "$total_freed_kb")" "$C_RESET"
  if ((WARNINGS > 0)); then
    printf '%s%d warning(s) above: some paths could not be fully removed.%s\n' "$C_YELLOW" "$WARNINGS" "$C_RESET"
  fi
}

main "$@"
