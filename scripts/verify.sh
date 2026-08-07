#!/usr/bin/env bash
# shellcheck disable=SC2015
# PASS/WARN/FAIL helpers always return success in the compact predicates below.
set -u

# B1-1 read-only state verifier.
# It checks current configuration/state only. It does NOT prove Boot Sequence,
# failure-injection behavior, cron growth, or evidence completeness.

LC_ALL=C
export LC_ALL

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
MISSION_KEY_SHA256='98f9221b6ea6e516a800246d3163969c3f718e22c79f184f8cb6d60b84b9e5cb'
pass() { printf '[PASS] %s\n' "$*"; PASS_COUNT=$((PASS_COUNT + 1)); }
warn() { printf '[WARN] %s\n' "$*"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { printf '[FAIL] %s\n' "$*"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

check_stat() {
  local path="$1" expected_owner="$2" expected_group="$3" expected_mode="$4" expected_type="$5"
  if [[ ! -e "$path" ]]; then fail "missing: $path"; return 1; fi
  if [[ -L "$path" ]]; then fail "symbolic link is not allowed: $path"; return 1; fi
  case "$expected_type" in
    directory)
      [[ -d "$path" ]] || { fail "not a directory: $path"; return 1; }
      ;;
    regular)
      [[ -f "$path" ]] || { fail "not a regular file: $path"; return 1; }
      ;;
    *)
      fail "internal verifier error: unsupported expected type '$expected_type' for $path"
      return 1
      ;;
  esac
  local actual
  actual="$(stat -c '%U:%G:%a' "$path" 2>/dev/null || true)"
  if [[ "$actual" == "${expected_owner}:${expected_group}:${expected_mode}" ]]; then
    pass "$path => $actual ($expected_type)"
    return 0
  fi
  fail "$path => $actual (expected ${expected_owner}:${expected_group}:${expected_mode}, $expected_type)"
  return 1
}

