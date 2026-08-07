#!/usr/bin/env bash
set -u

# B1-1 Bonus 2: time-based log retention.
# - Compress *.log files in LOG_DIR that are at least 7 days old.
# - Move resulting .gz files to ARCHIVE_DIR.
# - Delete archived .gz files that are at least 30 days old.
#
# Safety:
#   DRY_RUN=1 ./archive-logs.sh

LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
ARCHIVE_DIR="${AGENT_ARCHIVE_DIR:-/var/log/monitor/agent-app/archive}"
DRY_RUN="${DRY_RUN:-0}"

ARCHIVE_AFTER_DAYS="${ARCHIVE_AFTER_DAYS:-7}"
DELETE_AFTER_DAYS="${DELETE_AFTER_DAYS:-30}"

INFO_COUNT=0
ERROR_COUNT=0

info() {
  printf '[INFO] %s\n' "$*"
  INFO_COUNT=$((INFO_COUNT + 1))
}

error() {
  printf '[ERROR] %s\n' "$*" >&2
  ERROR_COUNT=$((ERROR_COUNT + 1))
}

if ! [[ "$ARCHIVE_AFTER_DAYS" =~ ^[0-9]+$ && "$DELETE_AFTER_DAYS" =~ ^[0-9]+$ ]]; then
  error 'retention day values must be non-negative integers'
  exit 2
fi

if [[ "$DRY_RUN" != "0" && "$DRY_RUN" != "1" ]]; then
  error 'DRY_RUN must be 0 or 1'
  exit 2
fi

if [[ ! -d "$LOG_DIR" ]]; then
  error "log directory does not exist: $LOG_DIR"
  exit 2
fi

if ! command -v find >/dev/null 2>&1 || ! command -v gzip >/dev/null 2>&1; then
  error 'required commands not found: find and gzip are required'
  exit 2
fi

# GNU find -mtime counts complete 24-hour periods and uses strict greater-than
# for +N. To represent "at least N days old", use +(N-1).
ARCHIVE_MTIME=$((ARCHIVE_AFTER_DAYS - 1))
DELETE_MTIME=$((DELETE_AFTER_DAYS - 1))

if (( ARCHIVE_MTIME < 0 )); then ARCHIVE_MTIME=0; fi
if (( DELETE_MTIME < 0 )); then DELETE_MTIME=0; fi

if [[ "$DRY_RUN" == "1" ]]; then
  info "DRY_RUN enabled; no files will be compressed, moved, or deleted"
else
  if ! mkdir -p -- "$ARCHIVE_DIR"; then
    error "could not create archive directory: $ARCHIVE_DIR"
    exit 2
  fi
fi

info "log_dir=$LOG_DIR"
info "archive_dir=$ARCHIVE_DIR"
info "archive_after_days=$ARCHIVE_AFTER_DAYS"
info "delete_after_days=$DELETE_AFTER_DAYS"

ARCHIVED=0
DELETED=0
SKIPPED=0

while IFS= read -r -d '' file; do
  base="$(basename -- "$file")"
  target="${ARCHIVE_DIR}/${base}.gz"

  if [[ -e "$target" ]]; then
    error "archive target already exists; skipping to avoid overwrite: $target"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[DRY-RUN] gzip -- %q && mv -- %q %q\n' "$file" "${file}.gz" "$target"
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
    SKIPPED=$((SKIPPED + 1))
  fi
done < <(find "$LOG_DIR" -maxdepth 1 -type f -name '*.log' -mtime "+$ARCHIVE_MTIME" -print0)

if [[ -d "$ARCHIVE_DIR" ]]; then
  while IFS= read -r -d '' file; do
    if [[ "$DRY_RUN" == "1" ]]; then
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
  done < <(find "$ARCHIVE_DIR" -maxdepth 1 -type f -name '*.gz' -mtime "+$DELETE_MTIME" -print0)
fi

printf '[SUMMARY] archived=%d deleted=%d skipped=%d errors=%d\n' \
  "$ARCHIVED" "$DELETED" "$SKIPPED" "$ERROR_COUNT"

if (( ERROR_COUNT > 0 )); then
  exit 1
fi

exit 0
