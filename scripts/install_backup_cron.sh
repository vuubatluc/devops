#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/fastapi-demo}"
RUN_AS_USER="${RUN_AS_USER:-ubuntu}"
CRON_SCHEDULE="${CRON_SCHEDULE:-0 2 * * *}"
LOG_FILE="${LOG_FILE:-/var/log/fastapi-demo-backup.log}"
CRON_FILE="${CRON_FILE:-/etc/cron.d/fastapi-demo-backup}"

if [[ ! -x "$APP_DIR/scripts/backup_mysql.sh" ]]; then
  echo "Backup script not found or not executable: $APP_DIR/scripts/backup_mysql.sh" >&2
  exit 1
fi

if [[ ! -f "$APP_DIR/.env" ]]; then
  echo "Missing env file: $APP_DIR/.env" >&2
  exit 1
fi

sudo tee "$CRON_FILE" >/dev/null <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
$CRON_SCHEDULE $RUN_AS_USER APP_DIR=$APP_DIR $APP_DIR/scripts/backup_mysql.sh >> $LOG_FILE 2>&1
EOF

sudo chmod 0644 "$CRON_FILE"
sudo systemctl enable --now cron

echo "Installed backup cron:"
cat "$CRON_FILE"
