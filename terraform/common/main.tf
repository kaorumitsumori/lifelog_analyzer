terraform {
  # FIXME: バックエンドはプロジェクトごとに用意されたバケットを設定してください
  # 初期状態ではコメントアウトされているので、ローカルにtfstateファイルが作成されます

  # backend "s3" {
  #   bucket   = "hogehoge-terraform-backend"
  #   key      = "common/terraform.tfstate"
  #   region   = "ap-northeast-1"
  #   role_arn = "arn:aws:iam::11111111111111111111111:role/terraform-backend-accessor"
  # }
}
provider "aws" {
  region = "ap-northeast-1"
  alias  = "prod"

  # FIXME: プロジェクトごとに用意された作業用ロールを設定してください
  # assume_role {
  #   role_arn = "arn:aws:iam::11111111111111111111111:role/admin"
  # }

  # FIXME: プロジェクトのリポジトリのある場所をManagedByタグに設定してください
  # 全リソースにタグを付けることで同居時に判別性を高めます
  # TUTORIAL:3(インフラ共通項目構築)-1  デプロイ環境をまたぐグローバルなインフラ設定をAWS上に作成します。
  #             ↑の指示に従ってManagedByタグを設定しましょう。 
  #             この設定によって、AWS上のリソースがどのterraform定義から作成されているのかがわかりやすくなります
  # TUTORIAL:3(インフラ共通項目構築)-2 このファイルがあるディレクトリに移動し、 `terraform init` して依存ライブラリをダウンロードしましょう
  # TUTORIAL:3(インフラ共通項目構築)-3 このファイルがあるディレクトリに移動し、 `terraform plan` してインフラの実行計画を確認しましょう
  # TUTORIAL:3(インフラ共通項目構築)-4 このファイルがあるディレクトリに移動し、 `terraform apply` してインフラを構築しましょう
  default_tags {
    tags = {
      ManagedBy = "https://github.com/avilendev/hogehoge/tree/main/terraform"
    }
  }
}

locals {
  _config = yamldecode(file("../config.yml"))
}

# TUTORIAL:5(片付け)-2 こちらも片付けをします。 `terraform destroy` しましょう。
# これで全リソースがAWSから削除されてきれいな状態に戻りました。

# TUTORIAL:5(片付け)-3 ここまでの作業を振り返りましょう。
# - ローカル環境のセットアップ
# - terraformによるインフラ構築
# - github actionsでのデプロイ
# - terraformでのインフラ削除
# の一連の流れを紹介しました
# 練習用に作ったリポジトリは削除してOKです
# サンドボックス以外の環境に適用する場合、 `FIXME:` と書かれた箇所を順に修正することで適用できます(整備中)
# チュートリアルは以上で終わりです。お疲れ様でした！
