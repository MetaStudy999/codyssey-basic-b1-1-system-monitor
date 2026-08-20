# B1-1 Workcell Validation Record

> Work branch: `mission/b1-1`  
> Control Tower baseline: `0d1581b3e82366988f57e1d76da311c028b8e15e`  
> Target repository baseline: `7f460bdef7a71439394d1461122ce6abd0d9fe48`

This record contains only checks actually performed by the current Workcell. It does **not** claim that the user's Ubuntu runtime is configured or that G5/G6 evidence is complete.

## 1. Source validation

- Mission PDF located and read as an 8-page document.
- Local supplied `b1-1-mission.pdf` and repository `b1-1-mission.pdf` were verified byte-identical by Git blob SHA:
  - `74e171b657e4826c5e024756aefd976beecf7229`
- Mission Markdown is a substantive transcription of the PDF and was classified `DUPLICATE` for Source-of-Truth purposes.
- `b1-1-evaluation.md` is substantive, but independent official provenance was not found; it remains `UNVERIFIED` and is used only as a supplementary review checklist.
- Source Mode: `MISSION-LED`
- Source Confidence: `MEDIUM`

## 2. Exact source identity used for repository-level monitor tests

GitHub blob tested:

```text
scripts/monitor.sh
blob SHA: 8514c4ef8daed17e93e659109c20acf2dd52aa11
```

The connector-retrieved source was mirrored into an isolated Linux shell. Before testing, its computed Git blob SHA was checked and matched the repository blob SHA above. Therefore the tests below were run against the exact repository content of `scripts/monitor.sh` at the Workcell baseline.

## 3. Repository-level checks actually executed

### WV-001 — Bash syntax

Command equivalent:

```bash
bash -n scripts/monitor.sh
```

Actual result:

```text
exit 0
```

Verdict: `PASS`

### WV-002 — Confirmed requirement markers

Automated assertions checked the exact script for:

- Bash shebang
- process health failure path
- default port `15034`
- port health failure path
- threshold defaults `20 / 10 / 80`
- append logging using `>>`
- required `PID / CPU / MEM / DISK_USED` log fields

Actual result: all assertions passed.

Verdict: `PASS`

### WV-003 — Process-missing failure

A random process pattern guaranteed not to exist was supplied so that the test did not depend on a literal string that could accidentally occur in a parent shell command line.

Actual result:

```text
[ERROR] Agent process not found: pattern=<random missing pattern>
exit 1
```

Verdict: `PASS`

### WV-004 — Process-present / port-missing failure

A harmless temporary Python process was started with a unique marker, while the monitor was pointed at an unused TCP port.

Actual result:

```text
[ERROR] Agent port is not LISTEN: tcp/54321
exit 1
```

Verdict: `PASS`

### WV-005 — Healthy synthetic monitor path + warning-only thresholds

A temporary local Python listener bound `0.0.0.0:15034` and carried a unique process marker. Thresholds were lowered to `-1` to trigger warning branches without creating CPU, memory, or disk pressure.

Actual result pattern:

```text
[WARNING] firewall is inactive or could not be confirmed active
[WARNING] CPU usage ... exceeds -1%
[WARNING] MEM usage ... exceeds -1%
[WARNING] DISK_USED ... exceeds -1%
[YYYY-MM-DD HH:MM:SS] PID:<pid> CPU:<value>% MEM:<value>% DISK_USED:<value>%
exit 0
```

The generated log line matched the required regular-expression shape.

Verdict: `PASS`

This proves the monitor's core health/warning/logging logic in an isolated Linux process/port fixture. It does **not** prove the real supplied Agent, actual UFW state, deployed ownership/mode, or cron.

### WV-006 — Config contract checks

The current repository config content was checked for:

- logrotate `size 10M`
- logrotate `rotate 10`
- `agent-admin / agent-core` ownership context
- every-minute cron entry for `/home/agent-admin/agent-app/bin/monitor.sh`
- all required `AGENT_*` example paths/values

Actual result: all assertions passed.

Verdict: `PASS`

### WV-007 — Secret boundary review

Repository `.gitignore` excludes:

```text
.env
.env.*
*.key
*.pem
```

while allowing `*.env.example`. The repository tree inspected during G1 did not reveal a committed runtime `.key`, private key, or real `.env` file.

Verdict: `PASS` for repository-level obvious secret-file screening.

## 4. G2 BUILD verdict

The baseline already contains the required `monitor.sh`, environment example, cron example, logrotate policy, detailed execution instructions, validation helpers, and learning material.

Current Workcell additions:

- `MISSION-WORK-PACKET.md`
- root `AGENTS.md` review contract

No confirmed Mission requirement required a change to the core monitor implementation after the checks above.

**G2 verdict: `PASS`**

## 5. G3 TEST verdict

Repository-level monitor and configuration checks actually executed by this Workcell passed.

Actual Ubuntu system configuration remains separate and belongs to G5 RUNTIME/G6 EVIDENCE.

**G3 verdict: `PASS`**

## 6. Self Review

One focused self-review was performed against the Mission PDF-backed requirements and current repository artifacts.

Findings:

- `BLOCKER`: 0
- `MAJOR`: 0
- Secret exposure blocker: 0
- False PASS found in current Workcell files: 0
- Runtime/evidence gap remains explicit.

A potentially confusing setup step in `docs/06-agent-setup.md` recursively changes the Agent tree group during app-file placement, but the same section immediately requires re-checking and re-applying the protected directory policy before the runtime key is created. This is treated as a documentation-improvement candidate, not a Mission blocker. Do not widen current scope unless runtime shows it causes an actual failure.

## 7. Remaining `NEEDS-RUNTIME`

The following cannot be promoted to PASS by repository-level tests:

- actual SSH effective configuration and fresh login on 20022
- actual Root SSH rejection
- actual UFW/firewalld effective policy
- actual users/groups/memberships
- actual directories, ownership, modes, ACL positive/negative access tests
- protected runtime key file existence/permissions and Agent acceptance
- supplied Agent five `[OK]` boot checks
- `Agent READY`
- supplied Agent non-root process owner
- supplied Agent `0.0.0.0:15034` LISTEN
- deployed `monitor.sh` owner/group/mode
- healthy and failure checks against the supplied Agent
- actual `/var/log/agent-app/monitor.log` append
- actual logrotate installation/rotation proof
- actual `agent-admin` cron and 1–2 minute automatic log growth
- required evidence capture

## 8. Next action

Run the repository's read-only runtime verifier on the dedicated B1-1 Ubuntu environment. Use its failures to make only the missing runtime changes, then capture evidence.

Do not merge or mark the Mission complete until G5/G6 are complete.
