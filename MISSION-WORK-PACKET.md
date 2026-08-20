# B1-1 Mission Work Packet — System Monitor

> Mission: **컴퓨터가 알아서 자기 상태를 점검하게 만들기**  
> Repository: `MetaStudy999/codyssey-basic-b1-1-system-monitor`  
> Work branch: `mission/b1-1`  
> Control Tower: `MetaStudy999/codyssey-basic` (**READ ONLY**)  
> Frozen Control Tower baseline: `0d1581b3e82366988f57e1d76da311c028b8e15e`

---

## 1. Identity

- Mission ID: `B1-1`
- Domain: Linux & OS
- Official requirement metadata: `required`
- Mission title: `컴퓨터가 알아서 자기 상태를 점검하게 만들기`
- Target repository: `MetaStudy999/codyssey-basic-b1-1-system-monitor`
- Target repository baseline: `7f460bdef7a71439394d1461122ce6abd0d9fe48`
- Starter Packet: `docs/00-governance/work-packets/b1-1.md`
- Active Wave: `config/waves/20260808-01.yaml`
- Dependency: `NONE`
- Starting gate: `G1_SOURCE`

## 2. Control Tower Baseline / Drift Check

### Frozen baseline

`0d1581b3e82366988f57e1d76da311c028b8e15e`

### Current Control Tower main observed at Workcell start

`f6192ad701bd1d2c317f908d210e7049f6b32310`

### Comparison

- Current `main` is **2 commits ahead** of the frozen baseline.
- Frozen baseline is the merge base; it is not behind/diverged.
- The Active Wave explicitly states that the manifest/prompt launcher commits are intentionally outside the frozen Governance baseline.
- Prompt, Active Wave, Starter Packet, `config/missions.yaml`, and Mission index all map B1-1 to the same target repository.
- The Starter Packet blob at current `main` and at the frozen baseline is identical: `dc03c65e34e6c05cc0648c01639385687f2020c6`.

**Drift verdict: `NO_IMPACT`**  
No `CONTROL_TOWER_DRIFT` condition was found. Governance remains pinned to the frozen baseline.

## 3. Source Inventory

| Source | Location / identity | State | Provenance / notes |
|---|---|---|---|
| Mission PDF | `b1-1-mission.pdf` | `VALID` | 8-page official mission source. Repository blob SHA `74e171b657e4826c5e024756aefd976beecf7229`. The supplied local PDF has the same Git blob SHA, so it is byte-identical to the repository PDF. Rendered pages are readable. |
| Mission Markdown | `b1-1-mission.md` | `DUPLICATE` | Substantive transcription of the PDF. It explicitly identifies the PDF as its source. Spot-check of required sections/values against the PDF found no requirement conflict. PDF remains authoritative. |
| Evaluation Markdown | `b1-1-evaluation.md` | `UNVERIFIED` | Substantive checklist exists and is internally consistent with the Mission, but no separate official Evaluation PDF/source/provenance was found in the repository or available File Library search. Use as a **supplementary review target**, not as authority to create Mission requirements. |
| Evaluation PDF | not found | `MISSING` | No Evaluation PDF discovered. |
| Control Tower mission index | frozen `docs/02-domains/01-linux-os/b1-1-system-monitor.md` | `VALID` | Confirms title/domain/required metadata and broad scope; does not replace Mission PDF. |
| Control Tower `config/missions.yaml` | frozen baseline | `VALID` | Confirms B1-1 repo, status TODO, current gate G1 SOURCE, required metadata. |
| Existing requirements/evidence map | `docs/reference/requirements-evidence-map.md` | `VALID` as repository mapping | Lower-priority derived document. Must not override Mission PDF. |
| README / learning docs | repository | `VALID` as derived docs | Useful for implementation/learning only. |
| Evidence directories | `evidence/*` | `EMPTY` | Directory structure exists, but current subdirectories contain no evidence files. |
| Execution report | `reports/execution-report.md` | `PARTIAL` | Contains previous runtime observations and explicitly marks remaining work TODO. Raw evidence is not yet stored under `evidence/`. |

### Source Mode

`MISSION-LED`

### Source Confidence

`MEDIUM`

Reason: Mission PDF is valid and authoritative, but the Evaluation checklist has not been independently verified as an official source.

