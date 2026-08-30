# Lab log

One entry per working session. Keep it honest: what was planned, what actually happened, what broke and how it was fixed. Commands and error messages are worth more than adjectives.

---

 create Red Hat Developer and Broadcom accounts, download RHEL 10 ISO and VMware Workstation Pro, create this repository.
**Problems and fixes.**
- 

**Next.** Install node1 and node2 (minimal install, 2 vCPU, 2 GB, NAT network).

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
