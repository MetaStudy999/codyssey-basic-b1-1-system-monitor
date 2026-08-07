# B1-1 최종 체크리스트

> 체크는 **실제 구현과 검증 결과가 있을 때만** 합니다. 문서에 절차가 있다는 이유만으로 완료 처리하지 않습니다.

## A. 필수 요구사항

### 환경

- [x] Ubuntu/Linux 환경 확인 — 현재 Ubuntu 24.04.4 LTS
- [x] systemd·sudo·필수 도구 확인
- [ ] Bash 스크립트 실제 환경 최종 정적 검증

### SSH

- [x] SSH 포트 `20022` 설정
- [x] `PermitRootLogin no`
- [x] `sshd -t` 성공
- [x] 실제 `20022` LISTEN
- [x] 실제 `22` 미LISTEN
- [ ] 외부/별도 클라이언트 일반 사용자 `20022` 접속 증빙

### 방화벽

- [x] UFW active
- [x] Default incoming deny
- [x] TCP `20022` 허용
- [x] TCP `15034` 허용
- [x] 불필요한 `22/tcp` ALLOW 없음

### 사용자·그룹·ACL

- [x] `agent-common` 그룹 객체 생성
- [x] `agent-core` 그룹 객체 생성
- [ ] `agent-admin` 생성
- [ ] `agent-dev` 생성
- [ ] `agent-test` 생성
- [ ] `agent-common = admin + dev + test`
- [ ] `agent-core = admin + dev`
- [ ] `$AGENT_HOME` 구성
- [ ] `upload_files` agent-common R/W
- [ ] `api_keys` agent-core only R/W
- [ ] `/var/log/agent-app` agent-core only R/W
- [ ] agent-test 허용/차단 실제 접근 시험

### Agent

- [ ] `agent-app.zip` 실제 내부 구조 확인
- [ ] 실제 Agent 엔트리 파일 확인
- [ ] 환경변수 실제 적용
- [ ] 키 파일 생성·권한 설정
- [ ] 키 내용 저장소/증빙 미노출
- [ ] Agent non-root 실행
- [ ] Boot Sequence 5단계 `[OK]`
- [ ] `Agent READY`
- [ ] `0.0.0.0:15034` LISTEN

### monitor.sh

- [x] `scripts/monitor.sh` 코드 구현
- [ ] `$AGENT_HOME/bin/monitor.sh` 실제 배치
- [ ] owner `agent-dev`
- [ ] group `agent-core`
- [ ] mode `750`
- [ ] 실제 환경 `bash -n` 통과
- [ ] 정상 실행 `exit 0`
- [ ] 프로세스 실패 `exit 1`
- [ ] 포트 실패 `exit 1`
- [ ] 방화벽 비활성 WARNING 후 계속
- [ ] CPU >20 WARNING
- [ ] MEM >10 WARNING
- [ ] DISK_USED >80 WARNING
- [ ] CPU/MEM/Root DISK 실제 값 수집
- [ ] 지정 형식으로 `monitor.log` 누적

### cron·logrotate

- [x] `config/crontab.example` 구현
- [x] `config/agent-monitor.logrotate` 구현
- [ ] `agent-admin` 실제 crontab 설치
- [ ] `* * * * *` 확인
- [ ] cron 최소 환경에서 monitor 성공
- [ ] 1~2분 후 로그 자동 증가
- [ ] logrotate dry-run 성공
- [ ] `10M / rotate 10` 확인
- [ ] 강제 회전 테스트
- [ ] 회전 후 monitor.log 재기록

---

## B. 테스트·장애·복구

- [x] `tests/test-cases.md` 테스트 매트릭스 구현
- [ ] 정상 시나리오 실제 PASS
- [ ] 프로세스 장애 실제 PASS
- [ ] 포트 장애 실제 PASS
- [ ] WARNING 시나리오 실제 PASS
- [ ] ACL 허용/차단 실제 PASS
- [ ] cron 실제 PASS
- [ ] logrotate 실제 PASS
- [ ] 장애 후 복구
- [ ] 복구 후 monitor `exit 0` 재확인
- [ ] `reports/test-results.md` 실제 결과 작성

