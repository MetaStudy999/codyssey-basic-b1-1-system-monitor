# B1-1 요구사항 수행 내역서

> 실제 수행 결과와 저장소 구현 상태를 구분합니다. 예상 출력이나 미실행 결과는 `TODO`로 남기고, 원본 출력은 `evidence/`에 연결합니다.

## 1. 실습 환경

| 항목 | 실제 확인값 | 상태 |
|---|---|---|
| OS | Ubuntu 24.04.4 LTS | TESTED |
| 원본 기준 | Ubuntu 22.04 또는 동등 Linux | 기준 |
| CPU Architecture | x86_64 | TESTED |
| PID 1 | systemd | TESTED |
| systemd | 255 | TESTED |
| 실행 사용자 | ubuntu | TESTED |

## 2. SSH

실제 수행:

```text
초기 22 LISTEN 확인
sshd_config 백업 및 cmp 확인
Port 20022
PermitRootLogin no
sshd -t 성공
sshd -T 최종값 확인
Ubuntu 24.04 sshd-socket-generator 동작 확인
20022 LISTEN / 22 미LISTEN 확인
```

현재 상태: `TESTED`

남은 항목:

```text
외부/별도 클라이언트 새 SSH 접속
실제 evidence 파일 정리
```

## 3. 방화벽

실제 수행:

```text
UFW 초기 inactive 확인
20022/tcp 허용
15034/tcp 허용
default deny incoming
UFW enable
최종 status verbose 확인
```

현재 상태: `TESTED`

확인 결과 핵심:

```text
Status: active
Default: deny (incoming)
20022/tcp ALLOW
15034/tcp ALLOW
22/tcp 별도 ALLOW 없음
```

## 4. 사용자·그룹·ACL

실제 현재 상태:

```text
agent-common 그룹 객체 생성됨
agent-core 그룹 객체 생성됨
agent-admin/dev/test 사용자 생성 전
멤버십/디렉터리/ACL 실제 적용 전
```

현재 상태: `TODO / 부분 구성`

저장소 문서에는 다음 정책을 구현했습니다.

```text
agent-common = admin + dev + test
agent-core   = admin + dev
upload_files = common R/W
api_keys     = core only R/W
log dir      = core only R/W
```

## 5. Agent 실행환경

원본 미션 데이터 설명에서 제공 파일명이 다음과 같이 확인됩니다.

```text
agent-app-linux-x86
agent-app-linux-arm64
```

따라서 기존의 `agent_app.py` 고정 실행 가정을 제거하고 다음 흐름으로 보완했습니다.

```text
uname -m
→ unzip -l agent-app.zip
→ x86/arm64 대상 선택
→ 제공 실행 파일만 배치
→ non-root 실행
→ Boot 5 [OK]
→ Agent READY
→ 0.0.0.0:15034
```

또한 Agent 파일 배치 시 `chown -R agent-admin:agent-common AGENT_HOME`을 금지해 `api_keys`의 `agent-core` 정책이 깨지지 않도록 수정했습니다.

실제 ZIP 내부 경로·실행·Boot/READY는 아직 `TODO`입니다.

## 6. monitor.sh

저장소 구현:

```text
아키텍처별 제공 Agent 프로세스 기본값
프로세스 health → 실패 exit 1
포트 health → 실패 exit 1
방화벽 비활성 → WARNING 후 계속
CPU/MEM/Root DISK 수집
20/10/80 threshold WARNING
지정 monitor.log 형식 append
로그 디렉터리/파일 쓰기 실패 → exit 2
append 자체 실패 → exit 2
```

보완 브랜치에서 작성본 `bash -n` 구문 검사는 수행했습니다. 사용자 Ubuntu에 실제 배치한 파일의 최종 `bash -n` 및 runtime은 아직 `TODO`입니다.

현재 상태: `IMPLEMENTED / runtime TODO`

## 7. cron·logrotate

cron:

```text
agent-admin crontab
* * * * *
monitor.sh 절대 경로
최소 PATH
```

logrotate는 원본의 **최대 10개 파일**을 엄격하게 해석해:

```text
현재 monitor.log 1개
+ 회전본 최대 9개
= 최대 10개
```

로 보완했습니다.

```text
size 10M
rotate 9
create 0660 agent-admin agent-core
```

현재 상태: `IMPLEMENTED / 실제 설치·runtime TODO`

## 8. 테스트 체계

`tests/test-cases.md`를 T-001~T-040으로 정리하고 `reports/test-results.md`와 1:1 대응하도록 보완했습니다.

검증 도구 역할:

```text
preflight.sh       = 사전 환경 확인
verify.sh          = 현재 상태 read-only 검사
acceptance-test.sh = 실제 기능·장애·ACL·cron 관찰
```

`verify.sh` 통과만으로 최종 미션 PASS라고 출력하지 않도록 수정했습니다.

## 9. 실제 트러블슈팅

`reports/troubleshooting-report.md`에 실제 관찰한 항목을 반영했습니다.

```text
TS-001 /run/sshd RuntimeDirectory
TS-002 ssh.socket / daemon-reload / generator
TS-003 UFW 15034 규칙 재확인
```

미발생 장애를 실제 이력처럼 기록하지 않습니다.

## 10. 보너스

현재 구현:

```text
scripts/report.sh
- CPU/MEM/DISK 평균·최소·최대
- 샘플 수
- 최소/최대 발생 시각
- 시간 구간 분석

scripts/archive-logs.sh
- 7일 경과 .log 압축
- archive 이동
- 30일 경과 .gz 삭제
- Dry Run
- 디렉터리/권한/find/gzip/mv/rm 오류 처리
- 대상 0개 정상 안내
- mv 실패 시 원본 복원 시도
```

현재 상태: `IMPLEMENTED / fixture 및 실제 로그 TEST TODO`

## 11. 현재 종합 상태

```text
환경                    TESTED
SSH                     TESTED / 외부 접속·evidence 남음
UFW                     TESTED / evidence 남음
IAM/ACL                 TODO / 그룹 객체 2개만 생성
Agent                   IMPLEMENTED guide / runtime TODO
monitor.sh              IMPLEMENTED / runtime TODO
cron/logrotate          IMPLEMENTED / runtime TODO
테스트 체계              IMPLEMENTED / 대부분 runtime TODO
트러블슈팅 보고서        실제 3건 반영
재현 도구               IMPLEMENTED
증빙                    TODO
Codex audit             TODO
사용자 acceptance       TODO
Bonus                   IMPLEMENTED / test TODO
```

최종 `PASS`는 **구현 + 실제 테스트 + 증빙**이 모두 연결된 뒤 부여합니다.
