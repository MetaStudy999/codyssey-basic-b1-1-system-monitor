# 06. Agent 애플리케이션 실행환경 구성

## 목표

제공 Agent를 일반 사용자로 실행하고 Boot Sequence와 포트 상태를 확인합니다.

## 주요 작업

1. 아키텍처에 맞는 실행 파일 선택
2. 고정 환경변수 적용
3. 키 파일과 로그 경로 권한 구성
4. 일반 사용자로 실행
5. Boot Sequence 5단계 `[OK]`
6. `Agent READY` 확인
7. `0.0.0.0:15034` LISTEN 확인

## STOP 조건

- `Agent READY`가 출력되지 않음
- TCP `15034`가 LISTEN하지 않음

## 완료 조건

- [ ] 일반 사용자 실행
- [ ] Boot 5단계 성공
- [ ] 프로세스와 포트 확인

## 이동

- [이전: 05. 사용자·그룹·ACL](./05-users-groups-acl.md)
- [다음: 07. monitor.sh](./07-monitor-script.md)