### Source Gaps

1. Official provenance of `b1-1-evaluation.md` is not independently confirmed.
2. No Evaluation PDF was found.
3. Existing runtime claims for environment/SSH/UFW are recorded in `reports/execution-report.md`, but raw evidence directories are currently empty; therefore they are not final PASS evidence yet.

## 4. Mission Contract — Confirmed Requirements

Only Mission-PDF-backed requirements are `CONFIRMED` below.

### 4.1 Deliverables

| ID | Confirmed requirement | Source |
|---|---|---|
| `REQ-OUT-01` | 요구사항 수행 내역서 1개 | Mission PDF §2 |
| `REQ-OUT-02` | `monitor.sh` 시스템 상태 수집/로깅 Bash 스크립트 | Mission PDF §2, §4 |
| `REQ-OUT-03` | 필수 증거: SSH 20022/root 차단, firewall, accounts/groups, ACL, Agent boot, monitor output, monitor.log, cron auto-run | Mission PDF §2 |

### 4.2 Security / Network

| ID | Confirmed requirement | Source |
|---|---|---|
| `REQ-SSH-01` | SSH port `20022` | Mission PDF §4.1 |
| `REQ-SSH-02` | Root remote login disabled | Mission PDF §4.1 |
| `REQ-FW-01` | UFW or firewalld enabled | Mission PDF §4.1 |
| `REQ-FW-02` | Inbound TCP allowed ports limited to `20022` and `15034` | Mission PDF §4.1 |

### 4.3 Users / Groups / ACL

| ID | Confirmed requirement | Source |
|---|---|---|
| `REQ-IAM-01` | Users: `agent-admin`, `agent-dev`, `agent-test` | Mission PDF §4.2 |
| `REQ-IAM-02` | Group `agent-common`: admin/dev/test | Mission PDF §4.2 |
| `REQ-IAM-03` | Group `agent-core`: admin/dev | Mission PDF §4.2 |
| `REQ-FS-01` | `$AGENT_HOME`, `$AGENT_HOME/upload_files`, `$AGENT_HOME/api_keys`, `/var/log/agent-app` exist | Mission PDF §4.2 |
| `REQ-ACL-01` | `upload_files`: `agent-common` R/W | Mission PDF §4.2 |
| `REQ-ACL-02` | `api_keys` and `/var/log/agent-app`: `agent-core` only R/W | Mission PDF §4.2 |

### 4.4 Agent Runtime

| ID | Confirmed requirement | Source |
|---|---|---|
| `REQ-ENV-01` | `AGENT_HOME` configured | Mission PDF §4.3 |
| `REQ-ENV-02` | `AGENT_PORT=15034` | Mission PDF §4.3 |
| `REQ-ENV-03` | `AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files` | Mission PDF §4.3 |
| `REQ-ENV-04` | `AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key` | Mission PDF §4.3 |
| `REQ-ENV-05` | `AGENT_LOG_DIR=/var/log/agent-app` recommended/configured | Mission PDF §4.3 |
| `REQ-KEY-01` | key file at required path with test key string | Mission PDF §4.3 |
| `REQ-AGENT-01` | Agent runs as non-root user | Mission PDF §4.3 |
| `REQ-AGENT-02` | Boot Sequence 5 steps all `[OK]` | Mission PDF §4.3 |
| `REQ-AGENT-03` | `Agent READY` output | Mission PDF §4.3 |
| `REQ-AGENT-04` | `0.0.0.0:15034` LISTEN | Mission PDF §4.3 |

### 4.5 `monitor.sh`

