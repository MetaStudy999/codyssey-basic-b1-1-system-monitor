# 04. 방화벽과 네트워크 접근 제어

> **기억 문장:** 필요한 문만 열고 나머지는 기본적으로 막는다.

이 장에서는 원본 B1-1 요구사항에 따라 UFW를 활성화하고 **TCP `20022`(SSH), TCP `15034`(Agent)만 인바운드 허용**하도록 구성합니다.

---

## 1. 목표

최종 방화벽 정책은 다음과 같습니다.

```text
UFW              = active
Default incoming = deny
20022/tcp        = ALLOW
15034/tcp        = ALLOW
22/tcp           = 별도 ALLOW 없음
```

IPv6가 활성화된 환경에서는 동일한 두 포트의 `(v6)` 허용 규칙이 함께 나타나는 것이 정상입니다.

---

## 2. 이해 — LISTEN과 방화벽 허용은 다르다

네트워크 상태는 두 층으로 구분합니다.

```text
프로그램/서비스
    ↓
특정 포트 LISTEN
    ↓
방화벽
    ↓
외부에서 해당 포트 접근 허용/차단
```

예를 들어 SSH가 `20022`에서 LISTEN해도 UFW가 `20022/tcp`를 차단하면 외부에서 접속할 수 없습니다.

반대로 UFW에서 `15034/tcp`를 허용해도 Agent가 아직 실행되지 않아 `15034`에서 LISTEN하지 않으면 서비스 접속은 되지 않습니다.

따라서:

```text
03 SSH = SSH가 20022에서 기다리게 함
04 UFW = 20022와 15034만 통과시키게 함
06 Agent = Agent가 실제 15034에서 기다리게 함
```

으로 역할을 구분합니다.

---

## 3. 실행 전 상태 확인

초기 확인 명령:

```bash
sudo ufw status verbose
```

실제 초기 결과:

```text
Status: inactive
```

즉 UFW 패키지는 설치되어 있었지만 방화벽은 꺼져 있었습니다.

### `[CHECK]`

`inactive` 자체가 사전 점검 실패는 아닙니다. 원본 미션의 **최종 상태에서는 active**여야 하므로 이 장에서 설정합니다.

---

## 4. SSH 실제 포트 먼저 확인

UFW를 활성화하기 전에 현재 SSH가 어느 포트에서 LISTEN하는지 확인합니다.

```bash
sudo ss -lntp | grep -E ':(22|20022|15034)\b' || true
```

03장 완료 후 실제 확인된 SSH 상태:

```text
0.0.0.0:20022
[::]:20022
```

기존 `22`는 나타나지 않았습니다.

> 원격 SSH 환경에서는 새 SSH 포트를 UFW에서 허용하기 전에 방화벽을 활성화하지 않습니다.

---

## 5. SSH 20022 허용

```bash
sudo ufw allow 20022/tcp
```

실제 결과:

```text
Rules updated
Rules updated (v6)
```

의미:

```text
IPv4 20022/tcp 허용
IPv6 20022/tcp 허용
```

---

## 6. Agent 15034 허용

```bash
sudo ufw allow 15034/tcp
```

실제 결과:

```text
Rules updated
Rules updated (v6)
```

### 왜 Agent 실행 전에도 허용하나요?

06장에서 Agent가 `0.0.0.0:15034`로 LISTEN해야 합니다. 방화벽을 먼저 안전하게 준비하면 Agent 실행 후 네트워크 검증을 바로 할 수 있습니다.

---

## 7. 등록된 규칙 확인

방화벽을 켜기 전에 등록 규칙을 먼저 확인합니다.

```bash
sudo ufw show added
```

최종 확인된 결과:

```text
Added user rules (see 'ufw status' for running firewall):
ufw allow 20022/tcp
ufw allow 15034/tcp
```

### 실제 수행 중 있었던 점검

첫 확인에서는 `20022/tcp`만 표시되어 `15034/tcp` 규칙을 다시 적용한 뒤 재확인했습니다.

