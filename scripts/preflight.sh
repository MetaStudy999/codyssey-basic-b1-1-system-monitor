#!/usr/bin/env bash
set -u

# Read-only B1-1 preflight checker.
# It does not modify SSH, UFW, users, groups, ACLs, cron, or files.

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() { printf '[PASS] %s\n' "$*"; PASS_COUNT=$((PASS_COUNT + 1)); }
warn() { printf '[WARN] %s\n' "$*"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { printf '[FAIL] %s\n' "$*"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

check_command() {
  local cmd="$1"
  local package_hint="${2:-$1}"
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
printf 'user=%s\n' "$CURRENT_USER"
printf 'pwd=%s\n' "$PWD"
if [[ "$CURRENT_USER" == "root" ]]; then
  warn 'running the whole mission as root is not recommended'
else
  pass "current user is non-root: $CURRENT_USER"
fi

printf '\n[os]\n'
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  printf 'ID=%s\n' "${ID:-unknown}"
  printf 'VERSION_ID=%s\n' "${VERSION_ID:-unknown}"
  printf 'PRETTY_NAME=%s\n' "${PRETTY_NAME:-unknown}"
  if [[ "${ID:-}" == "ubuntu" ]]; then
    pass 'Ubuntu detected'
    if [[ "${VERSION_ID:-}" == "22.04" ]]; then
      pass 'Ubuntu 22.04 matches the mission baseline directly'
    else
      warn "Ubuntu ${VERSION_ID:-unknown}: treat as an equivalent environment and verify behavior"
    fi
  else
    warn 'non-Ubuntu Linux: equivalent-environment differences must be reviewed'
  fi
else
  fail '/etc/os-release is not readable'
fi

ARCH="$(uname -m 2>/dev/null || echo unknown)"
printf 'architecture=%s\n' "$ARCH"
pass 'CPU architecture recorded (architecture itself is not treated as a mission pass/fail requirement)'

printf '\n[service-manager]\n'
PID1="$(ps -p 1 -o comm= 2>/dev/null | tr -d '[:space:]')"
printf 'pid1=%s\n' "${PID1:-unknown}"
if [[ "$PID1" == "systemd" ]]; then
  pass 'PID 1 is systemd'
else
  fail "PID 1 is not systemd: ${PID1:-unknown}"
fi

if command -v systemctl >/dev/null 2>&1; then
  pass "systemctl: $(command -v systemctl)"
else
  fail 'systemctl missing'
fi

printf '\n[sudo]\n'
if command -v sudo >/dev/null 2>&1; then
  pass "sudo command exists: $(command -v sudo)"
  if [[ "$EUID" -eq 0 ]]; then
    pass 'already running with administrative privilege'
  elif sudo -n true >/dev/null 2>&1; then
    pass 'sudo is currently available non-interactively/cached'
  else
    warn 'sudo may require interactive authentication; run `sudo -v` before system changes'
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
check_command python3 python3

printf '\n[current-network-baseline]\n'
if command -v ss >/dev/null 2>&1; then
  ss -lntH 2>/dev/null | awk '$4 ~ /:(22|20022|15034)$/ { print }' || true
fi

if command -v systemctl >/dev/null 2>&1 && command -v ufw >/dev/null 2>&1; then
  UFW_STATE="$(systemctl is-active ufw 2>/dev/null || true)"
  printf 'ufw.service=%s\n' "${UFW_STATE:-unknown}"
fi

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
