AWS 上にインフラを構築します

- API サーバ
  - ECS fargate
  - github actions でデプロイする。そのための iam 関連も。
  - API が参照する RDS
    - 暫定で mysql8.0 だが適当に変えて良い
  - これらが乗る VPC
- フロントエンド
  - S3+cloudfront
  - github actions でデプロイする。そのための iam 関連も。

# 使用方法

以下のようなディレクトリ構成になっています

- common: アカウントをまたぐような全体の構成、iam やドメイン周りのグローバルな設定が定義されています。まず最初にこれを apply します。
- env/\*: 環境ごとの設定が定義されています。common を apply した後にこれを apply します。
- modules/_: `env/_` から参照するモジュールです。DRY にしましょう。

従って、 最初に`common/` を apply し、その後に`env/*` を apply します。

初期状態のままで、サンドボックス環境の iam user 権限で apply できるようになっています。

TUTORIAL:1(ローカル環境構築)-5 サンドボックス環境の権限を手に入れましょう。
権限付与を依頼するのは #sys_aws_admin チャンネルです。
AWS 環境については https://www.notion.so/avilen-employee/AWS-c0669cf19611433b985d8c91aa34330a#f895454b218b4527a839dff5ba5ba406 を参照してください。
