# DevOps Mini Project: FastAPI on AWS

Mini project for practicing a complete DevOps workflow:

- FastAPI app with a basic browser UI
- Dockerfile and Docker Compose
- GitHub Actions CI/CD
- Terraform deployment to AWS EC2, RDS MySQL, S3, and IAM
- Prometheus and Grafana monitoring
- Bash auto-backup script with optional webhook alert

## App

- `GET /` - frontend console for testing the API
- `GET /health` - checks RDS and S3 connectivity
- `GET /metrics` - Prometheus metrics
- `POST /items/` - create an item in RDS
- `GET /items/` - list items from RDS
- `POST /items/{id}/upload` - upload a file to S3
- `GET /items/{id}/file` - generate a presigned download URL
- `DELETE /items/{id}` - delete the RDS row and S3 object
- `GET /docs` - Swagger UI

## Local Development

```bash
cp .env.example .env
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Open:

```text
http://localhost:8000/
```

## Docker Compose

Create `.env` first, then run:

```bash
docker compose up -d --build
```

Services:

- App: `http://localhost:8000`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000`

Grafana default login:

```text
admin / admin
```

## GitHub Actions

CI runs on pull requests and pushes to `main`:

- install Python dependencies
- run tests
- build Docker image

CD deploys on pushes to `main` or manual workflow dispatch. Add these repository secrets:

```text
EC2_HOST      public IP or DNS of EC2
EC2_USER      ubuntu
EC2_SSH_KEY   private key content for SSH
```

The deploy job updates either `/opt/fastapi-demo` or `~/devops`, then runs:

```bash
docker compose up -d --build
```

## Terraform

The `terraform/` folder provisions:

- EC2 instance
- Security groups
- RDS MySQL
- S3 bucket with public access blocked
- IAM role and instance profile for EC2 access to S3
- Docker Compose bootstrap via user data
- Daily database backup cron

Example:

```bash
cd terraform
terraform init
terraform apply \
  -var="github_repo=vuubatluc/devops" \
  -var="key_name=fastapi-demo-key" \
  -var="db_password=CHANGE_ME" \
  -var="s3_bucket_name=fastapi-demo-files-unique-name" \
  -var="admin_cidr=YOUR_IP/32"
```

Useful outputs:

```bash
terraform output app_url
terraform output docs_url
terraform output grafana_url
terraform output prometheus_url
```

## Backup

The backup script reads `.env`, runs `mysqldump`, compresses the SQL dump, and uploads it to S3:

```bash
APP_DIR=/opt/fastapi-demo ./scripts/backup_mysql.sh
```

On Terraform-created EC2, cron runs it daily at `02:00 UTC` and writes logs to:

```text
/var/log/fastapi-demo-backup.log
```

Optional alerting:

```env
ALERT_WEBHOOK_URL=https://your-webhook-url
```
