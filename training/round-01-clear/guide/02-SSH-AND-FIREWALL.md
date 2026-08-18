# B1-1 모듈 02 — SSH와 방화벽

> 범위: **STEP 03~04**  
> [← 모듈 01](01-PREFLIGHT-AND-BASELINE.md) · [입문자 가이드 허브](../BEGINNER-GUIDE.md) · [다음: 모듈 03 →](03-USERS-GROUPS-ACL.md)

## 📑 이 모듈 목차

- [STEP 03 — SSH를 20022로 안전하게 전환](#step-03)
- [STEP 04 — UFW를 20022/15034만 허용하도록 최종 정리](#step-04)

---

<a id="step-03"></a>
## STEP 03 — SSH를 20022로 안전하게 전환

## ① 왜 하는가

공식 요구사항은 SSH 포트 `20022`와 Root 원격 로그인 차단입니다. SSH는 원격 접속 경로 자체를 바꾸는 작업이므로 순서를 잘못 잡으면 현재 접속을 잃을 수 있습니다. 따라서 이 STEP은 **현재 상태 확인 → 체크포인트(Checkpoint) → 변경 → 검증(Verification) → 새 세션 → 필요 시 복구(Recovery)** 순서를 고정합니다.

## ② 무엇을 하는가

1. 현재 `sshd`, 포트, UFW 상태를 읽습니다.
2. `/etc/ssh/sshd_config`와 B1-1용 drop-in이 이미 있다면 그 파일까지 백업합니다.
3. UFW가 이미 활성 상태이면 `20022/tcp`를 먼저 허용합니다.
4. B1-1 drop-in에 `Port 20022`, `PermitRootLogin no`를 작성합니다.
5. `sshd -t`와 `sshd -T`가 모두 정상일 때만 reload합니다.
6. Ubuntu 내부에서 `20022` LISTEN을 확인합니다.
7. 기존 세션을 닫지 않은 상태에서 **다른 터미널**로 실제 새 SSH 세션을 확인합니다.
8. 실패하면 기존 세션에서 이전 drop-in/UFW 상태로 최소 복구합니다.

> 기존 SSH 세션과 기존 `22/tcp` 허용 규칙은 `20022` 새 세션이 성공하기 전까지 제거하지 않습니다. 기존 22 정리는 STEP 04에서만 진행합니다.

## ③ 이번 단계에서 알아야 할 용어

- **SSH(Secure Shell)** — 암호화된 원격 접속 프로토콜입니다.
- **SSH 서버(sshd)** — 원격 SSH 연결을 받아 인증하고 세션을 만드는 서버 프로세스입니다.
- **추가 설정 파일(drop-in)** — 기본 설정 파일을 직접 크게 수정하지 않고 `/etc/ssh/sshd_config.d/`에 기능별 설정을 추가하는 방식입니다.
- **최종 적용 설정(Effective Configuration)** — 여러 설정 파일을 모두 읽은 뒤 `sshd`가 실제로 적용하는 최종 값입니다.
- **체크포인트(Checkpoint)** — 변경 전 상태와 백업 위치를 기록해 되돌릴 수 있게 만드는 지점입니다.
- **복구(Recovery)** — 실패 시 변경 전 동작 상태로 되돌리는 절차입니다.
- **다시 불러오기(reload)** — 서비스를 완전히 종료하지 않고 검증된 설정을 다시 읽게 하는 작업입니다.

## ④ 필요한 핵심 개념

```mermaid
flowchart LR
    A[현재 SSH/UFW 상태] --> B[기본 설정 + 기존 drop-in 백업]
    B --> C[UFW active면 20022 사전 허용]
    C --> D[B1-1 drop-in 작성]
    D --> E[sshd -t]
    E --> F[sshd -T]
    F --> G[reload]
    G --> H[20022 LISTEN]
    H --> I[별도 터미널 새 SSH 세션]
    I -->|성공| J[STEP 04]
    I -->|실패| K[기존 세션에서 Recovery]
```

### OrbStack 접속과 B1-1 Mission SSH를 반드시 구분

```text
OrbStack 관리/편의 접속
ssh orb 또는 VS Code Remote-SSH orb

≠

B1-1 평가 대상
OrbStack Ubuntu 내부 OpenSSH Server(sshd)
TCP 20022
ssh -p 20022 <Ubuntu사용자>@<Ubuntu주소>
```

`ssh orb`로 Ubuntu에 들어갈 수 있다는 사실만으로 B1-1의 `sshd:20022`가 동작한다고 판정하지 않습니다. B1-1은 Ubuntu 내부 OpenSSH Server, 실제 `20022` LISTEN, 그리고 실제 새 SSH 세션을 별도로 확인합니다.

## ⑤ 실행할 명령어 또는 코드

### A. 변경 전 상태 확인 — 읽기 전용

```bash
sudo systemctl is-active ssh
sudo grep -RniE '^[[:space:]]*(Port|PermitRootLogin)' \
  /etc/ssh/sshd_config /etc/ssh/sshd_config.d 2>/dev/null || true
sudo sshd -T | grep -E '^(port|permitrootlogin) '
sudo ss -lntp | grep -E ':(22|20022)\b' || true
sudo ufw status verbose || true
```

`ssh` 서비스가 active가 아니거나 `sshd -T` 자체가 실패하면 **아직 설정 파일을 쓰지 않습니다.** STEP 02의 `openssh-server` 설치 상태와 `systemctl status ssh`를 먼저 확인합니다.

### B. 체크포인트와 백업 만들기

```bash
STAMP="$(date +%Y%m%d%H%M%S)"
DROPIN="/etc/ssh/sshd_config.d/99-codyssey-b1-1.conf"
MAIN_BAK="/etc/ssh/sshd_config.b1-1-r01.${STAMP}.bak"
DROPIN_BAK="${DROPIN}.b1-1-r01.${STAMP}.bak"
CHECKPOINT="/tmp/b1-1-ssh-checkpoint.${STAMP}.txt"
UFW_BEFORE="/tmp/b1-1-ufw-before-ssh.${STAMP}.txt"

sudo cp -a /etc/ssh/sshd_config "$MAIN_BAK"

if sudo test -e "$DROPIN"; then
    sudo cp -a "$DROPIN" "$DROPIN_BAK"
    DROPIN_EXISTED=yes
else
    DROPIN_EXISTED=no
fi

sudo ufw status numbered | tee "$UFW_BEFORE" >/dev/null || true

printf 'STAMP=%s\nMAIN_BAK=%s\nDROPIN=%s\nDROPIN_BAK=%s\nDROPIN_EXISTED=%s\nUFW_BEFORE=%s\n' \
  "$STAMP" "$MAIN_BAK" "$DROPIN" "$DROPIN_BAK" "$DROPIN_EXISTED" "$UFW_BEFORE" \
  > "$CHECKPOINT"

printf '[CHECKPOINT] %s\n' "$CHECKPOINT"
```

> `/tmp` 체크포인트에는 **경로와 상태만** 기록합니다. 비밀번호, SSH 개인키, Token, Secret 값은 기록하지 않습니다.

### C. UFW가 이미 active라면 20022를 먼저 허용

```bash
UFW_ADDED_20022=no

if sudo ufw status | grep -q '^Status: active$'; then
    if sudo ufw status | grep -Eq '^[[:space:]]*20022/tcp[[:space:]]+ALLOW IN'; then
        echo '[INFO] 20022/tcp is already allowed'
    else
        sudo ufw allow 20022/tcp
        UFW_ADDED_20022=yes
        echo '[CHECKPOINT] this STEP added 20022/tcp'
    fi
else
    echo '[INFO] UFW is inactive; final enable/policy is handled in STEP 04'
fi

printf 'UFW_ADDED_20022=%s\n' "$UFW_ADDED_20022" >> "$CHECKPOINT"
sudo ufw status verbose || true
```

UFW가 이미 active인데 `20022/tcp` 허용이 실패하면 SSH 포트를 바꾸지 않습니다.

### D. B1-1 SSH drop-in 작성

```bash
printf '%s\n' 'Port 20022' 'PermitRootLogin no' \
  | sudo tee "$DROPIN" >/dev/null

sudo chown root:root "$DROPIN"
sudo chmod 0644 "$DROPIN"
```

### E. reload 전에 반드시 두 번 검증

```bash
sudo sshd -t
sudo sshd -T | grep -E '^(port|permitrootlogin) '
```

정상 기준:

```text
port 20022
permitrootlogin no
```

`sshd -t`가 오류를 내거나 `sshd -T`에서 위 두 값이 나오지 않으면 **reload하지 않습니다.** 다른 drop-in이나 기본 파일의 우선순위를 조사하고 아래 Recovery 절차로 원래 상태를 복구합니다.

### F. 검증이 정상일 때만 reload하고 LISTEN 확인

```bash
sudo systemctl reload ssh
sudo systemctl is-active ssh
sudo ss -lntp | grep ':20022'
sudo sshd -T | grep -E '^(port 20022|permitrootlogin no)$'
```

여기까지 성공해도 기존 SSH 세션은 아직 닫지 않습니다.

### G. 실제 새 SSH 세션 확인

먼저 **OrbStack Ubuntu 터미널**에서 접속 대상 정보를 확인합니다.

```bash
whoami
hostname
hostname -I
```

- `whoami` 결과가 `<Ubuntu사용자>` 후보입니다.
- `hostname -I`는 Ubuntu가 가진 IP 주소 후보를 보여 줄 수 있습니다. 여러 주소가 나오면 macOS Host에서 실제로 도달 가능한 주소를 확인해야 합니다.
- 현재 사용자가 SSH 인증에 사용할 정상적인 비밀번호나 공개키 인증 경로가 없다면, Root 로그인을 허용하거나 보안 설정을 약화시켜 억지로 통과시키지 않습니다. 비-root 사용자용 정상 인증 경로를 먼저 준비합니다.

그 다음 **별도의 macOS Terminal**에서 B1-1 Mission SSH를 실행합니다.

```bash
ssh -p 20022 <Ubuntu사용자>@<Ubuntu주소>
```

> 이 명령이 실제 B1-1 `sshd:20022` 새 세션 확인입니다. `ssh orb`로 다시 접속한 것은 이 검증을 대신하지 않습니다.

새 세션 안에서 최소 확인:

```bash
whoami
printf 'SSH_CONNECTION=%s\n' "$SSH_CONNECTION"
```

`whoami`가 의도한 비-root 사용자이고 새 세션이 유지되면 실제 접속 경로가 열린 것입니다. `SSH_CONNECTION`에는 IP/포트 정보가 포함될 수 있으므로 공개 Evidence에 넣을 때는 네트워크 정보 공개 범위를 먼저 확인합니다.

### H. 실패 시 Recovery — 기존 세션을 닫지 말고 수행

먼저 체크포인트 파일을 확인합니다. 체크포인트에는 Secret이 없습니다.

```bash
cat "$CHECKPOINT"
```

#### 기존 B1-1 drop-in이 원래 존재했던 경우

```bash
sudo cp -a "$DROPIN_BAK" "$DROPIN"
sudo sshd -t
sudo systemctl reload ssh
```

#### 기존 B1-1 drop-in이 원래 없었던 경우

```bash
sudo rm -f "$DROPIN"
sudo sshd -t
sudo systemctl reload ssh
```

복구 후 현재 SSH 포트를 다시 확인합니다.

```bash
sudo systemctl is-active ssh
sudo sshd -T | grep -E '^(port|permitrootlogin) '
sudo ss -lntp | grep -E ':(22|20022)\b' || true
```

그리고 체크포인트의 `UFW_BEFORE`와 현재 UFW를 비교합니다.

```bash
cat "$UFW_BEFORE"
sudo ufw status numbered
```

`UFW_ADDED_20022=yes`였고 **이 STEP에서 새로 추가한 20022 규칙을 더 이상 유지할 이유가 없으며 이전 SSH 동작이 복구된 것을 확인한 뒤에만** 다음을 실행합니다.

```bash
sudo ufw delete allow 20022/tcp
sudo ufw status verbose
```

> 기존 `22/tcp` 규칙은 Recovery 중에도 임의 삭제하지 않습니다. `/etc/ssh/sshd_config` 본문은 이 STEP에서 수정하지 않지만, `MAIN_BAK`은 예기치 않은 수동 변경이 있었을 때 원본 비교/복구를 위한 안전 백업입니다.

## ⑥ 명령어와 코드에 입문자가 이해할 수 있는 주석

### 상태 확인 명령

- `systemctl is-active ssh`
  - Ubuntu의 `ssh` 서비스가 현재 실행 중인지 상태만 확인합니다.
- `grep -RniE ...`
  - `-R`은 디렉터리 아래를 재귀 탐색하고, `-n`은 줄 번호, `-i`는 대소문자 무시, `-E`는 확장 정규식을 사용합니다.
  - 여러 SSH 설정 파일에 `Port` 또는 `PermitRootLogin`이 중복되어 있는지 조사합니다.
- `sshd -T`
  - 설정 파일 여러 개를 모두 해석한 뒤 실제 적용될 값을 출력합니다.
  - 파일 한 곳만 보는 것보다 최종 적용 상태를 판단하기에 적합합니다.
- `ss -lntp`
  - `-l` LISTEN, `-n` 숫자 포트, `-t` TCP, `-p` 프로세스 정보를 표시합니다.

### 체크포인트와 백업 명령

- `STAMP="$(date +%Y%m%d%H%M%S)"`
  - `$(...)`는 괄호 안 명령의 출력을 변수에 넣는 명령 치환(Command Substitution)입니다.
  - `date +...`로 초 단위 시각을 붙여 백업 파일 이름 충돌을 줄입니다.
- `cp -a`
  - 파일 내용뿐 아니라 가능한 속성을 함께 보존해 백업합니다.
- `test -e "$DROPIN"`
  - 대상 파일이 이미 존재하는지 확인합니다. 기존 파일이 있으면 덮어쓰기 전에 반드시 별도 백업합니다.
- `tee "$UFW_BEFORE"`
  - UFW 상태 출력을 화면 파이프에서 파일로도 기록합니다. `/tmp`의 이 파일은 복구 비교용이며 비밀정보를 포함시키지 않습니다.
- `printf ... > "$CHECKPOINT"`
  - `>`는 파일을 새로 만들거나 기존 내용을 덮어씁니다. 여기서는 이번 실행용 새 타임스탬프 파일이므로 의도된 동작입니다.
- `>> "$CHECKPOINT"`
  - `>>`는 기존 내용을 지우지 않고 뒤에 추가합니다.

### UFW 사전 허용 명령

- `grep -q '^Status: active$'`
  - UFW가 이미 활성 상태인지 출력 없이 종료 코드로 판단합니다.
- `grep -Eq ...20022...ALLOW IN`
  - 기존 규칙에 `20022/tcp` 허용이 이미 있는지 확인해 불필요한 중복 추가를 줄입니다.
- `ufw allow 20022/tcp`
  - 현재 UFW가 active인 경우 SSH 포트를 바꾸기 **전에** 새 포트의 인바운드 TCP를 허용합니다.

### SSH 설정 작성과 검증

- `printf '%s\n' ... | sudo tee "$DROPIN" >/dev/null`
  - 두 설정 줄을 정확히 만들어 root 권한으로 drop-in 파일에 기록합니다.
  - `>/dev/null`은 `tee`가 같은 설정을 터미널에 다시 출력하는 것만 막습니다.
- `chown root:root`
  - SSH 시스템 설정 파일 소유자를 root로 고정합니다.
- `chmod 0644`
  - root는 읽기/쓰기, 그 외 사용자는 읽기만 가능하게 설정합니다.
- `sshd -t`
  - 서비스를 건드리지 않고 SSH 설정 문법과 기본 유효성을 검사합니다. 성공 시 일반적으로 출력이 없습니다.
- `sshd -T`
  - 실제 최종 적용 설정을 확인합니다. `port 20022`, `permitrootlogin no` 확인 전에는 reload하지 않습니다.
- `systemctl reload ssh`
  - 검증된 설정을 실행 중인 SSH 서비스가 다시 읽도록 합니다. `restart`보다 기존 세션 영향을 줄이는 방향으로 사용하지만, 기존 세션을 닫아도 된다는 뜻은 아닙니다.

### 실제 접속 명령

- `hostname -I`
  - Ubuntu에 할당된 IP 주소 후보를 출력합니다. 가상화 환경에서는 여러 주소가 나올 수 있으므로 실제 Host에서 도달 가능한 주소인지 확인해야 합니다.
- `ssh -p 20022 사용자@주소`
  - `-p 20022`는 기본 SSH 포트 22가 아니라 공식 Mission 포트 20022를 명시합니다.
  - 이 명령은 **별도의 macOS Terminal**에서 실행해 기존 Ubuntu 세션을 안전망으로 남겨 둡니다.
- `$SSH_CONNECTION`
  - 실제 SSH 세션에서 연결 양 끝의 주소와 포트 정보를 확인하는 환경변수입니다. 민감한 네트워크 정보를 공개 Evidence에 그대로 노출하지 않도록 주의합니다.

### Recovery 명령

- `cp -a "$DROPIN_BAK" "$DROPIN"`
  - 기존 drop-in이 있었던 경우 이전 파일을 되돌립니다.
- `rm -f "$DROPIN"`
  - 기존 drop-in이 없었는데 이번 STEP에서 새로 만든 경우에만 새 파일을 제거합니다.
- 복구 후에도 반드시 `sshd -t → reload → is-active → ss` 순서로 실제 서비스 상태를 다시 확인합니다.
- UFW 20022 삭제는 **이 STEP이 새로 추가한 규칙이라는 사실과 기존 SSH 경로 복구를 모두 확인한 뒤** 수행합니다.

### 재실행 안전성

이 STEP 전체는 **🔴 DO NOT RERUN BLINDLY**입니다.

```text
조회 명령                               → 🟢 SAFE TO RERUN
백업 생성                               → 🟡 CHECK BEFORE RERUN
UFW 20022 사전 허용                     → 🟡 CHECK BEFORE RERUN
SSH drop-in 쓰기 / reload               → 🔴 상태·백업·검증 후에만
Recovery의 rm/ufw delete                → 🔴 이전 상태를 확인한 뒤에만
```

> **STOP 기준:** 백업 경로를 확인할 수 없음, `sshd -t` 실패, 최종 적용 설정이 20022/Root 차단과 다름, reload 후 ssh service 비정상, 20022 LISTEN 없음, 실제 새 SSH 세션 실패 중 하나라도 발생하면 STEP 04로 진행하지 않습니다.

## ⑦ 예상되는 정상 결과

- 변경 전 SSH/UFW 상태와 백업 경로가 기록됩니다.
- 기존 B1-1 drop-in이 있었다면 덮어쓰기 전에 별도 백업됩니다.
- UFW가 active였다면 20022가 사전 허용된 뒤 SSH 설정이 변경됩니다.
- `sshd -t`가 오류 없이 끝납니다.
- `sshd -T`에서 `port 20022`, `permitrootlogin no`가 확인됩니다.
- reload 후 `ssh` service가 active입니다.
- Ubuntu 내부 `ss`에서 TCP `20022` LISTEN이 확인됩니다.
- 별도 macOS Terminal의 `ssh -p 20022 ...`로 실제 비-root 새 세션이 성공합니다.

## ⑧ 그 결과가 의미하는 것

B1-1의 SSH 요구사항이 단순히 설정 파일에 적힌 상태가 아니라 **최종 적용 설정 → 실제 서비스 LISTEN → 실제 새 세션**까지 연결되어 검증 가능한 상태가 된 것입니다. 또한 실패하더라도 이전 drop-in/UFW 상태를 기준으로 복구할 경로가 확보되어 있습니다.

## ⑨ 자주 발생하는 오류와 해결 방법

- `sshd -t` 오류 → reload 금지. 오류 위치를 확인하고 기존 drop-in 복구 또는 이번에 만든 drop-in 제거 후 다시 `sshd -t`.
- `sshd -T`에 `port 22`가 남음 → 다른 설정 파일의 `Port` 선언과 읽기 순서를 조사하고 reload 금지.
- `permitrootlogin no`가 아님 → 다른 설정 파일/Match 블록 영향을 확인하고 reload 금지.
- reload 후 `20022`가 LISTEN하지 않음 → 기존 세션을 유지한 채 `systemctl status ssh`, `sshd -T`, `ss`를 다시 확인.
- macOS에서 `Connection refused` → Ubuntu에서 20022 LISTEN 여부와 접속 주소를 먼저 확인. `ssh orb` 성공을 Mission SSH 성공으로 대체하지 않음.
- macOS에서 timeout → Host/Guest 네트워크 경로와 UFW를 확인. 주소를 임의 추측하지 않음.
- `Permission denied` → 비-root 사용자 인증 수단을 확인. Root 로그인 허용 또는 무분별한 `PasswordAuthentication yes`로 우회하지 않음.
- 기존 drop-in을 덮어쓴 뒤 문제 발생 → `DROPIN_BAK` 복구 후 `sshd -t`, reload, 기존 포트 확인.
- UFW에 20022를 새로 추가했지만 SSH 변경을 철회함 → 이전 SSH가 정상 복구된 뒤, 체크포인트와 `UFW_BEFORE` 비교 후 이번에 추가한 규칙만 제거.

## ⑩ 완료 확인

- [ ] 변경 전 `ssh` service / effective config / LISTEN / UFW 상태 확인
- [ ] `/etc/ssh/sshd_config` 백업
- [ ] 기존 B1-1 drop-in 존재 여부 확인 및 존재 시 별도 백업
- [ ] UFW 상태 체크포인트 기록
- [ ] UFW active일 때 20022 사전 허용
- [ ] B1-1 drop-in owner/group/mode 확인
- [ ] `sshd -t` 성공
- [ ] `sshd -T`에서 `port 20022`
- [ ] `sshd -T`에서 `permitrootlogin no`
- [ ] reload 후 `ssh` active
- [ ] Ubuntu 내부 20022 LISTEN
- [ ] OrbStack 관리 접속과 Mission `sshd:20022` 차이를 이해함
- [ ] 별도 macOS Terminal에서 실제 비-root 새 SSH 세션 성공
- [ ] 실패 시 Recovery 절차와 UFW 원복 조건을 이해함

---

<a id="step-04"></a>
## STEP 04 — UFW를 20022/15034만 허용하도록 최종 정리

## ① 왜 하는가

공식 요구사항은 Firewall이 활성 상태이고, 외부에서 들어오는 TCP 연결 중 `20022/tcp`와 `15034/tcp`만 허용되는 것입니다. 방화벽은 원격 접속 자체를 차단할 수 있으므로 단순히 규칙을 추가하는 것보다 **현재 상태 확인 → 체크포인트(Checkpoint) → 필수 규칙 확보 → 기본 정책 변경 → 활성화/다시 불러오기 → 불필요한 허용 규칙 정리 → 검증(Verification) → 필요 시 복구(Recovery)** 순서가 중요합니다.

## ② 무엇을 하는가

1. STEP 03의 `20022` 실제 새 SSH 세션이 성공했는지 다시 확인합니다.
2. 현재 UFW 활성 상태, 기본 정책, 전체 규칙과 재생성 가능한 규칙 목록을 `/tmp`에 체크포인트로 저장합니다.
3. UFW가 비활성 상태여도 먼저 `20022/tcp`, `15034/tcp` 허용 규칙을 준비합니다.
4. 기본 인바운드 정책을 `deny`, 기본 아웃바운드를 `allow`로 맞춥니다.
5. UFW가 비활성 상태였다면 필수 규칙이 준비된 뒤에만 활성화합니다. 이미 활성 상태라면 다시 불러오기(reload) 후 상태를 확인합니다.
6. 새 `20022` SSH 세션을 유지한 상태에서 기존 `22/tcp`와 그 밖의 불필요한 `ALLOW IN` 규칙을 **한 번에 하나씩** 검토·삭제합니다.
7. 최종적으로 UFW가 active이고, 인바운드 허용 포트가 `20022/tcp`, `15034/tcp`뿐인지 검증합니다.
8. 중간에 SSH 접속 또는 UFW 상태가 예상과 달라지면 체크포인트를 기준으로 최소 복구합니다.

> 이 STEP은 **B1-1 전용 Ubuntu Runtime**을 전제로 합니다. 업무 서버·공용 서버처럼 다른 필수 인바운드 포트가 실제로 필요한 환경이라면 그 포트를 억지로 삭제하지 말고 B1-1 전용 OrbStack/WSL2 Ubuntu 환경으로 옮기는 것이 안전합니다.

## ③ 이번 단계에서 알아야 할 용어

- **방화벽(Firewall)** — 네트워크 트래픽을 규칙에 따라 허용하거나 차단하는 보안 계층입니다.
- **UFW(Uncomplicated Firewall)** — Ubuntu에서 방화벽 정책을 비교적 단순한 명령으로 관리하는 도구입니다.
- **인바운드(Inbound)** — 외부에서 현재 Ubuntu 시스템으로 들어오는 연결입니다.
- **아웃바운드(Outbound)** — 현재 Ubuntu 시스템에서 외부로 나가는 연결입니다.
- **기본 차단(Default Deny)** — 명시적으로 허용하지 않은 인바운드 연결을 기본적으로 거부하는 정책입니다.
- **허용 규칙(ALLOW IN Rule)** — 특정 포트·프로토콜·주소의 인바운드 연결을 허용하는 규칙입니다.
- **체크포인트(Checkpoint)** — 변경 전 상태를 기록하여 잘못된 변경을 비교·복구할 수 있게 하는 지점입니다.
- **다시 불러오기(reload)** — 저장된 UFW 규칙을 현재 방화벽 상태에 다시 적용하는 작업입니다.
- **IPv4 / IPv6** — 서로 다른 IP 주소 체계입니다. UFW가 IPv6를 사용하도록 설정된 환경에서는 같은 허용 규칙이 `(v6)` 형태로 함께 보일 수 있습니다.

## ④ 필요한 핵심 개념

```mermaid
flowchart TD
    A[STEP 03 실제 SSH 20022 성공] --> B[UFW 현재 상태 Check]
    B --> C[Checkpoint 저장]
    C --> D[20022 + 15034 먼저 허용]
    D --> E[default deny incoming]
    E --> F[default allow outgoing]
    F --> G{UFW 현재 active?}
    G -->|아니오| H[enable]
    G -->|예| I[reload]
    H --> J[20022 새 SSH 세션 재확인]
    I --> J
    J --> K[불필요한 ALLOW IN 한 개씩 삭제]
    K --> L[매 삭제 후 번호 재확인]
    L --> M[최종 UFW 검증]
    M -->|정상| N[STEP 05]
    M -->|비정상| O[Checkpoint 기준 Recovery]
```

핵심 원칙은 다음입니다.

```text
필수 SSH 규칙 20022를 먼저 확보
→ 15034 허용
→ 기본 인바운드 차단
→ UFW 활성화/적용
→ 실제 SSH 20022가 계속 되는지 확인
→ 마지막에 기존 22와 불필요한 ALLOW IN 정리
```

`22/tcp`를 먼저 삭제하고 나중에 `20022/tcp`를 열어 보는 순서는 사용하지 않습니다.

## ⑤ 실행할 명령어 또는 코드

### A. STEP 03 완료 여부와 현재 연결 확인 — 읽기 전용

현재 Ubuntu 터미널에서:

```bash
sudo systemctl is-active ssh
sudo sshd -T | grep -E '^(port 20022|permitrootlogin no)$'
sudo ss -lntp | grep ':20022'
sudo ufw status verbose || true
```

그리고 STEP 03에서 연 **별도 `ssh -p 20022 ...` 세션을 닫지 않습니다.** 새 세션이 실제로 동작하지 않으면 이 STEP을 시작하지 않습니다.

### B. UFW 변경 전 체크포인트 만들기

```bash
STAMP="$(date +%Y%m%d%H%M%S)"
UFW_BEFORE_VERBOSE="/tmp/b1-1-ufw-before.${STAMP}.verbose.txt"
UFW_BEFORE_NUMBERED="/tmp/b1-1-ufw-before.${STAMP}.numbered.txt"
UFW_BEFORE_ADDED="/tmp/b1-1-ufw-before.${STAMP}.added.txt"
UFW_CHECKPOINT="/tmp/b1-1-ufw-checkpoint.${STAMP}.txt"

if sudo ufw status | grep -q '^Status: active$'; then
    UFW_WAS_ACTIVE=yes
else
    UFW_WAS_ACTIVE=no
fi

sudo ufw status verbose | tee "$UFW_BEFORE_VERBOSE" >/dev/null || true
sudo ufw status numbered | tee "$UFW_BEFORE_NUMBERED" >/dev/null || true
sudo ufw show added | tee "$UFW_BEFORE_ADDED" >/dev/null || true

printf 'STAMP=%s\nUFW_WAS_ACTIVE=%s\nUFW_BEFORE_VERBOSE=%s\nUFW_BEFORE_NUMBERED=%s\nUFW_BEFORE_ADDED=%s\n' \
  "$STAMP" "$UFW_WAS_ACTIVE" "$UFW_BEFORE_VERBOSE" "$UFW_BEFORE_NUMBERED" "$UFW_BEFORE_ADDED" \
  > "$UFW_CHECKPOINT"

printf '[CHECKPOINT] %s\n' "$UFW_CHECKPOINT"
```

체크포인트 파일에는 방화벽 상태와 규칙만 기록합니다. Secret 값은 저장하지 않습니다.

### C. 필수 두 포트를 먼저 허용

```bash
sudo ufw allow 20022/tcp
sudo ufw allow 15034/tcp
sudo ufw status numbered
```

이미 같은 규칙이 있으면 UFW가 기존 규칙이 있음을 알리거나 중복 추가를 건너뛸 수 있습니다. 이 단계에서는 **두 필수 포트가 실제로 허용 목록에 보이는지** 확인하는 것이 중요합니다.

### D. 기본 정책 설정

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw status verbose
```

`default deny incoming`은 명시적으로 허용된 인바운드만 통과시키는 기준입니다. 따라서 반드시 C 단계에서 `20022/tcp`를 먼저 확보한 뒤 실행합니다.

### E. UFW 활성화 또는 다시 불러오기

```bash
if sudo ufw status | grep -q '^Status: active$'; then
    sudo ufw reload
else
    sudo ufw --force enable
fi

sudo ufw status verbose
sudo ss -lntp | grep ':20022'
```

UFW가 비활성 상태였다면 `--force enable`이 방화벽을 실제로 활성화합니다. 이미 활성 상태였다면 `reload`로 현재 저장 규칙을 다시 적용합니다.

**여기서 반드시 별도 macOS Terminal의 `ssh -p 20022 ...` 세션이 계속 살아 있는지 확인합니다.** 새 연결을 하나 더 열어도 좋지만, 기존 성공 세션을 닫아 놓고 확인하면 안전망이 사라집니다.

### F. 현재 전체 허용 규칙 확인

```bash
sudo ufw status numbered
sudo ufw status verbose
```

정리 대상은 공식 요구에 필요하지 않은 **추가 `ALLOW IN`** 규칙입니다. `DENY`, `REJECT` 같은 차단 규칙을 단순히 "두 포트가 아니다"라는 이유만으로 지우지 않습니다.

특히 다음이 보이면 정리 후보입니다.

```text
22/tcp ALLOW IN
OpenSSH ALLOW IN
기타 B1-1과 무관한 TCP/UDP ALLOW IN
```

다만 그 규칙이 다른 실제 서비스에 필요한 환경이라면 삭제하지 말고 미션 전용 Ubuntu 환경으로 이동합니다.

### G. 불필요한 ALLOW IN을 한 개씩 삭제

먼저 현재 번호를 확인합니다.

```bash
sudo ufw status numbered
```

삭제할 규칙의 **현재 번호를 직접 확인한 뒤**, `<삭제할-규칙번호>`를 실제 숫자로 바꾸어 한 개만 삭제합니다.

```bash
sudo ufw delete <삭제할-규칙번호>
```

삭제 직후 반드시 다시 번호를 확인합니다.

```bash
sudo ufw status numbered
```

규칙 하나를 삭제할 때마다 번호가 다시 매겨질 수 있으므로, 이전 화면의 번호를 기억해서 연속으로 `delete 2`, `delete 3`처럼 실행하지 않습니다.

> **중요:** `<삭제할-규칙번호>`는 그대로 복사해서 실행하는 문자열이 아닙니다. 실제 `ufw status numbered`의 현재 번호를 사용해야 합니다.

기존 `22/tcp` 또는 `OpenSSH` 규칙도 **STEP 03의 `20022` 새 SSH 세션이 실제 성공하고, E 단계 이후에도 20022 접속이 유지되는 것을 확인한 다음** 삭제합니다.

### H. 최종 정책 검증

```bash
sudo ufw status verbose
sudo ufw status numbered
sudo ss -lntp | grep -E ':(20022|15034)\b' || true
```

최종적으로 직접 확인할 항목:

```text
Status: active
Default: deny (incoming)
20022/tcp  ALLOW IN
15034/tcp  ALLOW IN
그 외 불필요한 ALLOW IN 없음
```

`15034`는 Agent가 아직 시작되지 않은 시점이라면 `ss`에 LISTEN이 보이지 않아도 STEP 04 자체의 UFW 설정 오류는 아닙니다. 실제 `15034` LISTEN은 STEP 07에서 Agent 실행 후 검증합니다.

### IPv4 / IPv6 결과 해석

UFW의 IPv6 지원이 활성화되어 있으면 다음처럼 같은 포트가 두 줄로 보일 수 있습니다.

```text
20022/tcp                  ALLOW IN    Anywhere
20022/tcp (v6)             ALLOW IN    Anywhere (v6)
15034/tcp                  ALLOW IN    Anywhere
15034/tcp (v6)             ALLOW IN    Anywhere (v6)
```

이것은 **네 개의 서로 다른 서비스 포트를 연 것**이 아니라 동일한 두 포트를 IPv4와 IPv6 주소 체계에 각각 적용한 것입니다. 다만 IPv6 규칙이 있다는 이유만으로 무조건 정상이라고 가정하지 말고, 최종 허용 포트 번호 자체가 `20022`, `15034` 외에 더 있는지 확인합니다.

### I. 실패 시 Recovery — 체크포인트와 실제 SSH 상태 기준

Recovery를 시작하기 전에 현재 20022 SSH 세션과 UFW 상태를 확인합니다.

```bash
sudo ss -lntp | grep ':20022' || true
sudo ufw status verbose || true
cat "$UFW_CHECKPOINT"
cat "$UFW_BEFORE_VERBOSE"
cat "$UFW_BEFORE_NUMBERED"
cat "$UFW_BEFORE_ADDED"
```

#### 이번 STEP에서 UFW를 처음 활성화했고 이전 상태로 돌아가야 하는 경우

체크포인트에서 `UFW_WAS_ACTIVE=no`였다는 사실을 확인하고, 현재 작업을 철회해 **변경 전 비활성 상태로 복구해야 하는 상황에서만** 다음을 검토합니다.

```bash
sudo ufw disable
sudo ufw status verbose
```

`ufw disable`은 방화벽 자체를 끄는 명령이므로 일반적인 문제 해결용으로 습관적으로 사용하지 않습니다. B1-1 최종 상태는 UFW active여야 하므로, 이 명령은 실패한 변경을 되돌리는 Recovery 상황에서만 사용합니다.

#### 실수로 필요한 기존 규칙을 삭제한 경우

`$UFW_BEFORE_ADDED`와 `$UFW_BEFORE_NUMBERED`에서 삭제 전 규칙을 확인합니다. 필요한 규칙의 의미를 확인한 뒤 **그 규칙 하나만** UFW 명령으로 다시 추가합니다. 체크포인트 내용을 보지 않고 규칙을 추측하거나 전체 UFW를 `reset`하지 않습니다.

#### 기본 정책을 되돌려야 하는 경우

`$UFW_BEFORE_VERBOSE`에 기록된 변경 전 `Default:` 값을 확인합니다. 이전 incoming/outgoing 정책을 정확히 확인한 뒤 해당 `ufw default ...` 명령만 최소 범위로 되돌립니다.

> 이 가이드에서는 `ufw reset`을 Recovery 기본 방법으로 사용하지 않습니다. `reset`은 전체 규칙을 초기화하므로 기존 상태를 더 크게 훼손할 수 있습니다.

Recovery 후에는 반드시 다음을 다시 확인합니다.

```bash
sudo ufw status verbose
sudo ufw status numbered
sudo systemctl is-active ssh
sudo ss -lntp | grep ':20022' || true
```

## ⑥ 명령어와 코드에 입문자가 이해할 수 있는 주석

### 상태 확인과 체크포인트

- `ufw status verbose`
  - UFW 활성 상태, 기본 incoming/outgoing 정책, 현재 규칙을 상세하게 보여 줍니다.
- `ufw status numbered`
  - 현재 규칙 앞에 번호를 붙여 보여 줍니다. 이후 특정 규칙을 삭제할 때 현재 번호를 확인하는 기준입니다.
- `ufw show added`
  - UFW에 추가된 규칙을 명령 형태에 가까운 정보로 보여 주어 삭제 전 규칙을 재구성할 때 참고할 수 있습니다.
- `tee "$UFW_BEFORE_..." >/dev/null`
  - 현재 상태 출력을 `/tmp` 체크포인트 파일에 저장합니다. `>/dev/null`은 같은 내용을 터미널에 다시 출력하지 않게 합니다.
- `UFW_WAS_ACTIVE=yes/no`
  - 이번 STEP 시작 전 방화벽이 실제로 켜져 있었는지 기록합니다. 실패 시 `disable`이 원래 상태 복구인지 판단할 때 사용합니다.

### 필수 포트 허용

- `sudo ufw allow 20022/tcp`
  - B1-1 SSH 서버 포트 `20022`로 들어오는 TCP 연결을 허용합니다.
  - SSH 안전망이므로 기본 차단 정책이나 UFW 활성화보다 먼저 확보합니다.
- `sudo ufw allow 15034/tcp`
  - 제공 Agent가 사용하는 공식 포트 `15034`의 인바운드 TCP 연결을 허용합니다.
  - Agent가 아직 실행되지 않아도 방화벽 규칙은 미리 준비할 수 있습니다.
- `/tcp`
  - 같은 포트 번호의 UDP가 아니라 TCP 프로토콜만 허용한다는 뜻입니다.

### 기본 정책

- `sudo ufw default deny incoming`
  - 별도 허용 규칙이 없는 인바운드 연결을 기본 차단합니다.
  - 원격 SSH가 필요한 환경에서는 반드시 `20022/tcp` 허용을 먼저 확인합니다.
- `sudo ufw default allow outgoing`
  - 현재 Ubuntu에서 외부로 나가는 연결을 기본 허용합니다.
  - 공식 B1-1의 핵심 제한 대상은 인바운드 허용 포트입니다.

### 활성화와 적용

- `sudo ufw --force enable`
  - UFW를 실제로 활성화합니다.
  - `--force`는 대화형 확인 질문을 생략하므로 필수 SSH 규칙과 체크포인트를 확인한 뒤에만 사용합니다.
- `sudo ufw reload`
  - 이미 활성화된 UFW가 저장된 현재 규칙을 다시 적용하도록 합니다.
- `if ...; then ...; else ...; fi`
  - UFW가 이미 active인지에 따라 `reload`와 `enable` 중 하나만 실행하도록 분기합니다.

### 규칙 삭제

- `sudo ufw delete <삭제할-규칙번호>`
  - 현재 번호에 해당하는 규칙 하나를 삭제합니다.
  - 방화벽 변경 명령이므로 삭제 대상의 의미를 확인한 뒤 실행합니다.
- 규칙 번호는 삭제 후 다시 매겨질 수 있습니다.
  - 따라서 **삭제 한 번 → `status numbered` 재확인 → 다음 삭제** 순서를 지킵니다.
- `22/tcp`와 `OpenSSH`
  - 일반적인 기존 SSH 허용 규칙일 수 있습니다. B1-1에서는 새 `20022` SSH 연결 성공 후에만 제거 후보가 됩니다.

### 최종 검증

- `ss -lntp | grep -E ':(20022|15034)\b'`
  - 실제로 프로세스가 두 Mission 포트를 LISTEN하는지 확인하는 보조 검사입니다.
  - STEP 04에서는 `20022` SSH LISTEN이 핵심이고, `15034`는 STEP 07 전까지 아직 LISTEN하지 않을 수 있습니다.
- UFW 규칙과 LISTEN 상태는 서로 다른 개념입니다.
  - **UFW ALLOW**는 방화벽이 통과를 허용한다는 뜻이고, **LISTEN**은 실제 프로그램이 그 포트에서 연결을 받을 준비가 되었다는 뜻입니다.

### Recovery 명령

- `sudo ufw disable`
  - 방화벽을 비활성화합니다. `UFW_WAS_ACTIVE=no`였고 실패한 작업을 이전 상태로 되돌리는 경우에만 사용합니다.
- 체크포인트의 `ufw show added` / `status numbered`
  - 삭제 전 규칙을 추측하지 않고 실제 이전 규칙을 확인하는 근거입니다.
- `ufw reset`
  - 전체 방화벽 규칙 초기화이므로 이번 R01의 기본 Recovery 방법으로 사용하지 않습니다.

### 재실행 안전성

이 STEP 전체는 **🔴 DO NOT RERUN BLINDLY**입니다.

```text
status / show added / ss 조회                    → 🟢 SAFE TO RERUN
체크포인트 파일 생성                            → 🟢 SAFE TO RERUN
allow 20022/15034                               → 🟡 CHECK BEFORE RERUN
기본 정책 변경(default)                         → 🔴 현재 SSH/규칙 확인 후
UFW enable / reload                             → 🔴 필수 허용 규칙 확인 후
ufw delete                                      → 🔴 현재 번호·대상 확인 후 한 개씩
Recovery의 disable/default/규칙 재추가          → 🔴 체크포인트와 원래 상태 확인 후
```

> **STOP 기준:** STEP 03의 실제 `20022` 새 SSH 세션 미확인, UFW 체크포인트 저장 실패, `20022/tcp` 허용 실패, UFW 활성화 후 SSH 20022 연결 실패, 현재 환경에 삭제하면 안 되는 필수 ALLOW IN 존재, 최종 UFW 상태가 active가 아님 중 하나라도 발생하면 STEP 05로 진행하지 않습니다.

## ⑦ 예상되는 정상 결과

- 변경 전 UFW active/inactive 상태와 기본 정책·규칙이 체크포인트에 기록됩니다.
- `20022/tcp`, `15034/tcp` 허용 규칙이 기본 차단 정책과 활성화보다 먼저 확보됩니다.
- UFW `Status: active`가 됩니다.
- 기본 정책이 `deny (incoming)` / `allow (outgoing)`입니다.
- STEP 03에서 성공한 실제 `20022` SSH 세션이 UFW 적용 후에도 유지됩니다.
- 불필요한 ALLOW IN을 하나씩 정리한 뒤 인바운드 허용 포트가 `20022`, `15034`만 남습니다.
- IPv6가 활성인 환경에서는 동일한 두 포트의 `(v6)` 대응 규칙이 보일 수 있습니다.

## ⑧ 그 결과가 의미하는 것

B1-1의 Firewall 요구사항이 단순한 설정 예정 상태가 아니라 **기본 정책 → 필수 허용 규칙 → UFW 활성 상태 → SSH 연결 유지 → 불필요한 인바운드 허용 제거**까지 연결된 재현·검증 가능한 절차로 정리된 것입니다.

## ⑨ 자주 발생하는 오류와 해결 방법

- UFW enable 직후 SSH가 끊김 → 기존 세션이 남아 있다면 닫지 말고 `ufw status`, `ss :20022`, `sshd -T`부터 확인. 무작정 `reset` 금지.
- `20022/tcp`가 보이지 않음 → `ufw allow 20022/tcp` 성공 여부와 현재 `status numbered`를 확인하고, 확인 전 기존 22 규칙 삭제 금지.
- `15034/tcp`는 허용됐는데 LISTEN이 없음 → STEP 04 시점에는 Agent 미실행이면 정상일 수 있음. STEP 07에서 실제 LISTEN 검증.
- `ufw delete` 후 엉뚱한 규칙이 사라짐 → 즉시 추가 삭제를 멈추고 체크포인트의 `UFW_BEFORE_NUMBERED`/`UFW_BEFORE_ADDED`와 비교해 필요한 규칙 하나만 복구.
- 규칙 번호가 갑자기 달라짐 → 정상 동작일 수 있음. 삭제할 때마다 `ufw status numbered`를 다시 실행.
- `OpenSSH` 규칙이 있음 → 새 20022 실제 접속 성공 여부를 확인한 뒤, 그것이 기존 22 허용인지 현재 rule detail을 검토하고 삭제.
- IPv4와 `(v6)` 규칙이 각각 보여 네 개처럼 보임 → 포트 번호가 같은지 확인. 동일한 20022/15034의 IPv4/IPv6 대응 규칙이면 별도 서비스 포트가 늘어난 것이 아님.
- 업무에 필요한 다른 ALLOW IN이 있음 → 그 규칙을 억지로 삭제하지 말고 B1-1 전용 OrbStack/WSL2 Ubuntu Runtime으로 이동.
- Recovery가 필요함 → `ufw reset`부터 하지 말고 체크포인트의 시작 상태·기본 정책·규칙을 기준으로 최소 변경만 되돌림.

## ⑩ 완료 확인

- [ ] STEP 03 실제 `ssh -p 20022 ...` 새 세션 성공 확인
- [ ] 기존 SSH 세션/새 20022 세션을 안전망으로 유지
- [ ] 변경 전 UFW active/inactive 기록
- [ ] 변경 전 `status verbose` 저장
- [ ] 변경 전 `status numbered` 저장
- [ ] 변경 전 `ufw show added` 저장
- [ ] `20022/tcp` ALLOW IN
- [ ] `15034/tcp` ALLOW IN
- [ ] default deny incoming
- [ ] default allow outgoing
- [ ] UFW active
- [ ] UFW 적용 후에도 20022 SSH 연결 유지
- [ ] 불필요한 ALLOW IN을 한 번에 하나씩 정리
- [ ] 삭제할 때마다 규칙 번호 재확인
- [ ] IPv4/IPv6 동일 포트 규칙을 올바르게 해석
- [ ] 최종 인바운드 허용 포트는 20022/15034만 존재
- [ ] 실패 시 체크포인트 기반 Recovery 절차를 이해함

---

---

## 다음 이동

[← 모듈 01](01-PREFLIGHT-AND-BASELINE.md) · [입문자 가이드 허브](../BEGINNER-GUIDE.md) · [다음: 모듈 03 →](03-USERS-GROUPS-ACL.md)
