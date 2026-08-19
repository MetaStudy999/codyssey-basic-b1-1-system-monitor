# B1-1 모듈 07 — STEP 13 증빙 자료(Evidence)

> [← STEP 12](01-verification.md) · [모듈 07 목차](README.md) · [다음: STEP 14 →](03-evaluation-qa.md)

<a id="step-13"></a>
## STEP 13 — 실제 증빙 자료(Evidence) 수집·검토·연결

## ① 왜 하는가

공식 B1-1은 단순히 설정을 만들어 놓는 것으로 끝나지 않고, **실제로 수행한 설정과 실행 결과를 명령어 출력 또는 화면 캡처로 증빙**할 수 있어야 합니다. 공식 Mission도 SSH, 방화벽, 계정/그룹/ACL, Agent Boot 5단계와 `Agent READY`, `monitor.sh`, `monitor.log`, cron 자동 실행을 필수 증거 자료로 요구합니다.

STEP 03~12에서 수행한 검증 결과가 있더라도, 서로 다른 Terminal·시간·임시 시험 결과가 흩어져 있으면 평가자가 어떤 요구사항을 어떤 결과가 증명하는지 다시 추적하기 어렵습니다. 따라서 이 STEP에서는 **요구사항(Requirement) → 구현(Implementation) → 검증(Verification) → 증빙 자료(Evidence)** 연결을 기준으로 현재 R01의 실제 결과만 정리합니다.

> 문서에 적힌 예상 결과, 과거 Round 결과, Reference 예시, 다른 사람의 캡처는 현재 R01 Evidence가 아닙니다. 실제로 실행하지 않은 항목은 Evidence 완료로 표시하지 않습니다.

## ② 무엇을 하는가

1. STEP 12에서 실제 `verify.sh`가 `0 FAIL`이었는지 확인합니다.
2. 현재 Repository/Branch/Commit과 Evidence 수집 시각을 기록해 증빙의 출처(Provenance)를 남깁니다.
3. 기존 `evidence/README.md`와 `docs/requirements-mapping.md`의 R01~R22 연결표를 기준으로 필요한 증거 묶음을 확인합니다.
4. 바로 Repository에 파일을 만들기보다 `/tmp`의 고유 임시 디렉터리에 먼저 안전한 출력만 수집합니다.
5. Secret 값을 읽지 않는 명령만 사용합니다. 특히 `t_secret.key`는 `test -s`, `stat` 등 메타데이터만 기록합니다.
6. SSH, UFW, 사용자/그룹/ACL, Agent, monitor, 로그 회전, cron, 통합 검증 결과를 요구사항별 파일로 분리합니다.
7. 실제 새 SSH 세션, Agent Boot 5/5, cron Before/After처럼 자동 수집만으로 맥락이 부족한 항목은 해당 STEP에서 확보한 실제 Terminal 결과 또는 안전한 캡처를 사용합니다.
8. 수집 파일을 Repository에 복사하기 전에 Secret·Password·Token·Private Key·불필요한 개인정보/네트워크 정보가 없는지 사람이 직접 검토합니다.
9. 민감정보가 섞인 자료는 그대로 편집해 사실을 왜곡하지 말고, 더 안전한 명령으로 다시 수집하는 것을 우선합니다.
10. 검토가 끝난 파일만 `training/round-01-clear/evidence/` 아래 현재 R01 Evidence로 옮깁니다.
11. `docs/requirements-mapping.md`의 각 Requirement와 실제 Evidence 파일을 대응시킵니다.
12. Evidence가 모두 준비되어도 STEP 14 설명형 평가와 STEP 15 CLEAR Gate 전에는 Mission CLEAR로 기록하지 않습니다.

## ③ 이번 단계에서 알아야 할 용어

- **증빙 자료(Evidence)** — 요구사항을 실제로 수행했다는 사실을 제3자가 다시 확인할 수 있는 출력·로그·캡처입니다.
- **추적성(Traceability)** — 요구사항에서 구현, 검증, 증빙까지 연결이 끊기지 않는 성질입니다.
- **출처 정보(Provenance)** — 어떤 Repository/Commit/Runtime/시점에서 결과가 생성되었는지 보여 주는 정보입니다.
- **원시 증거(Raw Evidence)** — 실제 명령·프로그램이 생성한 원본 결과입니다.
- **민감정보 삭제(Redaction)** — 공개할 필요가 없는 민감한 일부 정보를 표시적으로 가리는 처리입니다. PASS/FAIL 자체를 바꾸는 용도로 사용하지 않습니다.
- **검증 가능한 증거(Verifiable Evidence)** — 다른 사람이 명령, 경로, 시각, 설정을 보고 요구사항 충족 여부를 판단할 수 있는 증거입니다.
- **증거 묶음(Evidence Bundle)** — 하나의 R01 실행에 대해 관련 증거 파일을 체계적으로 모은 집합입니다.
- **거짓 증거(False Evidence)** — 예상 출력, 수동으로 만든 성공 문자열, 다른 실행 결과를 현재 수행 결과처럼 사용하는 자료입니다.

