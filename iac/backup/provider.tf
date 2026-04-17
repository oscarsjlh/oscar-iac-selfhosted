terraform {
  required_providers {
    aws = {
      source  = "opentofu/aws"
      version = "6.40.0"
    }
  }
}

provider "aws" {
  profile = var.profile
  region  = var.region
}
