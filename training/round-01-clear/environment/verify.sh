#!/usr/bin/env bash
# B1-1 R01 verification-only script.
# Run with sudo so it can inspect system-level configuration and test effective
# access as each mission user. It does not change system configuration.

set -u

PASS=0
FAIL=0
AGENT_HOME="${AGENT_HOME:-/opt/agent-app}"
AGENT_LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
MONITOR_LOG="${AGENT_LOG_DIR}/monitor.log"
MONITOR="${AGENT_HOME}/bin/monitor.sh"

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }

if [ "$(id -u)" -ne 0 ]; then
    echo "[FAIL] run verification with: sudo bash training/round-01-clear/environment/verify.sh" >&2
    exit 1
fi

check_cmd() {
    if command -v "$1" >/dev/null 2>&1; then
        pass "command exists: $1"
    else
        fail "command missing: $1"
    fi
}

for cmd in bash sshd ss ps pgrep df stat getent id crontab ufw runuser git awk grep find; do
    check_cmd "$cmd"
done

# 1) SSH effective configuration and actual listen port.
if command -v sshd >/dev/null 2>&1; then
    SSHD_T=$(sshd -T 2>/dev/null || true)
    echo "$SSHD_T" | grep -Eq '^port 20022$' \
        && pass "SSH effective port is 20022" \
        || fail "SSH effective port 20022 not confirmed"
    echo "$SSHD_T" | grep -Eq '^permitrootlogin no$' \
        && pass "PermitRootLogin no" \
        || fail "Root remote login block not confirmed"
else
    fail "sshd command missing"
fi

if ss -lnt 2>/dev/null | awk '$4 ~ /:20022$/ {ok=1} END{exit !ok}'; then
    pass "TCP 20022 LISTEN"
else
    fail "TCP 20022 not LISTEN"
fi

# 2) R01 Golden Path firewall: UFW active, default deny incoming, and no
# inbound ALLOW rules other than 20022/tcp and 15034/tcp.
if command -v ufw >/dev/null 2>&1; then
    UFW_OUT=$(ufw status verbose 2>/dev/null || true)
    echo "$UFW_OUT" | grep -q '^Status: active$' \
        && pass "UFW active" \
        || fail "UFW is not active"

    echo "$UFW_OUT" | grep -Eq '^Default: deny \(incoming\)' \
        && pass "UFW default deny incoming" \
        || fail "UFW default deny incoming not confirmed"

    echo "$UFW_OUT" | awk '$0 ~ /ALLOW IN/ && $1 == "20022/tcp" {ok=1} END{exit !ok}' \
        && pass "UFW allows 20022/tcp" \
        || fail "UFW 20022/tcp allow not confirmed"

    echo "$UFW_OUT" | awk '$0 ~ /ALLOW IN/ && $1 == "15034/tcp" {ok=1} END{exit !ok}' \
        && pass "UFW allows 15034/tcp" \
        || fail "UFW 15034/tcp allow not confirmed"

    EXTRA_ALLOW=$(echo "$UFW_OUT" | awk '$0 ~ /ALLOW IN/ && $1 != "20022/tcp" && $1 != "15034/tcp" {print}')
    if [ -z "$EXTRA_ALLOW" ]; then
        pass "No extra inbound UFW ALLOW rules"
    else
        fail "Extra inbound UFW ALLOW rules detected"
        echo "$EXTRA_ALLOW" | sed 's/^/       /'
    fi
else
    fail "ufw command missing (R01 Golden Path uses UFW)"
fi

# 3) Users, groups, and exact membership policy.
for u in agent-admin agent-dev agent-test; do
    id "$u" >/dev/null 2>&1 && pass "user exists: $u" || fail "user missing: $u"
done
for g in agent-common agent-core; do
    getent group "$g" >/dev/null 2>&1 && pass "group exists: $g" || fail "group missing: $g"
done

id -nG agent-admin 2>/dev/null | grep -qw agent-common \
    && id -nG agent-admin 2>/dev/null | grep -qw agent-core \
    && pass "agent-admin is common+core" \
    || fail "agent-admin group membership"

id -nG agent-dev 2>/dev/null | grep -qw agent-common \
    && id -nG agent-dev 2>/dev/null | grep -qw agent-core \
    && pass "agent-dev is common+core" \
    || fail "agent-dev group membership"

