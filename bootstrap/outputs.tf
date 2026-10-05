output "state_bucket" {
  value = aws_s3_bucket.tfstate.bucket
}

output "github_role_arn" {
  value = aws_iam_role.github_actions.arn
}