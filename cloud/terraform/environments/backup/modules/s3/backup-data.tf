# Create the S3 bucket
resource "aws_s3_bucket" "backup_data" {
  bucket = "${var.resource_prefix}-backup-data"
  object_lock_enabled = true

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

resource "aws_s3_bucket_object_lock_configuration" "backup_data" {
  bucket = aws_s3_bucket.backup_data.bucket

  rule {
    default_retention {
      mode  = "GOVERNANCE"  # or "COMPLIANCE" of not even the bucket owner can delete
      days  = 3            # or use years = X
    }
  }

  depends_on = [aws_s3_bucket.backup_data, aws_s3_bucket_versioning.backup_data_versioning]
}

output "backup_data_bucket_arn" {
    description = "The ARN of the backup data bucket"
    value       = aws_s3_bucket.backup_data.arn
}

