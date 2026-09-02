# Glossary

Terms I have actually used in this lab, defined in my own words. One line each; if I can't explain it in one line, I don't understand it yet.

## Networking

- **IP address** — 32-bit identifier of a host, written as four octets (0–255).
- **Subnet mask / prefix (/24)** — how many leading bits identify the network; the rest identify hosts.
- **Network address** — first address of a subnet (all host bits 0); names the subnet, not usable by a host.
- **Broadcast address** — last address of a subnet (all host bits 1); talks to every host in it.
- **Block size** — 256 minus the mask's interesting octet; subnets start at its multiples.
- **Gateway** — the router a host sends traffic to when the destination is outside its subnet (here: 192.168.52.2).
- **DHCP** — protocol that hands out IP configuration automatically; opposite of a static IP.
- **DNS** — turns names (google.cl) into IP addresses; my nodes use 192.168.52.2 as resolver.
- **NAT** — the host translates my VMs' private addresses to its own so they can reach the Internet.
- **NTP** — protocol that keeps clocks synchronized; without it, logs, certificates and schedules break.

## Linux / RHEL

- **Kernel** — the core of the OS: manages CPU, memory, devices; `uname -r` shows the running one.
- **systemd** — the init system: starts services (units), controlled with `systemctl`, logged in `journalctl`.
- **hostname** — the machine's name; set with `hostnamectl set-hostname`.
- **machine-id** — unique identity in /etc/machine-id; clones must regenerate it.
- **dnf** — RHEL's package manager: installs, updates and removes software from repositories.
- **subscription-manager** — registers a RHEL system with Red Hat so dnf can download content.
- **Simple Content Access** — current model: registering grants content access; no per-system attach.
- **Red Hat Insights** — hosted service that analyses registered systems and flags patches and risks.
- **NetworkManager / nmcli** — the service (and its CLI) that owns network configuration in RHEL.
- **chrony** — RHEL's NTP implementation: chronyd syncs the clock, chronyc queries it.
- **firewalld** — RHEL's firewall service: zones with allowed services and ports.
- **SELinux** — mandatory access control: labels every process and file and blocks what policy forbids.
- **MOTD** — message shown at login (/etc/motd); ours will warn "managed by Ansible".
- **SSH host keys** — the server's own identity keys in /etc/ssh; clones inherit them and should regenerate.
- **tee** — splits a command's output: shows it on screen and writes it to a file at once.

## Ansible

- **Control node** — where Ansible runs (my WSL2 Ubuntu); nothing is installed on the targets.
- **Managed node** — a machine Ansible configures over SSH (node1, node2).
- **Inventory** — the file listing managed nodes, their groups and variables (hosts.yml).
- **Module** — a unit of work Ansible executes on a node (dnf, user, template, service).
- **Task** — one call to a module with its parameters, inside a play.
- **Playbook** — YAML file with plays: which hosts run which tasks.
- **Role** — a reusable package of tasks, defaults, handlers and templates (roles/baseline).
- **Handler** — a task that runs only when notified by a change (e.g. restart chronyd).
- **Idempotency** — running the same playbook twice changes nothing the second time.
- **Jinja2** — template language Ansible uses to generate config files from variables.
- **Collection** — an add-on package of modules installed with ansible-galaxy (ansible.posix…).
- **Ansible Vault** — encrypts secrets (passwords) inside the repository.
- **ansible-lint** — checks playbooks for errors and bad practices before they run.

## Practice

- **Baseline** — the minimum agreed state every server must be in; my baseline role makes it executable.
- **Drift** — when a machine's real state diverges from the declared one; a re-run detects and fixes it.
- **Full clone (VM)** — independent copy of a VM; needs new hostname, machine-id, host keys, registration.
- **Runbook** — a written, tested procedure for one failure scenario.
