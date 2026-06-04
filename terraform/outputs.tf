output "ec2_ip" {
  value = aws_eip.app.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.address
}

output "s3_bucket" {
  value = aws_s3_bucket.files.bucket
}

output "app_url" {
  value = "http://${aws_eip.app.public_ip}"
}

output "docs_url" {
  value = "http://${aws_eip.app.public_ip}/docs"
}

output "grafana_url" {
  value = "http://${aws_eip.app.public_ip}:3000"
}

output "prometheus_url" {
  value = "http://${aws_eip.app.public_ip}:9090"
}