## ④ 필요한 핵심 개념

```mermaid
flowchart TD
    A[공식 Mission / Evaluation] --> B[Requirement ID R01~R22]
    B --> C[실제 STEP 03~12 Runtime 결과]
    C --> D[/tmp 안전한 Evidence staging]
    D --> E[Secret / 민감정보 검토]
    E -->|안전| F[Repository Evidence bundle]
    E -->|위험| G[더 안전한 명령으로 재수집]
    G --> D
    F --> H[Requirement Mapping 연결]
    H --> I[Evidence completeness review]
    I --> J[STEP 14 Evaluation Q&A]
```

### Evidence의 세 가지 등급을 구분

```text
Reference / 예상 결과
→ 학습용 예시
→ Evidence 아님

실제 Runtime 출력이지만 요구사항과 연결되지 않음
→ 자료는 있으나 추적성 부족
→ Evidence 후보

현재 R01 실제 Runtime 출력
+ Requirement ID 연결
+ Secret 없음
+ 출처 정보 확인 가능
→ 제출 가능한 Evidence
```

### Redaction과 조작을 구분

공개할 필요가 없는 IP 주소 같은 정보가 포함되면 최소 범위로 가릴 수 있습니다. 그러나 다음 값은 요구사항 판정에 필요한 경우 임의 변경하지 않습니다.

```text
포트 번호
PASS / FAIL
exit code
사용자 역할(agent-admin/dev/test)
파일 owner/group/mode
Boot 5/5 상태
Agent READY 여부
cron 시간 흐름
로그 회전 파일 수와 크기
```

필수 증명값까지 가려야 할 정도로 원본 출력이 위험하면 기존 파일을 편집하는 것보다 **필요한 필드만 출력하는 안전한 명령으로 다시 수집**합니다.

## ⑤ 실행할 명령어 또는 코드

### 📍 실행 위치(Context)

```text
Host       : OrbStack Ubuntu 24.04 또는 WSL2 Ubuntu 24.04
Terminal A : 필요 시 STEP 07부터 유지 중인 Agent foreground Terminal
Terminal B : Ubuntu Bash — Evidence 수집·검토
Repository : $HOME/codyssey/codyssey-basic-b1-1-system-monitor
권한       : 일반 사용자 + 시스템 읽기에서 필요한 줄만 sudo
venv       : 해당 없음
전제       : STEP 12 실제 Verification Gate 통과
```

### A. Evidence 수집 전 Repository 출처 정보 확인

```bash
cd "$HOME/codyssey/codyssey-basic-b1-1-system-monitor"
pwd
git branch --show-current
git status --short
git rev-parse HEAD
date --iso-8601=seconds
```

`git status --short`에 예상하지 않은 변경이 있으면 Evidence를 수집하기 전에 그 출처를 확인합니다. 현재 실행과 무관한 미완성 변경이 섞인 상태를 제출 기준선으로 사용하지 않습니다.

### B. 이번 실행 전용 안전한 staging 디렉터리 만들기

```bash
EVIDENCE_STAGE="$(mktemp -d /tmp/b1-1-evidence.XXXXXX)"
printf '[INFO] evidence staging=%s\n' "$EVIDENCE_STAGE"

case "$EVIDENCE_STAGE" in
    /tmp/b1-1-evidence.*)
        echo '[PASS] staging path confirmed'
        ;;
    *)
        echo '[STOP] unexpected staging path'
        ;;
esac
```

Repository에 바로 저장하지 않고 `/tmp`에서 먼저 검토하므로 실수로 민감한 출력을 Git에 추가하는 위험을 줄입니다.

### C. Evidence context 파일 만들기

```bash
{
    printf 'captured_at=%s\n' "$(date --iso-8601=seconds)"
    printf 'repository=%s\n' "$(pwd)"
    printf 'branch=%s\n' "$(git branch --show-current)"
    printf 'commit=%s\n' "$(git rev-parse HEAD)"
    printf 'architecture=%s\n' "$(uname -m)"
    . /etc/os-release
    printf 'os=%s %s\n' "$NAME" "$VERSION_ID"
} > "$EVIDENCE_STAGE/00-context.txt"
```

