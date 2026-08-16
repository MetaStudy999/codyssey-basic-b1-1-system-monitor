# B1-1 R01 Environment

## 역할

B1-1의 환경설정을 **재현 가능하고 검증 가능하게** 관리합니다.

Round 01의 주 학습 경로는 `BEGINNER-GUIDE.md`에서 사용자가 주요 명령을 직접 실행하는 방식입니다. 이 폴더의 스크립트는 재현·복구를 위한 보조수단입니다.

## R01 Golden Path

- Ubuntu 22.04 LTS 또는 동등 Linux
- WSL2 Ubuntu도 `systemd`, `sshd`, UFW가 정상 동작하면 사용 가능
- Bash
- OpenSSH Server
- **UFW**를 R01 기준 Firewall로 사용
- `ss`, `ps`, `pgrep`, `df`, `stat`, `getfacl`, `runuser`, `cron`
- 기준 `AGENT_HOME=/opt/agent-app`

공식 Mission의 `$AGENT_HOME` 경로는 예시가 허용되는 변수입니다. R01에서는 공유 디렉터리를 한 사용자의 홈 아래에 두어 상위 디렉터리 권한에 막히는 문제를 피하고, `agent-common`/`agent-core` 최소 권한을 명확히 검증하기 위해 `/opt/agent-app`을 Golden Path로 사용합니다.

실제 검증된 OS/버전은 Runtime 단계에서 `versions.md`에 기록합니다.

## 권한 모델

```text
/opt/agent-app               agent-admin:agent-common 0710
├── upload_files/            agent-admin:agent-common 2770 + default ACL
├── api_keys/                agent-admin:agent-core   2770 + default ACL
├── bin/                     agent-dev:agent-core     0750
└── env.sh                   agent-admin:agent-core   0640

/var/log/agent-app           agent-admin:agent-core   2770 + default ACL
```

핵심 의미:

- `agent-common` = admin/dev/test
- `agent-core` = admin/dev
- `upload_files`는 세 계정 모두 R/W
- `api_keys`와 `/var/log/agent-app`은 test가 읽기/쓰기 불가
- `$AGENT_HOME` 자체는 common 그룹에 **traverse(x)**만 주어 불필요한 목록 열람을 줄임

## 파일

- `prerequisites.md` — 시작 조건과 필요한 도구
- `versions.md` — 기준과 실제 검증 버전
- `setup.sh` — 계정/그룹/디렉터리/monitor 설치 재현 보조
- `verify.sh` — **검증만 수행**, 시스템 설정 변경 금지
- `reset.sh` — 이 보조 스크립트가 설치한 비밀이 아닌 파일만 보수적으로 제거

## SSH/Firewall은 자동 setup 대상에서 제외

SSH와 Firewall은 잘못 자동화하면 원격 접속을 잃을 수 있습니다. Round 01에서는 다음 안전 순서를 사용합니다.

```text
현재 상태 확인
→ SSH/UFW 설정 백업
→ UFW가 이미 active면 20022를 먼저 추가 허용(기존 22 유지)
→ sshd 설정 작성
→ sshd -t 문법 검사
→ sshd -T effective config 확인
→ reload
→ 20022 LISTEN
→ 새 SSH 세션 성공
→ UFW를 20022/15034만 남도록 최종 정리
→ 최종 verify
```

`setup.sh`는 SSH 설정 파일과 Firewall 정책을 자동 변경하지 않습니다.

## Secret

실제 `t_secret.key`는 이 저장소에 만들지 않습니다.

Runtime 머신에서만 `$AGENT_HOME/api_keys/t_secret.key`를 생성하며 다음에 노출하지 않습니다.

- GitHub
- 채팅
- 터미널 캡처에서 값이 보이는 화면
- Evidence
- 로그

검증은 `test -s`, `stat` 등으로 **존재·소유권·권한만 확인**합니다.

## 안전 원칙

- `setup = 구축`
- `verify = 검증만`
- `reset = 현재 Round에서 안전하게 식별 가능한 설치물만 제거`
- 기존 계정/그룹/파일을 발견하면 무조건 삭제·덮어쓰기 하지 않음
- 광범위한 `rm -rf` 금지
- SSH/Firewall 자동 reset 금지
- 시스템 설정은 `현재 상태 → 백업 → 변경 → 문법 검사 → 적용 → 실제 상태 확인` 순서
