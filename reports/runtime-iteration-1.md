# B1-1 Runtime Iteration 1

> Branch: `mission/b1-1`  
> Runtime authority: Human / Ubuntu  
> Evidence: `evidence/14-final/verify-initial-20260808.txt`

## Result

The repository read-only verifier was executed in the actual B1-1 Ubuntu runtime.

```text
PASS=11
WARN=2
FAIL=17
```

Overall verdict: `NEEDS-RUNTIME` / incomplete.

## Confirmed working runtime items

- Static SSH drop-in contains port `20022`.
- Static SSH drop-in contains `PermitRootLogin no`.
- TCP `20022` is listening.
- TCP `22` is not listening.
- UFW is active.
- UFW default inbound policy is deny.
- UFW allows `20022/tcp`.
- UFW allows `15034/tcp`.
- No unexpected inbound UFW ALLOW rules were detected.
- `agent-admin` exists.
- No obvious tracked `.key` / runtime `.env` secret file was detected.

## Warnings

1. `sshd -T` could not be evaluated in the current runtime state. The verifier fell back to the static B1-1 drop-in. A fresh SSH client connection on port 20022 and explicit root rejection remain required evidence.
2. Traverse ACL `group:agent-common:--x` on `/home/agent-admin` was not yet confirmed.

## Blocking runtime gaps

### Users / groups

- `agent-dev` missing.
- `agent-test` missing.
- `agent-common` membership incomplete.
- `agent-core` membership incorrect/incomplete.

### Filesystem / ACL

Missing:

- `/home/agent-admin/agent-app`
- `/home/agent-admin/agent-app/upload_files`
- `/home/agent-admin/agent-app/api_keys`
- `/var/log/agent-app`

### Agent environment / key

Missing:

- `/etc/agent-app/agent.env`
- `/home/agent-admin/agent-app/api_keys/t_secret.key`

### Agent runtime

- supplied Agent process not running
- `0.0.0.0:15034` not listening

### Monitor deployment

Missing/not yet deployed:

- `/home/agent-admin/agent-app/bin/monitor.sh`
- deployed Bash syntax verification
- `/var/log/agent-app/monitor.log`

### Automation

Missing/not installed:

- `agent-admin` every-minute cron entry
- `/etc/logrotate.d/agent-monitor`

## Next runtime action

Resolve only the prerequisite chain in order:

1. create missing users and correct group memberships
2. create required directories and ACL/ownership policy
3. inspect the supplied `agent-app.zip` structure before deploying it
4. install runtime environment and protected key
5. run supplied Agent as non-root and verify five `[OK]`, `Agent READY`, and `0.0.0.0:15034`
6. deploy and run `monitor.sh`
7. install cron/logrotate and prove automatic log growth/rotation
8. rerun `sudo bash scripts/verify.sh`

Do not mark G5/G6 PASS until the second verifier run and required raw evidence are complete.
