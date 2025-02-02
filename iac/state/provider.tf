terraform {
  required_providers {
    aws = {
      source  = "opentofu/aws"
      version = "5.84.0"
    }
  }
}

provider "aws" {
  profile = var.profile
  region  = var.region
}
