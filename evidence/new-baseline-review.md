# B1-1 New Baseline · G4 Review

- Cycle: `restart-20260816`
- Gate: `G4_REVIEW`
- Review scope: official Mission/Evaluation mandatory requirements, current scripts/config, current learner/runtime path

## Review result

- BLOCKER: **0** after correction
- MAJOR: **0** after correction
- Runtime-only items: **remain for G5**

## 발견하고 바로 수정한 주요 문제

### MAJOR-01 · 과거 Agent 배치 문서의 광범위한 recursive chown

이전 `docs/06-agent-setup.md`에는 다음과 같은 패턴이 있었다.

```bash
sudo chown -R agent-admin:agent-common /home/agent-admin/agent-app
```

이 명령은 `api_keys`까지 `agent-common` 그룹으로 변경하여 `agent-test` 차단이라는 공식 최소권한 요구와 충돌할 수 있다.

조치:

- 기존 06 문서를 New Baseline 안전 실행 문서로 교체
- 실제 ZIP 구조/아키텍처 확인 후 **실행 파일만** 설치하도록 변경
- `api_keys`, `upload_files`, log directory 권한 경계를 유지하도록 명시
- 빠른 실행 가이드에서도 recursive chown 금지

### MAJOR-02 · 과거 상세 문서의 “실제 결과”와 현재 Cycle 혼동 가능성

기존 `01~15` 학습 문서는 과거 급행 수행 당시 실제 결과를 포함한다. 그대로 따라가면 과거 상태를 현재 PASS처럼 오해할 수 있다.

조치:

- `docs/README.md`를 새 기준 Index로 교체
- `00-new-baseline-runtime.md`를 현재 단일 빠른 실행 경로로 지정
- 과거 상세 문서의 결과는 현재 PASS가 아님을 명시

## 현재 구현 검토

### 보안/네트워크

- SSH 20022 / Root remote login no: 실행 가이드 존재, G5 실제 검증 필요
- UFW active / only 20022 + 15034 inbound: 실행 가이드 존재, G5 실제 검증 필요

### IAM/ACL

- 공식 3 users / 2 groups 구조와 디렉터리 권한 가이드 일치
- agent-test의 api_keys/log 차단과 upload_files R/W 시험 포함
- G5 실제 검증 필요

### Agent

- 5개 공식 환경변수 유지
- 제공 binary/Python entry를 추측하지 않고 ZIP 실제 구조 확인 후 실행
- non-root / Boot 1~5 OK / READY / 0.0.0.0:15034 검증 절차 포함
- key 값 비노출 정책 유지
- G5 실제 검증 필요

### monitor.sh

- process missing -> exit 1
- TCP 15034 missing -> exit 1
- firewall inactive -> WARNING only
- CPU/MEM/DISK thresholds 20/10/80 -> WARNING only
- required log format
- log append failure -> nonzero
- 제공 Linux Agent binary 이름 인식
- G3 behavioral test PASS

### cron / logrotate

- agent-admin 매분 cron 설정 예시
- monitor.log 10MB, current + 9 rotation = 최대 10개 정책
- `0660 agent-admin agent-core`
- G5 실제 cron 증가/logrotate dry-run 필요

## Runtime 단순화

새 `scripts/runtime-acceptance.sh`는 실제 Ubuntu에서 SSH/UFW/users/groups/ACL/key/Agent/monitor/cron/logrotate 상태를 한 번에 검사한다.

```bash
bash scripts/runtime-acceptance.sh | tee /tmp/b1-1-runtime.txt
```

`[FAIL]` 항목만 수정 후 재실행한다.

## G4 판정

`PASS`

현재 확인된 BLOCKER/MAJOR는 교정되었다. 단, 실제 OS/Agent/cron/logrotate 결과는 아직 G5 Runtime Evidence가 없으므로 Mission PASS가 아니며 다음 Gate는 `G5_RUNTIME / NEEDS-RUNTIME`이다.
