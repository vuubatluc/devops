#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y docker.io docker-compose-plugin git mysql-client curl unzip cron

systemctl enable --now docker
systemctl enable --now cron
usermod -aG docker ubuntu

if ! command -v aws >/dev/null 2>&1; then
  if command -v snap >/dev/null 2>&1; then
    snap install aws-cli --classic
  else
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install
  fi
fi

rm -rf /opt/fastapi-demo
git clone https://github.com/${github_repo}.git /opt/fastapi-demo

cat > /opt/fastapi-demo/.env << EOF
DATABASE_URL=mysql+pymysql://admin:${db_password}@${db_host}:3306/demo_db
S3_BUCKET=${s3_bucket}
AWS_REGION=${aws_region}
BACKUP_S3_PREFIX=backups/mysql
ALERT_WEBHOOK_URL=
ALERT_WEBHOOK_FORMAT=slack
EOF

cd /opt/fastapi-demo
docker compose up -d --build
APP_DIR=/opt/fastapi-demo /opt/fastapi-demo/scripts/install_backup_cron.sh
