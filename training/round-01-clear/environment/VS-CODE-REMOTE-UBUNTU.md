# B1-1 VS Code Remote Ubuntu Guide

## 목적

B1-1을 macOS + OrbStack Ubuntu 24.04에서 수행할 때 VS Code Terminal이 macOS 공유경로로 열려 다시 `cd ~`와 Repository 이동을 반복하는 문제를 방지합니다.

B1-1의 Primary Runtime은 다음 구조를 사용합니다.

```text
macOS
└─ VS Code
   └─ Remote-SSH `orb`
      └─ OrbStack Ubuntu 24.04
         └─ $HOME/codyssey/codyssey-basic-b1-1-system-monitor
```

핵심은 **VS Code UI만 macOS에 두고 Repository·Terminal·Git·Runtime은 Ubuntu 안에 두는 것**입니다.

---

## 1. Repository 위치

B1-1 Primary Repository는 Ubuntu home 아래를 사용합니다.

```bash
mkdir -p "$HOME/codyssey"
cd "$HOME/codyssey"
```

권장 경로:

```text
$HOME/codyssey/codyssey-basic-b1-1-system-monitor
```

다음 경로는 OrbStack이 공유해 주는 macOS filesystem이므로 Primary B1-1 Workspace로 사용하지 않습니다.

```text
/Users/<mac-user>/...
/mnt/mac/Users/<mac-user>/...
```

Mac 공유경로는 파일 교환/참조 용도로만 사용합니다.

---

## 2. VS Code 연결

macOS VS Code에서:

```text
Command Palette
→ Remote-SSH: Connect to Host
→ orb
```

연결 후:

```text
File
→ Open Folder
→ /home/<linux-user>/codyssey/codyssey-basic-b1-1-system-monitor
```

또는 Linux 안에서 `$HOME`을 기준으로 같은 Repository를 선택합니다.

OrbStack built-in SSH `orb`는 VS Code Remote 개발/관리 채널입니다.

---

## 3. B1-1 Repository VS Code 설정

Root의 `.vscode/settings.json`은 다음 정책을 적용합니다.

```json
{
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.cwd": "${workspaceFolder}",
  "terminal.integrated.shellIntegration.enabled": true,
  "python-envs.workspaceSearchPaths": [
    "./**/.venv"
  ]
}
```

B1-1 자체는 Python virtual environment가 필수인 Mission이 아니므로 `.venv`를 억지로 만들지 않습니다. Python Mission에서 같은 공통 설정을 재사용할 수 있도록 search path만 안전하게 둡니다.

---

## 4. 새 Terminal 정상 상태

VS Code에서 새 Terminal을 열었을 때 다음과 같은 형태가 목표입니다.

```text
user@ubuntu:~/codyssey/codyssey-basic-b1-1-system-monitor$
```

다음처럼 macOS 경로가 보이면 Workspace를 잘못 연 것입니다.

```text
/Users/<mac-user>/...
/mnt/mac/Users/<mac-user>/...
```

이 경우 Terminal 안에서 매번 `cd`로 우회하지 말고, **VS Code에서 Ubuntu Repository Folder 자체를 다시 Open**합니다.

---

## 5. 환경 확인 명령

새 Terminal에서 다음을 실행합니다.

```bash
printf 'SHELL=%s\n' "$SHELL"
printf 'PWD=%s\n' "$PWD"
printf 'HOME=%s\n' "$HOME"
printf 'VIRTUAL_ENV=%s\n' "${VIRTUAL_ENV:-<none>}"

cat /etc/os-release
uname -m
ps -p 1 -o comm=

command -v bash
command -v git

git rev-parse --show-toplevel
git branch --show-current
git status --short
```

경로 판정:

```bash
case "$PWD" in
  /Users/*|/mnt/mac/*)
    echo '[WARN] macOS shared path에서 작업 중입니다.'
    ;;
  "$HOME"/*)
    echo '[PASS] Ubuntu home filesystem에서 작업 중입니다.'
    ;;
  *)
    echo '[INFO] 작업 경로를 확인하세요.'
    ;;
esac
```

B1-1에서는 `VIRTUAL_ENV=<none>`이어도 정상입니다.

---

## 6. OrbStack SSH와 B1-1 SSH 구분

B1-1에서는 두 SSH 개념을 반드시 분리합니다.

```text
OrbStack built-in SSH `orb`
= macOS VS Code → Ubuntu 개발/관리 접속

Ubuntu OpenSSH `sshd:20022`
= B1-1 Mission에서 직접 구성/검증하는 대상
```

따라서 VS Code가 `orb`로 접속해 있다고 해서 B1-1의 `sshd:20022`가 PASS한 것은 아닙니다.

반대로 B1-1 `sshd` 설정을 수정하더라도 OrbStack built-in SSH와 Mission SSH를 동일한 설정으로 간주하지 않습니다.

---

## 7. Python Mission으로 확장할 때

향후 Python 기반 Mission에서는 Repository Root에 `.venv`를 둡니다.

```bash
python3 -m venv .venv
```

Remote Ubuntu의 VS Code에서 해당 `.venv/bin/python`을 Interpreter로 선택합니다.

Remote User Settings에는 다음 설정을 권장합니다.

```json
{
  "python-envs.terminal.autoActivationType": "shellStartup"
}
```

설정 변경 후 기존 Terminal을 닫고 새 Terminal을 엽니다.

정상 예:

```text
(.venv) user@ubuntu:~/codyssey/current-python-repo$
```

특정 Project의 `.venv`를 `~/.bashrc`에 직접 하드코딩하지 않습니다.

---

## 완료 확인

```text
[ ] VS Code가 Remote-SSH `orb`로 Ubuntu에 연결됨
[ ] Open Folder가 Ubuntu `$HOME/codyssey/...` Repository임
[ ] 새 Terminal이 Repository root에서 시작함
[ ] Shell이 Bash임
[ ] Git root가 현재 B1-1 Repository임
[ ] `/Users/...` 또는 `/mnt/mac/...` Primary Workspace가 아님
[ ] OrbStack SSH와 B1-1 `sshd:20022`를 구분함
```

이 확인은 개발환경 위치를 고정하기 위한 Preflight이며 B1-1 Mission PASS/CLEAR 자체를 의미하지 않습니다.
