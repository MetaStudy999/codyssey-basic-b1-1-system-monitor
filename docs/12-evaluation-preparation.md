# 12. 평가 대비 설명 자료

> **기억 문장:** 동작만 보여 주지 말고, 왜 그렇게 만들었는지 설명한다.

이 장은 `b1-1-evaluation.md`의 평가 항목을 그대로 따라가며 **구현 → 검증 → 설명**을 연결합니다.

---

## 1. 평가 항목 1 — 요구사항 구현 및 동작 확인

### SSH 20022 + Root 원격 접속 차단

구현:

```text
/etc/ssh/sshd_config.d/99-b1-1.conf
Port 20022
PermitRootLogin no
```

검증:

```bash
sudo sshd -T | grep -E '^(port|permitrootlogin) '
sudo ss -lntp | grep -E ':(22|20022)\b' || true
```

설명 핵심:

> 설정 파일 값, sshd의 최종 해석값, 실제 LISTEN 상태를 각각 확인한다.

### UFW 20022/15034만 허용

검증:

```bash
sudo ufw status verbose
```

목표:

```text
Status: active
Default: deny (incoming)
20022/tcp ALLOW
15034/tcp ALLOW
```

### 사용자·그룹

목표:

```text
agent-common = admin + dev + test
agent-core   = admin + dev
```

검증:

```bash
id agent-admin
id agent-dev
id agent-test
```

### Agent

성공 기준:

```text
Boot Sequence 5단계 [OK]
Agent READY
non-root
0.0.0.0:15034
```

### monitor.sh

검증 범위:

```text
process failure → exit 1
port failure    → exit 1
정상            → exit 0 + log
```

### monitor.log

형식:

```text
[YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%
```

### cron

```bash
sudo -u agent-admin crontab -l
```

`* * * * *`와 1~2분 후 로그 증가를 모두 확인합니다.

### 10MB / 10개

저장소 구현:

```text
config/agent-monitor.logrotate
```

핵심:

```text
size 10M
rotate 10
```

---

## 2. 평가 항목 2 — 구현 방식 및 명령어 설명

### Q1. 왜 프로세스 확인에 `pgrep`를 사용했는가?

현재 구현:

```bash
pgrep -f -- "$AGENT_PROCESS_PATTERN"
```

설명:

> `pgrep`는 프로세스 목록에서 조건과 일치하는 PID를 직접 찾을 수 있어 `ps | grep | grep -v grep` 같은 긴 파이프라인보다 목적이 명확합니다. `-f`는 실행 명령 전체를 대상으로 실제 앱 파일명을 찾기 위해 사용했습니다.

`ps`는 찾은 PID의 실제 소유자와 명령을 사람이 확인할 때 사용합니다.

```bash
ps -o user,pid,ppid,cmd -p <PID>
```

### Q2. 왜 포트 확인에 `ss`를 사용했는가?

현재 구현:

```bash
ss -lntH
```

설명:

> `ss`는 현재 Linux에서 socket 상태를 직접 확인할 수 있고, TCP LISTEN 여부를 빠르게 확인할 수 있습니다. B1-1에서는 단순히 프로세스가 존재하는지가 아니라 `15034`가 실제 LISTEN인지 확인해야 하므로 사용했습니다.

### Q3. CPU는 어떻게 구했는가?

현재 구현은 `/proc/stat`을 두 번 읽습니다.

```text
snapshot 1
→ 0.2초
→ snapshot 2
→ total/idle 차이로 CPU 사용률 계산
```

설명:

> 누적 CPU counter의 두 시점 차이를 사용해 짧은 구간의 실제 사용률을 계산합니다.

### Q4. MEM은 어떻게 구했는가?

```text
MemTotal
MemAvailable
```

를 `/proc/meminfo`에서 읽고:

```text
(MemTotal - MemAvailable) / MemTotal × 100
```

으로 계산합니다.

