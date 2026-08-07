# B1-1 Agent Review Contract

## Role

This repository is the Codyssey Basic B1-1 Mission workcell for **컴퓨터가 알아서 자기 상태를 점검하게 만들기**.

The primary implementation is already present. Reviewers are expected to find only mission-blocking or major correctness problems and must preserve the beginner-oriented learning structure.

## Workspace Boundary

- WRITE: `MetaStudy999/codyssey-basic-b1-1-system-monitor` only.
- DO NOT WRITE: `MetaStudy999/codyssey-basic` (Control Tower).
- DO NOT WRITE: any other Codyssey mission repository.
- Work branch: `mission/b1-1`.

## Frozen Governance Baseline

Control Tower baseline:

`0d1581b3e82366988f57e1d76da311c028b8e15e`

Governance is frozen to that SHA for this workcell.

## Source of Truth

Use this priority order:

1. `b1-1-mission.pdf`
2. `b1-1-mission.md`
3. verified official Evaluation, if provenance is established
4. directly related official operating material
5. `MISSION-WORK-PACKET.md`
6. `docs/reference/requirements-evidence-map.md`
7. `README.md`
8. learning docs
9. code
10. tests
11. reports
12. evidence

Current G1 classification:

- Mission PDF: `VALID`
- Mission Markdown: `DUPLICATE` transcription of the PDF
- `b1-1-evaluation.md`: `UNVERIFIED` official provenance; supplementary review checklist only
- Evaluation PDF: `MISSING`
- Source Mode: `MISSION-LED`
- Source Confidence: `MEDIUM`

Do not turn an unverified Evaluation item or general best practice into a mandatory Mission requirement.

## Confirmed Mission Scope

Review the implementation against the confirmed Mission requirements in `MISSION-WORK-PACKET.md`, especially:

- SSH `20022`, Root remote login disabled
- UFW/firewalld active; inbound TCP only `20022` and `15034`
- `agent-admin`, `agent-dev`, `agent-test`
- `agent-common`, `agent-core`
- required directories and least-privilege group/ACL policy
- Agent environment variables and protected key file
- non-root Agent; five boot checks `[OK]`; `Agent READY`; `0.0.0.0:15034` LISTEN
- Bash `monitor.sh` at `$AGENT_HOME/bin/monitor.sh`, owner/group/mode `agent-dev:agent-core:750`
- process/port failure => exit `1`
- firewall/resource threshold conditions => warning only
- CPU/MEM/root-disk collection
- thresholds CPU `>20`, MEM `>10`, DISK_USED `>80`
- required append-only monitor log format
- max `10MB / 10 files` retention
- `agent-admin` cron every minute and actual log growth after 1–2 minutes

Bonus work must not block completion.

## Preserve Beginner Learning Material

Do not replace the existing `docs/00-start-here.md` through `docs/15-bonus.md` structure with a new architecture unless a confirmed Mission requirement is impossible to satisfy otherwise.

If code changes make learning docs inaccurate, update only the directly affected explanation.

## Review Scope

Report only:

- `BLOCKER`
- `MAJOR`
- confirmed Mission requirement omission
- test failure
- code/document contradiction that can cause incorrect execution or evaluation
- false `PASS` / unverified runtime claim
- secret/credential exposure

Do not spend review budget on:

- MINOR style issues
- optional bonus improvements
- broad refactoring
- new frameworks/tooling
- enterprise hardening beyond the Mission
- rewriting all documentation

## Status Rules

- `TODO`: not implemented/run
- `IMPLEMENTED`: implementation exists, runtime not proven
- `TESTED`: an applicable test was actually run
- `PASS`: implementation + actual required runtime verification + required evidence
- `NEEDS-RUNTIME`: real Ubuntu/runtime proof is still required
- `BLOCKED`: external condition prevents progress

A file existing is never sufficient for `PASS`.

## Repository-level Checks

Where the execution environment permits, run:

```bash
bash -n scripts/*.sh
```

Then inspect/validate:

```text
scripts/monitor.sh
scripts/preflight.sh
scripts/verify.sh
config/agent.env.example
config/crontab.example
config/agent-monitor.logrotate
.gitignore
```

Runtime verification commands and evidence requirements are defined in `MISSION-WORK-PACKET.md` and the execution docs.

Do not claim SSH/UFW/users/ACL/Agent/cron PASS unless the actual Linux environment and evidence support it.

## Secret Boundary

Never commit actual `.env`, `*.key`, private keys, tokens, credentials, or screenshots/logs exposing secrets.

The Mission-specified test key string belongs only in the protected runtime key file. Verification should prove path/owner/group/mode and application acceptance without reproducing the secret value in evidence.

## Review Output Contract

Return:

1. Verdict
2. BLOCKER findings
3. MAJOR findings
4. Confirmed requirement omissions
5. Tests actually run
6. Runtime items still `NEEDS-RUNTIME`
7. Secret exposure check
8. Recommended next action

## Stop Condition

Stop reviewing when:

```text
BLOCKER = 0
MAJOR = 0
confirmed Mission requirements are implemented or correctly marked NEEDS-RUNTIME
repository-level tests pass
no secret exposure is found
```

Do not create a review-of-review loop.