---

## C. 설명·평가

- [x] `pgrep` 선택 이유 설명 준비
- [x] `ss` 선택 이유 설명 준비
- [x] CPU/MEM/DISK 수집·파싱 설명 준비
- [x] 로그 포맷 설명 준비
- [x] dev/admin/core 권한 설계 설명 준비
- [x] SSH/Root 보안 원리 설명 준비
- [x] WARNING과 exit 1 분리 설명 준비
- [x] `>`와 `>>` 설명 준비
- [x] Nginx 확장 설명 준비
- [x] 프로세스 있음/포트 없음 진단 설명 준비
- [x] 로그 급증·디스크 부족 대응 설명 준비
- [ ] 실제 구현·증빙과 모든 설명 연결
- [ ] 사용자 구두 검증

---

## D. 재현·증빙·독립 검증

- [x] read-only `scripts/preflight.sh` 구현
- [x] read-only `scripts/verify.sh` 구현
- [ ] 실제 환경에서 `preflight.sh` 재검증
- [ ] 실제 환경에서 `verify.sh` 최종 PASS
- [ ] 새 터미널 재현
- [ ] 재부팅 후 재현
- [ ] 가능하면 깨끗한 Ubuntu에서 재현
- [ ] `evidence/` 필수 증빙 완성
- [ ] `requirements-evidence-map.md` 필수 행 모두 PASS
- [ ] Codex 독립 검증
- [ ] Codex BLOCKER/MAJOR 해결
- [ ] 사용자 최종 인수 검증

---

## E. 제출 안전

- [x] `.gitignore`에 `.env`, key, log, backup 제외 규칙 존재
- [ ] 실제 tracked secret 검사 PASS
- [ ] 비밀번호·토큰·실제 key 값 없음
- [ ] 불필요한 개인 IP 마스킹
- [ ] 시스템 백업 원본 없음
- [ ] 운영 로그 전체 없음
- [ ] 임시 파일 없음
- [ ] 문서 링크 정상
- [ ] 수행 내역서 최종 완성
- [ ] `monitor.sh` 제출 상태 확인
- [ ] 최종 Git diff/상태 확인

---

## F. 보너스 — 삭제하지 않고 별도 완성

- [x] `scripts/report.sh` 구현
- [x] 평균·최소·최대·샘플 수 구현
- [x] 최소·최대 발생 시각 구현
- [x] 선택 시간 구간 분석 구현
- [x] `scripts/archive-logs.sh` 구현
- [x] 7일 경과 로그 압축·아카이브 구현
- [x] 30일 경과 archive 삭제 구현
- [x] Dry Run·예외 처리 구현
- [ ] `report.sh` fixture 검증
- [ ] 실제 `monitor.log` 통계 검증
- [ ] archive fixture 검증
- [ ] 30일 삭제 fixture 검증
- [ ] 보너스 증빙 완성

---

## 최종 판정

현재 상태:

```text
저장소 구조/문서       IMPLEMENTED
SSH/UFW 실제 환경      TESTED
IAM/ACL                진행 전/부분 구성
Agent                   TODO
monitor.sh              IMPLEMENTED / runtime TODO
cron/logrotate          IMPLEMENTED / runtime TODO
테스트                  IMPLEMENTED / runtime TODO
평가 설명               IMPLEMENTED
재현 도구               IMPLEMENTED / final run TODO
증빙                    TODO
Codex audit             TODO
사용자 acceptance       TODO
Bonus                   IMPLEMENTED / test TODO
```

**FINAL PASS는 아직 아닙니다.** 남은 실제 환경 수행·검증을 완료한 뒤 체크합니다.
