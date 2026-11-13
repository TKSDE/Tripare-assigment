variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS and ALB reside"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the ECS Fargate tasks"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "ecs_security_group_id" {
  description = "Security group ID for the ECS tasks"
  type        = string
}

variable "app_image" {
  description = "Docker image for the application container"
  type        = string
  default     = "public.ecr.aws/nginx/nginx:alpine"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

variable "task_cpu" {
  description = "Fargate CPU units for the task definition (e.g. 256, 512, 1024)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate Memory (MB) for the task definition (e.g. 512, 1024, 2048)"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of running task replicas"
  type        = number
  default     = 1
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "health_check_path" {
  description = "Target group health check HTTP path"
  type        = string
  default     = "/"
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
