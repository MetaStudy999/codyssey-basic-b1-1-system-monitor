# 환경별 차이

B1-1 원본 미션의 환경 기준은 **Ubuntu 22.04 또는 동등한 Linux 환경**입니다.

현재 실제 수행 사례는 **Ubuntu 24.04.4 LTS**이며, 이 문서는 환경에 따라 달라질 수 있는 부분을 분리해 기록합니다.

> 특정 환경의 차이를 원본 미션 요구사항으로 바꾸지 않습니다.

## 비교 대상

| 환경 | 주요 확인점 |
|---|---|
| Ubuntu 22.04 VM/서버 | 원본 기준에 가장 직접적으로 맞는 재현 환경 |
| Ubuntu 24.04 계열 | systemd/OpenSSH socket activation 등 실제 동작 차이 확인 |
| WSL2 Ubuntu | systemd 활성화, Windows 네트워크·방화벽, 외부 접속 방식 |
| OrbStack Ubuntu | macOS 호스트와 게스트 네트워크, systemd, 포트 접근 방식 |
| Docker 컨테이너 | PID 1, systemd, SSH/UFW 실습 적합성 여부 |

## 공통으로 확인할 항목

```text
PID 1 / systemd
sudo
OpenSSH Server
SSH 실제 LISTEN
UFW 또는 대체 방화벽의 실제 적용 범위
호스트 방화벽
포트 포워딩/NAT
cron
재부팅 후 지속성
CPU 아키텍처
제공 Agent 실행 가능 여부
```

## Ubuntu 24.04.4 실제 관찰 사항

현재 실습에서는 OpenSSH가 초기 상태에서 다음 구조로 동작했습니다.

```text
ssh.socket active
ssh.service inactive
22/tcp는 systemd가 LISTEN
```

`Port 20022` 설정 후 `systemctl daemon-reload`를 수행하자 `sshd-socket-generator`가 다음 위치에 socket 주소 설정을 자동 생성했습니다.

```text
/run/systemd/generator/ssh.socket.d/addresses.conf
```

따라서 Ubuntu 24.04에서는 `sshd_config`만 보는 것이 아니라 다음도 함께 확인해야 했습니다.

```bash
systemctl status ssh.socket --no-pager
systemctl cat ssh.socket
sudo ss -lntp
```

이 내용은 **현재 24.04.4 실습에서 확인된 환경 차이**이며 Ubuntu 22.04의 모든 설치가 같은 방식이라고 가정하지 않습니다.

## WSL2

확인할 것:

```text
systemd가 활성화되어 있는가?
Windows에서 WSL로 SSH 접근이 필요한가?
Windows Defender Firewall 규칙은 어떻게 되어 있는가?
WSL 네트워크 모드와 주소는 무엇인가?
재부팅/WSL 재시작 후 cron·서비스가 어떻게 동작하는가?
```

`systemctl`이 동작하지 않는 WSL 환경에서 systemd 기반 본문 명령을 그대로 실행하지 않습니다.

## OrbStack

확인할 것:

```text
Linux 머신의 PID 1
macOS ↔ Linux 머신 네트워크 접근
OpenSSH 설치·socket/service 상태
호스트 macOS 방화벽과 게스트 UFW의 역할 차이
```

OrbStack의 Docker 컨테이너와 OrbStack Linux 머신을 같은 환경으로 취급하지 않습니다.

## Docker 컨테이너

B1-1은 다음을 실제로 다룹니다.

```text
systemd
SSH server
UFW
cron
다중 사용자·ACL
```

일반적인 단일 프로세스 Docker 컨테이너는 이 전체 실습을 재현하기에 적합하지 않을 수 있습니다.

따라서 Docker는 `monitor.sh` 일부 테스트나 별도 고도화에는 사용할 수 있지만, **B1-1 전체 시스템 운영 실습의 유일한 재현 환경으로 사용하기 전에는 기능 차이를 검증**합니다.

## CPU 아키텍처

현재 실제 환경은:

```text
x86_64
```

입니다.

그러나 원본 미션의 필수 요구사항으로 `x86_64`를 추가하지 않습니다. `aarch64` 등 다른 환경에서는 제공 Agent의 실제 파일 형태와 실행 가능 여부를 06장에서 확인합니다.

## 문서 작성 원칙

본문에는 가능한 한 미션의 공통 흐름을 둡니다.

환경에 따라 달라지는 명령이나 해석은 이 문서 또는 해당 장의 **환경 차이** 절에 분리합니다.

```text
원본 요구사항
    ↓
공통 절차
    ↓
환경별 차이
    ↓
실제 동작 검증
```

이렇게 해야 한 환경의 우연한 동작을 전체 미션의 규칙으로 오해하지 않습니다.
