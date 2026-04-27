# Create the S3 bucket
resource "aws_s3_bucket" "backup_glacier_data" {
  bucket = "${var.resource_prefix}-glacier-backup-data"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "Glacier Backup Data"
  }
}

# Enable versioning with a separate resource
resource "aws_s3_bucket_versioning" "backup_glacier_data_versioning" {
  bucket = aws_s3_bucket.backup_glacier_data.bucket

  versioning_configuration {
    status = "Disabled"
  }
  depends_on = [aws_s3_bucket.backup_glacier_data]
}

# Transition objects to DEEP_ARCHIVE after 1 day
resource "aws_s3_bucket_lifecycle_configuration" "backup_glacier_data_transition" {
  bucket = aws_s3_bucket.backup_glacier_data.bucket

  rule {
    id     = "TransitionToDeepArchive"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 1
      storage_class = "DEEP_ARCHIVE"
    }
  }

  depends_on = [aws_s3_bucket.backup_glacier_data]
}

output "backup_glacier_data_bucket_arn" {
    description = "The ARN of the glacier backup data bucket"
    value       = aws_s3_bucket.backup_glacier_data.arn
}
