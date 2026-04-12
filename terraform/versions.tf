terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.35.0"
    }
  }

  backend "s3" {
    bucket = "gp-project-s3-cindia"
    key    = "jfrog/terraform.tfstate"
    dynamodb_table = "terraform-lock-table"
    region = "ap-south-1"
    encrypt = true
  }
}