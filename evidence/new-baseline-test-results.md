# B1-1 New Baseline · G3 Test Evidence

- Cycle: `restart-20260816`
- Gate: `G3_TEST`
- GitHub Actions run: `31917797413`

## 통과한 자동 검증

### Static contract

- Bash syntax
- 5개 공식 Agent 환경변수
- 제공 Agent process pattern
- CPU/MEM/DISK 임계값 20/10/80
- process/port 실패 처리
- firewall warning 정책
- log append 실패 처리
- 지정 로그 포맷
- cron 매분 실행
- logrotate `10M`, current + rotated 9 = 최대 10개
- 새 Baseline/G1 연결

### Monitor behavior

1. Agent process 없음 → `exit 1`
2. process 있음 + TCP 15034 없음 → `exit 1`
3. process + port 정상 → `exit 0`, 요구 로그 포맷 생성
4. CPU/MEM/DISK 경고 임계값 초과 → WARNING 출력 후 정상 계속
5. log append 불가 → `exit 2`, 정상 결과로 오판하지 않음

## 범위

이 테스트는 Repository 구현과 monitor 동작 계약을 검증한다. 실제 Ubuntu의 SSH/UFW/users/groups/ACL/Agent Boot/cron/logrotate 실환경 상태는 G5 Runtime에서 별도로 확인한다.

## G3 판정

`PASS`

GitHub Actions에서 static + behavioral regression이 모두 성공했다.
