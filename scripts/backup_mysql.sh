#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/fastapi-demo}"
ENV_FILE="${ENV_FILE:-$APP_DIR/.env}"
BACKUP_DIR="${BACKUP_DIR:-/tmp/fastapi-demo-backups}"
BACKUP_S3_PREFIX="${BACKUP_S3_PREFIX:-backups/mysql}"
ALERT_WEBHOOK_URL="${ALERT_WEBHOOK_URL:-}"
ALERT_WEBHOOK_FORMAT="${ALERT_WEBHOOK_FORMAT:-slack}"

notify() {
  local status="$1"
  local message="$2"
  local payload

  if [[ -z "$ALERT_WEBHOOK_URL" ]]; then
    echo "[$status] $message"
    return
  fi

  case "$ALERT_WEBHOOK_FORMAT" in
    discord)
      payload="$(python3 -c 'import json,sys; print(json.dumps({"content": sys.argv[1]}))' "[$status] $message")"
      ;;
    slack | generic)
      payload="$(python3 -c 'import json,sys; print(json.dumps({"text": sys.argv[1]}))' "[$status] $message")"
      ;;
    *)
      echo "Unsupported ALERT_WEBHOOK_FORMAT: $ALERT_WEBHOOK_FORMAT" >&2
      return 1
      ;;
  esac

  curl -fsS \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "$ALERT_WEBHOOK_URL" >/dev/null
}

load_env() {
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "Missing env file: $ENV_FILE" >&2
    exit 1
  fi

  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
}

parse_database_url() {
  python3 - "$DATABASE_URL" <<'PY'
import sys
from urllib.parse import urlparse

url = urlparse(sys.argv[1])
print(url.username or "")
print(url.password or "")
print(url.hostname or "")
print(url.port or 3306)
print((url.path or "/").lstrip("/"))
PY
}

main() {
  load_env
  mkdir -p "$BACKUP_DIR"

  mapfile -t db_parts < <(parse_database_url)
  local db_user="${db_parts[0]}"
  local db_password="${db_parts[1]}"
  local db_host="${db_parts[2]}"
  local db_port="${db_parts[3]}"
  local db_name="${db_parts[4]}"

  local timestamp
  timestamp="$(date -u +"%Y%m%dT%H%M%SZ")"
  local backup_file="$BACKUP_DIR/${db_name}_${timestamp}.sql.gz"
  local s3_uri="s3://${S3_BUCKET}/${BACKUP_S3_PREFIX}/${db_name}_${timestamp}.sql.gz"

  trap 'notify "backup_failed" "MySQL backup failed for '"$db_name"' on '"$(hostname)"'. Check backup logs."' ERR

  if [[ -z "$db_user" || -z "$db_password" || -z "$db_host" || -z "$db_name" ]]; then
    echo "DATABASE_URL is missing required MySQL connection parts" >&2
    exit 1
  fi

  MYSQL_PWD="$db_password" mysqldump \
    --host="$db_host" \
    --port="$db_port" \
    --user="$db_user" \
    --single-transaction \
    --routines \
    --triggers \
    "$db_name" | gzip > "$backup_file"

  aws s3 cp "$backup_file" "$s3_uri"
  rm -f "$backup_file"

  notify "backup_ok" "MySQL backup uploaded to $s3_uri"
}

main "$@"
