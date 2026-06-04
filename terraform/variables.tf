variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "ami_id" {
  type    = string
  default = "ami-0df7a207adb9748c7"
}

variable "key_name" {
  type    = string
  default = "lms-key"
}

variable "github_repo" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "s3_bucket_name" {
  type = string
}

variable "admin_cidr" {
  type        = string
  description = "CIDR allowed to access SSH, Grafana, and Prometheus."
  default     = "0.0.0.0/0"
}

variable "app_cidr" {
  type        = string
  description = "CIDR allowed to access the FastAPI app."
  default     = "0.0.0.0/0"
}
