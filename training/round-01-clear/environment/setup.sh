#!/usr/bin/env bash
# B1-1 R01 reproduction helper.
# Round 01 primary path is still the manual BEGINNER-GUIDE.
# This helper intentionally does NOT modify SSH or Firewall rules.

set -euo pipefail

if [ "${1:-}" != "--apply" ]; then
    cat <<'EOF'
B1-1 R01 setup helper

This script creates/normalizes only the Agent users, groups, directories,
non-secret env.sh, and monitor.sh installation.

It does NOT modify SSH or Firewall settings.

Run only after reading BEGINNER-GUIDE.md:
  sudo ./setup.sh --apply
EOF
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "[FAIL] setup.sh --apply must run with sudo/root." >&2
    exit 1
fi

AGENT_HOME="${AGENT_HOME:-/home/agent-admin/agent-app}"
AGENT_LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROUND_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
REFERENCE_MONITOR="${ROUND_DIR}/monitor.sh"
MARKER="${AGENT_HOME}/.codyssey-b1-1-round01"

ensure_group() {
    local group_name="$1"
    if getent group "$group_name" >/dev/null 2>&1; then
        echo "[PASS] group exists: $group_name"
    else
        groupadd "$group_name"
        echo "[PASS] group created: $group_name"
    fi
}

ensure_user() {
    local user_name="$1"
    if id "$user_name" >/dev/null 2>&1; then
        echo "[PASS] user exists: $user_name"
    else
        useradd --create-home --shell /bin/bash "$user_name"
        echo "[PASS] user created: $user_name"
    fi
}

ensure_group agent-common
ensure_group agent-core

ensure_user agent-admin
ensure_user agent-dev
ensure_user agent-test

usermod -aG agent-common,agent-core agent-admin
usermod -aG agent-common,agent-core agent-dev
usermod -aG agent-common agent-test

echo "[PASS] group membership configured"

install -d -o agent-admin -g agent-core -m 0750 "$AGENT_HOME"
install -d -o agent-admin -g agent-common -m 2770 "${AGENT_HOME}/upload_files"
install -d -o agent-admin -g agent-core -m 2770 "${AGENT_HOME}/api_keys"
install -d -o agent-dev -g agent-core -m 0750 "${AGENT_HOME}/bin"
install -d -o agent-admin -g agent-core -m 2770 "$AGENT_LOG_DIR"

# Default ACLs keep newly-created files group-accessible in shared directories.
if command -v setfacl >/dev/null 2>&1; then
    setfacl -m g:agent-common:rwx,m:rwx "${AGENT_HOME}/upload_files"
    setfacl -d -m g:agent-common:rwx,m:rwx "${AGENT_HOME}/upload_files"

    setfacl -m g:agent-core:rwx,m:rwx "${AGENT_HOME}/api_keys"
    setfacl -d -m g:agent-core:rwx,m:rwx "${AGENT_HOME}/api_keys"

    setfacl -m g:agent-core:rwx,m:rwx "$AGENT_LOG_DIR"
    setfacl -d -m g:agent-core:rwx,m:rwx "$AGENT_LOG_DIR"
    echo "[PASS] ACL configured"
else
    echo "[WARNING] setfacl not found; install package 'acl' before final verification"
fi

if [ ! -f "$REFERENCE_MONITOR" ]; then
    echo "[FAIL] reference monitor not found: $REFERENCE_MONITOR" >&2
    exit 1
fi

install -o agent-dev -g agent-core -m 0750 "$REFERENCE_MONITOR" "${AGENT_HOME}/bin/monitor.sh"

echo "[PASS] monitor.sh installed"

cat > "${AGENT_HOME}/env.sh" <<EOF
# B1-1 non-secret runtime environment
export AGENT_HOME="${AGENT_HOME}"
export AGENT_PORT="15034"
export AGENT_UPLOAD_DIR="${AGENT_HOME}/upload_files"
export AGENT_KEY_PATH="${AGENT_HOME}/api_keys/t_secret.key"
export AGENT_LOG_DIR="${AGENT_LOG_DIR}"
# Adjust after inspecting agent-app.zip if the executable name differs.
export AGENT_PROCESS_PATTERN="agent-app|agent_app.py"
EOF
chown agent-admin:agent-core "${AGENT_HOME}/env.sh"
chmod 0640 "${AGENT_HOME}/env.sh"

touch "$MARKER"
chown agent-admin:agent-core "$MARKER"
chmod 0640 "$MARKER"

cat <<EOF
[PASS] B1-1 non-network environment prepared

AGENT_HOME: ${AGENT_HOME}
LOG DIR   : ${AGENT_LOG_DIR}

NOT DONE by this helper:
- SSH 20022 configuration
- Root remote login policy
- Firewall rules
- t_secret.key creation/value
- Agent application execution
- cron registration
- Runtime verification/Evidence
EOF
