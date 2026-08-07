# 01. 실습 환경 준비와 사전 점검

> **기억 문장:** 바꾸기 전에 환경부터 확인한다.

이 장은 B1-1의 첫 번째 실제 수행 단계입니다. 시스템을 변경하기 전에 **현재 Linux 환경이 미션을 수행할 수 있는 상태인지 확인**합니다.

이 장에서는 원칙적으로 SSH 포트, UFW 규칙, 사용자·그룹, 파일 권한을 변경하지 않습니다. 변경 작업은 각각의 담당 장에서 수행합니다.

---

## 1. 목표

이 장을 마치면 다음을 확인할 수 있어야 합니다.

- 현재 실행 사용자와 작업 위치
- 운영체제와 버전
- CPU 아키텍처
- `systemd` 사용 가능 여부
- `sudo` 권한
- B1-1에서 필요한 주요 도구 설치 여부
- 현재 네트워크·디스크의 기본 상태
- 다음 단계로 진행 가능한지 여부

### 이 장의 PASS 기준

문서를 읽었다고 PASS가 아닙니다.

```text
환경 확인
+ 필수 도구 확인
+ 결과 기록
= 01단계 완료
```

실제 증빙 정리는 11장에서 수행하므로, 이 장에서 확인한 상태는 우선 `TESTED`로 관리할 수 있습니다.

---

## 2. 이해 — 미션 기준과 실제 실습 환경을 구분한다

### 2.1 원본 미션 기준

원본 미션은 다음 환경을 기준으로 합니다.

```text
Ubuntu 22.04 또는 동등한 Linux 환경
Bash
```

따라서 이 저장소 문서가 특정 Ubuntu 버전을 원본 미션보다 우선하여 요구하지 않습니다.

### 2.2 현재 실제 실습 환경

2026-08-07 실제 사전 점검에서 확인한 환경은 다음과 같습니다.

| 항목 | 실제 확인값 | 상태 |
|---|---|---|
| 사용자 | `ubuntu` | 확인 |
| 작업 위치 | `/home/ubuntu` | 확인 |
| 운영체제 | Ubuntu 24.04.4 LTS (Noble Numbat) | 확인 |
| CPU 아키텍처 | `x86_64` | 확인 |
| PID 1 | `systemd` | 확인 |
| systemd | 255 | 확인 |
| sudo | 종료 코드 `0` | 확인 |
| OpenSSH Server | `/usr/sbin/sshd` | 확인 |
| UFW | `/usr/sbin/ufw` | 확인 |
| cron | `/usr/sbin/cron` | 확인 |
| ACL 조회 | `/usr/bin/getfacl` | 확인 |
| ACL 설정 | `/usr/bin/setfacl` | 확인 |
| 포트 조회 | `/usr/bin/ss` | 확인 |
| logrotate | `/usr/sbin/logrotate` | 확인 |

> Ubuntu 24.04.4 LTS는 **현재 실습 사례**입니다. 원본 미션의 필수 버전을 24.04로 바꾸는 의미가 아닙니다.

### 2.3 CPU 아키텍처는 요구사항과 구분한다

현재 실습 환경은 `x86_64`입니다. 하지만 원본 미션에서 `x86_64` 자체를 필수 조건으로 요구한다고 단정하지 않습니다.

다른 아키텍처(`aarch64` 등)를 사용한다면 바로 실패로 판정하지 않고, **제공 Agent가 해당 아키텍처에서 실행 가능한지 06장에서 확인**합니다.

---

## 3. 실행 — 빠른 점검 모드

B1-1을 빠르게 다시 수행할 때는 아래 명령들을 순서대로 실행하면 됩니다. 모두 조회 중심입니다.

```bash
whoami
pwd
cat /etc/os-release
uname -m
ps -p 1 -o comm=
systemctl --version | head -n 2
sudo -v
echo $?
command -v sshd || echo "[MISSING] openssh-server"
command -v ufw || echo "[MISSING] ufw"
command -v cron || echo "[MISSING] cron"
command -v getfacl || echo "[MISSING] acl"
command -v setfacl || echo "[MISSING] acl"
command -v ss || echo "[MISSING] iproute2"
command -v logrotate || echo "[MISSING] logrotate"
```

### 왜 한꺼번에 자동 변경하지 않나요?

사전 점검은 **환경을 고치는 단계가 아니라 상태를 파악하는 단계**입니다. 없는 패키지가 발견되면 그 결과를 보고 필요한 항목만 설치합니다.

---

## 4. 실행 — 입문자 단계별 모드

처음 수행하거나 각 명령의 뜻을 학습할 때는 아래 순서로 하나씩 확인합니다.

### 4.1 현재 사용자

```bash
whoami
```

현재 실습에서 확인된 값:

