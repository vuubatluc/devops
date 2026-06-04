# FastAPI Demo: EC2 + RDS + S3

Demo project for a file-management API running on EC2, using RDS MySQL for persistence and S3 for file storage.

## API

- `POST /items` - create an item in RDS
- `GET /items` - list items from RDS
- `POST /items/{id}/upload` - upload a file to S3 and save the object URL in RDS
- `GET /items/{id}/file` - generate a presigned download URL
- `DELETE /items/{id}` - delete the RDS record and the S3 object
- `GET /health` - check RDS and S3 connectivity

## Local development

1. Copy `.env.example` to `.env` and fill in your values.
2. Install dependencies with `pip install -r requirements.txt`.
3. Run the app with `uvicorn app.main:app --reload`.

## Docker

Build and run with Docker Compose:

```bash
docker compose up --build
```

## Terraform

The `terraform/` folder provisions:

- EC2 for the FastAPI app
- RDS MySQL for storage
- S3 bucket for file uploads
- IAM role and instance profile for EC2 access to S3

Initialize and apply:

```bash
cd terraform
terraform init
terraform apply
```