### Q5. DISK는 어떻게 구했는가?

```bash
df -P /
```

의 Root partition `Use%`를 사용합니다.

원본 미션이 Root partition Used %를 요구하기 때문입니다.

### Q6. 왜 로그 포맷을 고정했는가?

```text
[시간] PID CPU MEM DISK
```

설명:

> 같은 형식으로 누적해야 사람이 비교하기 쉽고, 나중에 `report.sh` 같은 프로그램이 일정한 규칙으로 파싱할 수 있습니다.

### Q7. `agent-dev` 소유, `agent-admin` 실행이 어떻게 가능한가?

목표 권한:

```text
owner = agent-dev
group = agent-core
mode  = 750
```

그리고:

```text
agent-admin ∈ agent-core
agent-dev   ∈ agent-core
```

입니다.

따라서:

```text
agent-dev   → owner rwx
agent-admin → group r-x
agent-test  → others ---
```

가 되어 `agent-admin` cron이 실행할 수 있습니다.

### Q8. 10MB/10개를 어떻게 구현했는가?

`logrotate`를 선택했습니다.

```text
monitor.sh = monitoring
logrotate  = log lifecycle
```

역할을 분리해 스크립트가 로그 회전 로직까지 떠안지 않게 했습니다.

---

## 3. 평가 항목 3 — 보안·권한·운영 원리 설명

### Q1. SSH 포트 변경이 왜 보안에 도움이 되는가?

설명 포인트:

```text
22번을 무작위 스캔하는 자동화 트래픽 감소
불필요한 노이즈 감소
그러나 강력한 인증을 대체하지는 않음
```

즉 포트 변경만으로 보안이 완성되는 것은 아닙니다.

### Q2. Root 원격 로그인 차단이 왜 중요한가?

> Root는 시스템 전체 권한을 가지므로 원격 인증이 뚫렸을 때 영향 범위가 최대입니다. 일반 사용자로 로그인한 뒤 필요한 작업만 sudo를 사용하는 편이 권한 노출을 줄이고 작업 추적도 쉽습니다.

### Q3. 왜 `api_keys`와 로그를 `agent-core`로 제한했는가?

```text
api_keys = 인증 관련 민감 자원
운영 로그 = 시스템·애플리케이션 상태 정보
```

`agent-test` 업무에는 직접 수정 권한이 필요하지 않으므로 **Least Privilege** 원칙에 따라 core 그룹으로 제한합니다.

### Q4. 왜 어떤 문제는 WARNING이고 어떤 문제는 exit 1인가?

```text
process 없음 → 서비스가 실제로 없음 → exit 1
port 없음    → 서비스 제공 불가       → exit 1

firewall inactive → 보안 위험, 상태 수집은 가능 → WARNING
CPU/MEM/DISK high → 위험 신호, 즉시 모니터 종료 이유는 아님 → WARNING
```

### Q5. `>`와 `>>`의 차이는?

```text
>  = 기존 파일을 덮어씀
>> = 기존 파일 뒤에 추가
```

모니터링 로그는 시간 흐름을 남겨야 하므로 `>>`를 사용합니다.

---

## 4. 평가 항목 4 — 응용 및 장애 대응

### Q1. Nginx를 모니터링한다면 무엇을 바꾸는가?

핵심 네 가지:

```text
process   → nginx
port      → 80/443 등 실제 서비스 포트
log       → Nginx 운영 목적에 맞는 로그/상태 기록
threshold → 서비스 특성에 맞게 조정
```

전체 스크립트를 처음부터 다시 만드는 것이 아니라 **대상 프로세스·포트·로그·임계값을 환경화**하는 방향으로 확장할 수 있습니다.

### Q2. 프로세스는 있는데 포트가 열리지 않으면?

확인 순서:

```text
1. 실제 PID와 명령 확인
2. 앱 초기화 로그/출력 확인
3. AGENT_PORT 확인
4. ss로 해당 포트 확인
5. 같은 포트를 다른 프로세스가 쓰는지 확인
6. bind address 확인
7. key/권한/환경변수 오류 확인
```

