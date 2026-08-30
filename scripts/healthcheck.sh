#!/usr/bin/env bash
# healthcheck.sh — one-screen health summary of this server.
# Day 2 (30 Aug): complete the TODOs, then install it with the baseline role and run it from a systemd timer.
set -euo pipefail

echo "== $(hostname) — $(date '+%F %T %Z') =="
echo "-- uptime / load"; uptime
echo "-- memory"; free -m
echo "-- disks"; df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs
echo "-- failed units"; systemctl --failed --no-legend || true
# TODO: warn when any filesystem is above 85 %
# TODO: warn when chronyc tracking reports an offset above 0.5 s
# TODO: list listening ports (ss -tulpn) and compare with an expected list
# TODO: exit 1 when any warning was raised, so the timer's failure shows in journalctl