```text
ubuntu
```

- 일반 사용자이면 `[GO]`
- 처음부터 `root`로 모든 작업을 진행 중이면 `[CHECK]`

이 미션은 일반 사용자와 최소 권한 원칙을 학습하므로, Root 상시 사용을 기본 작업 방식으로 삼지 않습니다.

### 4.2 현재 작업 위치

```bash
pwd
```

현재 실습에서 확인된 값:

```text
/home/ubuntu
```

현재 위치가 다른 경로라고 해서 실패는 아닙니다. 파일 생성이나 저장소 작업 전에는 위치를 다시 확인합니다.

### 4.3 Ubuntu 버전

```bash
cat /etc/os-release
```

현재 실습 핵심 출력:

```text
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
```

판정 원칙:

- Ubuntu 22.04: 원본 미션 기준에 직접 부합
- Ubuntu 24.04 계열: 현재 실습처럼 동등 환경으로 수행 가능 여부를 실제 기능으로 검증
- 다른 Linux: SSH/UFW 또는 대체 방화벽/systemd/cron 등 차이를 확인한 뒤 진행
- Docker처럼 `systemd`·SSH·방화벽 실습이 제한되는 환경: 차이를 확인하기 전에는 시스템 구성 단계로 진행하지 않음

환경 차이는 [환경별 차이](./reference/environment-differences.md)에 기록합니다.

### 4.4 CPU 아키텍처

```bash
uname -m
```

현재 실습:

```text
x86_64
```

이 값은 **환경 기록용**입니다. 다른 아키텍처라면 Agent 호환성을 06장에서 검증합니다.

### 4.5 PID 1과 systemd

```bash
ps -p 1 -o comm=
```

현재 실습:

```text
systemd
```

이어서:

```bash
systemctl --version
```

현재 실습 첫 줄:

```text
systemd 255 (255.4-1ubuntu8.16)
```

B1-1에서는 SSH와 cron 같은 서비스를 다루므로 `systemd` 사용 가능 여부가 중요합니다.

### 4.6 sudo 권한

```bash
sudo -v
```

성공하면 일반적으로 출력이 없습니다. 바로 다음 명령으로 종료 코드를 확인합니다.

```bash
echo $?
```

현재 실습:

```text
0
```

- `0` = 성공
- sudo 권한 없음 = `[STOP]` 후 관리자 권한 확보

### 4.7 필수 도구

OpenSSH Server:

```bash
command -v sshd || echo "[MISSING] openssh-server"
```

현재 실습:

```text
/usr/sbin/sshd
```

UFW:

```bash
command -v ufw || echo "[MISSING] ufw"
```

현재 실습:

```text
/usr/sbin/ufw
```

cron:

```bash
command -v cron || echo "[MISSING] cron"
```

현재 실습:

```text
/usr/sbin/cron
```

ACL:

```bash
command -v getfacl || echo "[MISSING] acl"
command -v setfacl || echo "[MISSING] acl"
```

현재 실습:

```text
/usr/bin/getfacl
/usr/bin/setfacl
```

포트 조회 도구:

```bash
command -v ss || echo "[MISSING] iproute2"
```

현재 실습:

```text
/usr/bin/ss
```

로그 회전 도구:

```bash
command -v logrotate || echo "[MISSING] logrotate"
```

현재 실습:

```text
/usr/sbin/logrotate
```

---

## 5. 확인 — 추가 운영 상태 기록

아래 항목은 환경을 파악하는 데 유용하지만 아직 현재 세션의 B1-1 증빙으로 확정하지 않았습니다. 필요할 때 실행하고 결과를 기록합니다.

### 5.1 IP 주소

```bash
ip -brief addr
```

SSH 접속 시험이나 다른 장비에서 Agent에 접근할 때 사용할 주소를 파악합니다.

### 5.2 Root 디스크 여유 공간

```bash
df -h /
```

나중에 `monitor.sh`가 Root 파티션의 사용률을 수집하므로 기준 상태를 알아 두면 좋습니다.

### 5.3 현재 주요 포트

시스템 변경 전 기준 상태를 확인할 때 사용합니다.

```bash
sudo ss -lntp | grep -E ':(22|20022|15034)\b' || true
```

SSH와 방화벽의 실제 변경 및 최종 검증은 각각 03장과 04장에서 수행합니다.

---

## 6. GO / STOP 판정

### `[GO]`

다음 조건이면 02장으로 진행할 수 있습니다.

```text
일반 사용자 사용 가능
sudo 사용 가능
Linux 환경 확인
systemd 사용 가능
sshd 사용 가능
UFW 사용 가능
cron 사용 가능
ACL 도구 사용 가능
ss 사용 가능
logrotate 사용 가능
```