이 파일은 현재 Evidence가 어떤 Runtime/Commit에서 생성되었는지 확인하는 출처 정보입니다. Secret은 포함하지 않습니다.

### D. SSH 설정 Evidence

Ubuntu Terminal에서:

```bash
{
    sudo sshd -T | grep -E '^(port|permitrootlogin) '
    sudo ss -lntp | grep ':20022'
} > "$EVIDENCE_STAGE/01-ssh-config.txt"
```

STEP 03에서 실제 `ssh -p 20022 ...`로 들어온 **새 SSH 세션 안에서** 다음처럼 서버 포트와 비-root 사용자만 안전하게 남길 수 있습니다.

```bash
{
    printf 'session_user=%s\n' "$(whoami)"
    printf '%s\n' "$SSH_CONNECTION" | awk '{print "server_port=" $4}'
} > "$EVIDENCE_STAGE/01-ssh-session.txt"
```

`SSH_CONNECTION` 전체를 저장하면 IP 주소가 함께 들어갈 수 있으므로 위 명령은 공식 판정에 필요한 서버 포트 필드만 남깁니다.

### E. UFW Evidence

```bash
{
    sudo ufw status verbose
    echo '--- numbered rules ---'
    sudo ufw status numbered
} > "$EVIDENCE_STAGE/02-firewall.txt"
```

이 출력에서 UFW active, 기본 incoming deny, `20022/tcp`, `15034/tcp`, 불필요한 추가 `ALLOW IN`이 없는지를 확인합니다.

### F. 사용자·그룹·ACL Evidence

```bash
{
    id agent-admin
    id agent-dev
    id agent-test
    getent group agent-common
    getent group agent-core
    echo '--- owner/group/mode ---'
    sudo stat -c '%U %G %a %n' \
      /opt/agent-app \
      /opt/agent-app/upload_files \
      /opt/agent-app/api_keys \
      /opt/agent-app/bin \
      /var/log/agent-app
    echo '--- ACL ---'
    sudo getfacl -p \
      /opt/agent-app/upload_files \
      /opt/agent-app/api_keys \
      /var/log/agent-app
} > "$EVIDENCE_STAGE/03-users-groups-permissions.txt"
```

역할별 실제 접근 결과도 별도 파일로 남깁니다.

```bash
{
    for u in agent-admin agent-dev agent-test; do
        sudo runuser -u "$u" -- test -r /opt/agent-app/upload_files \
          && sudo runuser -u "$u" -- test -w /opt/agent-app/upload_files \
          && echo "[PASS] $u upload_files read/write" \
          || echo "[FAIL] $u upload_files read/write"
    done

    for u in agent-admin agent-dev; do
        sudo runuser -u "$u" -- test -r /opt/agent-app/api_keys \
          && sudo runuser -u "$u" -- test -w /opt/agent-app/api_keys \
          && echo "[PASS] $u api_keys read/write" \
          || echo "[FAIL] $u api_keys read/write"
    done

    if ! sudo runuser -u agent-test -- test -r /opt/agent-app/api_keys \
       && ! sudo runuser -u agent-test -- test -w /opt/agent-app/api_keys; then
        echo '[PASS] agent-test blocked from api_keys'
    else
        echo '[FAIL] agent-test can access api_keys'
    fi
} > "$EVIDENCE_STAGE/04-effective-access.txt"
```

### G. 환경변수와 Secret 메타데이터 Evidence

비밀값이 없는 환경 설정은 필요한 필드만 출력합니다.

```bash
sudo runuser -u agent-admin -- bash -c '
  source /opt/agent-app/env.sh
  printf "AGENT_HOME=%s\n" "$AGENT_HOME"
  printf "AGENT_PORT=%s\n" "$AGENT_PORT"
  printf "AGENT_UPLOAD_DIR=%s\n" "$AGENT_UPLOAD_DIR"
  printf "AGENT_KEY_PATH=%s\n" "$AGENT_KEY_PATH"
  printf "AGENT_LOG_DIR=%s\n" "$AGENT_LOG_DIR"
' > "$EVIDENCE_STAGE/05-environment.txt"
```

Secret은 **값을 읽지 않고** 존재와 메타데이터만 남깁니다.

```bash
{
    sudo test -s /opt/agent-app/api_keys/t_secret.key \
      && echo '[PASS] Secret file exists and is non-empty; value not read' \
      || echo '[FAIL] Secret file missing or empty'
    sudo stat -c '%U %G %a %s %n' /opt/agent-app/api_keys/t_secret.key
} > "$EVIDENCE_STAGE/05-secret-metadata.txt"
```