이때 중요한 원칙은:

> 명령이 성공했다고 생각하고 넘어가지 않고 **최종 상태를 조회 명령으로 다시 확인한다.**

입니다.

---

## 8. 기본 인바운드 정책 설정

명시적으로 허용하지 않은 인바운드 연결은 기본 차단합니다.

```bash
sudo ufw default deny incoming
```

실제 결과:

```text
Default incoming policy changed to 'deny'
(be sure to update your rules accordingly)
```

구조는 다음과 같습니다.

```text
외부 → 서버
       │
       ├─ 20022/tcp → 허용
       ├─ 15034/tcp → 허용
       └─ 그 외      → 기본 차단
```

---

## 9. UFW 활성화

필요한 허용 규칙과 기본 정책을 확인한 뒤 활성화합니다.

```bash
sudo ufw enable
```

실제 결과:

```text
Firewall is active and enabled on system startup
```

이 문장은 다음 두 가지를 의미합니다.

```text
현재 UFW active
재부팅 후에도 활성화되도록 설정
```

### 원격 SSH에서 경고가 나오는 경우

다음과 비슷한 메시지가 나타날 수 있습니다.

```text
Command may disrupt existing ssh connections. Proceed with operation (y|n)?
```

원격 환경에서는 `20022/tcp` 허용과 복구 세션을 먼저 확인한 뒤 진행합니다.

---

## 10. 최종 UFW 검증

```bash
sudo ufw status verbose
```

실제 최종 결과의 핵심:

```text
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)

20022/tcp                  ALLOW IN    Anywhere
15034/tcp                  ALLOW IN    Anywhere
20022/tcp (v6)             ALLOW IN    Anywhere (v6)
15034/tcp (v6)             ALLOW IN    Anywhere (v6)
```

### 판정

```text
UFW active             ✅
default deny incoming  ✅
20022/tcp allow         ✅
15034/tcp allow         ✅
22/tcp allow 없음       ✅
IPv6 동일 정책          ✅
```

---

## 11. 실제 LISTEN 상태 재확인

방화벽 활성화 후에도 SSH가 정상적으로 LISTEN하는지 확인합니다.

```bash
sudo ss -lntp | grep -E ':(22|20022|15034)\b' || true
```

현재 실제 결과:

```text
0.0.0.0:20022
[::]:20022
```

판정:

```text
20022 → 있음      : 정상
22    → 없음      : 정상
15034 → 아직 없음 : Agent 미실행 상태이므로 현재는 정상
```

`15034`의 실제 LISTEN 여부는 06장에서 Agent를 실행한 뒤 검증합니다.

---

## 12. 왜 `default deny incoming`인가

방화벽 정책을 다음처럼 생각하면 쉽습니다.

```text
모든 문을 일단 닫는다
        ↓
필요한 문만 이름을 지정해 연다
```

B1-1에서는 외부에서 필요한 서비스가 다음 두 개이므로:

```text
SSH   = 20022/tcp
Agent = 15034/tcp
```

이 두 포트만 명시적으로 허용합니다.

이는 **최소 허용(least exposure)** 방식으로 불필요한 네트워크 공격 표면을 줄이는 기본 원칙입니다.

---

## 13. `ALLOW`와 실제 서비스 상태를 혼동하지 않는다

다음 두 문장은 서로 다릅니다.

```text
UFW에서 15034 허용됨
Agent가 15034에서 LISTEN 중
```

현재 04장에서는 첫 번째만 완료되었습니다.

06장에서는:

```bash
sudo ss -lntp | grep ':15034\b'
```

등으로 실제 Agent LISTEN을 확인해야 합니다.

---

## 14. 오류와 복구

### 14.1 `ufw show added`에 규칙 하나가 안 보임

추측하지 않고 해당 규칙을 다시 적용한 뒤 `ufw show added`로 재확인합니다.

```bash
sudo ufw allow 15034/tcp
sudo ufw show added
```

실제 수행에서도 이 방식으로 최종 두 규칙을 확인했습니다.

