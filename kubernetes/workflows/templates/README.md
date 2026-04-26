# Difference between essential-cloud-backups and cloud-backups:

## essential-cloud-backups:
- Only backs up essential data
- Uses versioned S3 bucket for backup storage
- Cleans up old versions after 15 days
- Runs weekly on Sundays at 12:30 AM

## cloud-backups:
- Backs up all data
- Uses non-versioned S3 bucket for backup storage
- No automatic cleanup of old versions
- Runs daily at 2:00 AM

