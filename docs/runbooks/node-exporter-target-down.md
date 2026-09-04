# Runbook — Prometheus target DOWN (node_exporter)

**Applies to:** any host in the `node` job of the lab Prometheus (`http://192.168.52.11:9095`).
**Last tested:** 2026-09-03, by provoking the failure on node2 and restoring it.

## Symptom

- `http://192.168.52.11:9095/targets` shows the endpoint in red, `State: DOWN`, with
  `Get "http://<host>:9100/metrics": dial tcp <host>:9100: connect: connection refused`.
- In Grafana, the "Node Exporter Full" dashboard stops producing new points for that `Nodename`.

## Impact

The host is no longer monitored. Nothing on the host is broken *by* this — which is precisely the
danger: a real problem there would now go unseen.

## Diagnosis

Work outwards from the host. Do not diagnose through the dashboard: the Prometheus targets page is
a snapshot and does not refresh itself.

1. **Is the service running?**
   ```bash
   systemctl is-active node_exporter
   ```
   One word: `active` or `inactive`/`failed`. If it is not active, go to Resolution.

2. **Is it answering locally?**
   ```bash
   curl -sS -m 3 http://localhost:9100/metrics | head -3
   ```
   If it answers here but Prometheus still cannot reach it, the fault is the network or the
   firewall, not the service.

3. **Is the port open?**
   ```bash
   sudo firewall-cmd --list-ports
   ```
   `9100/tcp` must appear in the list.

4. **Read what the error actually says.** This single distinction resolves most cases:
   - `connection refused` — the host answered, and nothing is listening on that port. **The service is down.**
   - `timeout` / `no route to host` — nobody answered at all. **Firewall, routing, or the host is down.**
   - `404` or unexpected content — something else is listening on 9100.

## Resolution

```bash
sudo systemctl start node_exporter
sudo systemctl enable node_exporter    # only if it was not enabled; enabled != active
```

If the port was closed:

```bash
sudo firewall-cmd --add-port=9100/tcp --permanent
sudo firewall-cmd --reload
```

If the host has drifted into a state nobody can explain, re-apply the desired state rather than
patching by hand:

```bash
ansible-playbook playbooks/monitoring.yml -K --ask-vault-pass --limit <host>
```

## Verification

```bash
systemctl is-active node_exporter                        # active
curl -sS -m 3 http://localhost:9100/metrics | head -3    # returns metrics
```

Then reload `http://192.168.52.11:9095/targets` (F5). The endpoint returns to **UP** within one
scrape interval — 15 s in this lab. The Grafana dashboard keeps a visible gap for the outage
window; that gap is evidence, not a fault.

## Notes from the test

- Stopping the service produced exactly `connection refused`, confirmed three independent ways:
  `systemctl is-active` returning `inactive`, `curl` from the host itself, and a browser pointed
  straight at `:9100`.
- `systemctl status` is long and opens in a pager (`q` to leave). `systemctl is-active` answers the
  first question in one word and is the better opening move.
- `curl -s` silences the error message along with the progress bar. Use `-sS` to keep the error.
- Prove a failure at its source before arguing with a user interface.