### 14.2 UFW 활성화 후 SSH 접속 실패

기존 세션 또는 로컬 콘솔을 유지하고 다음을 확인합니다.

```bash
sudo ufw status verbose
sudo ss -lntp | grep -E ':(22|20022)\b' || true
systemctl status ssh.socket --no-pager
```

다음 두 조건을 구분해야 합니다.

```text
SSH가 20022에서 LISTEN하지 않음 → SSH 문제
SSH는 20022 LISTEN, UFW가 차단 → 방화벽 문제
```

### 14.3 잘못된 포트를 허용함

필요한 접근이 유지되는 것을 먼저 확인한 뒤 잘못된 규칙만 제거합니다. 원격 작업에서는 현재 SSH 허용 규칙을 먼저 삭제하지 않습니다.

### 14.4 UFW를 급히 꺼야 하는 상황

장애 복구 시 무조건 `ufw disable`부터 하지 않습니다. 우선 콘솔에서 현재 규칙과 LISTEN 상태를 확인하여 원인을 분리합니다.

---

## 15. 검증과 요구사항 추적

이 장과 직접 연결되는 항목:

| ID | 요구사항 | 현재 상태 |
|---|---|---|
| `FW-01` | UFW 활성화 | `TESTED` |
| `FW-02` | TCP `20022` 허용 | `TESTED` |
| `FW-03` | TCP `15034` 허용 | `TESTED` |
| `FW-04` | 인바운드 허용은 20022·15034만 | `TESTED` |

현재 실제 환경에서 설정과 조회 검증까지 완료했습니다. 11장에서 증빙 파일을 정리한 뒤 `PASS`로 올립니다.

전체 상태는 [요구사항-구현-검증-증빙 대응표](./reference/requirements-evidence-map.md)를 사용합니다.

---

## 16. 증빙 후보

11장에서 다음 형태로 정리합니다.

```text
evidence/04-firewall/
├── ufw-added-rules.txt
├── ufw-status-final.txt
└── listen-after-ufw.txt
```

개인 IP가 불필요하게 포함되면 마스킹합니다. 포트, 정책, 상태처럼 평가에 필요한 정보는 남깁니다.

---

## 17. 이번 단계 기억하기

### 한 문장

> **필요한 문만 열고 나머지는 기본적으로 막는다.**

### 핵심어 3개

```text
ALLOW · DENY · VERIFY
```

### 핵심 명령 3개

```bash
sudo ufw show added
sudo ufw status verbose
sudo ss -lntp
```

### 내가 설명할 수 있어야 할 것

> 왜 15034를 UFW에서 허용했다고 해서 Agent가 실행 중이라고 말할 수 없는가?

답의 핵심은 **방화벽 규칙과 프로세스의 실제 LISTEN 상태는 서로 다른 계층이기 때문**입니다.

---

## 18. 완료 체크

- [x] 초기 UFW `inactive` 확인
- [x] SSH `20022` LISTEN 확인
- [x] `20022/tcp` 허용
- [x] `15034/tcp` 허용
- [x] `ufw show added`로 두 규칙 확인
- [x] 기본 incoming `deny` 설정
- [x] UFW 활성화
- [x] 부팅 시 활성화 설정 확인
- [x] IPv4/IPv6 규칙 확인
- [x] `22/tcp` 별도 허용 규칙 없음 확인
- [x] 방화벽 활성화 후 SSH `20022` LISTEN 확인
- [ ] Agent 실행 후 `15034` LISTEN 확인 — 06장
- [ ] 11장에서 최종 증빙 파일 정리

현재 04단계는 **구현·실제 검증 `TESTED` 상태**입니다. 증빙 정리 완료 전에는 최종 `PASS`로 표시하지 않습니다.

---

## 이동

- [이전: 03. SSH 보안](./03-ssh-security.md)
- [다음: 05. 사용자·그룹·ACL](./05-users-groups-acl.md)
- [전체 목차](./README.md)
