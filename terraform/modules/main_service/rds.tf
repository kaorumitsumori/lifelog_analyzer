resource "aws_rds_cluster" "main" {
  cluster_identifier     = "${var.env}-${var.servicename}"
  engine                 = "aurora-mysql"
  engine_version         = "8.0.mysql_aurora.3.02.2"
  availability_zones     = data.aws_availability_zones.available.names
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [module.security_group_db.security_group_id]

  master_username = "admin"
  master_password = "dummypassword" # NOTE: 初回作成後に手動変更する

  backup_retention_period = 1
  preferred_backup_window = "19:00-19:30" # NOTE: 時間は適当。日本時間の深夜。
  copy_tags_to_snapshot   = true
  skip_final_snapshot     = true
  deletion_protection     = false # FIXME: チュートリアル用にfalseにしています。実運用の際はtrueにしてください。 

  lifecycle {
    ignore_changes = [master_password]
  }

  serverlessv2_scaling_configuration {
    max_capacity = 128
    min_capacity = 0.5
  }
  # TODO: cloudwatch logs
  # TODO: 暗号化
}

resource "aws_rds_cluster_instance" "main" {
  identifier         = "${var.env}-${var.servicename}-main-instance-01"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  monitoring_interval  = 60
  monitoring_role_arn  = aws_iam_role.rds_monitoring_role.arn
  promotion_tier       = 1
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.main.name
}

module "security_group_db" {
  source          = "terraform-aws-modules/security-group/aws"
  name            = "${var.env}-${var.servicename}-db"
  description     = "Allow Access from ECS ${var.env}-${var.servicename}"
  use_name_prefix = false
  vpc_id          = module.vpc.vpc_id
  egress_rules    = ["all-all"] # 暫定的にインターネットへの任意のoutboundを許可する

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      description              = "Allow Access from ECS"
      source_security_group_id = module.security_group_ecs_service.security_group_id
    },
  ]
  number_of_computed_ingress_with_source_security_group_id = 1
}

resource "aws_db_subnet_group" "main" {
  name        = "${var.env}-${var.servicename}-main"
  description = "main subnet group"
  subnet_ids  = module.vpc.private_subnets
}

# RDSのモニタリング用に自動作成されるロール
resource "aws_iam_role" "rds_monitoring_role" {
  name = "${var.env}-${var.servicename}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "monitoring.rds.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  ]

  # FIXME: サンドボックス環境ではこの指定が必要。実際の環境で使うときはこの行を削除してください
  permissions_boundary = "arn:aws:iam::256976153308:policy/sandbox-user-permission-boundary"
}
