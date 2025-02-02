variable "state_bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  type        = string
}

variable "backup_bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  type        = string
}
variable "table_name" {
  type = string
}
variable "profile" {
  type = string
}
variable "region" {
  type = string
}
