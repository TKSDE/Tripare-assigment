aws_region               = "us-east-1"
environment              = "dev"
vpc_cidr                 = "10.0.0.0/16"
availability_zones       = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
private_app_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
private_db_subnet_cidrs  = ["10.0.21.0/24", "10.0.22.0/24"]
container_port           = 80
app_image                = "public.ecr.aws/nginx/nginx:alpine"

task_cpu      = 256
task_memory   = 512
desired_count = 1

rds_instance_class        = "db.t4g.micro"
rds_allocated_storage     = 20
rds_max_allocated_storage = 50
rds_multi_az              = false
rds_backup_retention      = 1
rds_deletion_protection   = false
rds_database_name         = "hotel_booking_db"
rds_master_username       = "dbadmin"
rds_master_password       = "TripareDevPass2026!"
