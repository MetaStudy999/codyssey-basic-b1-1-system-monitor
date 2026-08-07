# 08. 로그 관리와 cron 자동화

## 목표

`monitor.log`를 누적하고 logrotate와 `agent-admin`의 매분 cron을 구성합니다.

## 주요 작업

- 로그 소유권·권한 확인
- 최대 `10MB`, 최대 `10개` 회전 설정
- cron 최소 환경 시험
- 절대경로와 필수 환경변수 적용
- 매분 실행 후 로그 증가 확인

## STOP 조건

- 최소 환경 시험 실패
- 로그 쓰기 권한 실패
- cron 실행 계정 불일치

## 완료 조건

- [ ] 로그 누적
- [ ] logrotate 강제 시험
- [ ] cron 매분 실행

## 이동

- [이전: 07. monitor.sh](./07-monitor-script.md)
- [다음: 09. 테스트와 복구](./09-testing-recovery.md)
