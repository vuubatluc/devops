#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y docker.io docker-compose-plugin git

systemctl enable --now docker
usermod -aG docker ubuntu

rm -rf /opt/fastapi-demo
git clone https://github.com/${github_repo}.git /opt/fastapi-demo

cat > /opt/fastapi-demo/.env << EOF
DATABASE_URL=mysql+pymysql://admin:${db_password}@${db_host}:3306/demo_db
S3_BUCKET=${s3_bucket}
AWS_REGION=${aws_region}
EOF

cd /opt/fastapi-demo
docker compose up -d --build
