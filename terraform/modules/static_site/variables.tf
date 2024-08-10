variable "env" {
  type = string
}

variable "servicename" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "app_domain" {
  type = string
}
variable "hosted_zone_id" {
  type = string
}

variable "basicauth_user" {
  type    = string
  default = ""
}
variable "basicauth_password" {
  type    = string
  default = ""
}

variable "repo_to_allow_access_aws" {
  type        = string
  description = "github actionsからAWSにアクセスを許可するリポジトリ"
}
