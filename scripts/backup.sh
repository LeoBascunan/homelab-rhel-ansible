#!/usr/bin/env bash
# backup.sh — tar.gz of /etc and /home to /var/backups, keep the last 7.
# Day 2 (30 Aug): complete the TODOs and schedule it with a systemd timer (see docs/LOG.md).
set -euo pipefail

BACKUP_DIR=/var/backups/lab
KEEP=7
STAMP=$(date +%F-%H%M)

mkdir -p "$BACKUP_DIR"
# TODO: create "$BACKUP_DIR/$(hostname)-$STAMP.tar.gz" from /etc and /home with tar, excluding caches
# TODO: verify the archive (tar -tzf) before deleting anything
# TODO: delete archives older than the newest $KEEP
# TODO: log a one-line summary with logger -t backup
