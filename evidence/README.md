# B1-1 증빙 자료 관리 규칙

이 디렉터리는 미션 수행 과정에서 생성한 명령 출력과 화면 캡처를 저장합니다.

## 1. 기본 원칙

1. 가능하면 스크린샷과 명령 출력 텍스트를 함께 보관합니다.
2. 파일 이름은 실행 순서와 평가 항목을 알 수 있도록 작성합니다.
3. 개인 IP, 사용자 비밀번호, API 키, 토큰, 키 파일 내용은 마스킹합니다.
4. 증빙 파일은 `docs/requirements.md`의 항목과 연결합니다.
5. 재현이 필요한 명령은 `docs/execution-record.md`에도 기록합니다.

## 2. 권장 파일 이름

```text
01-environment.txt
02-sshd-config.txt
03-ssh-listen.txt
04-firewall-status.txt
05-users-groups.txt
06-directory-acl.txt
07-agent-env.txt
08-agent-boot.txt
09-agent-port.txt
10-monitor-permission.txt
11-monitor-process-test.txt
12-monitor-port-test.txt
13-monitor-warning-test.txt
14-monitor-resource.txt
15-monitor-log.txt
16-logrotate.txt
17-crontab.txt
18-cron-before-after.txt
```

스크린샷은 같은 기본 이름에 `.png`를 사용합니다.

```text
08-agent-boot.txt
08-agent-boot.png
```

## 3. 텍스트 증빙 저장 예시

```bash
mkdir -p evidence

uname -a 2>&1 | tee evidence/01-environment.txt
sudo sshd -T 2>&1 | grep -E '^(port|permitrootlogin)' \
  | tee evidence/02-sshd-config.txt
sudo ss -tulnp 2>&1 | tee evidence/03-ssh-listen.txt
sudo ufw status numbered 2>&1 | tee evidence/04-firewall-status.txt
```

종료 코드도 함께 남겨야 하는 시험은 다음처럼 기록합니다.

```bash
{
  /absolute/path/to/monitor.sh
  rc=$?
  echo "EXIT_CODE=$rc"
} 2>&1 | tee evidence/11-monitor-process-test.txt
```

파이프라인에서 원래 명령의 종료 코드를 확인해야 하는 경우 `PIPESTATUS`를 사용합니다.

```bash
/absolute/path/to/monitor.sh 2>&1 | tee evidence/11-monitor-process-test.txt
rc=${PIPESTATUS[0]}
echo "EXIT_CODE=$rc" | tee -a evidence/11-monitor-process-test.txt
```

## 4. cron 전후 비교 예시

```bash
{
  echo "=== BEFORE ==="
  date
  wc -l /var/log/agent-app/monitor.log
  tail -n 3 /var/log/agent-app/monitor.log

  sleep 70

  echo "=== AFTER ==="
  date
  wc -l /var/log/agent-app/monitor.log
  tail -n 3 /var/log/agent-app/monitor.log
} 2>&1 | tee evidence/18-cron-before-after.txt
```

## 5. 민감정보 점검

커밋 전에 다음 항목을 확인합니다.

- 키 파일과 `.env` 파일이 추적되지 않는가?
- 명령 출력에 개인 IP나 비밀번호가 포함되지 않았는가?
- 환경변수 증빙에서 실제 비밀값이 마스킹되었는가?
- 스크린샷에 터미널 기록이나 브라우저 개인정보가 노출되지 않았는가?

## 6. 문서 연결

각 수행 기록에는 증빙 경로를 명시합니다.

```markdown
- 검증 결과: PASS
- 증빙: `evidence/08-agent-boot.txt`
- 관련 요구사항: APP-03, APP-04
```
