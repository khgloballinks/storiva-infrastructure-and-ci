terraform {
  backend "s3" {
    bucket         = "storiva-tfstate"
    key            = "prod/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    dynamodb_table = "storiva-tfstate-lock"
  }
}