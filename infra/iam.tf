data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  lambdas = {
    create   = ["dynamodb:PutItem"]
    redirect = ["dynamodb:GetItem"]
  }
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  for_each           = local.lambdas
  name               = "url-shortener-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda" {
  for_each = local.lambdas

  statement {
    sid       = "DynamoDB"
    actions   = each.value
    resources = [aws_dynamodb_table.urls.arn]
  }

  statement {
    sid     = "Logs"
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/url-shortener-${each.key}:*"
    ]
  }
}

resource "aws_iam_role_policy" "lambda" {
  for_each = local.lambdas
  name     = "url-shortener-${each.key}"
  role     = aws_iam_role.lambda[each.key].id
  policy   = data.aws_iam_policy_document.lambda[each.key].json
}