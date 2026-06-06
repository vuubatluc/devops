# DevOps Mini Project: FastAPI on AWS

Video demo: https://youtu.be/sUd3Fi2XHYk?si=kAD6KsTbnRjCeWbk

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

- App through Nginx: `http://localhost`
- App debug on EC2 only: `http://127.0.0.1:8000`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000`

Grafana default login:

```text
admin / admin
```

## Nginx and Domain

Nginx listens on port `80` and proxies traffic to the FastAPI container.

After buying a domain, create DNS records:

```text
Type: A
Name: @
Value: EC2_PUBLIC_IP

Type: A
Name: www
Value: EC2_PUBLIC_IP
```

Open these EC2 inbound ports:

```text
80/tcp   0.0.0.0/0
443/tcp  0.0.0.0/0
```

For the current Docker setup, edit `nginx/conf.d/default.conf` and replace:

```nginx
server_name _;
```

with:

```nginx
server_name example.com www.example.com;
```

Then redeploy:

```bash
docker compose up -d --build
```

Use an Elastic IP for EC2 before pointing a real domain at it. Without Elastic IP, the public IP can change after stop/start.

## GitHub Actions

CI runs on pull requests and pushes to `main`:

- install Python dependencies
- run tests
- build Docker image

CD deploys on pushes to `main` or manual workflow dispatch. It expects a self-hosted GitHub Actions runner on the EC2 instance. The deploy job updates either `/opt/fastapi-demo` or `~/devops`, then runs:

```bash
docker compose up -d --build
```

### Self-Hosted Runner on EC2

In GitHub, open:

```text
Settings -> Actions -> Runners -> New self-hosted runner
```

Choose Linux x64 and run the generated commands on EC2. Install it as a service:

```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

The `ubuntu` user must be able to run Docker:

```bash
sudo usermod -aG docker ubuntu
```

After confirming deployments work, restrict EC2 inbound SSH back to your IP only.

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

For a manually created EC2 where the repo is in `~/devops`, test it with:

```bash
cd ~/devops
APP_DIR=$PWD ./scripts/backup_mysql.sh
aws s3 ls "s3://$S3_BUCKET/$BACKUP_S3_PREFIX/"
```

Install the daily cron job:

```bash
cd ~/devops
APP_DIR=$PWD ./scripts/install_backup_cron.sh
```

By default, cron runs daily at `02:00 UTC` and writes logs to:

```text
/var/log/fastapi-demo-backup.log
```

Optional alerting:

```env
ALERT_WEBHOOK_URL=https://your-webhook-url
ALERT_WEBHOOK_FORMAT=slack
```

Use Discord webhooks with:

```env
ALERT_WEBHOOK_FORMAT=discord
```
