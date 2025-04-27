# Create the S3 bucket
resource "aws_s3_bucket" "backup_states" {
  bucket = "${var.resource_prefix}-backup-states"
  object_lock_enabled = true

  lifecycle {
    prevent_destroy = true
  } 

  tags = {
    Name = "Backup States"
  }
}

# Enable versioning with a separate resource
resource "aws_s3_bucket_versioning" "backup_states_versioning" {
  bucket = aws_s3_bucket.backup_states.bucket

  versioning_configuration {
    status = "Enabled"
  }
  depends_on = [aws_s3_bucket.backup_states]
}

resource "aws_s3_bucket_object_lock_configuration" "backup_states" {
  bucket = aws_s3_bucket.backup_states.bucket

  rule {
    default_retention {
      mode  = "GOVERNANCE"  # or "COMPLIANCE" of not even the bucket owner can delete
      days  = 1            # or use years = X
    }
  }

  depends_on = [aws_s3_bucket.backup_states, aws_s3_bucket_versioning.backup_states_versioning]
}

output "backup_states_bucket_arn" {
    description = "The ARN of the backup states bucket"
    value       = aws_s3_bucket.backup_states.arn
}

