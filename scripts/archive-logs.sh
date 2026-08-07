#!/usr/bin/env bash
set -u

# B1-1 Bonus 2: time-based log retention.
# - Compress *.log files in LOG_DIR that are at least 7 days old.
# - Move resulting .gz files to ARCHIVE_DIR.
# - Delete archived .gz files that are at least 30 days old.
# Safety: DRY_RUN=1 bash scripts/archive-logs.sh

LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
ARCHIVE_DIR="${AGENT_ARCHIVE_DIR:-/var/log/monitor/agent-app/archive}"
DRY_RUN="${DRY_RUN:-0}"
ARCHIVE_AFTER_DAYS="${ARCHIVE_AFTER_DAYS:-7}"
DELETE_AFTER_DAYS="${DELETE_AFTER_DAYS:-30}"
ERROR_COUNT=0

info() { printf '[INFO] %s\n' "$*"; }
error() { printf '[ERROR] %s\n' "$*" >&2; ERROR_COUNT=$((ERROR_COUNT + 1)); }

for cmd in basename find gzip mktemp mv rm; do
  command -v "$cmd" >/dev/null 2>&1 || { error "required command not found: $cmd"; exit 2; }
done

if ! [[ "$ARCHIVE_AFTER_DAYS" =~ ^[1-9][0-9]*$ && "$DELETE_AFTER_DAYS" =~ ^[1-9][0-9]*$ ]]; then
  error 'retention day values must be positive integers'
  exit 2
fi
if [[ "$DRY_RUN" != 0 && "$DRY_RUN" != 1 ]]; then
  error 'DRY_RUN must be 0 or 1'
  exit 2
fi
if [[ ! -d "$LOG_DIR" ]]; then
  error "log directory does not exist: $LOG_DIR"
  exit 2
fi
if [[ ! -r "$LOG_DIR" || ! -x "$LOG_DIR" ]]; then
  error "log directory is not readable/traversable: $LOG_DIR"
  exit 2
fi

if [[ "$DRY_RUN" == 0 ]]; then
  if ! mkdir -p -- "$ARCHIVE_DIR"; then
    error "could not create archive directory: $ARCHIVE_DIR"
    exit 2
  fi
  if [[ ! -w "$LOG_DIR" || ! -w "$ARCHIVE_DIR" || ! -x "$ARCHIVE_DIR" ]]; then
    error 'write/traverse permission is insufficient for compression or archive move'
    exit 2
  fi
elif [[ -e "$ARCHIVE_DIR" && ( ! -r "$ARCHIVE_DIR" || ! -x "$ARCHIVE_DIR" ) ]]; then
  error "archive directory is not readable/traversable: $ARCHIVE_DIR"
  exit 2
fi

ARCHIVE_MTIME=$((ARCHIVE_AFTER_DAYS - 1))
DELETE_MTIME=$((DELETE_AFTER_DAYS - 1))
ARCHIVE_LIST="$(mktemp /tmp/b1-1-archive-list.XXXXXX)"
DELETE_LIST="$(mktemp /tmp/b1-1-delete-list.XXXXXX)"
trap 'rm -f "$ARCHIVE_LIST" "$DELETE_LIST"' EXIT

if ! find "$LOG_DIR" -maxdepth 1 -type f -name '*.log' -mtime "+$ARCHIVE_MTIME" -print0 > "$ARCHIVE_LIST"; then
  error "find failed while scanning log directory: $LOG_DIR"
  exit 2
fi

if [[ -d "$ARCHIVE_DIR" ]]; then
  if ! find "$ARCHIVE_DIR" -maxdepth 1 -type f -name '*.gz' -mtime "+$DELETE_MTIME" -print0 > "$DELETE_LIST"; then
    error "find failed while scanning archive directory: $ARCHIVE_DIR"
    exit 2
  fi
fi

info "log_dir=$LOG_DIR"
info "archive_dir=$ARCHIVE_DIR"
info "archive_after_days=$ARCHIVE_AFTER_DAYS"
info "delete_after_days=$DELETE_AFTER_DAYS"
[[ "$DRY_RUN" == 1 ]] && info 'DRY_RUN enabled; no files will be changed'

ARCHIVED=0
DELETED=0
SKIPPED=0

while IFS= read -r -d '' file; do
  base="$(basename -- "$file")"
  target="${ARCHIVE_DIR}/${base}.gz"
  if [[ -e "$target" ]]; then
    error "archive target already exists; refusing overwrite: $target"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [[ "$DRY_RUN" == 1 ]]; then
    printf '[DRY-RUN] gzip -n -- %q && mv -- %q %q\n' "$file" "${file}.gz" "$target"
    ARCHIVED=$((ARCHIVED + 1))
    continue
  fi

  if ! gzip -n -- "$file"; then
    error "gzip failed: $file"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if mv -- "${file}.gz" "$target"; then
    info "archived: $target"
    ARCHIVED=$((ARCHIVED + 1))
  else
    error "move failed after compression: ${file}.gz -> $target"
    if gzip -d -- "${file}.gz" 2>/dev/null; then
      info "restored original after move failure: $file"
    else
      error "could not restore compressed source after move failure: ${file}.gz"
    fi
    SKIPPED=$((SKIPPED + 1))
  fi
done < "$ARCHIVE_LIST"

while IFS= read -r -d '' file; do
  if [[ "$DRY_RUN" == 1 ]]; then
    printf '[DRY-RUN] rm -- %q\n' "$file"
    DELETED=$((DELETED + 1))
    continue
  fi
  if rm -- "$file"; then
    info "deleted expired archive: $file"
    DELETED=$((DELETED + 1))
  else
    error "delete failed: $file"
    SKIPPED=$((SKIPPED + 1))
  fi
done < "$DELETE_LIST"

if [[ "$ARCHIVED" -eq 0 && "$DELETED" -eq 0 && "$ERROR_COUNT" -eq 0 ]]; then
  info 'no files matched the retention policy; nothing to do'
fi

printf '[SUMMARY] archived=%d deleted=%d skipped=%d errors=%d\n' "$ARCHIVED" "$DELETED" "$SKIPPED" "$ERROR_COUNT"
(( ERROR_COUNT == 0 )) || exit 1
exit 0
