terraform {
  # FIXME: バックエンドはプロジェクトごとに用意されたバケットを設定してください
  # 初期状態ではコメントアウトされているので、ローカルにtfstateファイルが作成されます

  # backend "s3" {
  #   bucket   = "hogehoge-terraform-backend"
  #   key      = "env/prod/terraform.tfstate"
  #   region   = "ap-northeast-1"
  #   role_arn = "arn:aws:iam::11111111111111111111111:role/terraform-backend-accessor"
  # }
}

locals {
  _config = yamldecode(file("../../config.yml"))

  env                      = "prod"
  servicename              = local._config["servicename"]
  root_domain              = local._config["root_domain"][local.env]
  frontend_domain          = local.root_domain
  api_domain               = "api.${local.root_domain}"
  repo_to_allow_access_aws = local._config["repo_to_allow_access_aws"]
  basic_auth_user          = local._config["basic_auth_user"][local.env]
  basic_auth_password      = local._config["basic_auth_password"][local.env]
}

provider "aws" {
  region = "ap-northeast-1"

  # FIXME: プロジェクトごとに用意された作業用ロールを設定してください
  # assume_role {
  #   role_arn = "arn:aws:iam::11111111111111111111111:role/admin"
  # }

  # FIXME: プロジェクトのリポジトリのある場所をManagedByタグに設定してください
  # TUTORIAL:4(インフラ構築)-1 prod環境(とりあえず1つ目の環境です。prodじゃなくてdevとかstgとかでもよい)のインフラ設定をAWS上に作成します。↑の指示に従ってタグを設定しましょう。
  # TUTORIAL:4(インフラ構築)-3 このファイルがあるディレクトリに移動し、 `terraform init` `terraform plan` `terraform apply` を順番に実行しましょう(applyは数分かかります)
  # TUTORIAL:4(インフラ構築)-4 terraform applyが成功したら、一部のファイルが書き換わってgit差分が出ているはずです。これをコミットしましょう
  # TUTORIAL:4(インフラ構築)-5 先程コミットしたファイルを参照し、既に構築されているCIが自動デプロイを実行できます。githubにpushし、リポジトリのactionsタブから `deploy-prod` ワークフローを手動実行しましょう
  default_tags {
    tags = {
      ManagedBy = "https://github.com/avilendev/hogehoge/tree/main/terraform"
    }
  }
}

# NOTE: cloudfront関連リソースは一部us-east-1でしか作成できない
provider "aws" {
  region = "us-east-1"
  alias  = "useast1"

  # FIXME: プロジェクトごとに用意された作業用ロールを設定してください
  # assume_role {
  #   role_arn = "arn:aws:iam::11111111111111111111111:role/admin"
  # }

  # FIXME: プロジェクトのリポジトリのある場所をManagedByタグに設定してください
  # TUTORIAL:4(インフラ構築)-2 ここも同様に変更します
  default_tags {
    tags = {
      ManagedBy = "https://github.com/avilendev/hogehoge/tree/main/terraform"
    }
  }
}

# TUTORIAL:4(インフラ構築)-6 デプロイしたURLにアクセスして動作を確認しましょう。URLはconfig.ymlに定義されています。
# TUTORIAL:5(片付け)-1 片付けをします。 `terraform destroy` を実行しましょう。このコマンドは、terraform applyで作成したリソースをすべて削除します。
