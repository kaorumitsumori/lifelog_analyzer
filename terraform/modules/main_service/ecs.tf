resource "aws_ecs_cluster" "main" {
  name = "${var.env}-${var.servicename}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT",
  ]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE" # TODO: to FARGATE_SPOT ?
  }
}

resource "aws_ecr_repository" "app" {
  name                 = "${var.env}-${var.servicename}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true # 安全のためにscanする
  }
  force_delete = true # FIXME: チュートリアル用にtrueにしています。実運用の際はfalseにしてください。
}

resource "aws_iam_role" "ecs_task_execution" {
  name        = "${var.env}-${var.servicename}-ecs-task-execution"
  description = ""

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    module.parameters.parameters_accessor_policy.arn, # parameter storeの参照に必要
  ]

  # FIXME: サンドボックス環境ではこの指定が必要。実際の環境で使うときはこの行を削除してください
  permissions_boundary = "arn:aws:iam::256976153308:policy/sandbox-user-permission-boundary"
}

resource "aws_iam_role" "ecs_task" {
  name        = "${var.env}-${var.servicename}-ecs-task"
  description = ""

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess" # TODO: 後で絞る
  ]
  
  # FIXME: サンドボックス環境ではこの指定が必要。実際の環境で使うときはこの行を削除してください
  permissions_boundary = "arn:aws:iam::256976153308:policy/sandbox-user-permission-boundary"
}

resource "aws_cloudwatch_log_group" "application" {
  name = "/ecs/${var.env}-${var.servicename}-app"
}

module "parameters" {
  source  = "github.com/moajo/terraform-aws-parameters?ref=v1"
  envs    = merge(local.ecs_env, var.app_envs)
  secrets = local.app_secrets
  prefix  = "${var.env}-${var.servicename}"
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.env}-${var.servicename}"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  cpu                      = 512
  memory                   = 4096
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    # NOTE: 初回apply用ダミータスク
    # 本物のtaskはterraform管理外のデプロイ処理によって定義します。
    {
      "name" : var.container_name,
      "command" : [
        "/bin/sh -c \"sed -i 's/Listen 80/Listen ${var.container_port}/g' /usr/local/apache2/conf/httpd.conf && echo '<html> <head> <title>Amazon ECS Sample App</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p> </div></body></html>' >  /usr/local/apache2/htdocs/index.html && httpd-foreground\""
      ],
      "entryPoint" : ["sh", "-c"],
      "essential" : true,
      "image" : "httpd:2.4",
      "portMappings" : [
        {
          "containerPort" : var.container_port,
          "hostPort" : var.container_port,
          "protocol" : "tcp"
        }
      ]
    }
  ])
}
data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.main.family
}

# NOTE: サービスのセキュリティグループ。
# albからのhttpリクエストのみ許可する。

module "security_group_ecs_service" {
  source          = "terraform-aws-modules/security-group/aws"
  name            = "${var.env}-${var.servicename}-ecs-service"
  description     = "use for ecs service ${var.env}-${var.servicename}"
  use_name_prefix = false
  vpc_id          = module.vpc.vpc_id
  egress_rules    = ["all-all"] # 暫定的にインターネットへの任意のoutboundを許可する

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = var.container_port
      to_port                  = var.container_port
      protocol                 = "tcp"
      description              = "allow http from alb"
      source_security_group_id = module.security_group_alb.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1
}

resource "aws_ecs_service" "main" {
  name                              = "${var.env}-${var.servicename}"
  cluster                           = aws_ecs_cluster.main.id
  desired_count                     = 1
  health_check_grace_period_seconds = 0
  launch_type                       = "FARGATE" # マネージドに寄せたいのでfargateを使用する
  platform_version                  = "LATEST"
  wait_for_steady_state             = false # NOTE: terraformがapply時にsteadyまで待つかどうか。ひとまず不要なのでfalseにしている
  enable_ecs_managed_tags           = true  # 自動でいい感じのtagを付けてくれる機能。とりあえずtrue。
  enable_execute_command            = true  # 作業用に `aws ecs execute-command` を有効化する

  # NOTE: デプロイ時間短縮のため。 TODO: 本番環境では100にする
  # https://dev.classmethod.jp/articles/tsnote-i-want-to-shorten-the-deployment-time-for-rolling-updates-of-ecs-is-there-any-way-to-shorten-the-time/
  deployment_minimum_healthy_percent = 0

  # dummy. これはCIからコマンドで更新される。初回apply用に適当なtask definitionを当てておく
  task_definition = "${aws_ecs_task_definition.main.family}:${max(aws_ecs_task_definition.main.revision, data.aws_ecs_task_definition.main.revision)}"

  load_balancer {
    container_name   = var.container_name
    container_port   = var.container_port
    target_group_arn = module.alb.target_group_arns[0]
  }
  network_configuration {
    security_groups = [
      module.security_group_ecs_service.security_group_id
    ]
    subnets = module.vpc.private_subnets

    # NOTE: NATがない場合、igwにアクセスするためにはpublic ipが必要になる。
    assign_public_ip = var.force_expose_private_subnet_for_cost_optimize
  }

  # NOTE: サーキットブレーカーはとりあえず有効にしている
  # デプロイに失敗したら直前のデプロイ成功していたバージョンに自動でロールバックする
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  ecs_env = {
    "APP_ENV" : var.env,
    "AWS_DEFAULT_REGION" : "ap-northeast-1",

    "DB_HOST" : aws_rds_cluster.main.endpoint,
    "DB_USER" : "admin", # TODO: 仮なのでなおす。移行時はサービス停止->スナップショット->復元->tf import
    "DB_DB_NAME" : "${var.env}_${var.servicename}",
    "DB_PASSWORD" : "dummypassword",
    "DB_PORT" : tostring(aws_rds_cluster.main.port),
  }

  task_definition_template_json = jsonencode({
    "family" : aws_ecs_task_definition.main.family,
    "executionRoleArn" : aws_iam_role.ecs_task_execution.arn,
    "taskRoleArn" : aws_iam_role.ecs_task.arn,
    "cpu" : "256",
    "memory" : "512",
    "networkMode" : "awsvpc",
    "requiresCompatibilities" : ["FARGATE"],
    "containerDefinitions" : [
      {
        "name" : var.container_name,
        "image" : "${aws_ecr_repository.app.repository_url}:$${IMAGE_TAG}",
        "essential" : true,
        "logConfiguration" : {
          "logDriver" : "awslogs",
          "options" : {
            "awslogs-group" : "${aws_cloudwatch_log_group.application.name}",
            "awslogs-region" : "${data.aws_region.current.name}",
            "awslogs-datetime-format" : "%Y-%m-%d %H:%M:%S",
            "awslogs-stream-prefix" : "ecs"
          }
        },
        "portMappings" : [
          {
            "protocol" : "tcp",
            "containerPort" : var.container_port
          }
        ],
        "environment" : [        ]
        "secrets" : module.parameters.parameters_names,
        "mountPoints" : [],
        "volumesFrom" : [],
      },
    ]
  })
}
