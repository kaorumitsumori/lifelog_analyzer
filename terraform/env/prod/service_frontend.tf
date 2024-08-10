module "frontend" {
  providers = {
    aws = aws.useast1
  }
  source                   = "../../modules/static_site"
  env                      = local.env
  servicename              = "${local.servicename}front"
  repo_to_allow_access_aws = local.repo_to_allow_access_aws
  bucket_name              = "${local.env}-${local.servicename}-static-frontend"
  hosted_zone_id           = data.aws_route53_zone.main.zone_id
  app_domain               = local.frontend_domain
  basicauth_user           = local.basic_auth_user
  basicauth_password       = local.basic_auth_password
}
