# B1-1 최종 체크리스트

> 체크는 **실제 구현·검증·증빙 근거**가 있을 때만 합니다. 문서나 코드가 존재한다는 이유만으로 실제 수행 항목을 완료 처리하지 않습니다.

## A. 원본 기준·환경

- [x] 원본 미션 기준을 Ubuntu 22.04 또는 동등 Linux로 유지
- [x] 실제 실습 환경 Ubuntu 24.04.4 LTS를 별도 기록
- [x] x86_64는 미션 필수조건이 아니라 실제 환경/Agent 선택 정보로 처리
- [x] 원본 데이터 설명의 `agent-app-linux-x86` / `agent-app-linux-arm64` 반영
- [ ] 실제 `agent-app.zip` 내부 파일/경로 확인

## B. SSH

- [x] SSH Port `20022` 설정
- [x] `PermitRootLogin no`
- [x] `sshd -t` 실제 성공
- [x] `sshd -T` 실제 최종값 확인
- [x] 실제 `20022` LISTEN
- [x] 실제 `22` 미LISTEN
- [ ] 외부/별도 클라이언트 일반 사용자 새 SSH 접속
- [ ] SSH evidence 파일 정리

## C. 방화벽

- [x] UFW active 실제 확인
- [x] default incoming deny 실제 확인
- [x] `20022/tcp` 허용 실제 확인
- [x] `15034/tcp` 허용 실제 확인
- [x] 불필요한 `22/tcp` ALLOW 없음 확인
- [ ] UFW evidence 파일 정리

## D. 사용자·그룹·ACL

- [x] `agent-common` 그룹 객체 생성
- [x] `agent-core` 그룹 객체 생성
- [ ] `agent-admin` 생성
- [ ] `agent-dev` 생성
- [ ] `agent-test` 생성
- [ ] `agent-common = admin + dev + test`
- [ ] `agent-core = admin + dev`
- [ ] `$AGENT_HOME` / `upload_files` / `api_keys` / log dir 구성
- [ ] `upload_files` agent-common R/W
- [ ] `api_keys` agent-core ONLY R/W
- [ ] `/var/log/agent-app` agent-core ONLY R/W
- [ ] agent-test 허용/차단 실제 접근시험

## E. Agent

- [x] Python 파일 고정 가정 제거
- [x] 아키텍처별 제공 실행 파일 선택 절차 반영
- [x] Agent 배치 시 `chown -R ... agent-common` 금지로 api_keys 정책 보호
- [ ] ZIP 실제 목록 확인
- [ ] 아키텍처 대상 실행 파일 배치
- [ ] 환경변수 실제 적용
- [ ] key 파일 생성 및 `agent-admin:agent-core:660`
- [ ] Agent non-root 실행
- [ ] Boot Sequence 5개 `[OK]`
- [ ] `Agent READY`
- [ ] `0.0.0.0:15034` LISTEN
- [ ] Agent evidence 정리

## F. monitor.sh

### 저장소 구현

- [x] 제공 Agent 파일명/아키텍처 기본 process pattern 처리
- [x] process 실패 → `exit 1`
- [x] port 실패 → `exit 1`
- [x] firewall 비활성 → WARNING 후 계속
- [x] CPU 수집
- [x] MEM 수집
- [x] Root DISK 수집
- [x] 20/10/80 threshold WARNING
- [x] 지정 로그 포맷
- [x] append 방식
- [x] 기존 monitor.log 쓰기 불가 검사
- [x] 실제 append 실패 → `exit 2`
- [x] `agent-core` R/W와 맞춘 `umask 0007`

### 실제 환경

- [ ] `$AGENT_HOME/bin/monitor.sh` 배치
- [ ] owner `agent-dev`
- [ ] group `agent-core`
- [ ] mode `750`
- [ ] 사용자 Ubuntu에서 `bash -n` 통과
- [ ] 정상 실행 exit 0
- [ ] process failure exit 1
- [ ] port failure exit 1
- [ ] WARNING 시 exit 0
- [ ] monitor.log 실제 누적
- [ ] monitor.log `agent-admin:agent-core:660`

## G. cron·logrotate

### 저장소 구현

- [x] agent-admin crontab 예시
- [x] `* * * * *`
- [x] cron 최소 PATH
- [x] `size 10M`
- [x] strict max 10 files = current 1 + rotated 9
- [x] `rotate 9`
- [x] `create 0660 agent-admin agent-core`

### 실제 환경