다음과 같은 명령은 Evidence 수집에 사용하지 않습니다.

```text
cat /opt/agent-app/api_keys/t_secret.key
head /opt/agent-app/api_keys/t_secret.key
tail /opt/agent-app/api_keys/t_secret.key
grep <실제 Secret 값> ...
set -x
```

### H. Agent Boot / Process / TCP 15034 Evidence

Boot 5/5와 `Agent READY`는 **STEP 07에서 실제 제공 Agent를 실행했을 때의 출력**을 사용합니다. 제공 앱의 출력 형식이 바뀔 수 있으므로 Boot stdout 전체를 자동으로 파일에 redirect하기 전에 민감정보가 출력되지 않는지 먼저 확인합니다.

안전하게 별도로 재수집 가능한 Process/Port Evidence:

```bash
{
    pgrep -a -x agent-app
    ps -C agent-app -o user=,uid=,pid=,comm=,args=
    sudo ss -lntp | grep ':15034'
} > "$EVIDENCE_STAGE/06-agent-runtime.txt"
```

STEP 07의 실제 화면에서 다음이 모두 확인된 캡처 또는 Secret이 제거된 안전한 실제 출력이 필요합니다.

```text
Boot 1/5 ~ 5/5 모두 [OK]
Agent READY
실행 user = agent-admin
UID != 0
0.0.0.0:15034 LISTEN
```

문서의 예상 Boot 예시를 복사해 `06-agent-boot.txt`로 만들지 않습니다.

### I. monitor 정상 실행 / 로그 Evidence

STEP 08의 실제 정상 실행 결과를 사용합니다. 현재 상태를 안전하게 다시 확인할 때는 다음 메타데이터와 최신 로그를 수집할 수 있습니다.

```bash
{
    sudo stat -c '%U %G %a %s %n' /opt/agent-app/bin/monitor.sh
    sudo stat -c '%U %G %a %s %n' /var/log/agent-app/monitor.log
    sudo tail -n 3 /var/log/agent-app/monitor.log
} > "$EVIDENCE_STAGE/07-monitor-log.txt"
```

`monitor.sh` 정상 실행 콘솔의 Process/Port/CPU/MEM/DISK/Warning/`monitor_exit=0` 결과는 STEP 08에서 실제로 수행한 출력을 사용합니다.

### J. 로그 회전 Evidence

STEP 09의 격리 시험에서 확보한 실제 결과를 사용합니다. 최소한 다음 사실을 한 자료에서 추적할 수 있어야 합니다.

```text
실행 전 active + .1~.9 = 10개
active = R01 회전 경계값
old active → .1
old .1 → .2 ... old .8 → .9
old .9 제거
실행 후 active + .1~.9 = 10개
monitor.log.10 없음
새 active 공식 포맷
```

실제 production 로그를 10MB로 인위적으로 키워 Evidence를 다시 만들지 않습니다. STEP 09의 `/tmp` 격리 시험 결과가 현재 R01의 동작 Evidence입니다.

### K. cron Evidence — 전체 crontab 공개 금지

전체 사용자 crontab을 그대로 저장하지 않고 B1-1 관련 줄만 수집합니다.

```bash
{
    sudo systemctl is-active cron
    sudo crontab -u agent-admin -l 2>/dev/null \
      | grep -E '(/opt/agent-app/env\.sh|/opt/agent-app/bin/monitor\.sh)' || true
} > "$EVIDENCE_STAGE/10-cron-config.txt"
```

실제 자동 실행 Evidence는 STEP 10에서 확보한 다음 세 요소를 함께 사용합니다.

```text
관찰 시작 Before 시각/monitor.log 최신 상태
1~2분 동안 수동 monitor 실행 없음
After 시각/새 monitor.log 라인 + 공식 포맷
```

crontab에 미션 외 민감한 명령이 있을 수 있으므로 전체 `crontab -l` 출력 파일을 공개 저장하지 않습니다.

### L. 실패 경로와 Warning-only Evidence

STEP 11의 격리 시험 실제 출력에서 다음을 분리해 보관합니다.

```text
Process failure
→ [FAIL] 확인
→ exit=1
→ 실제 Agent/15034 유지

Port failure
→ Process [OK]
→ 시험 포트 [FAIL]
→ exit=1
→ 실제 15034 유지

CPU/MEM/DISK Warning-only
→ 세 Warning 확인
→ 격리 monitor.log append
→ exit=0
```