if id -nG agent-test 2>/dev/null | grep -qw agent-common \
   && ! id -nG agent-test 2>/dev/null | grep -qw agent-core; then
    pass "agent-test is common and not core"
else
    fail "agent-test must be common and must not be core"
fi

# 4) Directory existence and effective least-privilege behavior.
for d in "$AGENT_HOME" "$AGENT_HOME/upload_files" "$AGENT_HOME/api_keys" "$AGENT_HOME/bin" "$AGENT_LOG_DIR"; do
    [ -d "$d" ] && pass "directory exists: $d" || fail "directory missing: $d"
done

if [ -d "$AGENT_HOME/upload_files" ]; then
    runuser -u agent-admin -- test -w "$AGENT_HOME/upload_files" \
        && runuser -u agent-dev -- test -w "$AGENT_HOME/upload_files" \
        && runuser -u agent-test -- test -w "$AGENT_HOME/upload_files" \
        && pass "upload_files writable by admin/dev/test" \
        || fail "upload_files common-group write policy"
fi

if [ -d "$AGENT_HOME/api_keys" ]; then
    if runuser -u agent-admin -- test -w "$AGENT_HOME/api_keys" \
       && runuser -u agent-dev -- test -w "$AGENT_HOME/api_keys" \
       && ! runuser -u agent-test -- test -r "$AGENT_HOME/api_keys" \
       && ! runuser -u agent-test -- test -w "$AGENT_HOME/api_keys"; then
        pass "api_keys is core-only for effective access"
    else
        fail "api_keys effective core-only policy"
    fi
fi

if [ -d "$AGENT_LOG_DIR" ]; then
    if runuser -u agent-admin -- test -w "$AGENT_LOG_DIR" \
       && runuser -u agent-dev -- test -w "$AGENT_LOG_DIR" \
       && ! runuser -u agent-test -- test -r "$AGENT_LOG_DIR" \
       && ! runuser -u agent-test -- test -w "$AGENT_LOG_DIR"; then
        pass "agent log directory is core-only for effective access"
    else
        fail "agent log directory effective core-only policy"
    fi
fi

# 5) Non-secret environment file and Secret file existence/permission only.
ENV_FILE="$AGENT_HOME/env.sh"
if [ -f "$ENV_FILE" ]; then
    pass "env.sh exists"
    grep -q "^export AGENT_HOME=\"$AGENT_HOME\"$" "$ENV_FILE" && pass "AGENT_HOME env" || fail "AGENT_HOME env"
    grep -q '^export AGENT_PORT="15034"$' "$ENV_FILE" && pass "AGENT_PORT env" || fail "AGENT_PORT env"
    grep -q "^export AGENT_UPLOAD_DIR=\"$AGENT_HOME/upload_files\"$" "$ENV_FILE" && pass "AGENT_UPLOAD_DIR env" || fail "AGENT_UPLOAD_DIR env"
    grep -q "^export AGENT_KEY_PATH=\"$AGENT_HOME/api_keys/t_secret.key\"$" "$ENV_FILE" && pass "AGENT_KEY_PATH env" || fail "AGENT_KEY_PATH env"
    grep -q "^export AGENT_LOG_DIR=\"$AGENT_LOG_DIR\"$" "$ENV_FILE" && pass "AGENT_LOG_DIR env" || fail "AGENT_LOG_DIR env"
    grep -q '^export AGENT_PROCESS_NAME="agent-app"$' "$ENV_FILE" && pass "AGENT_PROCESS_NAME env" || fail "AGENT_PROCESS_NAME env"
else
    fail "env.sh missing"
fi

SECRET_FILE="$AGENT_HOME/api_keys/t_secret.key"
if [ -f "$SECRET_FILE" ] && [ -s "$SECRET_FILE" ]; then
    pass "Secret file exists and is non-empty (value not read)"
    SECRET_OWNER=$(stat -c '%U' "$SECRET_FILE" 2>/dev/null || true)
    SECRET_GROUP=$(stat -c '%G' "$SECRET_FILE" 2>/dev/null || true)
    SECRET_MODE=$(stat -c '%a' "$SECRET_FILE" 2>/dev/null || true)
    [ "$SECRET_OWNER" = agent-admin ] && pass "Secret owner agent-admin" || fail "Secret owner is $SECRET_OWNER"
    [ "$SECRET_GROUP" = agent-core ] && pass "Secret group agent-core" || fail "Secret group is $SECRET_GROUP"
    [ "$SECRET_MODE" = 660 ] && pass "Secret mode 660" || fail "Secret mode is $SECRET_MODE"
