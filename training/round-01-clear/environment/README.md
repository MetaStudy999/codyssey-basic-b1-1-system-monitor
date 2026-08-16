# B1-1 R01 Environment

## 역할

B1-1의 환경설정을 **재현 가능하고 검증 가능하게** 관리합니다.

Round 01의 주 학습 경로는 `BEGINNER-GUIDE.md`에서 사용자가 주요 명령을 직접 실행하는 방식입니다. 이 폴더의 스크립트는 재현·복구를 위한 보조수단입니다.

## Golden Path

- Ubuntu 22.04 LTS 또는 동등 Linux
- WSL2 Ubuntu도 systemd/sshd/UFW가 정상 동작하는 경우 사용할 수 있음
- Bash
- OpenSSH Server
- UFW 또는 firewalld 중 하나
- `ss`, `ps`, `pgrep`, `df`, `stat`, `getfacl`, `cron`

실제 검증된 OS/버전은 Runtime 단계에서 `versions.md`에 기록합니다.

## 파일

- `prerequisites.md` — 시작 조건과 필요한 도구
- `versions.md` — 기준과 실제 검증 버전
- `setup.sh` — 계정/그룹/디렉터리/monitor 설치 재현 보조
- `verify.sh` — **검증만 수행**, 시스템 변경 금지
- `reset.sh` — 이 보조 스크립트가 설치한 B1-1 파일만 보수적으로 제거

## SSH/Firewall은 자동 setup 대상에서 제외

SSH와 Firewall은 잘못 자동화하면 원격 접속을 잃을 수 있습니다. Round 01에서는 다음 순서로 직접 수행합니다.

`현재 상태 → 백업 → 새 포트 허용 → sshd 변경 → 문법 검사 → 적용 → 20022 LISTEN → 새 접속 확인 → Firewall 최종 정리`

`setup.sh`는 SSH 설정 파일과 Firewall 정책을 자동 변경하지 않습니다.

## Secret

실제 `t_secret.key`는 이 저장소에 만들지 않습니다.

Runtime 머신에서만 `$AGENT_HOME/api_keys/t_secret.key`를 생성하며 다음에 노출하지 않습니다.

- GitHub
- 채팅
- 터미널 캡처에서 값이 보이는 화면
- Evidence
- 로그

## 안전 원칙

- `setup = 구축`
- `verify = 검증만`
- `reset = 이 Round 보조 설치물만 제거`
- 기존 계정/그룹을 발견하면 재사용하며 삭제하지 않음
- 광범위한 `rm -rf` 금지
- SSH/Firewall 자동 reset 금지