| ID | Confirmed requirement | Source |
|---|---|---|
| `REQ-MON-01` | Deployment path `$AGENT_HOME/bin/monitor.sh` | Mission PDF §4.4 |
| `REQ-MON-02` | owner `agent-dev`, group `agent-core`, mode `750` | Mission PDF §4.4 |
| `REQ-MON-03` | cron runner `agent-admin` in `agent-core` | Mission PDF §4.4 |
| `REQ-MON-04` | Agent process check; failure exits `1` | Mission PDF §4.4 |
| `REQ-MON-05` | TCP 15034 LISTEN check; failure exits `1` | Mission PDF §4.4 |
| `REQ-MON-06` | Firewall inactive => `[WARNING]`, script continues | Mission PDF §4.4 |
| `REQ-MON-07` | Collect CPU usage percent | Mission PDF §4.4 |
| `REQ-MON-08` | Collect memory usage percent | Mission PDF §4.4 |
| `REQ-MON-09` | Collect root partition used percent | Mission PDF §4.4 |
| `REQ-MON-10` | CPU `>20%` warning only | Mission PDF §4.4 |
| `REQ-MON-11` | MEM `>10%` warning only | Mission PDF §4.4 |
| `REQ-MON-12` | DISK_USED `>80%` warning only | Mission PDF §4.4 |
| `REQ-MON-13` | Append `/var/log/agent-app/monitor.log` in `[YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%` format | Mission PDF §4.4 |
| `REQ-MON-14` | Retain max `10MB / 10 files` using logrotate or script logic | Mission PDF §4.4 |

### 4.6 cron / Platform / Constraints

| ID | Confirmed requirement | Source |
|---|---|---|
| `REQ-CRON-01` | `agent-admin` crontab runs monitor every minute | Mission PDF §4.5 |
| `REQ-CRON-02` | After 1–2 minutes, `monitor.log` gains new line(s) automatically | Mission PDF §4.5 |
| `REQ-PLATFORM-01` | Ubuntu 22.04 LTS or equivalent Linux | Mission PDF §6 |
| `REQ-CONSTRAINT-01` | Automation script must be Bash; Python replacement prohibited | Mission PDF §7 |
| `REQ-CONSTRAINT-02` | Use sudo only when needed; prefer normal users | Mission PDF §7 |
| `REQ-CONSTRAINT-03` | Provided Python app is execution target; monitoring/automation is core | Mission PDF §7 |

### 4.7 Learning / Explainability

| ID | Confirmed explanation target | Source |
|---|---|---|
| `LEARN-01` | Why SSH port change and Root remote-login blocking are baseline security | Mission PDF §3 |
| `LEARN-02` | Why allow-only-needed firewall policy | Mission PDF §3 |
| `LEARN-03` | Why users/groups/ACL separate shared vs security directories | Mission PDF §3 |
| `LEARN-04` | Why environment variables pin execution environment | Mission PDF §3 |
| `LEARN-05` | Process/port/resource monitoring and logging flow | Mission PDF §3 |
| `LEARN-06` | cron and log retention purpose | Mission PDF §3 |

### 4.8 Optional Bonus — Non-blocking

`report.sh` summary report and time-based archive/delete policy are **OPTIONAL** and must not delay Mission completion.

## 5. Evaluation Candidate Mapping

`b1-1-evaluation.md` is currently `UNVERIFIED` as an official source. Its items are nevertheless useful as a supplementary independent review checklist because they are compatible with the Mission PDF.

Candidate groups:

- implementation/runtime: SSH, firewall, accounts/groups, Agent boot, monitor failure behavior, log append, cron, 10MB/10-file retention
- implementation explanation: process/port commands, resource parsing, owner/group/cron policy, logrotate mechanism
- security/operations explanation: threat model, least privilege, warning-vs-fail distinction, `>` vs `>>`
- troubleshooting/application: service target changes, process-up/port-down diagnosis, log-growth/disk-full response

**Rule:** Evaluation candidate items may strengthen tests/learning, but must not create new official Mission requirements until provenance is confirmed.

## 6. Repository Baseline

Baseline commit: `7f460bdef7a71439394d1461122ce6abd0d9fe48`

### Existing implementation

- `scripts/monitor.sh` — core monitor implementation
- `scripts/preflight.sh`, `scripts/verify.sh` — validation helpers
- `config/agent.env.example`
- `config/crontab.example`
- `config/agent-monitor.logrotate`
- `docs/00-start-here.md` through `docs/15-bonus.md`
- `docs/reference/requirements-evidence-map.md`
- `reports/execution-report.md`
- `tests/test-cases.md`
- `agent-app.zip`

### Existing runtime state claimed by lower-priority report

`reports/execution-report.md` records:

- environment: Ubuntu 24.04.4 / x86_64 / systemd 255
- SSH 20022 and `PermitRootLogin no`: previously observed
- UFW active with 20022/15034: previously observed
- users/groups/ACL: incomplete
- Agent runtime: TODO
- monitor runtime: TODO
- cron/logrotate runtime: TODO
- evidence finalization: TODO