else
    fail "Secret file missing/empty (value is never printed)"
fi

# 6) monitor.sh implementation and installed policy.
if [ -f "$MONITOR" ]; then
    OWNER=$(stat -c '%U' "$MONITOR" 2>/dev/null || true)
    GROUP=$(stat -c '%G' "$MONITOR" 2>/dev/null || true)
    MODE=$(stat -c '%a' "$MONITOR" 2>/dev/null || true)
    [ "$OWNER" = agent-dev ] && pass "monitor.sh owner agent-dev" || fail "monitor.sh owner is $OWNER"
    [ "$GROUP" = agent-core ] && pass "monitor.sh group agent-core" || fail "monitor.sh group is $GROUP"
    [ "$MODE" = 750 ] && pass "monitor.sh mode 750" || fail "monitor.sh mode is $MODE"
    bash -n "$MONITOR" && pass "monitor.sh Bash syntax" || fail "monitor.sh Bash syntax"
    runuser -u agent-admin -- test -x "$MONITOR" && pass "agent-admin can execute monitor.sh" || fail "agent-admin cannot execute monitor.sh"
    ! runuser -u agent-test -- test -r "$MONITOR" && pass "agent-test cannot read monitor.sh" || fail "agent-test can read monitor.sh"
else
    fail "monitor.sh missing at $MONITOR"
fi

# 7) Agent process and port runtime checks.
AGENT_PROCESS_NAME="${AGENT_PROCESS_NAME:-agent-app}"
PID=$(pgrep -x "$AGENT_PROCESS_NAME" 2>/dev/null | head -n1 || true)
if [ -n "$PID" ]; then
    pass "Agent process running (PID $PID)"
    RUN_USER=$(ps -p "$PID" -o user= 2>/dev/null | awk '{print $1}')
    [ "$RUN_USER" != root ] && pass "Agent runs as non-root ($RUN_USER)" || fail "Agent runs as root"
else
    fail "Agent process not running"
fi

if ss -lnt 2>/dev/null | awk '$4 ~ /:15034$/ {ok=1} END{exit !ok}'; then
    pass "TCP 15034 LISTEN"
else
    fail "TCP 15034 not LISTEN"
fi

# 8) Runtime monitor log and fixed format.
if [ -s "$MONITOR_LOG" ]; then
    pass "monitor.log exists and is non-empty"
    LAST=$(tail -n1 "$MONITOR_LOG")
    if echo "$LAST" | grep -Eq '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] PID:[0-9]+ CPU:[0-9.]+% MEM:[0-9.]+% DISK_USED:[0-9.]+%$'; then
        pass "monitor.log format"
    else
        fail "monitor.log format"
    fi
else
    fail "monitor.log missing or empty"
fi

# Active monitor.log plus numbered rotations must stay at <= 10 files.
LOG_COUNT=$(find "$AGENT_LOG_DIR" -maxdepth 1 -type f \( -name 'monitor.log' -o -name 'monitor.log.[0-9]*' \) 2>/dev/null | wc -l)
[ "$LOG_COUNT" -le 10 ] && pass "monitor log file count <= 10" || fail "monitor log file count is $LOG_COUNT"

# 9) agent-admin cron every minute.
CRON=$(crontab -u agent-admin -l 2>/dev/null || true)
if echo "$CRON" | grep -Eq '^\* \* \* \* \* .*monitor\.sh'; then
    pass "agent-admin cron every minute"
else
    fail "agent-admin cron entry not confirmed"
fi

# 10) Repository Secret tracking check. Secret contents are never read.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd)
if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    TRACKED=$(git -C "$REPO_ROOT" ls-files | grep -E '(^|/)(\.env($|\.)|.*\.(key|pem)$|secrets/)' || true)
    [ -z "$TRACKED" ] && pass "no tracked Secret-pattern files" || fail "tracked Secret-pattern files detected"
fi

echo
printf 'Result: %d PASS / %d FAIL\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
