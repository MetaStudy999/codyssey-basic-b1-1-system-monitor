# B1-1 R01 — Reference Build

## 목적

이 문서는 B1-1의 **Reference Complete Version 준비 상태**를 기록합니다.

Reference Build는 실제 Ubuntu/WSL에서 미션을 통과했다고 주장하는 단계가 아닙니다. 실제 Runtime, sudo 작업, SSH/Firewall 적용, 프로세스 실행, 포트 LISTEN, cron 자동 실행, Evidence 확보는 Phase C에서 별도로 수행합니다.

## Source of Truth

1. `b1-1-mission.pdf`
2. `b1-1-mission.md`
3. `b1-1-evaluation.md`
4. `agent-app.zip`

공식 원본은 수정하지 않습니다.

## Reference Complete Path

1. Source/Evaluation 분석
2. Baseline 확인
3. Golden Path 확정
4. SSH 안전 전환 설계
5. Firewall 정책 설계
6. 계정/그룹/ACL 구성
7. Agent 실행 환경 구성
8. 제공 앱 아키텍처 확인 및 실행
9. `monitor.sh` 구현
10. Process/Port Health Check
11. CPU/MEM/DISK 수집과 Warning
12. `monitor.log` 누적
13. 10MB/10개 로그 관리
14. `agent-admin` cron 매분 실행
15. 통합 `verify.sh`
16. 안전한 `reset.sh`
17. Requirement ↔ Verification ↔ Evidence 연결
18. Evaluation 예상 Q&A
19. Secret 점검
20. 실제 Runtime/Evidence 후 CLEAR

## Reference Build 준비 결과

- [x] 공식 요구사항 분석
- [x] Evaluation 분석
- [x] 전체 수행 순서
- [x] Round 01 운영 원칙
- [x] `BEGINNER-GUIDE.md` 전체 Runtime Step 01~15 작성
- [x] `CHECKLIST.md`를 Reference/Runtime 구분으로 정리
- [x] `monitor.sh` 기준 구현
- [x] 환경 준비 문서
- [x] 재현 보조 `setup.sh`
- [x] 검증 전용 `verify.sh`
- [x] 보수적 `reset.sh`
- [x] Requirement/Evidence Mapping
- [x] Evaluation Q&A 기준 답안
- [x] Evidence 저장 규칙
- [x] 실제 Secret 값을 Reference 파일에 저장하지 않음
- [x] 실제 Runtime을 수행하지 않은 항목을 PASS/CLEAR로 표시하지 않음

## Phase C Runtime에서만 완료할 것

- [ ] 실제 OS/버전 재검증
- [ ] `agent-app.zip` 내부 파일/CPU 아키텍처 실제 확인
- [ ] 실제 SSH `20022` 적용/접속 검증
- [ ] 실제 Firewall 검증
- [ ] 실제 계정/권한/ACL 검증
- [ ] 실제 Agent Boot 5/5 및 `Agent READY`
- [ ] 실제 `15034` LISTEN
- [ ] 실제 `monitor.sh` 실행
- [ ] 실제 Process/Port 실패 경로 확인
- [ ] 실제 cron 자동 로그 증가
- [ ] 실제 로그 회전 동작 확인
- [ ] `verify.sh` 실제 실행 결과 0 FAIL
- [ ] 실제 Evidence 확보
- [ ] 최종 `✅ CLEAR`

## Reference Build 자체 검토

- 공식 Mission의 필수 요구사항과 `requirements-mapping.md` 연결 확인
- 공식 Evaluation의 설명형 항목과 `evaluation-qa.md` 연결 확인
- `monitor.sh`에 Process/Port Health Check, Resource, Warning, Log, 10MB/10개 정책 포함 확인
- `setup.sh`가 SSH/Firewall을 자동 변경하지 않도록 제한
- `verify.sh`는 검증 전용으로 설계
- `reset.sh`는 사용자/그룹/Secret/SSH/Firewall을 삭제하지 않는 보수적 정책 적용
- 실제 Secret 값은 새 Reference 산출물에 기록하지 않음

## 현재 판정

**Reference Build: 기준본 준비 완료**

**Mission 상태: 🟡 ACTIVE 유지 / Runtime 미검증 / CLEAR 아님**

다음 Phase A 작업은 B1-2 Reference Build입니다. B1-2의 Runtime은 B1-1 CLEAR 이후에 시작합니다.
