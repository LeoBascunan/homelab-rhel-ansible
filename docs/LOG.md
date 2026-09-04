# Lab log

One entry per working session. Keep it honest: what was planned, what actually happened, what broke and how it was fixed. Commands and error messages are worth more than adjectives.

## Key lessons

Short rules, each one paid for with a debugging session. The story behind every one of them is in the dated entry.

- **When dnf complains about a GPG signature or metadata, suspect the cache first.** `sudo dnf clean all` followed by `sudo dnf makecache` fixes most of it. A run that dies half-way can leave a truncated `repomd.xml`, and a signature checked against a truncated file will never match. The seal was fine; my copy of the document was torn. *(Day 4)*
- **An error can come from a previous run that died half-way, not from the change I just made.** Before editing anything, ask what state the last failure left behind. *(Day 4)*
- **A misspelled variable name fails silently in Ansible.** Setting `grafana_rhsm_suscription` (the Spanish spelling) instead of `grafana_rhsm_subscription` created a new, unused variable: the role kept its own default and the error message did not change one character. A typo in a value explodes immediately; a typo in a variable name says nothing at all. *(Day 4)*
- **The error message names the file it read the value from — go and read that file.** Two role bugs were solved by opening the role's own `defaults/main.yml` instead of guessing. *(Day 4)*
- **`--check` predicts, it does not converge.** A check-mode run reports what *would* change; only a real run makes it true, and only a *second* real run proves idempotency. *(Day 3)*
- **A grep only proves the absence of the exact pattern you searched for.** `grep "RHEL 9"` came back clean while "Red Hat Enterprise Linux 9" was still sitting in the file. *(Day 0+1)*
- **Order matters between `subscription-manager` and `insights-client`.** A host has to be registered before it can report. *(Day 0+1)*

---

## 2026-08-29/30 — Day 0+1: first server and this repository

**Plan.** Accounts, downloads, first VM, RHEL install, registration, publish the repo.

**Done.**
- Installed VMware Workstation Pro 26H1 on Windows.
- Downloaded the RHEL 10.2 DVD ISO from the Red Hat Developer portal.
- Created node1: 2 vCPU, 2 GB RAM, 20 GB disk, NAT network.
- Installed RHEL 10.2 as "Server" + Headless Management (Cockpit); keyboard latam,
  timezone America/Santiago, hostname node1, root enabled without SSH password login,
  user leo with wheel membership.
- Registered with subscription-manager (Developer Subscription); first `dnf update`
  brought a new kernel (6.12.0-211.49.1); `dnf needs-restarting -r` confirmed the
  reboot. Registered insights-client: node1 reports to console.redhat.com.
- Network: NAT subnet 192.168.52.0/24, gateway and DNS 192.168.52.2; node1 got
  192.168.52.128 by DHCP. Static .11 pending.
- Installed WSL2 + Ubuntu on the Windows host and published this repository.

**Problems and fixes.**
- First downloaded the RHEL 9.0 *boot* ISO: old and network-only. Replaced with the 10.2 DVD.
- Skipped "Customize Hardware" in the new-VM wizard; fixed memory, CPUs, ISO and NAT afterwards.
- WSL was not installed on this PC; `wsl --install` set up Ubuntu without a reboot.
- Fixed the scaffold from RHEL 9 to RHEL 10 with sed; the first `grep "RHEL 9"` check
  missed "Red Hat Enterprise Linux 9" spelled out — a grep only proves the absence of
  the exact pattern you searched.
- Typed a command while insights-client was running; the process swallowed it. Wait for the prompt.

**Next.** Clone node1 → node2 (hostname, machine-id, re-register), static IPs with nmcli, SSH keys to both nodes, /etc/hosts.

---

## 2026-09-01 — Day 2: two nodes under Ansible

**Done.**
- Cloned node1 → node2 (full clone) and gave it its own identity: hostname,
  regenerated /etc/machine-id, subscription-manager clean + register, insights re-registered.
- Regenerated node2's SSH host keys (clones inherit them from the source).
- Static IPs with nmcli: node1 = 192.168.52.11/24, node2 = .12, gateway/DNS .2. Verified
  gateway, Internet and node-to-node ping.
- SSH keys from the WSL2 control node to both nodes; verified with BatchMode.
- Installed ansible + ansible-lint, created the real inventory (ansible_user: leo),
  installed collections, and ran playbooks/ping.yml: ok=3, failed=0 on both nodes.

