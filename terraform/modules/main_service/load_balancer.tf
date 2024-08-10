module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name                       = "${var.env}-${var.servicename}"
  load_balancer_type         = "application"
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  security_groups            = [module.security_group_alb.security_group_id]
  enable_deletion_protection = false  # FIXME: チュートリアル用にfalseにしています。実運用の際はtrueにしてください。
  idle_timeout               = 60 * 5 // /dev等の開発用エンドポイントが遅いので眺めにしてる。

  # access_logs = {
  #   bucket = "my-alb-logs"
  # }

  target_groups = [
    {
      name             = "${var.env}-${var.servicename}"
      backend_port     = 80
      backend_protocol = "HTTP" # NOTE: ターゲットへのリクエストは普通のHTTPにしておいた
      target_type      = "ip"   # NOTE: awsvpcネットワークモードの場合ipを指定する必要がある

      health_check = {
        enabled             = true
        path                = var.healthcheck_path
        interval            = 30
        healthy_threshold   = 5
        unhealthy_threshold = 5
        timeout             = 5
        matcher             = "200"
      }
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = module.acm.acm_certificate_arn
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]
}

# NOTE: ALBのセキュリティグループ。
# http/httpsだけ受信する。
# ターゲットへの送信を許可する。
module "security_group_alb" {
  source      = "terraform-aws-modules/security-group/aws"
  name        = "${var.env}-${var.servicename}-alb"
  description = "use for ALB ${var.env}-${var.servicename}"

  use_name_prefix = false
  vpc_id          = module.vpc.vpc_id
  egress_rules    = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "allow http"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "allow https"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  ingress_with_ipv6_cidr_blocks = [
    {
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      description      = "allow http"
      ipv6_cidr_blocks = "::/0"
    },
    {
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      description      = "allow https"
      ipv6_cidr_blocks = "::/0"
    },
  ]
}
