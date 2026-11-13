variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment identifier"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.100.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.100.1.0/24", "10.100.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "Private app subnet CIDRs"
  type        = list(string)
  default     = ["10.100.11.0/24", "10.100.12.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "Private database subnet CIDRs"
  type        = list(string)
  default     = ["10.100.21.0/24", "10.100.22.0/24"]
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 80
}

variable "app_image" {
  description = "Application docker image"
  type        = string
  default     = "public.ecr.aws/nginx/nginx:alpine"
}

variable "task_cpu" {
  description = "Fargate CPU units"
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Fargate Memory (MB)"
  type        = number
  default     = 2048
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 100
}

variable "rds_max_allocated_storage" {
  description = "Max auto-scaling storage in GB"
  type        = number
  default     = 500
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ RDS deployment"
  type        = bool
  default     = true
}

variable "rds_backup_retention" {
  description = "Backup retention in days"
  type        = number
  default     = 30
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "rds_database_name" {
  description = "Database name"
  type        = string
  default     = "hotel_booking_db"
}

variable "rds_master_username" {
  description = "Master database username"
  type        = string
  default     = "dbadmin"
}

variable "rds_master_password" {
  description = "Master database password"
  type        = string
  sensitive   = true
  default     = "ProdSuperSecurePass2026!"
}
