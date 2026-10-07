data "archive_file" "lambda" {
  for_each         = local.lambdas
  type             = "zip"
  source_file      = "${path.module}/../src/${each.key}/app.py"
  output_path      = "${path.module}/build/${each.key}.zip"
  output_file_mode = "0644"
}

resource "aws_cloudwatch_log_group" "lambda" {
  for_each          = local.lambdas
  name              = "/aws/lambda/url-shortener-${each.key}"
  retention_in_days = 7
}

resource "aws_lambda_function" "fn" {
  for_each         = local.lambdas
  function_name    = "url-shortener-${each.key}"
  role             = aws_iam_role.lambda[each.key].arn
  handler          = "app.handler"
  runtime          = "python3.13"
  architectures    = ["arm64"]
  memory_size      = 128
  timeout          = 5
  filename         = data.archive_file.lambda[each.key].output_path
  source_code_hash = data.archive_file.lambda[each.key].output_base64sha256

  environment {
    variables = {
      TABLE_NAME     = aws_dynamodb_table.urls.name
      ALLOWED_ORIGIN = "https://${aws_cloudfront_distribution.web.domain_name}"
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda, aws_iam_role_policy.lambda]
}