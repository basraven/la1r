# Create the IAM user
resource "aws_iam_user" "backup_uploader" {
  name = "backup-uploader"
}

# Create a policy allowing only upload (PutObject) to the specific bucket
resource "aws_iam_policy" "backup_upload_policy" {
  name        = "backup-upload-policy"
  description = "Allow uploading (PutObject) to backup-states and backup-data buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
        ]
        Resource = [
            "${var.backup_data_bucket_arn}/*",
            "${var.backup_versioned_data_bucket_arn}/*"
        ]
      }
    ]
  })
}
# Create a policy allowing only list (ListBucket) to the specific bucket
resource "aws_iam_policy" "backup_list_policy" {
  name        = "backup-list-policy"
  description = "Allow list (ListBucket) to backup-states and backup-data buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
        ]
        Resource = [
            "${var.backup_data_bucket_arn}",
            "${var.backup_versioned_data_bucket_arn}"
        ]
      }
    ]
  })
}
resource "aws_iam_policy" "backup_tag_policy" {
  name        = "backup-tag-policy"
  description = "Allow tag (GetObjectTagging, PutObjectTagging) to backup-states and backup-data buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectTagging",
          "s3:PutObjectTagging",
        ]
        Resource = [
            "${var.backup_data_bucket_arn}/*",
            "${var.backup_versioned_data_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Attach the policy to the user
resource "aws_iam_user_policy_attachment" "attach_backup_upload_policy" {
  user       = aws_iam_user.backup_uploader.name
  policy_arn = aws_iam_policy.backup_upload_policy.arn
}
resource "aws_iam_user_policy_attachment" "backup_list_policy" {
  user       = aws_iam_user.backup_uploader.name
  policy_arn = aws_iam_policy.backup_list_policy.arn
}
resource "aws_iam_user_policy_attachment" "backup_tag_policy" {
  user       = aws_iam_user.backup_uploader.name
  policy_arn = aws_iam_policy.backup_tag_policy.arn
}
