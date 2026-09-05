# Runbook — containerised service missing after a reboot or logout

**Applies to:** the rootless Podman containers managed by Quadlet on node2 (`web.container`).
**Last tested:** 2026-09-05, by rebooting node2 and confirming the service returned on its own.

## Symptom

- `http://192.168.52.12:8080` refuses the connection.
- On the host, `podman ps` lists nothing, and `systemctl --user status web` reports the unit as
  inactive — or the whole user manager is gone.

## Impact

The service is down. Nobody was warned, because a container that never started raises no alert of
its own — the miss is silent, which is the reason this runbook exists.

## Diagnosis

Ask the questions in this order; each one rules out a whole class of cause.

1. **Is the user manager even running?** Rootless containers belong to the user's own systemd
   instance, and that instance stops when the last session closes unless lingering is enabled.
   ```bash
   loginctl show-user leo | grep Linger
   ```
   `Linger=no` is the answer: go to Resolution, first item.

2. **Does systemd know about the unit?**
   ```bash
   systemctl --user list-unit-files | grep web
   systemctl --user status web
   ```
   Nothing listed → the `.container` file is missing or malformed. Quadlet silently skips a file it
   cannot parse, so a typo looks exactly like a missing file.

3. **Did the container start and then fail?**
   ```bash
   journalctl --user -u web --no-pager -n 40
   podman ps -a
   ```
   An image that cannot be pulled, or a port already taken, shows up here.

4. **Is the port reachable from outside but fine locally?**
   ```bash
   curl -sS http://localhost:8080 | head -3
   sudo firewall-cmd --list-ports
   ```
   Answers locally but not from the network → the firewall, not the container.

## Resolution

Lingering not enabled:

```bash
sudo loginctl enable-linger leo
systemctl --user daemon-reload
systemctl --user start web
```

Unit not picked up after editing the file:

```bash
systemctl --user daemon-reload      # Quadlet regenerates web.service here
systemctl --user start web
```

Anything unexplained — re-apply the desired state instead of patching by hand:

```bash
ansible-playbook playbooks/container.yml -K --ask-vault-pass
```

## Verification

```bash
systemctl --user is-active web       # active
curl -sS http://localhost:8080 | head -3
```

Then the real test, the one that matters: `sudo reboot`, wait a minute, log back in and check again
without touching anything.

## Notes from the test

- `systemctl --user enable web` does **not** work on a Quadlet unit and fails with "transient or
  generated". The generated `.service` lives under `/run` and is rebuilt on every reload; the
  `[Install] WantedBy=default.target` line inside the `.container` file is what enables it.
- No command in this runbook needs `sudo` except `loginctl enable-linger` and the firewall — that
  is the point of running the container rootless.
