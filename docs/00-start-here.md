# 00. 시작 안내

## 이번 장에서 하는 일

기준 환경, 고정 경로, 실행 계정, GO/STOP 규칙을 확정합니다.

## 고정 변수

```bash
AGENT_HOME=/opt/agent-app
AGENT_PORT=15034
AGENT_UPLOAD_DIR=/opt/agent-app/upload_files
AGENT_KEY_PATH=/opt/agent-app/api_keys/t_secret.key
AGENT_LOG_DIR=/var/log/agent-app
```

## 실행 계정 구분

- 기존 sudo 사용자
- `agent-admin`
- `agent-dev`
- `agent-test`

## 완료 조건

- [ ] 기준 환경 확정
- [ ] 고정 경로 확인
- [ ] 실행 계정 표기법 확인
- [ ] GO/STOP 규칙 확인

## 이동

- [다음: 01. 환경 준비](./01-environment.md)
- [전체 목차](./README.md)