### `[STOP]`

다음 상황에서는 시스템 설정을 변경하지 않습니다.

- `sudo` 권한이 없음
- `systemd`가 동작하지 않는데 systemd 기반 절차를 그대로 수행하려 함
- SSH 설정을 변경할 예정인데 복구 가능한 콘솔/접속 방법이 없음
- 필요한 도구가 누락되었는데 원인을 확인하지 않음
- 현재 환경이 원본 미션과 크게 다른데 차이를 검토하지 않음

> 도구 하나가 없다고 미션 전체 실패는 아닙니다. 부족한 패키지를 안전하게 보완한 뒤 다시 점검합니다.

---

## 7. 오류와 복구

### `System has not been booted with systemd`

Docker 컨테이너 또는 systemd가 활성화되지 않은 WSL 환경에서 흔히 볼 수 있습니다.

**대응:** 환경별 차이를 먼저 확인하고, 가능하면 systemd를 사용할 수 있는 Ubuntu VM/WSL/OrbStack 환경으로 재현합니다.

### `user is not in the sudoers file`

현재 계정에 관리자 권한이 없습니다.

**대응:** 관리자 권한이 있는 계정으로 전환하거나 해당 환경의 관리자에게 sudo 권한을 요청합니다.

### `[MISSING] ...`

필수 도구가 설치되지 않았다는 뜻입니다.

**대응:** 누락 패키지를 확인한 뒤 필요한 것만 설치하고 같은 `command -v` 검사로 재확인합니다.

### 아키텍처가 `aarch64`

그 자체로 실패가 아닙니다.

**대응:** 06장에서 제공 Agent의 실행 형태(Python 소스인지 특정 아키텍처 바이너리인지)를 확인하여 호환성을 판단합니다.

---

## 8. 검증과 요구사항 추적

이 장과 연결된 마스터 추적 항목은 다음입니다.

| ID | 확인 대상 | 현재 상태 |
|---|---|---|
| `ENV-01` | Ubuntu 22.04 또는 동등 Linux 환경 | `TESTED` |
| `ENV-02` | Bash 기반 수행 | `TODO` — 스크립트 구현과 함께 최종 검증 |
| `ENV-03` | systemd·sudo·필수 도구 | `TESTED` |

전체 상태는 [요구사항-구현-검증-증빙 대응표](./reference/requirements-evidence-map.md)에서 관리합니다.

`TESTED`는 실제 환경에서 확인했지만 **증빙 파일 정리가 아직 남아 있다는 뜻**입니다. `PASS`는 11장 이후 구현·테스트·증빙이 모두 연결된 뒤 부여합니다.

---

## 9. 증빙

최종적으로 다음 종류의 결과를 `evidence/01-environment/`에 저장할 수 있습니다.

```text
OS 버전
CPU 아키텍처
PID 1 / systemd
sudo 검증 결과
필수 도구 경로
```

주의사항:

- 비밀번호를 저장하지 않습니다.
- 불필요한 개인 IP·토큰·키 값을 공개하지 않습니다.
- 실제 실행하지 않은 결과를 예시 출력으로 증빙하지 않습니다.

---

## 10. 이번 단계 기억하기

### 한 문장

> **바꾸기 전에 환경부터 확인한다.**

### 핵심어 3개

```text
OS · systemd · tools
```

### 핵심 명령 3개

```bash
cat /etc/os-release
systemctl --version
command -v <명령>
```

### 내가 설명할 수 있어야 할 것

> 왜 SSH나 방화벽을 먼저 바꾸지 않고 현재 환경부터 확인하는가?

답의 핵심은 **환경 차이 때문에 같은 명령도 다르게 동작할 수 있고, 잘못된 시스템 변경을 사전에 막기 위해서**입니다.

---

## 11. 완료 체크

- [x] 현재 사용자 확인
- [x] 현재 작업 위치 확인
- [x] Ubuntu 버전 확인
- [x] CPU 아키텍처 확인
- [x] PID 1 / systemd 확인
- [x] sudo 사용 가능 확인
- [x] OpenSSH Server 확인
- [x] UFW 확인
- [x] cron 확인
- [x] ACL 도구 확인
- [x] `ss` 확인
- [x] logrotate 확인
- [ ] Bash 요구사항은 실제 `monitor.sh` 구현과 함께 최종 검증
- [ ] 최종 증빙 파일 정리

현재 01단계는 **사전 환경 검증 `TESTED` 상태**입니다. 증빙 정리가 완료되기 전에는 최종 `PASS`로 표시하지 않습니다.

---

## 이동

- [이전: 00. 시작 안내](./00-start-here.md)
- [다음: 02. 저장소 작업 체계](./02-repository-workflow.md)
- [전체 목차](./README.md)
