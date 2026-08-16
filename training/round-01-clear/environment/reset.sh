#!/usr/bin/env bash
# Conservative B1-1 R01 reset helper.
# It never changes SSH/Firewall and never deletes users/groups or Secret files.

set -euo pipefail

if [ "${1:-}" != "--apply" ]; then
    cat <<'EOF'
B1-1 R01 reset helper

This reset is intentionally conservative.
It removes only helper-installed non-secret files when the Round marker exists.

It NEVER removes:
- users/groups
- SSH settings
- Firewall rules
- t_secret.key
- runtime logs/Evidence

R01 Golden Path:
  AGENT_HOME=/opt/agent-app

Run:
  sudo ./reset.sh --apply
EOF
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "[FAIL] reset.sh --apply must run with sudo/root." >&2
    exit 1
fi

AGENT_HOME="${AGENT_HOME:-/opt/agent-app}"
MARKER="${AGENT_HOME}/.codyssey-b1-1-round01"

if [ ! -f "$MARKER" ]; then
    echo "[INFO] Round marker not found. Nothing is removed."
    exit 0
fi

for f in "${AGENT_HOME}/bin/monitor.sh" "${AGENT_HOME}/env.sh" "$MARKER"; do
    if [ -f "$f" ]; then
        rm -f -- "$f"
        echo "[PASS] removed helper-installed file: $f"
    fi
done

cat <<'EOF'
[PASS] Conservative reset complete.

Kept intentionally because automatic deletion could be destructive:
- users/groups and memberships
- shared directories
- t_secret.key
- /var/log/agent-app contents
- SSH configuration
- Firewall configuration
- cron entries

Review the exact pre-R01 state before manually reverting any of those items.
EOF
