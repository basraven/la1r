# Create the S3 bucket
resource "aws_s3_bucket" "backup_data" {
  bucket = "${var.resource_prefix}-backup-data"

  lifecycle {
    prevent_destroy = true
  } 

  tags = {
    Name = "Backup Data"
  }
}

# Enable versioning with a separate resource
resource "aws_s3_bucket_versioning" "backup_data_versioning" {
  bucket = aws_s3_bucket.backup_data.bucket

  versioning_configuration {
    status = "Disabled"
  }
  depends_on = [aws_s3_bucket.backup_data]
}

output "backup_data_bucket_arn" {
    description = "The ARN of the backup data bucket"
    value       = aws_s3_bucket.backup_data.arn
}

