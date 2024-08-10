module "api" {
  source                   = "../../modules/main_service"
  env                      = local.env
  servicename              = "${local.servicename}api"
  repo_to_allow_access_aws = local.repo_to_allow_access_aws
  healthcheck_path         = "/"
  container_port           = 8080
  container_name           = "app"
  vpc_cidr                 = "10.2.0.0/16"
  domain                   = local.api_domain

  hosted_zone_id = data.aws_route53_zone.main.zone_id

  force_expose_private_subnet_for_cost_optimize = false # trueにするとNATを使わないようにするのでコストが下がる

  app_envs = {
    "SITE_URL" : "https://${local.frontend_domain}/",
  }
}

