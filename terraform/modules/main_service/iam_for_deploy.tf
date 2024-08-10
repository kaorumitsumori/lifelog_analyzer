
module "github_actions_role" {
  source               = "github.com/moajo/terraform-aws-github-actions-oidc-role.git?ref=v3.2.0"
  role_name            = "${var.env}-${var.servicename}-github-actions"
  repo_to_allow_assume = var.repo_to_allow_access_aws

  # FIXME: サンドボックス環境ではこの指定が必要。実際の環境で使うときはこの行を削除してください
  permissions_boundary_arn = "arn:aws:iam::256976153308:policy/sandbox-user-permission-boundary"
}

resource "aws_iam_policy" "github_actions" {
  name        = "${var.env}-${var.servicename}-github-actions"
  path        = "/"
  description = "Allow push ecr and update ECS service"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowLoginECR",
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
        ],
        "Resource" : ["*"]
      },
      {
        "Sid" : "AllowRegisterTaskDef",
        "Effect" : "Allow",
        "Action" : [
          "ecs:RegisterTaskDefinition",
        ],
        "Resource" : ["*"]
      },
      {
        "Sid" : "AllowPushImage",
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetDownloadUrlForLayer", # NOTE: docker/build-push-action@v2 で必要
          "ecr:BatchGetImage",          # NOTE: docker/build-push-action@v2 で必要
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ],
        "Resource" : [
          "*"
        ]
      },
      {
        "Sid" : "AllowDeployECS",
        "Effect" : "Allow",
        "Action" : [
          "iam:PassRole",
          "ecs:DescribeServices",
          "ecs:UpdateService",
        ],
        "Resource" : [
          "*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = module.github_actions_role.role.name
  policy_arn = aws_iam_policy.github_actions.arn
}
