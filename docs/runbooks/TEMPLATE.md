# Runbook: <scenario>

**Symptom.** What the user or the monitoring sees.

**Impact.** Who or what is affected, and how urgently.

## First checks (60 seconds)

```bash
uptime
dmesg -T | tail
vmstat 1 5
df -h && df -i
systemctl --failed
journalctl -p err -b --no-pager | tail -n 50
```

## Diagnosis

Step by step, with the command and what its output means.

## Fix

Exact commands. Say what is safe to run during operations and what needs a maintenance window.

## Verification

How to prove the fix worked (a command, a dashboard, a test).

## Prevention

The monitoring alert, the playbook change or the documentation that makes this less likely to recur.

## Test record

| Date | Provoked with | Result |
|------|---------------|--------|
|      |               |        |
