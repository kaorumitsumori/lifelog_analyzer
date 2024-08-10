output "task_definition_template_json" {
  value = local.task_definition_template_json
}
output "vpc_id" {
  value = module.vpc.vpc_id
}
output "private_route_table_id" {
  value = module.vpc.private_route_table_ids[0]
}

output "infra_metadata" {
  value = {
    AWS_ROLE_ARN        = module.github_actions_role.role.arn,
    ECS_SERVICE_NAME    = aws_ecs_service.main.name,
    ECS_CLUSTER_NAME    = aws_ecs_cluster.main.name,
    ECR_URL_APP         = aws_ecr_repository.app.repository_url,
  }
}
