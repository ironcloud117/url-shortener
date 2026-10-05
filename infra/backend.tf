terraform {
  backend "s3" {
    bucket       = "url-shortener-tfstate-691588646615"
    key          = "infra/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}