실제 Agent를 다시 끄거나 UFW를 비활성화하여 Evidence를 재생성하지 않습니다.

### M. 통합 `verify.sh` Evidence

STEP 12의 실제 전체 출력과 종료 코드를 사용합니다. 현재 상태를 다시 검증할 필요가 있다면 다음처럼 실행하되 실제 모든 PASS/FAIL을 그대로 봅니다.

```bash
VERIFY_SCRIPT="training/round-01-clear/environment/verify.sh"

if sudo bash "$VERIFY_SCRIPT" \
  | tee "$EVIDENCE_STAGE/12-verify.txt"; then
    VERIFY_RC=0
else
    VERIFY_RC=${PIPESTATUS[0]}
fi

printf 'verify_exit=%s\n' "$VERIFY_RC" \
  | tee -a "$EVIDENCE_STAGE/12-verify.txt"
```

> `tee`를 사용하면 화면에서 실제 검증을 보면서 파일에도 저장합니다. `PIPESTATUS[0]`는 pipe 왼쪽의 `verify.sh` 실제 종료 코드를 보존합니다. 이 결과는 **`Result: N PASS / 0 FAIL`과 `verify_exit=0`이 둘 다 실제로 확인된 경우에만** STEP 12 PASS Evidence가 됩니다.

### N. staging 파일 목록과 민감정보 수동 검토

먼저 파일명과 크기만 봅니다.

```bash
find "$EVIDENCE_STAGE" -maxdepth 1 -type f \
  -printf '%f %s bytes\n' | sort
```

그 다음 **자신이 방금 안전한 명령으로 만든 파일만** 하나씩 읽어 검토합니다. 파일 출처가 불명확하거나 Boot 캡처처럼 민감정보 가능성이 있는 자료는 자동 일괄 `cat`하지 않습니다.

검토 기준:

```text
[ ] Secret 값 없음
[ ] Password 없음
[ ] API Key / Access Token / Private Key 없음
[ ] 불필요한 IP/개인정보 없음
[ ] PASS/FAIL/exit code를 임의 수정하지 않음
[ ] 실제 현재 R01 결과임
[ ] Requirement와 연결 가능함
```

민감정보가 발견되면 해당 파일을 Git에 옮기지 않습니다. 필요한 증명 필드만 출력하는 더 안전한 명령으로 다시 수집합니다.

### O. 검토 완료한 파일만 Repository Evidence로 이동

현재 실행용 디렉터리 이름을 만듭니다.

```bash
EVIDENCE_RUN="training/round-01-clear/evidence/r01-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$EVIDENCE_RUN"
printf '[INFO] repository evidence dir=%s\n' "$EVIDENCE_RUN"
```

**검토가 끝난 파일만** 한 개씩 복사합니다. 예:

```bash
cp "$EVIDENCE_STAGE/00-context.txt" "$EVIDENCE_RUN/"
cp "$EVIDENCE_STAGE/01-ssh-config.txt" "$EVIDENCE_RUN/"
cp "$EVIDENCE_STAGE/02-firewall.txt" "$EVIDENCE_RUN/"
```

위 세 줄은 예시입니다. staging에 있다는 이유만으로 `cp "$EVIDENCE_STAGE"/* ...`처럼 전부 일괄 복사하지 않습니다.

복사 후 Git이 추가 대상으로 보는 파일명을 확인합니다.

```bash
git status --short "$EVIDENCE_RUN"
git diff --no-index /dev/null "$EVIDENCE_RUN/00-context.txt" || true
```

실제 Evidence를 Git에 commit하기 전에는 파일 내용을 다시 검토하고, 현재 Repository의 제출 정책에 따라 필요한 자료만 추적합니다.

### P. Requirement Mapping과 Evidence 연결 확인

현재 R01 매핑 문서를 읽습니다.

```bash
sed -n '1,260p' training/round-01-clear/docs/requirements-mapping.md
```

최소 연결 예:

```text
R01~R02 → SSH config + 실제 새 session
R03     → UFW
R04~R06 → users/groups/ACL/effective access
R07~R08 → non-secret env + Secret metadata
R09~R11 → Agent process + Boot 5/5 + READY + 15034
R12~R18 → monitor 권한/정상/실패/Warning/log
R19     → 10MB/10개 격리 회전
R20     → agent-admin cron + 실제 1~2분 자동 증가
R21     → verify.sh 0 FAIL + exit 0
R22     → Secret 미노출 검토
```

Evidence 파일이 존재해도 해당 Requirement를 실제로 증명하지 못하면 “완료”로 표시하지 않습니다.

