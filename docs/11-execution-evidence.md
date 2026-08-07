# 11. 수행 내역서와 증빙 작성

> **기억 문장:** 했다는 설명과 실제로 했다는 증거를 분리해서 남긴다.

이 장에서는 B1-1 수행 결과를 **보고서(`reports/`)와 증빙(`evidence/`)**으로 나누어 정리합니다.

---

## 1. 목표

원본 미션의 제출물 중 하나인 **요구사항 수행 내역서**를 만들 수 있도록 다음을 연결합니다.

```text
요구사항
→ 실제 설정/코드
→ 실행 명령
→ 실제 출력
→ PASS/FAIL
→ 증빙 파일
```

---

## 2. reports와 evidence의 차이

### `reports/`

사람이 읽는 설명입니다.

```text
무엇을 했는가
왜 그렇게 했는가
어떤 결과가 나왔는가
어떤 오류가 있었는가
어떻게 복구했는가
```

### `evidence/`

실제 실행 결과의 원본 또는 최소 가공본입니다.

```text
sshd -T 출력
ufw status 출력
id/getfacl 출력
Agent READY 출력
monitor.sh 실행 결과
monitor.log 최근 라인
crontab -l
logrotate dry-run/회전 결과
```

쉽게 기억하면:

```text
report   = 설명
evidence = 증명
```

---

## 3. 증빙 기본 규칙

증빙 파일에는 가능하면 다음 정보를 함께 기록합니다.

```text
실행 시각
실행 계정
실행 명령
종료 코드
실제 출력
판정
```

단, 다음은 기록하지 않습니다.

```text
비밀번호
실제 key 내용
API token
private key
불필요한 개인정보
전체 시스템 백업
```

키 파일은 **경로·소유권·권한·줄 수**로 증명하고 값 자체는 출력하지 않습니다.

---

## 4. 필수 증빙 묶음

### 01 환경

```text
evidence/01-environment/
```

후보:

```text
os-release.txt
systemd-sudo-tools.txt
```

### 03 SSH

```text
evidence/03-ssh/
```

후보:

```text
sshd-effective-config.txt
ssh-listen-ports.txt
ssh-config-test.txt
ssh-connection-test.txt
```

### 04 방화벽

```text
evidence/04-firewall/
```

후보:

```text
ufw-added-rules.txt
ufw-status-final.txt
```

### 05 사용자·그룹·ACL

```text
evidence/05-users-groups-acl/
```

후보:

```text
users-groups.txt
directory-permissions.txt
acl-upload-files.txt
acl-api-keys.txt
acl-log-dir.txt
access-tests.txt
```

### 06 Agent

```text
evidence/06-agent/
```

후보:

```text
agent-files.txt
agent-env-masked.txt
key-permissions.txt
agent-boot.txt
agent-process-owner.txt
agent-listen-15034.txt
```

### 07 monitor.sh

```text
evidence/07-monitor/
```

후보:

```text
monitor-file-permissions.txt
monitor-bash-syntax.txt
monitor-success.txt
monitor-process-failure.txt
monitor-port-failure.txt
monitor-warnings.txt
monitor-log-format.txt
```

### 08 자동화

```text
evidence/08-automation/
```

후보:

```text
crontab-agent-admin.txt
cron-log-before-after.txt
logrotate-config.txt
logrotate-dry-run.txt
logrotate-force-test.txt
```

### 09 테스트·복구

```text
evidence/09-testing/
```

후보:

```text
test-summary.txt
recovery-final.txt
```

### 14 최종

```text
evidence/14-final/
```

최종 통합 검증 결과를 보관합니다.

---

## 5. 현재 이미 확인된 실제 항목

현재 대화형 실습에서 실제로 확인한 항목은 다음과 같습니다.

```text
Ubuntu 24.04.4 LTS
x86_64
systemd 255
sudo 성공
필수 도구 설치
SSH port 20022
PermitRootLogin no
20022 LISTEN / 22 미LISTEN
UFW active
Default incoming deny
20022/tcp ALLOW
15034/tcp ALLOW
agent-common 그룹 생성
agent-core 그룹 생성
```

하지만 **대화 기록 자체를 Git 증빙 파일로 자동 간주하지 않습니다.** 11장에서 최종 제출용 증빙은 실제 시스템에서 필요한 명령을 다시 실행해 파일로 저장하는 것이 재현성과 신뢰성이 높습니다.

---

## 6. 아직 증빙하면 안 되는 항목

다음은 아직 실제 실행 검증이 끝나지 않았습니다.

```text
사용자 3개 생성 및 멤버십
ACL 허용/차단 시험
Agent Boot Sequence 5 [OK]
Agent READY
15034 실제 LISTEN
monitor.sh 실제 Ubuntu 실행
cron 자동 로그 증가
logrotate 실제 회전
전체 장애/복구 시험
보너스
```

