/**
 * cloudfrontの設定
 * - s3をoriginにして配信している
 * - アクセスログを有効にしている
 * - gzip圧縮を有効にしている
 * - httpをhttpsにリダイレクトしている
 */

resource "random_password" "referer_secret" {
  length           = 16
  special          = true
}
resource "aws_cloudfront_distribution" "main" {
  comment             = "${var.servicename} static site hosting(${var.app_domain})"
  price_class         = "PriceClass_All" # とりあえず全エッジロケーションを使う
  enabled             = true
  is_ipv6_enabled     = true
  aliases             = [var.app_domain]
  wait_for_deployment = true # terraform apply時にデプロイ完了を待つ
  origin {
    connection_attempts = 3
    connection_timeout  = 10
    domain_name         = aws_s3_bucket_website_configuration.main.website_endpoint
    origin_id           = aws_s3_bucket_website_configuration.main.website_endpoint
    custom_header {
      name  = "Referer"
      value = random_password.referer_secret.result
    }

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols = [
        "TLSv1",
        "TLSv1.1",
        "TLSv1.2",
      ]
    }
  }

  # NOTE: とりあえずロギング
  logging_config {
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "${var.env}-static-site"
    include_cookies = false # NOTE: cookie使わないのでとりあえずfalse
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true                # gzip圧縮を有効にしてる
    viewer_protocol_policy = "redirect-to-https" # NOTE: httpリダイレクトを有効にしてる
    target_origin_id       = aws_s3_bucket_website_configuration.main.website_endpoint
    cache_policy_id        = data.aws_cloudfront_cache_policy.managed_caching_optimized.id

    dynamic "function_association" {
      for_each = var.basicauth_user != "" ? ["dummy"] : []
      content {
        event_type   = "viewer-request"
        function_arn = aws_cloudfront_function.basic_auth[0].arn
      }
    }
  }

  # NOTE: 地理的制限は必要ないので無し
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # NOTE: https設定
  viewer_certificate {
    acm_certificate_arn      = module.acm.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  # SPAなので/以外のpathへのアクセスを/にリダイレクトする必要があるので、その設定
  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 404
    response_code         = 200
    response_page_path    = "/"
  }
}

resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "${var.servicename} for ${var.env}"
}

# NOTE: これがS3配信の推奨設定らしい
data "aws_cloudfront_cache_policy" "managed_caching_optimized" {
  name = "Managed-CachingOptimized"
}


/**
 * cloudfrontのログ配信用バケットの設定
 */
resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${var.bucket_name}-logs"
  force_destroy = true  # FIXME: チュートリアル用にtrueにしています。実運用の際はfalseにしてください。
}
resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    // ACLを有効化する
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_acl" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  access_control_policy {
    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    # NOTE: https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html#AccessLogsBucketAndFileOwnership
    # CloudFrontログ配信ユーザのID
    grant {
      grantee {
        id   = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }
}
data "aws_canonical_user_id" "current" {}

# 暫定basic認証
resource "aws_cloudfront_function" "basic_auth" {
  count   = var.basicauth_user != "" ? 1 : 0
  name    = "${var.servicename}-${var.env}-basic_auth"
  runtime = "cloudfront-js-1.0"
  comment = "basic_auth"
  publish = true
  code = templatefile(
    "${path.module}/functions/basicauth.js.tftpl",
    {
      username = var.basicauth_user,
      password = var.basicauth_password,
    }
  )
}
