/**
 * 標準的な public/private サブネットに分割された VPC 構成を定義している
 * - デフォルト VPC は使わない(手動で削除してOK)
 * - VPC はenv毎に作成し `10.0.0.0/16` とする
 * - private subnet を `10.0.0.0` から `/20` で各 AZ に作成する
 * - public subnet を `10.0.128.0` から `/24` で各 AZ に作成する
 *   - `/24` とした理由は、public subnetに大量のリソースを置くことは少なく、一般的にはこれで十分であることから。
 *   - `10.0.128.0` とした理由は、将来private subnetを拡張するときに連番で取れるようにスペースを開けておくため。
 */

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name            = "${var.env}-${var.servicename}"
  cidr            = var.vpc_cidr
  azs             = data.aws_availability_zones.available.names
  private_subnets = [for i, region in data.aws_availability_zones.available.names : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i, region in data.aws_availability_zones.available.names : cidrsubnet(cidrsubnet(var.vpc_cidr, 4, 8), 4, i)]

  map_public_ip_on_launch = false # 安全のため自動アサインを無効化
  enable_nat_gateway      = var.force_expose_private_subnet_for_cost_optimize ? false : true
  single_nat_gateway      = true
  enable_dns_hostnames    = true
  enable_ipv6             = false # NOTE: 今は必要ないので無効化している。将来的に有効化するかも？

  # 使用しないが、tagの付与等のために一応管理対象にはしておく
  manage_default_route_table = true

  # 安全のため、default security groupから全routeを削除する。
  manage_default_security_group  = true
  default_security_group_egress  = []
  default_security_group_ingress = []
}

# NOTE: NATのコスト削減のため、private subnetにigwをつけてpublic化する。
# タスク起動時にインターネットアクセスは必要
resource "aws_route" "expose_private_subnet" {
  for_each               = var.force_expose_private_subnet_for_cost_optimize ? toset(module.vpc.private_route_table_ids) : []
  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.vpc.igw_id
}
