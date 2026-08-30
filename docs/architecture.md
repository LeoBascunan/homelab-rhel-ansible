# Architecture

## Hosts

| Host  | Purpose                      | OS      | vCPU | RAM  | Disk  | IP           |
|-------|------------------------------|---------|------|------|-------|--------------|
| node1 | monitoring server and target | RHEL 10  | 2    | 2 GB | 20 GB | 192.168.52.11 |
| node2 | target                       | RHEL 10  | 2    | 2 GB | 20 GB | 192.168.52.12 |

Control node: WSL2 (Ubuntu) on the Windows host, `ansible-core` installed with pipx.

## Network

- VMware Workstation NAT network (VMnet8). Find the subnet in *Edit → Virtual Network Editor*; replace `X` above and in `inventory/hosts.yml`.
- Static addresses set with `nmcli` on each node; gateway is the VMware NAT gateway (usually `.2`).
- Name resolution: `/etc/hosts` on the control node and on each VM (a small DNS server may follow later).

## Naming

`node1`, `node2` … deliberately boring. Roles are expressed in the inventory groups, not in hostnames.

## Access

- SSH with keys only; the administrator account is created by the `baseline` role; root login over SSH disabled.
- Secrets (initial passwords, Grafana admin password) live in `inventory/group_vars/all/vault.yml`, encrypted with Ansible Vault.