핵심:

> 프로세스 존재와 서비스 제공 가능 상태는 같은 것이 아니다.

### Q3. 로그 급증으로 디스크가 가득 찰 위험이 있으면?

#### 단기

```text
현재 디스크 사용률 확인
로그 증가 원인 확인
불필요한 임시/회전 파일 검토
서비스 장애를 막을 공간 확보
logrotate 동작 확인
```

#### 중기

```text
로그 폭증 원인 수정
회전 크기·보존 정책 조정
알림 추가
아카이브 정책 적용
보너스 7일 압축·30일 삭제 적용
```

원인 파악 없이 운영 로그를 무조건 삭제하는 방식은 피합니다.

---

## 5. 평가 답변 방식

각 질문은 다음 4문장 구조로 답하면 정리가 쉽습니다.

```text
1. 무엇을 했다.
2. 왜 그렇게 했다.
3. 어떤 명령/코드로 구현했다.
4. 어떤 결과로 검증했다.
```

예:

```text
SSH 포트를 20022로 변경했습니다.
기본 22번 자동 스캔 노이즈를 줄이고 미션 요구사항을 충족하기 위해서입니다.
99-b1-1.conf에서 Port 20022와 PermitRootLogin no를 설정했습니다.
sshd -T와 ss -lntp로 최종 설정과 실제 LISTEN을 확인했습니다.
```

---

## 6. 평가와 증빙 연결

평가 답변은 말로만 준비하지 않습니다.

```text
답변
→ 구현 파일
→ 실제 검증 명령
→ evidence
```

을 연결합니다.

마스터 추적 파일:

```text
docs/reference/requirements-evidence-map.md
```

---

## 7. 현재 평가 준비 상태

```text
SSH 설명             준비됨
UFW 설명             준비됨
권한 설계 설명        문서 준비 / 실제 구현 전
Agent 설명           절차 준비 / 실제 결과 전
monitor 구현 설명     준비됨
cron/logrotate 설명   준비됨
장애 대응 설명        준비됨
실제 전체 증빙         미완료
```

따라서 12장 문서 자체는 준비됐지만 **실제 구현·증빙이 없는 항목은 평가 PASS로 간주하지 않습니다.**

---

## 8. 이번 단계 기억하기

### 한 문장

> **동작만 보여 주지 말고, 왜 그렇게 만들었는지 설명한다.**

### 핵심어 3개

```text
WHAT · WHY · PROOF
```

### 최종 연습 질문

```text
왜 20022인가?
왜 Root를 막았는가?
왜 common/core를 나눴는가?
왜 process와 port를 둘 다 보는가?
왜 WARNING과 exit 1을 나눴는가?
왜 >>를 쓰는가?
왜 cron에서 환경을 따로 고려하는가?
왜 logrotate를 분리했는가?
프로세스만 있고 포트가 없으면 어떻게 진단하는가?
Nginx로 바뀌면 무엇을 수정하는가?
```

---

## 9. 완료 체크

- [x] 평가 항목 1 구현 확인 포인트 정리
- [x] 평가 항목 2 명령·구현 설명 정리
- [x] 평가 항목 3 보안·운영 원리 정리
- [x] 평가 항목 4 응용·장애 대응 정리
- [x] 4문장 답변 구조 정의
- [ ] 05~09 실제 테스트 결과와 답변 연결
- [ ] 최종 evidence 링크 연결
- [ ] 사용자 구두 검증

현재 12단계는 **평가 설명 자료 IMPLEMENTED / 실제 결과 연결 전**입니다.

---

## 이동

- [이전: 11. 수행 내역과 증빙](./11-execution-evidence.md)
- [다음: 13. 재현 시험](./13-reproducibility-test.md)
- [전체 목차](./README.md)