sshd_loaded_configs_have_only_safe_root_policy() {
  local config_file="$1" debug_output loaded_file
  local -a loaded_files=()

  # `sshd -T -C` proves one effective context only. The debug parse lists every
  # file reached through Include directives, so also reject a Match block that
  # could re-enable root login for another address, host, or user context.
  debug_output="$(sshd -T -ddd -f "$config_file" \
    -C user=root,host=localhost,addr=127.0.0.1 2>&1 || true)"
  mapfile -t loaded_files < <(
    sed -n '/^debug2: load_server_config: filename / {
      s/^debug2: load_server_config: filename //
      s/\r$//
      p
    }' <<< "$debug_output" | sort -u
  )
  (( ${#loaded_files[@]} > 0 )) || return 1

  for loaded_file in "${loaded_files[@]}"; do
    [[ -r "$loaded_file" ]] || return 1
    awk '
      {
        line = $0
        sub(/#.*/, "", line)
        sub(/^[[:space:]]+/, "", line)
        sub(/[[:space:]]+$/, "", line)
        if (line == "") next
        lower = tolower(line)
        if (lower ~ /^permitrootlogin([[:space:]]|=)/) {
          value = lower
          sub(/^permitrootlogin[[:space:]]*(=[[:space:]]*)?/, "", value)
          if (value != "no") unsafe = 1
        }
      }
      END { exit unsafe }
    ' "$loaded_file" || return 1
  done
  return 0
}

group_members_are_exact() {
  local group_name="$1" group_line group_gid listed_members actual expected
  local -a listed=()
  shift

  group_line="$(getent group "$group_name" 2>/dev/null)" || return 1
  IFS=: read -r _ _ group_gid listed_members <<< "$group_line"
  IFS=, read -r -a listed <<< "$listed_members"
  actual="$({
    printf '%s\n' "${listed[@]}"
    getent passwd | awk -F: -v gid="$group_gid" '$4 == gid { print $1 }'
  } | sed '/^$/d' | sort -u)"
  expected="$(printf '%s\n' "$@" | sort -u)"
  [[ "$actual" == "$expected" ]]
}

check_no_named_acl() {
  local path="$1" acl_output unexpected
  if ! command -v getfacl >/dev/null 2>&1; then
    fail "getfacl is required to verify core-only ACLs: $path"
    return
  fi
  if ! acl_output="$(getfacl -cp -- "$path" 2>/dev/null)"; then
    fail "could not read ACL: $path"
    return
  fi
  unexpected="$(awk -F: '
    /^(user|group):[^:]+:/ { print }
    /^default:(user|group):[^:]+:/ { print }
  ' <<< "$acl_output")"
  if [[ -n "$unexpected" ]]; then
    fail "unexpected named ACL grant(s) on $path: $unexpected"
  else
    pass "no unexpected named ACL grants: $path"
  fi
}

check_default_rw_acl() {
  local path="$1" acl_output
  if ! command -v getfacl >/dev/null 2>&1 \
    || ! acl_output="$(getfacl -cp -- "$path" 2>/dev/null)"; then
    fail "could not read default ACL: $path"
    return
  fi
  if [[ "$(grep -Fxc 'default:user::rwx' <<< "$acl_output")" -eq 1 \
    && "$(grep -Fxc 'default:group::rwx' <<< "$acl_output")" -eq 1 \
    && "$(grep -Fxc 'default:mask::rwx' <<< "$acl_output")" -eq 1 \
    && "$(grep -Fxc 'default:other::---' <<< "$acl_output")" -eq 1 ]]; then
    pass "default ACL preserves owner/group R/W collaboration: $path"
  else
    fail "default ACL must be u::rwx,g::rwx,m::rwx,o::---: $path"
  fi
}

escape_ere() {
  printf '%s' "$1" | sed 's/[][(){}.^$*+?|\\]/\\&/g'
}

resolve_process_pattern() {
  local env_file="$1" pattern=""
  if [[ -r "$env_file" ]]; then
    pattern="$(awk -F= '$1=="AGENT_PROCESS_PATTERN" {count++; value=substr($0,index($0,"=")+1)} END {if (count == 1) print value}' "$env_file")"
  fi
  if [[ -n "$pattern" ]]; then printf '%s' "$pattern"; return; fi
  case "$(uname -m 2>/dev/null || true)" in
    x86_64|amd64) printf '%s' 'agent-app-linux-x86' ;;
    aarch64|arm64) printf '%s' 'agent-app-linux-arm64' ;;
    *) return 1 ;;
  esac
}

is_self_or_ancestor_pid() {
  local candidate="$1" current="$$" parent

  while [[ "$current" =~ ^[0-9]+$ ]] && (( current > 0 )); do
    [[ "$candidate" == "$current" ]] && return 0
    parent="$(awk '/^PPid:/ { print $2; exit }' "/proc/${current}/status" 2>/dev/null || true)"
    [[ "$parent" =~ ^[0-9]+$ && "$parent" != "$current" ]] || break
    current="$parent"
  done
  return 1
}

