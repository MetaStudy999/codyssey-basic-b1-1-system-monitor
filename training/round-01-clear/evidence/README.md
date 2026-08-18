# B1-1 R01 — Evidence Guide

Evidence는 단순 스크린샷 모음이 아니라 공식 평가항목을 증명하는 자료입니다.

## 원칙

`Requirement → Implementation → Verification → Evidence`

실제 Runtime을 수행하지 않은 결과를 예상 출력으로 만들어 Evidence에 넣지 않습니다.

## 권장 Evidence 묶음

1. `01-ssh.txt` 또는 캡처
   - effective SSH port 20022
   - `PermitRootLogin no`
   - 20022 LISTEN
2. `02-firewall.txt`
   - `ufw status verbose`의 전체 정책 출력
   - Firewall active
   - default deny incoming
   - 20022/tcp, 15034/tcp ALLOW IN
   - 그 외 불필요한 ALLOW IN 없음
   - 필요한 두 포트만 잘라낸 출력이 아니라 전체 정책을 증빙하여 추가 허용 규칙이 없음을 함께 확인
3. `03-users-groups.txt`
   - agent-admin/dev/test
   - agent-common/core membership
4. `04-permissions.txt`
   - 디렉터리 owner/group/mode
   - ACL
5. `05-agent-boot.txt`
   - Boot Sequence 5단계 `[OK]`
   - `Agent READY`
   - Secret 값 제외
6. `06-port-15034.txt`
   - Agent가 0.0.0.0:15034 LISTEN
7. `07-monitor-success.txt`
   - process/port/resource/Warning 출력
8. `08-monitor-failure.txt`
   - Process 또는 Port 비정상에서 exit 1
9. `09-monitor-log.txt`
   - 공식 포맷 최근 라인
10. `10-log-rotation.txt`
    - 10MB/10개 정책의 안전한 재현 결과
11. `11-cron.txt`
    - agent-admin crontab
    - 1~2분 전후 monitor.log 증가
12. `12-verify.txt`
    - `verify.sh` 최종 `[PASS]/[FAIL]`
    - `Result: N PASS / N FAIL`

## Secret 금지

Evidence에 다음을 포함하지 않습니다.

- `t_secret.key` 실제 내용
- `.env` 실제 값
- Password
- API Key
- Access Token
- Private Key

Secret 파일은 `test -f`, `stat`, 권한 확인 등 **존재와 메타데이터만** 증빙합니다.

## CLEAR 조건

필수 Evidence가 실제 결과로 채워지고 공식 Evaluation을 재확인한 뒤에만 B1-1을 `✅ CLEAR`로 판정합니다.
