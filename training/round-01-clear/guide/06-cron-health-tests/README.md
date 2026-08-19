# B1-1 모듈 06 — cron 자동 실행·실패·경고 분기

> 범위: **STEP 10~11**  
> [← 모듈 05](../05-monitor-log/README.md) · [전체 입문자 가이드](../../BEGINNER-GUIDE.md) · [다음: 모듈 07 →](../07-verification-evidence/README.md)

## 이 모듈의 목적

예약 실행 스케줄러(cron)가 `agent-admin` 권한으로 `monitor.sh`를 매분 실행하도록 구성하고, 프로세스·포트 실패 경로(Failure Path)와 경고 전용 경로(Warning-only Path)를 서로 분리하여 검증합니다.

## 📑 모듈 목차(Module Table of Contents, Module TOC)

### 1. cron 자동 실행과 실제 로그 증가
- [STEP 10 — agent-admin cron 매분 자동 실행 검증](01-cron.md)

### 2. 실패 경로와 경고 전용 경로
- [STEP 11 — Health 실패와 Warning-only 분기 격리 검증](02-health-tests.md)

## 완료 조건

- [ ] STEP 10 완료
- [ ] STEP 11 완료
- [ ] cron 등록과 실제 자동 실행 결과를 구분할 수 있다.
- [ ] 프로세스/포트 실패 시 종료 코드(Exit Code) `1`, 경고 전용 경로는 `0`이어야 하는 이유를 설명할 수 있다.

## 이동

[← 모듈 05](../05-monitor-log/README.md) · [전체 입문자 가이드](../../BEGINNER-GUIDE.md) · [다음: 모듈 07 →](../07-verification-evidence/README.md)
