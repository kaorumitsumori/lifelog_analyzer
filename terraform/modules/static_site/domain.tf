resource "aws_route53_record" "main" {
  zone_id = var.hosted_zone_id
  name    = var.app_domain
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

module "acm" {
  source              = "terraform-aws-modules/acm/aws"
  domain_name         = var.app_domain
  zone_id             = var.hosted_zone_id
  wait_for_validation = true
}
