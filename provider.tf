terraform {
  backend "s3" {
    encrypt = true   
    bucket = "eks-project-s3-bucket"
    dynamodb_table = "s3-lock-table"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}