process_signature_matches() {
  local pid="$1" exe_path exe_base expected_base arg index
  local -a expected=() actual=()

  exe_path="$(readlink -f -- "/proc/${pid}/exe" 2>/dev/null || true)"
  [[ -n "$exe_path" && -r "/proc/${pid}/cmdline" ]] || return 1
  exe_base="${exe_path##*/}"
  while IFS= read -r -d '' arg; do actual+=("$arg"); done < "/proc/${pid}/cmdline"
  (( ${#actual[@]} > 0 )) || return 1
  read -r -a expected <<< "$AGENT_PROCESS_PATTERN"
  (( ${#expected[@]} > 0 )) || return 1

  if (( ${#expected[@]} == 1 )) && [[ "${expected[0]}" == *.py ]]; then
    case "$exe_base" in
      python|python[0-9]*|pypy|pypy[0-9]*) ;;
      *) return 1 ;;
    esac
    for (( index = 1; index < ${#actual[@]}; index++ )); do
      [[ "${actual[index]##*/}" == "${expected[0]##*/}" ]] && return 0
    done
    return 1
  fi

  expected_base="${expected[0]##*/}"
  [[ "$exe_base" == "$expected_base" && "${actual[0]##*/}" == "$expected_base" ]] || return 1
  (( ${#actual[@]} >= ${#expected[@]} )) || return 1
  for (( index = 1; index < ${#expected[@]}; index++ )); do
    [[ "${actual[index]}" == "${expected[index]}" ]] || return 1
  done
  return 0
}

find_agent_pids() {
  local pid found=1
  while IFS= read -r pid; do
    [[ "$pid" =~ ^[0-9]+$ ]] || continue
    is_self_or_ancestor_pid "$pid" && continue
    if process_signature_matches "$pid"; then
      printf '%s\n' "$pid"
      found=0
    fi
  done < <(pgrep -f -- "$AGENT_PROCESS_REGEX" 2>/dev/null || true)
  return "$found"
}

env_value_is_exactly_once() {
  local file="$1" key="$2" expected_value="$3" actual
  actual="$(awk -F= -v key="$key" '
    $1 == key { count++; value=substr($0,index($0,"=")+1) }
    END { if (count != 1) exit 1; print value }
  ' "$file")" || return 1
  [[ "$actual" == "$expected_value" ]]
}

cron_policy_is_exact() {
  awk '
    function trim(value) {
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      return value
    }
    /^[[:space:]]*($|#)/ { next }
    /^[[:space:]]*SHELL[[:space:]]*=/ {
      shell_count++
      shell_value = (trim($0) == "SHELL=/bin/bash")
      next
    }
    /^[[:space:]]*PATH[[:space:]]*=/ {
      path_count++
      path_value = (trim($0) == "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")
      next
    }
    /^[[:space:]]*MAILTO[[:space:]]*=/ {
      mailto_count++
      mailto_value = (trim($0) == "MAILTO=\"\"")
      next
    }
    /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=/ {
      unexpected_assignments++
      next
    }
    index($0, "/home/agent-admin/agent-app/bin/monitor.sh") {
      monitor_refs++
      line = trim($0)
      if (line ~ /^\* +\* +\* +\* +\* +\/home\/agent-admin\/agent-app\/bin\/monitor[.]sh( +>\/dev\/null +2>&1)?$/ \
          && shell_value && path_value) valid_jobs++
      next
    }
    END {
      exit !(shell_count == 1 && path_count == 1 \
             && (mailto_count == 0 || (mailto_count == 1 && mailto_value)) \
             && unexpected_assignments == 0 \
             && monitor_refs == 1 && valid_jobs == 1)
    }
  ' <<< "$1"
}

logrotate_policy_is_exact() {
  local file="$1"
  awk '
    function trim(value) {
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      return value
    }
    {
      line = $0
      sub(/#.*/, "", line)
      line = trim(line)
      if (line == "") next
      if (!inside && line ~ /^\/var\/log\/agent-app\/monitor[.]log[[:space:]]*\{$/) {
        target_count++
        inside = 1
        size_count = rotate_count = compress_count = missingok_count = 0
        notifempty_count = su_count = create_count = other_count = 0
        size_ok = rotate_ok = su_ok = create_ok = 0
        next
      }
      if (inside && line == "}") {
        if (size_count == 1 && size_ok == 1 \
            && rotate_count == 1 && rotate_ok == 1 \
            && compress_count == 1 && missingok_count == 1 && notifempty_count == 1 \
            && su_count == 1 && su_ok == 1 \
            && create_count == 1 && create_ok == 1 \
            && other_count == 0) valid_count++
        inside = 0
        next
      }
      if (inside) {
        fields = split(line, part, /[[:space:]]+/)
        if (part[1] == "size") {
          size_count++
          if (fields == 2 && part[2] == "10M") size_ok++
        } else if (part[1] == "rotate") {
          rotate_count++
          if (fields == 2 && part[2] == "9") rotate_ok++
        } else if (part[1] == "compress" && fields == 1) {
          compress_count++
        } else if (part[1] == "missingok" && fields == 1) {
          missingok_count++
        } else if (part[1] == "notifempty" && fields == 1) {
          notifempty_count++
        } else if (part[1] == "su") {
          su_count++
          if (fields == 3 && part[2] == "agent-admin" && part[3] == "agent-core") su_ok++
        } else if (part[1] == "create") {
          create_count++
          if (fields == 4 && part[2] == "0660" && part[3] == "agent-admin" && part[4] == "agent-core") create_ok++
        } else {
          other_count++
        }
      }
    }
    END { exit !(target_count == 1 && valid_count == 1 && !inside) }
  ' "$file"
}

# Allow isolated function fixtures without executing current-state checks.
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  return 0
fi

printf 'B1-1 read-only state verifier\n'
printf '%s\n' '----------------------------------------'
[[ "$EUID" -eq 0 ]] || warn 'Run as root for complete verification: sudo bash scripts/verify.sh'

printf '\n[ssh]\n'
if command -v sshd >/dev/null 2>&1; then
  if sshd -t 2>/dev/null; then
    pass 'sshd configuration syntax is valid'
  else
    fail 'sshd -t failed; effective SSH policy cannot be trusted'
  fi
  if SSHD_EFFECTIVE="$(sshd -T -C user=root,host=localhost,addr=127.0.0.1 2>/dev/null)" \
    && [[ -n "$SSHD_EFFECTIVE" ]]; then
    grep -Fxq 'port 20022' <<<"$SSHD_EFFECTIVE" && pass 'sshd effective port=20022' || fail 'sshd effective port is not 20022'
    grep -Fxq 'permitrootlogin no' <<<"$SSHD_EFFECTIVE" && pass 'PermitRootLogin=no for a root connection context' || fail 'PermitRootLogin is not no for a root connection context'
  else
    fail 'sshd effective configuration could not be evaluated for root context'
    grep -Eq '^[[:space:]]*Port[[:space:]]+20022([[:space:]]|$)' /etc/ssh/sshd_config.d/99-b1-1.conf 2>/dev/null && warn 'static SSH Port 20022 found, but effective config is unverified' || fail 'static SSH Port 20022 not found'
    grep -Eq '^[[:space:]]*PermitRootLogin[[:space:]]+no([[:space:]]|$)' /etc/ssh/sshd_config.d/99-b1-1.conf 2>/dev/null && warn 'static PermitRootLogin no found, but Match overrides are unverified' || fail 'static PermitRootLogin no not found'
  fi
  if sshd_loaded_configs_have_only_safe_root_policy /etc/ssh/sshd_config; then
    pass 'all loaded PermitRootLogin directives are exactly no (including Match/Include files)'
  else
    fail 'loaded SSH configuration contains an unsafe PermitRootLogin override or could not be fully inspected'
  fi
else
  fail 'sshd command missing'
fi

SS_OUTPUT="$(ss -lntpH 2>/dev/null || true)"
awk '$4 ~ /:20022$/ && ($0 ~ /"sshd"/ || $0 ~ /"systemd"/) {found=1} END {exit !found}' <<<"$SS_OUTPUT" && pass 'TCP 20022 is LISTEN via sshd/systemd socket activation' || fail 'TCP 20022 sshd/systemd listener is not confirmed'
awk '$4 ~ /:22$/ {found=1} END {exit !found}' <<<"$SS_OUTPUT" && fail 'TCP 22 is still LISTEN' || pass 'TCP 22 is not LISTEN'

printf '\n[ufw]\n'
if command -v ufw >/dev/null 2>&1; then
  UFW_OUTPUT="$(ufw status verbose 2>/dev/null || true)"
  grep -Fq 'Status: active' <<<"$UFW_OUTPUT" && pass 'UFW active' || fail 'UFW not confirmed active'
  grep -Eq '^Default: deny \(incoming\)' <<<"$UFW_OUTPUT" && pass 'UFW default incoming deny' || fail 'UFW default incoming is not deny'
  awk '$1 == "20022/tcp" && $0 !~ /\(v6\)/ && $0 ~ /ALLOW IN/ {found=1} END {exit !found}' <<<"$UFW_OUTPUT" && pass 'UFW allows IPv4 20022/tcp' || fail 'UFW IPv4 20022/tcp allow missing'
  awk '$1 == "15034/tcp" && $0 !~ /\(v6\)/ && $0 ~ /ALLOW IN/ {found=1} END {exit !found}' <<<"$UFW_OUTPUT" && pass 'UFW allows IPv4 15034/tcp' || fail 'UFW IPv4 15034/tcp allow missing'
  UNEXPECTED_RULES="$(awk '/ALLOW IN/ && $1 != "20022/tcp" && $1 != "15034/tcp" {print}' <<<"$UFW_OUTPUT")"
  [[ -z "$UNEXPECTED_RULES" ]] && pass 'no unexpected UFW ALLOW IN rules' || fail "unexpected UFW ALLOW IN rule(s): $UNEXPECTED_RULES"
else
  fail 'ufw command missing'
fi

printf '\n[users-groups]\n'
for user in agent-admin agent-dev agent-test; do
  id "$user" >/dev/null 2>&1 && pass "user exists: $user" || fail "user missing: $user"
done
group_members_are_exact agent-common agent-admin agent-dev agent-test \
  && pass 'agent-common contains exactly agent-admin, agent-dev, agent-test' \
  || fail 'agent-common membership has a missing or unexpected user'
group_members_are_exact agent-core agent-admin agent-dev \
  && pass 'agent-core contains exactly agent-admin, agent-dev' \
  || fail 'agent-core membership has a missing or unexpected user'

printf '\n[filesystem-acl]\n'
check_stat /home/agent-admin/agent-app agent-admin agent-common 2750 directory
check_stat /home/agent-admin/agent-app/upload_files agent-admin agent-common 2770 directory
check_stat /home/agent-admin/agent-app/api_keys agent-admin agent-core 2770 directory
check_stat /var/log/agent-app agent-admin agent-core 2770 directory
[[ -d /home/agent-admin/agent-app/upload_files ]] && check_no_named_acl /home/agent-admin/agent-app/upload_files
[[ -d /home/agent-admin/agent-app/api_keys ]] && check_no_named_acl /home/agent-admin/agent-app/api_keys
[[ -d /var/log/agent-app ]] && check_no_named_acl /var/log/agent-app
[[ -d /home/agent-admin/agent-app/upload_files ]] && check_default_rw_acl /home/agent-admin/agent-app/upload_files
[[ -d /home/agent-admin/agent-app/api_keys ]] && check_default_rw_acl /home/agent-admin/agent-app/api_keys
[[ -d /var/log/agent-app ]] && check_default_rw_acl /var/log/agent-app
if command -v getfacl >/dev/null 2>&1 && getfacl -cp /home/agent-admin 2>/dev/null | grep -Fxq 'group:agent-common:--x'; then
  pass 'agent-common traverse ACL exists on /home/agent-admin'
else
  fail 'agent-common traverse ACL on /home/agent-admin not confirmed'
fi
if [[ "$EUID" -eq 0 ]] && command -v sudo >/dev/null 2>&1; then
  for traverse_user in agent-dev agent-test; do
    if sudo -n -u "$traverse_user" bash -c 'test -x "$1" && ! test -r "$1" && ! test -w "$1"' bash /home/agent-admin; then
      pass "$traverse_user has traverse-only access to /home/agent-admin"
    else
      fail "$traverse_user must have traverse-only access to /home/agent-admin"
    fi
  done
else
  fail 'root with sudo is required to verify effective parent-home traversal'
fi

printf '\n[agent-env-key]\n'
ENV_FILE=/etc/agent-app/agent.env
if [[ -r "$ENV_FILE" ]]; then
  pass "$ENV_FILE readable"
  if [[ -L "$ENV_FILE" ]]; then
    fail "$ENV_FILE must not be a symbolic link"
  else
    check_stat "$ENV_FILE" root agent-core 640 regular
  fi
  if awk '
    /^[[:space:]]*($|#)/ { next }
    /^(AGENT_HOME|AGENT_PORT|AGENT_UPLOAD_DIR|AGENT_KEY_PATH|AGENT_LOG_DIR|AGENT_PROCESS_PATTERN)=/ { next }
    { invalid=1 }
    END { exit invalid }
  ' "$ENV_FILE"; then
    pass 'agent.env contains only supported simple assignments/comments'
  else
    fail 'agent.env contains an unsupported or executable shell line'
  fi
  if awk -F= '
    /^[[:space:]]*($|#)/ { next }
    { if (++seen[$1] > 1) duplicate=1 }
    END { exit duplicate }
  ' "$ENV_FILE"; then
    pass 'agent.env has no duplicate keys'
  else
    fail 'agent.env contains a duplicate key'
  fi
  env_value_is_exactly_once "$ENV_FILE" AGENT_HOME /home/agent-admin/agent-app && pass 'AGENT_HOME correct and unique' || fail 'AGENT_HOME incorrect or duplicated'
  env_value_is_exactly_once "$ENV_FILE" AGENT_PORT 15034 && pass 'AGENT_PORT correct and unique' || fail 'AGENT_PORT incorrect or duplicated'
  env_value_is_exactly_once "$ENV_FILE" AGENT_UPLOAD_DIR /home/agent-admin/agent-app/upload_files && pass 'AGENT_UPLOAD_DIR correct and unique' || fail 'AGENT_UPLOAD_DIR incorrect or duplicated'
  env_value_is_exactly_once "$ENV_FILE" AGENT_KEY_PATH /home/agent-admin/agent-app/api_keys/t_secret.key && pass 'AGENT_KEY_PATH correct and unique' || fail 'AGENT_KEY_PATH incorrect or duplicated'
  env_value_is_exactly_once "$ENV_FILE" AGENT_LOG_DIR /var/log/agent-app && pass 'AGENT_LOG_DIR correct and unique' || fail 'AGENT_LOG_DIR incorrect or duplicated'
else
  fail "$ENV_FILE missing or unreadable"
fi
check_stat /home/agent-admin/agent-app/api_keys/t_secret.key agent-admin agent-core 660 regular
[[ -f /home/agent-admin/agent-app/api_keys/t_secret.key ]] && check_no_named_acl /home/agent-admin/agent-app/api_keys/t_secret.key
if [[ -f /home/agent-admin/agent-app/api_keys/t_secret.key ]] \
  && awk 'NR == 1 { nonempty = (length($0) > 0) } NR > 1 { extra = 1 } END { exit !(nonempty && !extra) }' /home/agent-admin/agent-app/api_keys/t_secret.key; then
  pass 'key file contains exactly one non-empty line without printing its value'
else
  fail 'key file must contain exactly one non-empty line'
fi
if command -v sha256sum >/dev/null 2>&1 && [[ -f /home/agent-admin/agent-app/api_keys/t_secret.key ]]; then
  KEY_SHA256="$(sha256sum -- /home/agent-admin/agent-app/api_keys/t_secret.key | awk '{ print $1 }')"
  [[ "$KEY_SHA256" == "$MISSION_KEY_SHA256" ]] \
    && pass 'key file matches the mission value by one-way digest without printing the value' \
    || fail 'key file does not match the mission value'
else
  fail 'sha256sum or key file unavailable for secret-safe value verification'
fi

printf '\n[agent-runtime]\n'
AGENT_PROCESS_PATTERN="$(resolve_process_pattern "$ENV_FILE" || true)"
AGENT_PID=""
AGENT_LISTENER_PID=""
if [[ -z "$AGENT_PROCESS_PATTERN" ]]; then
  fail 'Agent process signature is unavailable for this architecture/env file'
else
  AGENT_PROCESS_REGEX="(^|[[:space:]/])$(escape_ere "$AGENT_PROCESS_PATTERN")([[:space:]]|$)"
  mapfile -t AGENT_PIDS < <(find_agent_pids || true)
  if (( ${#AGENT_PIDS[@]} > 0 )); then
    AGENT_PID="${AGENT_PIDS[0]}"
    for candidate_pid in "${AGENT_PIDS[@]}"; do
      if awk -v pid="$candidate_pid" '$4 == "0.0.0.0:15034" && $0 ~ ("pid=" pid "([^0-9]|$)") {found=1} END {exit !found}' <<< "$SS_OUTPUT"; then
        AGENT_PID="$candidate_pid"
        AGENT_LISTENER_PID="$candidate_pid"
        break
      fi
    done
  fi
fi
if [[ -n "$AGENT_PID" ]]; then
  AGENT_USER="$(ps -o user= -p "$AGENT_PID" 2>/dev/null | tr -d '[:space:]')"
  [[ -n "$AGENT_USER" && "$AGENT_USER" != root ]] && pass "Agent process non-root: pid=$AGENT_PID user=$AGENT_USER pattern=$AGENT_PROCESS_PATTERN" || fail "Agent process owner invalid: pid=$AGENT_PID user=${AGENT_USER:-unknown}"
else
  fail "Agent process not found: pattern=$AGENT_PROCESS_PATTERN"
fi
if [[ -n "$AGENT_LISTENER_PID" ]]; then
  pass "Agent PID $AGENT_LISTENER_PID owns 0.0.0.0:15034 LISTEN"
else
  fail 'selected Agent PID does not own 0.0.0.0:15034 LISTEN'
fi

printf '\n[monitor]\n'
MONITOR=/home/agent-admin/agent-app/bin/monitor.sh
check_stat "$MONITOR" agent-dev agent-core 750 regular
[[ -f "$MONITOR" ]] && bash -n "$MONITOR" && pass 'deployed monitor.sh Bash syntax OK' || fail 'deployed monitor.sh Bash syntax failed or file missing'
LOG=/var/log/agent-app/monitor.log
if [[ -s "$LOG" ]]; then
  LAST_LINE="$(tail -n 1 "$LOG")"
  grep -Eq '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] PID:[0-9]+ CPU:[0-9]+(\.[0-9]+)?% MEM:[0-9]+(\.[0-9]+)?% DISK_USED:[0-9]+%$' <<<"$LAST_LINE" \
    && pass 'monitor.log last line matches required format' || fail "monitor.log format mismatch: $LAST_LINE"
  check_stat "$LOG" agent-admin agent-core 660 regular
  check_no_named_acl "$LOG"
else
  fail 'monitor.log missing or empty'
fi

printf '\n[cron-logrotate]\n'
CRON_OUTPUT="$(crontab -u agent-admin -l 2>/dev/null || true)"
if cron_policy_is_exact "$CRON_OUTPUT"; then
  pass 'agent-admin has one every-minute monitor job with safe SHELL/PATH/MAILTO and no execution overrides'
else
  fail 'agent-admin cron must have safe unique env lines before one exact every-minute monitor job and no overrides'
fi
ROTATE=/etc/logrotate.d/agent-monitor
if [[ -r "$ROTATE" ]]; then
  if logrotate_policy_is_exact "$ROTATE"; then
    pass 'target monitor.log stanza has exact size/rotate/su/create policy'
  else
    fail 'target monitor.log stanza does not have exact 10M/9/core/0660 policy'
  fi
else
  fail "$ROTATE missing or unreadable"
fi

printf '\n[repository-secret-files]\n'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
if command -v git >/dev/null 2>&1 && git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  TRACKED_SECRETS="$(git -C "$REPO_ROOT" ls-files | grep -E '(^|/)([^/]*\.key|[^/]*\.env($|\.))' | grep -vE '\.env\.example$' || true)"
  [[ -z "$TRACKED_SECRETS" ]] && pass 'no obvious tracked .key/.env secret files' || fail "possible tracked secret files: $TRACKED_SECRETS"
else
  warn 'repository secret-file check skipped: Git worktree not detected'
fi

printf '\n[summary]\n'
printf 'PASS=%d WARN=%d FAIL=%d\n' "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"
if (( FAIL_COUNT > 0 )); then
  printf '[FAIL] B1-1 current-state verification has blocking items.\n'
  exit 1
fi

printf '[PASS] B1-1 current-state checks passed.\n'
printf '[NEXT] Final mission PASS still requires runtime acceptance tests, Boot/READY evidence, cron-growth observation, and evidence review.\n'
exit 0
