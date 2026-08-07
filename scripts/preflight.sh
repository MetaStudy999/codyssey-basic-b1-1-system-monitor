#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2015
# /etc/os-release is a trusted OS file; PASS/WARN/FAIL helpers return success.
set -u

# Read-only B1-1 preflight checker.

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
pass() { printf '[PASS] %s\n' "$*"; PASS_COUNT=$((PASS_COUNT + 1)); }
warn() { printf '[WARN] %s\n' "$*"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { printf '[FAIL] %s\n' "$*"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

check_command() {
  local cmd="$1" package_hint="${2:-$1}"
  if command -v "$cmd" >/dev/null 2>&1; then
    pass "$cmd: $(command -v "$cmd")"
  else
    fail "$cmd missing (package/tool hint: $package_hint)"
  fi
}

printf 'B1-1 preflight (read-only)\n'
printf '%s\n' '----------------------------------------'

printf '\n[identity]\n'
CURRENT_USER="$(id -un 2>/dev/null || echo unknown)"
printf 'user=%s\npwd=%s\n' "$CURRENT_USER" "$PWD"
[[ "$CURRENT_USER" == root ]] && warn 'running the whole mission as root is not recommended' || pass "current user is non-root: $CURRENT_USER"

printf '\n[os]\n'
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  printf 'ID=%s\nVERSION_ID=%s\nPRETTY_NAME=%s\n' "${ID:-unknown}" "${VERSION_ID:-unknown}" "${PRETTY_NAME:-unknown}"
  if [[ "${ID:-}" == ubuntu ]]; then
    pass 'Ubuntu detected'
    [[ "${VERSION_ID:-}" == 22.04 ]] && pass 'Ubuntu 22.04 matches mission baseline directly' || warn "Ubuntu ${VERSION_ID:-unknown}: treat as equivalent environment and verify behavior"
  else
    warn 'non-Ubuntu Linux: equivalent-environment differences must be reviewed'
  fi
else
  fail '/etc/os-release is not readable'
fi

ARCH="$(uname -m 2>/dev/null || echo unknown)"
printf 'architecture=%s\n' "$ARCH"
case "$ARCH" in
  x86_64|amd64) pass 'Agent target expected from mission data: agent-app-linux-x86' ;;
  aarch64|arm64) pass 'Agent target expected from mission data: agent-app-linux-arm64' ;;
  *) warn 'architecture is not one of the two provided Agent targets; verify compatibility before Agent setup' ;;
esac

printf '\n[service-manager]\n'
PID1="$(ps -p 1 -o comm= 2>/dev/null | tr -d '[:space:]')"
printf 'pid1=%s\n' "${PID1:-unknown}"
[[ "$PID1" == systemd ]] && pass 'PID 1 is systemd' || fail "PID 1 is not systemd: ${PID1:-unknown}"
check_command systemctl systemd

printf '\n[sudo]\n'
if command -v sudo >/dev/null 2>&1; then
  pass "sudo command exists: $(command -v sudo)"
  if [[ "$EUID" -eq 0 ]] || sudo -n true >/dev/null 2>&1; then
    pass 'administrative privilege is currently available/cached'
  else
    warn 'sudo may require interactive authentication; run sudo -v before system changes'
  fi
else
  fail 'sudo command missing'
fi

printf '\n[required-tools]\n'
check_command bash bash
check_command sshd openssh-server
check_command ufw ufw
check_command cron cron
check_command getfacl acl
check_command setfacl acl
check_command ss iproute2
check_command logrotate logrotate
check_command pgrep procps
check_command awk awk
check_command df coreutils
check_command unzip unzip
check_command file file

printf '\n[current-network-baseline]\n'
ss -lntH 2>/dev/null | awk '$4 ~ /:(22|20022|15034)$/ { print }' || true

printf '\n[disk]\n'
df -h / 2>/dev/null || warn 'could not read root filesystem usage'

printf '\n[summary]\n'
printf 'PASS=%d WARN=%d FAIL=%d\n' "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"
if (( FAIL_COUNT > 0 )); then
  printf '[STOP] Resolve FAIL items before changing SSH/firewall/users.\n'
  exit 1
fi
printf '[GO] No blocking preflight failure detected. Review WARN items before continuing.\n'
exit 0
