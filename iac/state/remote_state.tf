terraform {
  backend "s3" {
    bucket         = var.bucket_name
    key            = "state/state.tfstate"
    region         = var.region
    profile        = var.profile
    dynamodb_table = var.table_name
    encrypt        = true
  }
}
