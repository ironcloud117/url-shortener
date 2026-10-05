resource "aws_dynamodb_table" "urls" {
  name         = "url-shortener-urls"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "short_code"

  attribute {
    name = "short_code"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}