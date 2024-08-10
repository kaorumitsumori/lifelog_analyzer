locals {
  # NOTE: 以下の値はsecret managerに格納されます
  # terraformの定義上では値を設定していないので、applyしてsecretを作成したら手動で設定してください
  # terraformで機密情報を管理したくないのでこのようになっています
  app_secrets = [
    # "HOGEHOGE", # これはダミーなので消して良い
    # TUTORIAL:4(インフラ構築)-7 APIコンテナにシークレットを持たせたい場合はここを書き換えてapplyするということを覚えておきましょう
  ]
}

variable "env" {
  type        = string
  description = "環境名"
}

variable "servicename" {
  type        = string
  description = "サービスの識別子。記号なしの英数のみの文字列。"
}

variable "repo_to_allow_access_aws" {
  type        = string
  description = "github actionsからAWSにアクセスを許可するリポジトリ"
}

variable "healthcheck_path" {
  type        = string
  description = "コンテナのヘルスチェックリクエストを送信するpath"
}

variable "container_port" {
  type        = number
  description = "コンテナの開放するポート"
}
variable "container_name" {
  type        = string
  description = "トラフィックをルーティングするコンテナの名前"
}

variable "app_envs" {
  type        = map(string)
  description = "アプリケーションコンテナにわたす環境変数"
}
variable "vpc_cidr" {
  type        = string
  description = "VPCのCIDR。peering用にずらして使う。/16である必要がある"
}

variable "force_expose_private_subnet_for_cost_optimize" {
  type        = bool
  default     = false
  description = "NATを削除してprivate subnetをpublic subnetとして使うかどうか。trueにするとコストが下がるがセキュリティも若干低下する。prod環境では有効にしてはいけない。"
}

variable "domain" {
  type        = string
  description = ""
}

variable "hosted_zone_id" {
  type        = string
  description = "ドメイン設定に使うゾーンのID"
}