### Q. staging 정리 — Evidence 복사·검토 완료 후

필요한 자료가 안전하게 Repository 또는 별도 제출 위치에 보존되었고 더 이상 staging이 필요하지 않을 때만 정리합니다.

```bash
case "${EVIDENCE_STAGE:-}" in
    /tmp/b1-1-evidence.*)
        find "$EVIDENCE_STAGE" -mindepth 1 -maxdepth 1 -type f -delete
        rmdir "$EVIDENCE_STAGE"
        ;;
    *)
        echo '[STOP] unexpected staging path; nothing deleted'
        ;;
esac
```

`rmdir`이 실패하면 예상하지 않은 파일이나 하위 디렉터리가 있다는 뜻일 수 있으므로 `rm -rf`로 강제 삭제하지 않습니다.

## ⑥ 명령어와 코드에 입문자가 이해할 수 있는 주석

### 출처 정보

- `git rev-parse HEAD`
  - Evidence가 어떤 Git Commit 기준에서 수집되었는지 전체 SHA를 출력합니다.
- `date --iso-8601=seconds`
  - 시간대(offset)가 포함된 수집 시각을 기록합니다.
- `/etc/os-release`
  - Ubuntu 배포판 이름/버전 출처를 시스템 표준 파일에서 읽습니다.

### staging

- `mktemp -d /tmp/b1-1-evidence.XXXXXX`
  - 매 실행마다 고유한 임시 디렉터리를 만들어 기존 Evidence와 섞이지 않게 합니다.
- `case ... /tmp/b1-1-evidence.*)`
  - 생성·삭제 전에 경로가 이번 STEP의 예상 패턴인지 확인합니다.
- Repository에 바로 쓰지 않는 이유
  - 수집 직후 아직 Secret/민감정보 검토가 끝나지 않은 파일을 Git working tree에 두지 않기 위해서입니다.

### 출력 저장

- `{ ... } > file`
  - 중괄호 안 여러 명령의 stdout을 하나의 Evidence 파일에 새로 기록합니다.
- `>`
  - 대상 파일을 새로 만들거나 덮어씁니다. staging은 이번 실행의 새 고유 디렉터리이므로 의도된 동작입니다.
- `tee file`
  - 명령 결과를 화면과 파일에 동시에 보냅니다. STEP 12처럼 전체 PASS/FAIL을 눈으로 보면서 저장할 때 사용합니다.
- `${PIPESTATUS[0]}`
  - pipe를 사용했을 때 가장 왼쪽 `verify.sh`의 실제 종료 코드를 확인합니다. 단순 `$?`만 보면 `tee`의 종료 코드가 될 수 있습니다.

### Secret-safe Evidence

- `test -s t_secret.key`
  - Secret 파일이 존재하고 비어 있지 않은지만 확인합니다.
- `stat`
  - owner/group/mode/크기 같은 메타데이터만 출력합니다.
- Secret 파일에 `cat`, `head`, `tail`, 값 검색용 `grep`을 사용하지 않는 이유
  - 증빙에 필요한 것은 존재·권한·실제 Agent Boot 결과이지 비밀값 자체가 아니기 때문입니다.

### SSH session 최소 정보

- `SSH_CONNECTION`
  - 실제 SSH session의 양쪽 IP/포트가 포함된 환경변수입니다.
- `awk '{print "server_port=" $4}'`
  - 전체 연결 문자열 대신 서버 측 포트만 추출하여 불필요한 IP 노출을 줄입니다.

### 역할별 접근 검증

- `runuser -u 사용자 -- test -r/-w`
  - Root가 파일 내용을 대신 읽는 것이 아니라 실제 역할 사용자 신분으로 읽기·쓰기 가능 여부만 확인합니다.
- `[PASS]`/`[FAIL]`
  - 실제 종료 코드에 따라 생성된 결과를 그대로 저장합니다. 실패를 성공 문자열로 수동 수정하지 않습니다.

### Repository Evidence 복사

- `mkdir -p "$EVIDENCE_RUN"`
  - 현재 R01 실행용 Evidence 디렉터리를 만듭니다.
- `cp source destination`
  - **검토 완료한 파일 하나씩** Repository Evidence 위치로 복사합니다.
- wildcard 전체 복사를 피하는 이유
  - 검토하지 않은 민감 파일이 함께 Git working tree로 들어가는 것을 막기 위해서입니다.
- `git status --short "$EVIDENCE_RUN"`
  - Git이 어떤 Evidence 파일을 새 파일/변경 파일로 보는지 확인합니다.

