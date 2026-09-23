variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "depi-aws-security-mini-project-1"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "alert_email" {
  description = "Email address for security alerts"
  type        = string
}


variable "app_bucket_name" {
  description = "Exact S3 bucket name for the application"
  type        = string
}

