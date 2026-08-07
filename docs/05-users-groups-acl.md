# 05. 사용자·그룹·디렉터리·ACL 구성

## 목표

미션에서 요구한 사용자·그룹·디렉터리와 최소 권한 정책을 구성합니다.

## 대상

- 사용자: `agent-admin`, `agent-dev`, `agent-test`
- 그룹: `agent-common`, `agent-core`
- 경로: `/opt/agent-app`, `/var/log/agent-app`

## 주요 검증

- `agent-test`는 업로드 경로 사용 가능
- `agent-test`는 키 경로 접근 차단
- `agent-admin`, `agent-dev`는 역할에 맞는 접근 가능

## 완료 조건

- [ ] 사용자·그룹 구성 일치
- [ ] 소유권·권한 확인
- [ ] ACL 허용·차단 시험 통과

## 이동

- [이전: 04. 방화벽](./04-firewall-network.md)
- [다음: 06. Agent 실행환경](./06-agent-setup.md)
