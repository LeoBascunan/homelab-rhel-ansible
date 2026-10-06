# Home lab — RHEL 10 · Ansible · Prometheus / Grafana · Podman

Two Red Hat Enterprise Linux 10 servers, managed from an Ansible control node, monitored with
Prometheus and Grafana, running a containerised service under systemd — with a written log of every
decision and every mistake along the way.

**Author:** Leonardo Bascuñán · Antofagasta, Chile
**Built:** 29 August – 5 September 2026 · **Last maintenance:** 6 October 2026

## Why this exists

I work in application support and development, and I am moving into Linux infrastructure and
automation. Reading about Ansible is not the same as having a playbook fail at eleven at night
because a role shipped an empty string where a boolean was expected. This repository is where that
happens, in public, with the errors left in.

Everything here was built by hand first and then automated. The [lab log](docs/LOG.md) records what
was planned, what actually happened, and what broke — it opens with the lessons that cost the most
time.

## Architecture

```
  Windows 11 host — VMware Workstation Pro
  ┌──────────────────────────────────────────────────────────────────────┐
  │  WSL2 (Ubuntu)              NAT network 192.168.52.0/24              │
  │  ┌─────────────────┐  SSH   ┌──────────────────┐ ┌──────────────────┐│
  │  │ control node    │ ─────▶ │ node1  .11       │ │ node2  .12       ││
  │  │ ansible         │        │ RHEL 10.2        │ │ RHEL 10.2        ││
  │  │ this repository │        │ Prometheus :9095 │ │ node_exporter    ││
  │  └─────────────────┘        │ Grafana    :3000 │ │ nginx (Podman)   ││
  │                             │ node_exporter    │ │            :8080 ││
  │                             └──────────────────┘ └──────────────────┘│
  └──────────────────────────────────────────────────────────────────────┘
```

| Host  | Role                       | vCPU | RAM  | IP             |
|-------|----------------------------|------|------|----------------|
| node1 | monitoring server + target | 2    | 2 GB | 192.168.52.11  |
| node2 | target + workload          | 2    | 2 GB | 192.168.52.12  |

Two decisions worth writing down:

- **Prometheus listens on 9095, not the default 9090.** Cockpit already owns 9090 on these hosts.
  Recorded here so that nobody "fixes" it back.
- **The container workload runs on node2, not on node1.** A monitoring host that runs out of memory
  takes the visibility down with it, exactly when it is needed most.

## What is automated

| Playbook / role | What it does |
|---|---|
| `playbooks/ping.yml` | Connectivity and facts check against every node. |
| `roles/baseline` (via `playbooks/site.yml`) | The state every node must be in: administrator account with an authorised key, a sudoers drop-in validated with `visudo -cf`, an sshd drop-in validated with `sshd -t` (`PermitRootLogin no`, `PasswordAuthentication no`), firewalld, chrony for time, base packages and a templated MOTD. Idempotent: the second run reports `changed=0`. |
| `playbooks/monitoring.yml` | node_exporter on both nodes, Prometheus and Grafana on node1, ports opened with firewalld from the play itself. |
| `playbooks/container.yml` | nginx as a rootless Podman container on node2, managed by systemd through a Quadlet unit rendered from a Jinja2 template, with lingering enabled so it survives logout and reboot. |

Secrets live in Ansible Vault (`inventory/group_vars/all/vault.yml`). The playbooks hold a
*reference* — `{{ vault_grafana_admin_password }}` — never the secret itself. That is what makes it
safe to publish this repository.

## How to run

```bash
# control node: Ubuntu on WSL2
sudo apt install ansible ansible-lint

ansible-playbook playbooks/ping.yml -J
ansible-playbook playbooks/site.yml --check --diff -K -J   # predict first
ansible-playbook playbooks/site.yml -K -J                  # then converge
ansible-playbook playbooks/monitoring.yml -K -J
ansible-playbook playbooks/container.yml  -K -J
ansible-lint
```

`-K` asks for the sudo password on the nodes; `-J` asks for the Vault password. Every command
carries `-J`, even `ping.yml`: Ansible loads all group variables before running anything, encrypted
ones included.

Once it is up: Prometheus targets at `http://192.168.52.11:9095/targets`, Grafana at
`http://192.168.52.11:3000` with the Node Exporter Full dashboard (ID 1860), and the containerised
service at `http://192.168.52.12:8080`.

## Runbooks

One file per failure scenario, each written **after provoking the failure it describes** — not
from theory.

- [Prometheus target DOWN (node_exporter)](docs/runbooks/node-exporter-target-down.md) — provoked by
  stopping the exporter on node2; covers the `connection refused` versus `timeout` distinction that
  decides whether to look at the service or at the network.
- [Containerised service missing after a reboot or logout](docs/runbooks/container-service-not-running.md)
  — the rootless-container trap: without lingering, the user's systemd instance stops and takes the
  container with it.

## Maintenance

**6 October 2026**, after a month powered off. Red Hat had removed node2 from its inventory — its
own status still said *Registered*, while the CDN answered 403 and `subscription-manager refresh`
answered 410 Gone — so it was registered again. A kernel update failed because Red Hat had published
the 211.63.1 modules without the kernel itself; both nodes were patched to the newest complete
kernel, 211.62.1, node2 entirely from Ansible. Everything came back on its own after the reboots.
Full story in the [log, day 6](docs/LOG.md).

## Repository layout

```
inventory/        hosts, group variables, the Vault file
roles/baseline/   the state every node must be in
playbooks/        ping, site, monitoring, container (+ Jinja2 templates)
docs/LOG.md       dated entries: what was planned, what broke, how it was fixed
docs/runbooks/    one tested procedure per failure scenario
docs/GLOSSARY.md  the terms, defined as they came up
```

## What this lab is not

It is a lab, not production. I have not run these systems under real load, there are no alerting
rules yet, and the two nodes sit on one host with no shared storage or high availability. Saying so
is part of the point: the repository documents what I have actually done, at the size I have
actually done it.