### 안전한 staging 정리

- `find ... -type f -delete`
  - 예상 staging 바로 아래의 일반 파일만 제거합니다.
- `rmdir`
  - 디렉터리가 비어 있을 때만 제거합니다. 알 수 없는 내용이 있으면 강제로 지우지 않습니다.

### 재실행 안전성

STEP 13은 시스템 설정 자체는 대부분 읽기만 하지만 Evidence 파일을 생성·복사·삭제할 수 있습니다.

```text
pwd / git / date / stat / id / getent / ss / ufw 조회         → 🟢 SAFE TO RERUN
mktemp staging 생성                                            → 🟢 새 고유 경로 생성
staging에 Evidence 출력 저장                                   → 🟢 고유 경로 안에서는 안전
verify.sh 재실행                                               → 🟢 검증 전용, 단 실제 Runtime 전제 확인
Repository Evidence 디렉터리 생성                              → 🟡 중복 실행 디렉터리 확인
검토한 파일 개별 cp                                            → 🟡 대상 파일 확인 후
Evidence 파일 대량 wildcard 복사                               → 🚫 사용하지 않음
Secret 내용 출력                                               → 🚫 사용하지 않음
PASS/FAIL/exit code 수동 수정                                  → 🚫 Evidence 조작
staging find -delete / rmdir                                   → 🔴 필요한 Evidence 보존 확인 후
```

> **STOP 기준:** STEP 12 실제 `0 FAIL` 미확인, 현재 Repository/Commit 출처 불명, 실제 새 SSH 세션 Evidence 없음, Boot 5/5/READY 실제 결과 없음, STEP 09 회전 시험 미실행, STEP 10 실제 자동 증가 미확인, STEP 11 실패/Warning 분기 미실행, staging에 Secret/Token/Password/Private Key 발견, Requirement와 연결할 수 없는 자료를 PASS Evidence로 사용하려 함 중 하나라도 있으면 STEP 14로 진행하지 않습니다.

## ⑦ 예상되는 정상 결과

Evidence는 최소 다음 범주를 실제 현재 R01 결과로 설명할 수 있어야 합니다.

```text
00 Context / Provenance
01 SSH effective config + 실제 20022 새 session
02 UFW active + 20022/15034 only
03~04 users/groups/permissions/ACL/effective access
05 non-secret environment + Secret metadata only
06 Agent Boot 5/5 + READY + process user + 15034
07 monitor 정상 실행 + monitor.log
08 Process/Port failure exit 1
09 CPU/MEM/DISK Warning-only + log + exit 0
10 10MB/10개 rotation 실제 격리 시험
11 agent-admin cron + 실제 1~2분 자동 log 증가
12 verify.sh Result N PASS / 0 FAIL + exit 0
```

파일 번호는 Repository `evidence/README.md`의 권장 묶음과 함께 사용하며, 실제 제출 형식에 맞게 파일명은 조정할 수 있습니다. 핵심은 **실제 Requirement를 빠짐없이 다시 확인할 수 있는가**입니다.

## ⑧ 그 결과가 의미하는 것

STEP 13이 실제로 완료되면 B1-1의 설정과 실행 결과가 단순한 개인 경험이 아니라 다음 구조로 외부 검토 가능한 상태가 됩니다.

```text
공식 Requirement
        ↓
현재 R01 구현
        ↓
실제 Runtime 검증
        ↓
Secret 없는 Evidence
        ↓
Requirement Mapping
```

그러나 Evidence Complete만으로 설명형 Evaluation까지 자동 통과하는 것은 아닙니다. 다음 STEP 14에서 `pgrep`/`ss` 선택 이유, CPU/MEM/DISK 파싱, 최소 권한, `>`와 `>>`, 장애 대응 등을 자신의 실제 Runtime과 연결해 설명할 수 있어야 합니다.

## ⑨ 자주 발생하는 오류와 해결 방법

