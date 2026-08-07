# codyssey-basic-b1-1-system-monitor

코디세이 AI/SW 기초 B1-1 미션 **「컴퓨터가 알아서 자기 상태를 점검하게 만들기」** 수행 저장소입니다.

> 현재 단계: 미션 수행 계획과 평가 추적 체계 정리

## 미션 개요

| 항목 | 내용 |
|---|---|
| 분야 | AI/SW 기초 |
| 구분 | Linux와 OS |
| 학습시간 | 40시간 |
| 핵심 결과물 | 요구사항 수행 내역서, `monitor.sh` |
| 주요 기술 | Ubuntu, SSH, UFW/firewalld, Linux 계정·그룹·ACL, Bash, cron, logrotate |

## 문서

- [B1-1 미션 원문](./b1-1-mission.md)
- [B1-1 평가 항목](./b1-1-evaluation.md)
- [요구사항 및 증빙 추적표](./docs/requirements.md)
- [미션 실행 계획](./docs/execution-plan.md)
- [최종 검수 체크리스트](./docs/final-checklist.md)
- [증빙 자료 관리 규칙](./evidence/README.md)

## 수행 흐름

```text
환경·복구 계획
  → SSH·방화벽
  → 계정·그룹·ACL
  → Agent 실행
  → monitor.sh 구현
  → 로그·cron·logrotate
  → 정상·장애 테스트
  → 증빙·문서화·최종 검수
```

## 완료 기준

- SSH 포트 `20022` 적용 및 Root 원격 로그인 차단
- 방화벽 활성화 및 `20022/tcp`, `15034/tcp` 허용
- `agent-admin`, `agent-dev`, `agent-test` 계정 구성
- `agent-common`, `agent-core` 그룹과 최소 권한·ACL 적용
- Agent Boot Sequence 5단계 `[OK]`, `Agent READY`, `0.0.0.0:15034` 확인
- `monitor.sh`의 프로세스·포트 Health Check와 CPU/MEM/DISK 수집
- 비정상 프로세스·포트에서 `exit 1`
- `/var/log/agent-app/monitor.log` 누적 기록
- `agent-admin`의 cron 매분 실행
- 로그 관리 정책 `10MB / 10개` 적용
- 정상·장애 테스트와 평가 문항별 증빙 완료

## 권장 저장소 구조

```text
.
├── README.md
├── b1-1-mission.md
├── b1-1-evaluation.md
├── docs/
│   ├── requirements.md
│   ├── execution-plan.md
│   ├── final-checklist.md
│   ├── execution-record.md       # 구현 단계에서 추가
│   └── troubleshooting.md        # 구현 단계에서 추가
├── scripts/
│   ├── monitor.sh                # 구현 단계에서 추가
│   └── verify.sh                 # 선택
├── config/
│   ├── agent-monitor.logrotate   # 구현 단계에서 추가
│   └── crontab.example           # 구현 단계에서 추가
└── evidence/
    └── README.md
```

## 작업 원칙

- `main` 브랜치에 직접 push하지 않고 기능·문서 브랜치와 Pull Request를 사용합니다.
- 커밋 메시지는 Conventional Commits 형식을 사용합니다.
- 설정 변경 전 백업과 복구 경로를 먼저 확보합니다.
- 명령 실행 결과는 가능하면 스크린샷뿐 아니라 텍스트로 함께 남깁니다.
- API 키·비밀번호·개인 IP 등 민감정보는 저장소에 커밋하지 않습니다.
- 필수 요구사항을 모두 통과한 뒤 보너스 기능을 진행합니다.
