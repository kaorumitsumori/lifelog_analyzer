# インフラ情報をCI等から参照するために、ファイルに出力しておく
module "metadata" {
  source = "github.com/moajo/terraform-metadata?ref=v1"
  vars = merge(
    module.api.infra_metadata,
    module.frontend.infra_metadata,
    {
      ACCOUNT_ID               = data.aws_caller_identity.current.account_id,
      AWS_REGION               = data.aws_region.current.name,
      NEXT_PUBLIC_API_ENDPOINT = "https://${local.api_domain}"
    }
  )
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# NOTE: このtemplateをもとにCIでタスク定義を更新する
resource "local_file" "task_def" {
  content  = module.api.task_definition_template_json
  filename = "${path.module}/../../metadata_outputs/${local.env}/task_def.template.json"
}
