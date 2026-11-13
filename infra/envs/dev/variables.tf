variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment identifier"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "Private app subnet CIDRs"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "Private database subnet CIDRs"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
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
  default     = 256
}

variable "task_memory" {
  description = "Fargate Memory (MB)"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Max auto-scaling storage in GB"
  type        = number
  default     = 50
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ RDS deployment"
  type        = bool
  default     = false
}

variable "rds_backup_retention" {
  description = "Backup retention in days"
  type        = number
  default     = 1
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
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
  default     = "DevSecretPass2026!"
}