이 항목들은 예시 출력으로 채우지 않습니다.

---

## 7. 증빙 캡처 방법 예시

### SSH

```bash
{
  date
  whoami
  echo '$ sudo sshd -T | grep -E "^(port|permitrootlogin) "'
  sudo sshd -T | grep -E '^(port|permitrootlogin) '
  echo '$ sudo ss -lntp | grep -E ":(22|20022)\\b" || true'
  sudo ss -lntp | grep -E ':(22|20022)\b' || true
} > evidence/03-ssh/sshd-effective-config.txt
```

### UFW

```bash
sudo ufw status verbose > evidence/04-firewall/ufw-status-final.txt
```

### 사용자·그룹

```bash
{
  id agent-admin
  id agent-dev
  id agent-test
} > evidence/05-users-groups-acl/users-groups.txt
```

### 키 권한 — 값은 출력하지 않음

```bash
sudo stat -c 'owner=%U group=%G mode=%a path=%n' \
  /home/agent-admin/agent-app/api_keys/t_secret.key \
  > evidence/06-agent/key-permissions.txt
```

---

## 8. 증빙을 가공할 때의 원칙

허용:

```text
비밀값 마스킹
불필요한 개인 IP 마스킹
긴 출력 중 요구사항 관련 부분만 발췌
명령과 출력 사이에 설명 추가
```

금지:

```text
실제 실패 출력을 성공처럼 수정
예상 출력을 실제 출력으로 복사
timestamp/PID를 임의 작성
키 값 노출
```

---

## 9. 수행 내역서 구조

`reports/execution-report.md`는 다음 흐름으로 작성합니다.

```text
1. 실습 환경
2. 원본 요구사항 요약
3. 초기 상태
4. SSH
5. UFW
6. 사용자·그룹·ACL
7. Agent
8. monitor.sh
9. cron·logrotate
10. 테스트·복구
11. 평가 대응
12. 최종 결과
13. 보너스
```

각 항목에는 최소한 다음을 넣습니다.

```text
목표
구현
검증
결과
증빙 링크
```

---

## 10. 요구사항 추적표와 연결

마스터 파일:

```text
docs/reference/requirements-evidence-map.md
```

상태는 다음 기준으로 관리합니다. `NEEDS-RUNTIME`과 `BLOCKED`는 완료 단계가 아니라 현재 제약을 나타냅니다.

```text
TODO
→ IMPLEMENTED
→ TESTED
→ PASS

NEEDS-RUNTIME = 실제 Ubuntu에서 수행·검증해야 함
BLOCKED       = 외부 조건 때문에 현재 수행할 수 없음
```

### PASS 규칙

```text
구현 있음
+ 실제 테스트 성공
+ 증빙 파일 존재
= PASS
```

한 요소라도 없으면 PASS로 올리지 않습니다.

---

## 11. Codex 검증에 사용할 자료

Codex 독립 검증 시 다음 순서로 확인하게 합니다.

```text
원본 mission
원본 evaluation
requirements-evidence-map
실제 구현
테스트
reports
증빙
```

Codex가 각 요구사항마다:

```text
PASS / FAIL
근거 파일
근거 라인 또는 명령
누락 사항
재현 명령
```

을 제시하도록 합니다.

---

## 12. 이번 단계 기억하기

### 한 문장

> **했다는 설명과 실제로 했다는 증거를 분리해서 남긴다.**

### 핵심어 3개

```text
REPORT · EVIDENCE · TRACE
```

### 내가 설명할 수 있어야 할 것

> 왜 실제 출력이 없는 항목을 보고서 문장만으로 PASS 처리하면 안 되는가?

답의 핵심은 **다른 사람이 독립적으로 사실 여부를 검증할 수 없기 때문**입니다.

---

## 13. 완료 체크

- [x] reports/evidence 역할 구분
- [x] 단계별 증빙 위치 정의
- [x] 민감정보 마스킹 원칙 정의
- [x] 요구사항 추적 방식 연결
- [x] 현재 실제 확인 항목과 미확인 항목 분리
- [ ] 실제 Ubuntu에서 최종 증빙 파일 생성
- [ ] `reports/execution-report.md` 실제 결과 채움
- [ ] 추적표 `PASS` 상태 반영

현재 11단계는 **증빙 체계 IMPLEMENTED / 실제 증빙 수집 진행 전**입니다.

---

## 이동

- [이전: 10. 트러블슈팅](./10-troubleshooting.md)
- [다음: 12. 평가 대비](./12-evaluation-preparation.md)
- [전체 목차](./README.md)
