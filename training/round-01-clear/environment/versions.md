# B1-1 R01 — Versions

## 공식 기준

공식 Mission은 **Ubuntu 22.04 LTS 또는 동등 Linux 환경**을 허용합니다.

## Reference Build 기준

| 항목 | 기준 | 실제 Runtime 검증 |
|---|---|---|
| OS | Ubuntu 22.04 LTS 또는 동등 Linux | 미검증 |
| Shell | Bash | 미검증 |
| OpenSSH | 배포판 제공 버전 | 미검증 |
| Firewall | UFW 또는 firewalld | 미검증 |
| Process tools | procps (`ps`, `pgrep`) | 미검증 |
| Network tools | iproute2 (`ss`) | 미검증 |
| ACL | acl (`getfacl`, `setfacl`) | 미검증 |
| Scheduler | cron | 미검증 |
| Archive | unzip | 미검증 |

## 기록 원칙

실제 Runtime을 시작할 때 아래 명령 결과를 기준으로 이 표를 갱신합니다.

```bash
cat /etc/os-release
uname -m
bash --version | head -n 1
ssh -V
ss -V
getfacl --version
crontab -V 2>&1 || true
```

예상 버전을 실제 검증 버전처럼 기록하지 않습니다.
