# 환경별 차이

본문은 Ubuntu 24.04 LTS VM을 기준으로 합니다.

## 비교 대상

- 실제 Ubuntu 서버
- WSL2 Ubuntu
- OrbStack Ubuntu
- Docker 컨테이너

## 확인할 차이

- systemd
- SSH 외부 접속
- UFW 적용 범위
- Windows·macOS 호스트 방화벽
- 포트 포워딩
- cron과 재부팅 지속성

본문 명령과 환경별 보정 명령을 같은 코드 블록에 섞지 않습니다.
