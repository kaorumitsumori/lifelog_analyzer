# FIXME: 新しくアカウントを作成した場合は必要だが、サンドボックスでは不要

# for github actions
# data "http" "github_actions_openid_configuration" {
#   url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
# }
# data "tls_certificate" "github_actions" {
#   url = jsondecode(data.http.github_actions_openid_configuration.response_body).jwks_uri
# }
# resource "aws_iam_openid_connect_provider" "github_actions" {
#   url             = "https://token.actions.githubusercontent.com"
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
# }
# resource "aws_iam_service_linked_role" "ecs" {
#   aws_service_name = "ecs.amazonaws.com"
# }
# resource "aws_iam_service_linked_role" "autoscaling" {
#   aws_service_name = "ecs.application-autoscaling.amazonaws.com"
# }