- 예상 출력이 보기 좋아 실제 출력 대신 사용됨 → 폐기하고 현재 R01 Runtime에서 다시 수집합니다.
- 과거 Round 파일을 재사용함 → `00-context.txt`의 Commit/수집 시각과 현재 실행을 비교하고 현재 R01 결과로 다시 만듭니다.
- Secret 파일을 `cat`한 화면이 있음 → 해당 자료는 제출하지 말고 `test -s`/`stat`로 다시 수집합니다.
- Boot 화면에 민감정보가 보임 → 그 캡처를 사용하지 않고 민감정보가 없는 안전한 실행/캡처 방법을 선택합니다.
- 전체 `crontab -l`을 저장함 → 미션 관련 줄만 `grep`으로 다시 수집합니다.
- SSH Evidence에 IP 주소가 불필요하게 노출됨 → 실제 session에서 서버 포트만 추출하는 명령으로 다시 수집합니다.
- UFW 캡처가 일부 잘려 다른 ALLOW IN 존재 여부를 판단할 수 없음 → 전체 `ufw status verbose/numbered` 결과를 다시 수집합니다.
- ACL은 보이지만 실제 접근 가능 여부가 없음 → `runuser ... test -r/-w` 결과를 추가합니다.
- `Agent READY`만 있고 15034 Evidence가 없음 → `ps`와 `ss`를 별도 수집합니다.
- `15034`만 있고 Boot 5/5가 없음 → 포트만으로 Boot 성공을 추측하지 말고 STEP 07 실제 Boot 결과를 확보합니다.
- monitor.log 최신 라인만 있고 수동/cron 구분이 없음 → STEP 10 Before/After 시간 흐름을 함께 사용합니다.
- 회전 후 파일 수만 있고 이동 순서가 없음 → STEP 09 marker 결과로 old active/.1~.9 이동을 증명합니다.
- verify `0 FAIL`만 있음 → STEP 03~11 별도 Runtime Evidence를 생략하지 않습니다.
- Evidence 파일을 수정하여 FAIL을 지움 → 증거 조작입니다. 원인을 수정하고 실제 검증을 다시 실행합니다.
- Repository에 복사 후 민감정보 발견 → commit하지 말고 해당 파일을 안전하게 제거한 뒤 더 안전한 명령으로 재수집합니다. 이미 원격에 올라갔다면 단순 삭제 commit만으로 민감정보가 사라졌다고 가정하지 말고 Secret 교체와 Git history 대응을 별도로 검토합니다.

## ⑩ 완료 확인

- [ ] STEP 12 실제 `Result: N PASS / 0 FAIL` + `verify_exit=0` 확인
- [ ] 현재 Repository / Branch / Commit / 수집 시각 기록
- [ ] Evidence staging을 `/tmp/b1-1-evidence.*` 고유 경로로 생성
- [ ] 공식 Mission의 필수 증거 자료 항목과 R01~R22 Mapping 확인
- [ ] SSH effective config Evidence
- [ ] 실제 `20022` 새 SSH session Evidence
- [ ] UFW 전체 정책 Evidence
- [ ] 사용자 3개 / 그룹 2개 Evidence
- [ ] 디렉터리 owner/group/mode/ACL Evidence
- [ ] 역할별 effective access Evidence
- [ ] non-secret 환경변수 Evidence
- [ ] Secret은 존재/non-empty/owner/group/mode만 Evidence
- [ ] Secret 값 출력 없음
- [ ] Agent Boot 1/5~5/5 실제 `[OK]` Evidence
- [ ] `Agent READY` 실제 Evidence
- [ ] Agent user=`agent-admin`, UID != 0 Evidence
- [ ] TCP `0.0.0.0:15034` Evidence
- [ ] monitor 정상 실행 / `exit=0` Evidence
- [ ] CPU/MEM/DISK 실제 수집 Evidence
- [ ] 공식 monitor.log 포맷 Evidence
- [ ] Process failure `exit=1` Evidence
- [ ] Port failure `exit=1` Evidence
- [ ] CPU/MEM/DISK Warning-only `exit=0` Evidence
- [ ] 10MB/10개 실제 격리 회전 Evidence
- [ ] agent-admin cron exact/related 1개 Evidence
- [ ] 실제 1~2분 cron 자동 monitor.log 증가 Evidence
- [ ] `verify.sh` 전체 결과 `0 FAIL` Evidence
- [ ] Requirement Mapping과 Evidence 파일 연결
- [ ] Evidence 파일에 Password/API Key/Token/Private Key 없음
- [ ] 불필요한 개인정보/네트워크 정보 최소화
- [ ] PASS/FAIL/exit code를 수동 조작하지 않음
- [ ] Repository로 옮기기 전에 파일별 수동 검토 완료
- [ ] staging 정리는 필요한 자료 보존 후 예상 경로에서만 수행
- [ ] **실제 Evidence가 채워지기 전에는 Evidence Complete로 기록하지 않음**
- [ ] **STEP 14 Evaluation Q&A 전에는 B1-1 CLEAR로 기록하지 않음**

---

[← STEP 12](01-verification.md) · [모듈 07 목차](README.md) · [다음: STEP 14 →](03-evaluation-qa.md)
