resource "aws_route53_record" "main" {
  zone_id = var.hosted_zone_id
  name    = var.domain
  type    = "A"
  alias {
    name                   = module.alb.lb_dns_name
    zone_id                = module.alb.lb_zone_id
    evaluate_target_health = false
  }
}

module "acm" {
  source              = "terraform-aws-modules/acm/aws"
  domain_name         = var.domain
  zone_id             = var.hosted_zone_id
  wait_for_validation = true
  subject_alternative_names = [
    "*.${var.domain}",
  ]
}
