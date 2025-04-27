# Define a variable for the S3 backup states bucket ARN
variable "backup_states_bucket_arn" {
  description = "The ARN of the backup states bucket"
  type        = string
}

# Define a variable for the S3 backup data bucket ARN
variable "backup_data_bucket_arn" {
  description = "The ARN of the backup data bucket"
  type        = string
}