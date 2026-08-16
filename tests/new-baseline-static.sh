#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

expect_line() {
  local file="$1"
  local pattern="$2"
  grep -Eq "$pattern" "$file" || fail "$file missing expected pattern: $pattern"
}

printf '[1/5] Bash syntax\n'
for file in scripts/*.sh; do
  bash -n "$file"
done

printf '[2/5] Agent environment contract\n'
expect_line config/agent.env.example '^AGENT_HOME=/home/agent-admin/agent-app$'
expect_line config/agent.env.example '^AGENT_PORT=15034$'
expect_line config/agent.env.example '^AGENT_UPLOAD_DIR=/home/agent-admin/agent-app/upload_files$'
expect_line config/agent.env.example '^AGENT_KEY_PATH=/home/agent-admin/agent-app/api_keys/t_secret\.key$'
expect_line config/agent.env.example '^AGENT_LOG_DIR=/var/log/agent-app$'
expect_line config/agent.env.example '^AGENT_PROCESS_PATTERN=agent-app-linux-x86$'

printf '[3/5] monitor.sh mandatory contract\n'
expect_line scripts/monitor.sh 'AGENT_PORT="\$\{AGENT_PORT:-15034\}"'
expect_line scripts/monitor.sh 'CPU_WARN_THRESHOLD="\$\{CPU_WARN_THRESHOLD:-20\}"'
expect_line scripts/monitor.sh 'MEM_WARN_THRESHOLD="\$\{MEM_WARN_THRESHOLD:-10\}"'
expect_line scripts/monitor.sh 'DISK_WARN_THRESHOLD="\$\{DISK_WARN_THRESHOLD:-80\}"'
expect_line scripts/monitor.sh 'Agent process not found'
expect_line scripts/monitor.sh 'Agent port is not LISTEN'
expect_line scripts/monitor.sh 'firewall is inactive or could not be confirmed active'
expect_line scripts/monitor.sh 'failed to append monitor log'
expect_line scripts/monitor.sh 'PID:\$AGENT_PID CPU:\$\{CPU\}% MEM:\$\{MEM\}% DISK_USED:\$\{DISK_USED\}%'

printf '[4/5] cron/logrotate contract\n'
expect_line config/crontab.example '^\* \* \* \* \* /home/agent-admin/agent-app/bin/monitor\.sh >/dev/null 2>&1$'
expect_line config/agent-monitor.logrotate '^[[:space:]]*size 10M$'
expect_line config/agent-monitor.logrotate '^[[:space:]]*rotate 9$'
expect_line config/agent-monitor.logrotate '^[[:space:]]*create 0660 agent-admin agent-core$'

printf '[5/5] New baseline source/evidence contract\n'
test -f NEW-BASELINE.md || fail 'NEW-BASELINE.md missing'
test -f evidence/new-baseline-source-lock.md || fail 'G1 source evidence missing'
expect_line .live/mission-status.json '"cycle_id": "restart-20260816"'
expect_line .live/mission-status.json '"G1_SOURCE": "PASS"'
expect_line .live/mission-status.json '"current_gate": "G2_BUILD"'

printf 'PASS: B1-1 new-baseline static build contract\n'