- [ ] agent-admin crontab 설치
- [ ] cron service active
- [ ] 최소 환경 monitor 성공
- [ ] 1~2분 내 자동 로그 증가
- [ ] logrotate dry-run 성공
- [ ] 강제 회전
- [ ] 최대 파일 수 정책 확인
- [ ] 회전 후 새 로그 권한 확인
- [ ] 회전 후 monitor 재기록

## H. 테스트·검증 구조

- [x] `tests/test-cases.md` T-001~T-040 구성
- [x] `reports/test-results.md` T-001~T-040 1:1 대응
- [x] `scripts/preflight.sh` read-only 사전 점검
- [x] `scripts/verify.sh`를 **현재상태 검사**로 역할 제한
- [x] `scripts/acceptance-test.sh` runtime gate 추가
- [x] verify가 최종 mission PASS를 단독 선언하지 않도록 수정
- [x] 실제 트러블슈팅 3건 보고서 반영
- [ ] 사용자 Ubuntu에서 acceptance-test 수행
- [ ] T-001~T-040 실제 상태 갱신
- [ ] 장애 복구 후 정상 재검증

## I. 재현

- [x] preflight / verify / acceptance 역할 구분
- [x] 새 터미널 절차 정의
- [x] 재부팅 후 절차 정의
- [x] 깨끗한 환경 절차 정의
- [ ] 새 터미널 실제 검증
- [ ] 재부팅 후 실제 검증
- [ ] 가능하면 깨끗한 Ubuntu 재현

## J. 제출·증빙

- [x] 요구사항 추적표 존재
- [x] 수행 내역서 현재 상태 동기화
- [x] 테스트 결과 ledger 동기화
- [x] 트러블슈팅 보고서 실제 이력 반영
- [ ] TESTED인 SSH/UFW evidence 파일 생성·정리
- [ ] IAM/Agent/monitor/cron/logrotate evidence 생성
- [ ] tracked secret 검사
- [ ] 실제 key/token/password 미노출 확인
- [ ] 개인 IP/운영 로그 전체 등 불필요 정보 제거
- [ ] 필수 요구사항 추적표 모든 행 최종 PASS

## K. 평가 설명

- [x] pgrep/ss 선택 이유
- [x] CPU/MEM/DISK 파싱 설명
- [x] 로그 포맷 및 `>>` 설명
- [x] dev/admin/core 권한 정책 설명
- [x] SSH/Root 보안 원리
- [x] WARNING vs exit 1 설명
- [x] Nginx 확장 설명
- [x] process 있음/port 없음 진단
- [x] 로그 급증/디스크 부족 대응
- [x] `rotate 9`가 strict max 10 files인 이유 추가
- [ ] 실제 evidence와 평가 답변 연결
- [ ] 사용자 구두 검증

## L. 보너스

- [x] `report.sh` 구현
- [x] 평균/최대/최소/샘플 수
- [x] 최소·최대 발생 시각
- [x] 시간 범위 분석
- [x] `archive-logs.sh` 구현
- [x] 7일 압축·archive 이동
- [x] 30일 archive 삭제
- [x] Dry Run
- [x] 권한 부족 사전검사
- [x] `find` 실패 검출
- [x] 동일 대상 덮어쓰기 방지
- [x] move 실패 후 원본 복원 시도
- [x] 대상 0개 정상 안내
- [ ] report fixture 검증
- [ ] archive fixture 검증
- [ ] 실제 monitor.log report 검증
- [ ] bonus evidence

## M. Codex 전 게이트

- [x] P0: Agent 실행 파일 가정 수정
- [x] P0: Agent 배치 재귀 chown 문제 수정
- [x] P0: monitor 로그 append 실패 처리 수정
- [x] P1: verify 역할 재정의
- [x] P1: acceptance runtime gate 추가
- [x] P1: strict 10-file logrotate 정책 보완
- [x] P1: test-results 1:1 동기화
- [x] P1: troubleshooting 실제 보고서 반영
- [x] P1: 미검증 `bash -n` 완료 주장 제거/정정
- [x] P1: bonus archive 오류 검출 보강
- [ ] 보완 브랜치 전체 정적 재검증 결과 정리
- [ ] Codex 독립 Audit
- [ ] Codex BLOCKER/MAJOR 해결
- [ ] 사용자 최종 인수

## 현재 판정

```text
Repository design       IMPLEMENTED
Pre-Codex P0/P1 fixes   IMPLEMENTED
SSH/UFW                 TESTED / evidence pending
IAM/ACL                 TODO
Agent runtime           TODO
Monitor runtime         TODO
Cron/logrotate runtime  TODO
Runtime acceptance      TODO
Evidence                TODO
Codex                    TODO
Bonus runtime           TODO
FINAL PASS               NO
```
