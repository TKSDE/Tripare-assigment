aws_region               = "us-east-1"
environment              = "prod"
vpc_cidr                 = "10.100.0.0/16"
availability_zones       = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs      = ["10.100.1.0/24", "10.100.2.0/24"]
private_app_subnet_cidrs = ["10.100.11.0/24", "10.100.12.0/24"]
private_db_subnet_cidrs  = ["10.100.21.0/24", "10.100.22.0/24"]
container_port           = 80
app_image                = "public.ecr.aws/nginx/nginx:alpine"

task_cpu      = 1024
task_memory   = 2048
desired_count = 2

rds_instance_class        = "db.r6g.large"
rds_allocated_storage     = 100
rds_max_allocated_storage = 500
rds_multi_az              = true
rds_backup_retention      = 30
rds_deletion_protection   = true
rds_database_name         = "hotel_booking_db"
rds_master_username       = "dbadmin"
rds_master_password       = "TripareProdPass2026!"
