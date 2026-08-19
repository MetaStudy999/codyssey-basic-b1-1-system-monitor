# B1-1 모듈 04 — 에이전트(Agent) 준비와 실제 실행(Runtime)

> 범위: **STEP 06~07**  
> [← 모듈 03](../03-users-groups-acl/README.md) · [전체 입문자 가이드](../../BEGINNER-GUIDE.md) · [다음: 모듈 05 →](../05-monitor-log/README.md)

## 이 모듈의 목적

제공 에이전트(Agent) 실행 파일, 환경 변수(Environment Variable), 비밀정보(Secret)를 안전하게 준비하고, 실제 에이전트를 비루트(Non-root) 사용자로 실행하여 부팅 순서(Boot Sequence), 준비 상태(READY), 포트 리슨(Listen)을 검증합니다.

## 📑 모듈 목차(Module Table of Contents, Module TOC)

### 1. Agent 파일·환경 변수·비밀정보 준비
- [STEP 06 — Agent 압축 파일(Archive)·환경 변수·비밀정보 준비](../04-AGENT-RUNTIME.md#step-06)

### 2. Agent 실제 실행과 포트 검증
- [STEP 07 — Agent 실제 실행(Runtime) 검증](../04-AGENT-RUNTIME.md#step-07)

## 완료 조건

- [ ] STEP 06 완료
- [ ] STEP 07 완료
- [ ] 비밀정보(Secret) 값을 출력하지 않고 존재·권한·동작만 확인하는 원칙을 지켰다.
- [ ] Agent가 비루트 사용자로 실행되는지 확인했다.
- [ ] `0.0.0.0:15034` 실제 리슨(Listen)을 확인했다.

## 이동

[← 모듈 03](../03-users-groups-acl/README.md) · [전체 입문자 가이드](../../BEGINNER-GUIDE.md) · [다음: 모듈 05 →](../05-monitor-log/README.md)
