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

## Reference Build에서 준비하는 것

- [x] 공식 요구사항 분석
- [x] Evaluation 분석
- [x] 전체 수행 순서
- [x] Round 01 운영 원칙
- [x] `monitor.sh` 기준 구현
- [x] 환경 준비 문서
- [x] 재현 보조 `setup.sh`
- [x] 검증 전용 `verify.sh`
- [x] 보수적 `reset.sh`
- [x] Requirement/Evidence Mapping
- [x] Evidence 저장 규칙
- [x] Secret 보호 규칙
- [ ] 실제 OS/버전 재검증
- [ ] 실제 SSH `20022` 적용/접속 검증
- [ ] 실제 Firewall 검증
- [ ] 실제 계정/권한/ACL 검증
- [ ] 실제 Agent Boot 5/5 및 `Agent READY`
- [ ] 실제 `15034` LISTEN
- [ ] 실제 `monitor.sh` 실행
- [ ] 실제 cron 자동 로그 증가
- [ ] 실제 로그 회전 동작 확인
- [ ] 실제 Evidence 확보
- [ ] 최종 `✅ CLEAR`

## 현재 판정

**Reference Build 준비 중 / Mission 상태는 🟡 ACTIVE 유지**

실제 Runtime을 수행하지 않은 항목은 PASS 또는 CLEAR로 기록하지 않습니다.
