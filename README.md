# codyssey-basic-b1-1-system-monitor

코디세이 기초 B1-1 시스템 모니터 미션 저장소입니다.

## 목표

Ubuntu 환경에서 SSH·방화벽·사용자·그룹·ACL을 구성하고, 제공 Agent를 일반 사용자로 실행한 뒤 Bash 기반 `monitor.sh`로 상태를 점검·기록·자동화합니다.

## 기준 실습 환경

- Ubuntu 24.04 LTS VM
- x86_64
- systemd
- OpenSSH Server
- UFW
- cron

WSL2·OrbStack·Docker 차이는 [환경별 차이](./docs/reference/environment-differences.md)에서 별도로 다룹니다.

## 5단계 수행 흐름

1. 시작 준비: `00~02`
2. 시스템 구성: `03~06`
3. 핵심 구현: `07~08`
4. 검증과 복구: `09~10`
5. 제출 완성: `11~15`

자세한 진행 순서는 [실습 문서 인덱스](./docs/README.md)를 확인합니다.

## 원본 문서

- [B1-1 미션](./b1-1-mission.md)
- [B1-1 평가 항목](./b1-1-evaluation.md)
- [B1-1 미션 PDF](./b1-1-mission.pdf)

## 주요 디렉터리

- `docs/`: 입문자 실행 안내서
- `scripts/`: 실제 Bash 스크립트
- `config/`: 환경변수·cron·logrotate 예시
- `tests/`: 테스트 정의
- `reports/`: 실제 수행 결과
- `evidence/`: 검증 근거

> 현재 단계는 저장소 구조와 문서 골격 구성입니다. 실제 명령과 스크립트는 각 단계에서 검증 후 채웁니다.
