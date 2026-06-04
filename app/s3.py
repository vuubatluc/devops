import boto3
from botocore.exceptions import ClientError

from app.config import settings


s3 = boto3.client("s3", region_name=settings.aws_region)


def upload_file(file_bytes: bytes, key: str, content_type: str | None) -> str:
    s3.put_object(
        Bucket=settings.s3_bucket,
        Key=key,
        Body=file_bytes,
        ContentType=content_type or "application/octet-stream",
    )
    return key


def get_presigned_url(key: str, expires_in: int = 3600) -> str:
    return s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": settings.s3_bucket, "Key": key},
        ExpiresIn=expires_in,
    )


def delete_file(key: str) -> None:
    try:
        s3.delete_object(Bucket=settings.s3_bucket, Key=key)
    except ClientError:
        pass


def check_s3_connection() -> bool:
    try:
        s3.head_bucket(Bucket=settings.s3_bucket)
        return True
    except ClientError:
        return False
