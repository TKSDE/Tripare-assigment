module "network" {
  source = "../../modules/network"

  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  container_port           = var.container_port
  db_port                  = 5432
  enable_nat_gateway       = true
  single_nat_gateway       = true

  tags = {
    Environment = var.environment
  }
}

module "ecs" {
  source = "../../modules/ecs"

  environment           = var.environment
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  private_subnet_ids    = module.network.private_app_subnet_ids
  alb_security_group_id = module.network.alb_security_group_id
  ecs_security_group_id = module.network.ecs_security_group_id
  app_image             = var.app_image
  container_port        = var.container_port
  task_cpu              = var.task_cpu
  task_memory           = var.task_memory
  desired_count         = var.desired_count

  environment_variables = [
    {
      name  = "DB_HOST"
      value = module.rds.db_address
    },
    {
      name  = "DB_PORT"
      value = tostring(module.rds.db_port)
    },
    {
      name  = "DB_NAME"
      value = module.rds.db_name
    },
    {
      name  = "ENVIRONMENT"
      value = var.environment
    }
  ]

  tags = {
    Environment = var.environment
  }
}

module "rds" {
  source = "../../modules/rds"

  environment             = var.environment
  db_subnet_group_name    = module.network.db_subnet_group_name
  rds_security_group_id   = module.network.rds_security_group_id
  database_name           = var.rds_database_name
  master_username         = var.rds_master_username
  master_password         = var.rds_master_password
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  max_allocated_storage   = var.rds_max_allocated_storage
  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention
  deletion_protection     = var.rds_deletion_protection
  skip_final_snapshot     = true

  tags = {
    Environment = var.environment
  }
}
