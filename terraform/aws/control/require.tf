# Terraform version and plugin versions
terraform {
  required_version = ">= 0.11.7"
}

provider "aws" {
  region = "ap-southeast-2"
  version = "~> 1.29"
}

provider "random" {
	version = "~> 1.3"
}

provider "template" {
  version = "~> 1.0"
}

provider "null" {
  version = "~> 2.0"
}

/*
provider "tls" {
  version = "~> 1.0"
}
*/
