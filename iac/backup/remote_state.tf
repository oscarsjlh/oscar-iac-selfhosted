terraform {
  backend "s3" {
    bucket         = var.state_bucket_name
    key            = "backup/state.tfstate"
    region         = var.region
    profile        = var.profile
    dynamodb_table = var.table_name
    encrypt        = true
  }
}