**Problems and fixes.**
- Ran systemd-machine-id-setup without sudo the first time (sudo only applied to rm).
- ssh-copy-id to node1 failed three password attempts; retried and succeeded.
- insights-client refused to register before subscription-manager: order matters.

**Next.** Write the baseline role tasks (users, sudo, sshd hardening, firewalld, motd) and run site.yml.

---

## 2026-09-02 — Day 3: the baseline role

**Plan.** Turn ad-hoc hardening into a role — users, sudo, SSH, firewalld, chrony, MOTD — and prove it is idempotent.

**Done.**
- Wrote `roles/baseline`: administrator account with wheel membership and an authorized key,
  a sudoers drop-in validated with `visudo -cf`, an sshd drop-in validated with `sshd -t`
  (`PermitRootLogin no`, `PasswordAuthentication no`), firewalld enabled, chrony for time
  synchronisation, base packages, and a templated MOTD warning that the host is managed by
  Ansible and that manual changes will be overwritten.
- Secrets moved into Ansible Vault (`inventory/group_vars/all/vault.yml`), run with `--ask-vault-pass`.
- Ran `playbooks/site.yml --check --diff` first, then for real. Second real run:
  **changed=0 on both nodes** — the role converges.

**Problems and fixes.**
- `Missing sudo password`: privilege escalation needs `-K` on the command line (or a become
  password stored in the vault).
- Check mode failed on `authorized_key` with "user must exist in check mode". The real cause
  was `admin_user` still holding the scaffold placeholder in group_vars, not a check-mode
  limitation. Read the variable before blaming the module.
- Misread a check-mode recap (`changed=7`) as work already done. Check mode predicts; it does
  not converge.

**Next.** node_exporter on both nodes, Prometheus and Grafana on node1, all by playbook.

---

## 2026-09-02/03 — Day 4: monitoring stack

**Plan.** Deploy node_exporter everywhere, Prometheus and Grafana on node1 using the upstream
`prometheus.prometheus` and `grafana.grafana` collections, and open the ports with firewalld
from the play itself.

**Done.**
- `playbooks/monitoring.yml`: node_exporter on all nodes (:9100), Prometheus on node1 scraping
  both exporters, Grafana on node1 (:3000).
- Prometheus listens on **:9095**, not the default :9090 — Cockpit already owns 9090 on these
  hosts. Deliberate conflict avoidance, written down so future me does not "fix" it back.
- Ports opened from the play's `post_tasks` with `ansible.posix.firewalld` (9100, 9095, 3000),
  `permanent` and `immediate` both true so the rule survives a reboot and applies now.
- Grafana's admin password lives in the vault and reaches the role as
  `grafana_ini.security.admin_password: "{{ vault_grafana_admin_password }}"` — the playbook
  holds a reference, never the secret itself, which is what makes it safe to publish.

**Problems and fixes.**
- Preflight assert failed with `grafana_security is undefined`. Version 6 of the collection
  renamed its variables. Confirmed the installed version with `ansible-galaxy collection list`
  (6.0.6) and migrated to the `grafana_ini` form.
- `Conditionals must have a boolean result`: the role ships `grafana_rhsm_subscription: ""` and
  `grafana_rhsm_repo: ""` — empty strings — and uses both in `when:`. Modern ansible-core refuses
  non-boolean conditionals. Fixed by defining both as real booleans (`false`) in the play vars:
  Grafana comes from the upstream repo here, not from an RHSM subscription. Found them by reading
  the role's own `defaults/main.yml`, the file the error message had been naming all along.
- The first attempt at that fix changed nothing because I had typed `grafana_rhsm_suscription`,
  the Spanish spelling. Ansible does not warn about unknown variable names.
- `repomd.xml GPG signature verification error: Bad PGP signature` on the grafana repo.
  Reproduced by hand on node1 with `sudo dnf makecache`; `sudo dnf clean all` plus a fresh
  `makecache` pulled the metadata down cleanly and the signature validated. The earlier aborted
  runs had left a truncated cache. Both `gpgcheck` and `repo_gpgcheck` stay at 1 — the easy
  "fix" of disabling signature checking was not needed and would have hidden the real cause.
- `ansible all -m ping` failed with "Attempting to decrypt but no vault secrets found":
  Ansible loads every group_vars file before running anything, encrypted ones included, so
  ad-hoc commands need `--ask-vault-pass` too, even when the module uses no secrets.

**Next.** Verify both targets UP in Prometheus, log into Grafana, add the Prometheus datasource
and import dashboard 1860; then provoke failures (service down, disk full, high load) and write
the first runbooks against them.
