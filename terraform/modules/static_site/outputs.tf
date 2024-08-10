output "cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.main.arn
}
output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.main.id
}

output "bucket_arn" {
  value = aws_s3_bucket.main.arn
}

output "bucket_name" {
  value = aws_s3_bucket.main.id
}

output "infra_metadata" {
  value = {
    FRONTEND_CI_ROLE_ARN        = module.github_actions_role.role.arn,
    FRONTEND_REGION             = "us-east-1",
    ORIGIN_BUCKETNAME=aws_s3_bucket.main.id
    CLOUDFRONT_DISTRIBUTION_ID=aws_cloudfront_distribution.main.id
  }
}