Because `evidence/*` directories are empty, prior runtime observations are **not promoted to PASS evidence** by this Workcell without fresh or recoverable raw output.

## 7. Current Requirement Coverage at G1

| Area | Baseline status | G1 verdict |
|---|---|---|
| Mission source | PDF + MD present | `VALID` / `DUPLICATE` |
| Evaluation source | MD only, provenance unclear | `UNVERIFIED` |
| SSH | runtime observations documented | `TESTED-CLAIM / EVIDENCE GAP` |
| Firewall | runtime observations documented | `TESTED-CLAIM / EVIDENCE GAP` |
| Users/groups/ACL | partial only | `TODO` |
| Agent runtime | not completed | `TODO` |
| monitor code | implemented | `IMPLEMENTED` |
| logrotate config | implemented | `IMPLEMENTED` |
| cron config | implemented | `IMPLEMENTED` |
| Runtime evidence | evidence directories empty | `NEEDS-RUNTIME` |
| Learning docs | extensive | `IMPLEMENTED`, later validate against final implementation |

## 8. Mission-specific TOC

```text
B1-1
├── G1 Source / Evaluation Discovery
├── Linux Environment Baseline
├── SSH 20022 / Root Remote Login
├── Firewall 20022 + 15034
├── Users / Groups
├── Directory Ownership / ACL
├── Agent Environment / Secret File
├── Agent Boot / 15034 Listen
├── monitor.sh
│   ├── Process Health
│   ├── Port Health
│   ├── Firewall Warning
│   ├── CPU / Memory / Root Disk
│   ├── 20 / 10 / 80 Warnings
│   └── monitor.log Append
├── 10MB / 10-file Retention
├── cron Every Minute
├── Runtime Verification
├── Evidence
├── Learning / Evaluation Practice
└── Handoff / Merge
```

## 9. Scope / Non-scope

### Scope

- Confirmed Mission requirements above
- Minimum changes needed to make current baseline reliable and reproducible
- Automated/static tests that can be run without claiming real OS configuration
- Fresh Ubuntu runtime steps/evidence only where necessary
- Fixes for BLOCKER/MAJOR findings only

### Non-scope

- New monitoring frameworks
- Prometheus/Grafana/ELK
- Container orchestration
- Enterprise hardening beyond Mission requirements
- Mandatory implementation of bonus tasks
- Refactoring the existing 00–15 learning structure unless it conflicts with requirements
- Modifying Control Tower or another Mission repository

## 10. Agent Routing

- Orchestrator / Integrator: ChatGPT
- Primary implementation: current repository baseline is already substantial; ChatGPT performs minimal required corrections directly
- Independent Reviewer: one review pass after build/test
- Human / Runtime Authority: required for actual Ubuntu users/groups/ACL/SSH/firewall/Agent/cron/evidence
- Specialist triggers: only if PDF/source conflict or repeated unexplained runtime failure occurs

Review budget:

1. Self Review: 1
2. Independent Review: 1
3. Recheck only modified/failing items: 1

## 11. Dependency / Drift

- Official dependency: `NONE`
- Recommended prior environment: prior Linux practice may be reused but is not a B1-1 prerequisite.
- Control Tower drift: `NO_IMPACT`; frozen Governance baseline retained.
- Source drift policy: if a verifiable official Evaluation is later supplied, re-run only Evaluation mapping and affected tests/evidence.

## 12. Test Plan

### AI-executable / repository-level

- Bash syntax: `bash -n scripts/*.sh`
- Static requirement checks for `scripts/monitor.sh`
- Verify logrotate policy contains 10M + rotate 10 semantics
- Verify cron example contains every-minute schedule and `agent-admin` deployment instructions
- Verify environment example contains required variable names/paths without real secret leakage
- Inspect `.gitignore` / repository tree for secret/key leakage
- Review `monitor.sh` exit semantics and warning-only semantics
- Review log format construction

### Runtime-only

