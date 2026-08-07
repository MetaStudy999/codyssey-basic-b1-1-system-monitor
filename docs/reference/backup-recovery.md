# B1-1 백업과 복구 원칙

## 핵심 원칙

```text
변경 전 확인
→ 원본/현재 상태 백업
→ 한 번에 한 영역만 변경
→ 즉시 검증
→ 실패 시 원복
→ 재검증
```

실제 시스템 백업 파일은 저장소 밖의 로컬 경로에 보관하고 Git에 커밋하지 않습니다.

## SSH

변경 전에:

```bash
sudo cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config.b1-1.backup
sudo cmp -s /etc/ssh/sshd_config /etc/ssh/sshd_config.b1-1.backup
```

원격 환경에서는 기존 SSH 세션을 닫기 전에 새 20022 세션을 확인합니다.

## UFW

SSH 포트 전환 전 새 포트를 먼저 허용하고, `ufw status verbose`로 최종 정책을 확인합니다. 복구 시 SSH 설정과 방화벽 허용 포트 순서를 함께 고려합니다.

## 사용자·그룹·ACL

광범위한 `chmod -R`/`chown -R`보다 각 보안 경계를 개별 복구합니다.

```text
AGENT_HOME   → agent-common 통과/읽기
upload_files → agent-common R/W
api_keys     → agent-core ONLY R/W
log dir      → agent-core ONLY R/W
```

특히 Agent 파일 배치 때문에 `api_keys` 그룹을 `agent-common`으로 재귀 변경하지 않습니다.

## 환경 파일·key

환경 파일은 비밀값 없이 재생성할 수 있도록 `config/agent.env.example`을 유지합니다. 실제 key 내용은 저장소/증빙에 복사하지 않습니다.

## cron

변경 전 현재 값을 별도 파일에 저장할 수 있습니다.

```bash
sudo -u agent-admin crontab -l > /tmp/agent-admin.crontab.before 2>/dev/null || true
```

복구 후에는 단순 등록뿐 아니라 1~2분 후 로그 증가까지 재검증합니다.

## logrotate

설치 전 현재 `/etc/logrotate.d/agent-monitor`가 있으면 저장소 밖에서 백업합니다. 변경 후에는 `logrotate -d`를 먼저 사용하고, 강제 회전은 통제된 실습 시점에 수행합니다.

## 보너스 archive

실제 `/var/log`에서 바로 시험하지 않고 `/tmp` fixture와 `DRY_RUN=1`로 먼저 검증합니다. `archive-logs.sh`는 move 실패 시 압축 원본 복원을 시도하지만, 실제 실행 전 권한과 대상 경로를 확인하는 것이 우선입니다.

## 복구 완료 기준

```text
원래 서비스가 다시 동작함
+ 보안 정책이 요구사항과 일치함
+ verify/acceptance 재검증
+ 복구 결과 기록
```
