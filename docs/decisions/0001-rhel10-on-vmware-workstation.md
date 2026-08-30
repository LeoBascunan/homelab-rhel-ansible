# 0001 — RHEL 10 on VMware Workstation Pro, control node in WSL2

**Date:** 2026-08-28  **Status:** accepted

## Context

The target role administers RHEL and VMware-based systems with Ansible. The lab must run on a single Windows PC and be reproducible in a week.

## Decision

- Real RHEL 10 (Red Hat Developer Subscription for Individuals, no cost) instead of a clone, so that `subscription-manager`, repositories and Red Hat documentation match what is used at work.
- VMware Workstation Pro (free for personal use) as the hypervisor, for its closeness to the vSphere family (snapshots, virtual networks, VMware Tools).
- Ansible from WSL2 rather than from a third VM: one less machine, and the repository lives where the editor is.

## Consequences

- Workstation runs alongside Hyper-V/WSL2 through the Windows Hypervisor Platform; nested virtualization is not available in that mode, so a nested ESXi is out of scope for now.
- The lab network is NAT-only; nothing is exposed to the LAN.
