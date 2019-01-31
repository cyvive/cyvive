# Terraform version and plugin versions
terraform {
  required_version = ">= 0.11.7"
}

provider "aws" {
  region = "ap-southeast-2"
  version = "~> 1.29"
}

provider "external" {
  version = "~> 1.0.0"
}

