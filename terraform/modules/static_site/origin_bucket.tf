/**
 * 静的配信用s3バケット
 * - cloudfrontからのアクセスのみ許可
 * - ここへのデプロイはgithub actionsで行う。.github/以下を参照
 */

resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name
  force_destroy = true # FIXME: チュートリアル用にtrueにしています。実運用の際はfalseにしてください。
}
resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404/index.html"
  }
}

# 全アクセスを許可
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicReadGetObject",
        "Action" : "s3:GetObject",
        "Effect" : "Allow",
        "Principal" : "*",
        "Resource" : "${aws_s3_bucket.main.arn}/*",
        "Condition" : {
          "StringLike" : {
            "aws:Referer" : random_password.referer_secret.result
          }
        }
      },
    ]
  })
}

# 公開する
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

