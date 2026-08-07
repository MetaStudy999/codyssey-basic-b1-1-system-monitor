# B1-1 요구사항 수행 내역서

> 실제 수행 결과만 기록합니다. 예상 출력이나 아직 실행하지 않은 결과는 `TODO`로 남깁니다. 원본 출력은 `evidence/`에 보관합니다.

## 1. 실습 환경

| 항목 | 실제 값 | 상태 |
|---|---|---|
| OS | Ubuntu 24.04.4 LTS | 확인 |
| CPU Architecture | x86_64 | 확인 |
| PID 1 | systemd | 확인 |
| systemd | 255 | 확인 |
| 실행 사용자 | ubuntu | 확인 |

원본 미션 기준은 **Ubuntu 22.04 또는 동등한 Linux 환경**이며, 위 값은 현재 실제 실습 환경입니다.

## 2. 원본 요구사항

- SSH `20022`
- Root 원격 로그인 차단
- UFW 활성화, `20022/tcp`, `15034/tcp` 허용
- 사용자 3개, 그룹 2개
- 디렉터리·권한·ACL
- Agent 환경변수 및 키 파일
- 일반 사용자 Agent 실행
- Boot Sequence 5 `[OK]`
- `Agent READY`
- `0.0.0.0:15034` LISTEN
- `monitor.sh`
- 프로세스/포트 Health Check 실패 시 `exit 1`
- 방화벽 및 자원 임계값 WARNING
- CPU/MEM/Root DISK 수집
- 지정 로그 포맷
- `10MB / 10개` 로그 관리
- agent-admin cron 매분 실행
- 보너스 `report.sh`, 시간 기반 로그 보존

## 3. 초기 상태

### 3.1 사용자·환경

- `whoami` → `ubuntu`
- `pwd` → `/home/ubuntu`
- Ubuntu 24.04.4 LTS
- x86_64
- systemd 255
- sudo 사용 가능

### 3.2 필수 도구

확인됨:

```text
sshd
ufw
cron
getfacl
setfacl
ss
logrotate
```

## 4. SSH

### 목표

```text
Port 20022
PermitRootLogin no
```

### 실제 수행

- 초기 22 LISTEN 확인
- `ssh.socket` activation 확인
- `/etc/ssh/sshd_config` 백업
- 백업 `cmp` 동일 확인
- `/etc/ssh/sshd_config.d/99-b1-1.conf` 작성
- `sshd -t` 통과
- `sshd -T` 최종값 확인
- Ubuntu 24.04 `sshd-socket-generator` 동작 확인
- 실제 `20022` LISTEN, `22` 미LISTEN 확인

### 현재 결과

```text
port 20022
permitrootlogin no
20022 LISTEN
22 없음
```

### 남은 항목

- 외부 클라이언트 일반 사용자 새 SSH 접속 증빙
- evidence 파일 정리

## 5. 방화벽

### 실제 수행

- 초기 UFW inactive 확인
- `20022/tcp` 허용
- `15034/tcp` 허용
- `default deny incoming`
- UFW 활성화
- 최종 규칙 확인

### 현재 결과

```text
Status: active
Default: deny (incoming)
20022/tcp ALLOW
15034/tcp ALLOW
22/tcp 별도 ALLOW 없음
```

## 6. 사용자·그룹·ACL

### 현재 실제 상태

```text
agent-common 그룹 생성됨
agent-core 그룹 생성됨
사용자 3개는 아직 생성 전
멤버십/디렉터리/ACL은 아직 미구현
```

### 상태

`TODO / 부분 구성`

## 7. Agent 실행

### 상태

`TODO`

실제 `agent-app.zip` 구조 확인 후 기록합니다.

필수 결과:

```text
non-root
Boot 5 [OK]
Agent READY
0.0.0.0:15034
```

## 8. monitor.sh

### 저장소 구현

`scripts/monitor.sh` 구현 완료.

구현 항목:

```text
process health
port health
exit 1
firewall warning
CPU/MEM/DISK
20/10/80 warning
monitor.log append
cron 환경 파일 로딩
```

### 실제 Ubuntu 테스트

`TODO`

## 9. 로그·cron·logrotate

### 저장소 구현

- `config/crontab.example` 구현
- `config/agent-monitor.logrotate` 구현

### 실제 Ubuntu 적용

`TODO`

## 10. 테스트·복구

테스트 정의:

```text
tests/test-cases.md
```

현재 실제 완료:

- SSH 설정/포트 검증
- UFW 설정 검증

나머지 테스트는 05·06 실제 환경 구성이 완료된 뒤 실행합니다.

## 11. 실제 트러블슈팅

### `/run/sshd` 오류

증상:

```text
Missing privilege separation directory: /run/sshd
```

원인: `ssh.service` inactive 상태에서 RuntimeDirectory가 아직 준비되지 않음.

조치: 수동 mkdir 대신 `systemctl start ssh.service`로 systemd가 준비하도록 처리.

### systemd unit 재로딩

```text
ssh.socket changed on disk ... systemctl daemon-reload
```

조치: `sudo systemctl daemon-reload` 후 effective socket 설정 재검증.

### UFW 규칙 재확인

첫 `ufw show added`에서 `15034`가 보이지 않아 규칙을 다시 적용하고 최종 두 규칙을 확인.

## 12. 평가 대응

평가 항목별 설명은 `docs/12-evaluation-preparation.md`에서 준비합니다.

## 13. 최종 결과

현재:

```text
환경          TESTED
SSH           TESTED
UFW           TESTED
IAM/ACL       TODO
Agent         TODO
monitor.sh    IMPLEMENTED / runtime TODO
cron/logrotate IMPLEMENTED / runtime TODO
전체 테스트   TODO
증빙          TODO
재현          TODO
최종 제출     TODO
보너스        TODO
```

## 14. 보너스

필수 미션 완료 후 다음을 기록합니다.

```text
report.sh
CPU/MEM/DISK 평균·최대·최소·샘플 수
선택 시간 구간 분석
7일 로그 압축
archive 이동
30일 archive 삭제
예외 처리
```
