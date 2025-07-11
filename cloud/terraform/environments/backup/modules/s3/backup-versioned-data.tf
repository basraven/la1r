# Create the S3 bucket
resource "aws_s3_bucket" "backup_versioned_data" {
  bucket = "${var.resource_prefix}-versioned-backup-data"
  object_lock_enabled = true

  lifecycle {
    prevent_destroy = true
  } 

  tags = {
    Name = "Versioned Backup Data"
  }
}

# Enable versioning with a separate resource
resource "aws_s3_bucket_versioning" "backup_versioned_data_versioning" {
  bucket = aws_s3_bucket.backup_versioned_data.bucket

  versioning_configuration {
    status = "Enabled"
  }
  depends_on = [aws_s3_bucket.backup_versioned_data]
}

resource "aws_s3_bucket_object_lock_configuration" "backup_versioned_data" {
  bucket = aws_s3_bucket.backup_versioned_data.bucket

  rule {
    default_retention {
      mode  = "GOVERNANCE"  # or "COMPLIANCE" of not even the bucket owner can delete
      days  = 3            # or use years = X
    }
  }

  depends_on = [aws_s3_bucket.backup_versioned_data, aws_s3_bucket_versioning.backup_versioned_data_versioning]
}

# Remove old versions of objects after 15 days
resource "aws_s3_bucket_lifecycle_configuration" "backup_versioned_data_cleanup" {
  bucket = aws_s3_bucket.backup_versioned_data.bucket

  rule {
    id     = "ExpireOldVersions"
    status = "Enabled"

    filter {
      prefix = ""
    }   # <-- empty filter means "apply to all objects"

    noncurrent_version_expiration {
      noncurrent_days = 15
    }
  }

  depends_on = [aws_s3_bucket_object_lock_configuration.backup_versioned_data]
}

output "backup_versioned_data_bucket_arn" {
    description = "The ARN of the versioned backup data bucket"
    value       = aws_s3_bucket.backup_versioned_data.arn
}

