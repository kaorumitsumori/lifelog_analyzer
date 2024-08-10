# FIXME: 適当なドメインのzoneを作成します。
# 実際はAWS管理者からこのzoneに管理権限を委譲してもらう必要があるので、管理者に申請してください。

resource "aws_route53_zone" "prod" {
  provider = aws.prod
  name     = local._config["root_domain"]["prod"]
  comment  = "used for prod environment"
}

output "prod_name_servers" {
  value = aws_route53_zone.prod.name_servers
}

# FIXME: デフォルトで設定されているサンドボックス環境では、avilensandbox.netという
# ドメインが予め用意されています。
# 従って、この場で同時に委譲処理を以下のように定義することができます。
# これはあくまでサンドボックス内でのみ有効な記述であり、実際のドメインを運用する際には以下の記述は削除する必要があります
# 代わりにAWS管理者から委譲してもらってください
data "aws_route53_zone" "sandbox" {
  name = "avilensandbox.net."
}
resource "aws_route53_record" "tmp_ns_delegation" {
  name    = local._config["root_domain"]["prod"]
  type    = "NS"
  zone_id = data.aws_route53_zone.sandbox.zone_id
  ttl     = 300
  records = aws_route53_zone.prod.name_servers
}
