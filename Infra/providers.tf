terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      "${var.managed_tag_key}" = var.managed_tag_value
    }
  }
}
