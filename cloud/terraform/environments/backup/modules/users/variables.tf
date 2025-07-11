# Define a variable for the S3 backup states bucket ARN
variable "backup_versioned_data_bucket_arn" {
  description = "The ARN of the versioned backup bucket"
  type        = string
}

# Define a variable for the S3 backup data bucket ARN
variable "backup_data_bucket_arn" {
  description = "The ARN of the backup data bucket"
  type        = string
}