- `sshd -t`, `sshd -T`, `ss -lntp`
- fresh non-root SSH login on 20022 and root rejection
- UFW/firewalld effective policy
- `id`, `getent`, `stat`, `getfacl`, positive/negative write tests
- Agent Boot Sequence 5×`[OK]`, `Agent READY`, `0.0.0.0:15034`
- monitor healthy execution + process failure + port failure
- warning thresholds without forced exit
- actual monitor.log append
- actual logrotate dry-run/forced rotation or equivalent controlled proof
- `agent-admin` cron and 1–2 minute log growth

## 13. Runtime Plan

Use one dedicated Ubuntu environment. Do not change SSH/firewall blindly on an irreplaceable host.

Runtime sequence:

1. preflight + current state capture
2. SSH 20022 with current session kept open; new-session verification before removing 22 access
3. firewall policy
4. users/groups/directories/ACL
5. Agent env/key/deployment
6. Agent boot/listen
7. monitor deployment/ownership/mode
8. healthy/failure/warning tests
9. logrotate
10. cron 1–2 minute verification
11. evidence capture

AI must not mark these steps PASS before actual output is obtained.

## 14. Evidence Plan

Required evidence locations:

```text
evidence/01-environment/
evidence/03-ssh/
evidence/04-firewall/
evidence/05-users-groups-acl/
evidence/06-agent/
evidence/07-monitor/
evidence/08-automation/
evidence/09-testing/
evidence/14-final/
```

Evidence principles:

- actual command output/log/screenshot only
- redact secrets; never store the test key value merely to prove it exists
- distinguish expected output from actual output
- each PASS requirement must link to specific evidence or an accepted runtime record

## 15. Gate Checklist

### G1 SOURCE

- [x] frozen Governance baseline confirmed
- [x] target repository/packet mapping confirmed
- [x] repository baseline SHA captured
- [x] Mission PDF found and validated
- [x] Mission Markdown found and classified
- [x] Evaluation candidate found and classified
- [x] File Library search performed for missing official Evaluation provenance
- [x] Source Mode / Confidence / Gaps fixed
- [x] confirmed Mission requirements extracted
- [x] current repository coverage mapped

**G1 verdict: `PASS`** under `MISSION-LED` mode. Evaluation provenance remains a recorded Source Gap, but Mission PDF is sufficient to close G1 and proceed.

### G2 BUILD

- [ ] validate/fix minimum repository implementation against confirmed requirements
- [ ] add/update Workcell-local `AGENTS.md` for independent review if needed
- [ ] ensure no secret leak

### G3 TEST

- [ ] repository-level automated/static checks pass
- [ ] record tests actually run

### G4 REVIEW

- [ ] Self Review once
- [ ] Independent Review once
- [ ] `BLOCKER=0`, `MAJOR=0`

### G5 RUNTIME

- [ ] complete actual Ubuntu steps
- [ ] unresolved real-environment items remain `NEEDS-RUNTIME`

### G6 EVIDENCE

- [ ] required evidence captured and mapped

### G7 LEARN

- [ ] final docs match actual implementation/runtime
- [ ] six Mission explainability goals can be answered from repository docs
- [ ] supplementary Evaluation candidate topics covered where non-conflicting

### G8 MERGE

- [ ] Mission PR merged to `main`
- [ ] `HANDOFF.md` created
- [ ] `mission-result.yaml` created
- [ ] final commit SHA / PR URL recorded

## 16. STOP Rule

Stop the B1-1 Workcell when:

```text
Confirmed Mission requirements satisfied
+ required repository tests passed
+ required runtime evidence obtained
+ BLOCKER = 0
+ MAJOR = 0
+ learning material aligned
+ Mission PR merged
```

Do not delay completion for bonus tasks, MINOR findings, new frameworks, or aesthetic refactors.

## 17. Handoff Contract

Final `HANDOFF.md` and `mission-result.yaml` must contain:

- Mission ID / title
- frozen Control Tower baseline SHA
- target repo baseline + final commit SHA
- PR URL / merge state
- Source Inventory, Mode, Confidence, Gaps
- confirmed Requirement results
- Evaluation candidate provenance status
- G1–G8 states
- tests actually run and results
- runtime results
- evidence paths
- BLOCKER / MAJOR counts
- learning status
- remaining risks/backlog
- request for Serial Control Tower integration

The Workcell must **not** update `MetaStudy999/codyssey-basic` progress/README/site directly.
