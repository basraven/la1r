# Create an Organizational Unit for "backup"
resource "aws_organizations_organizational_unit" "backup_ou" {
  name      = "backup"
  parent_id = var.target_organization_id
}

# Create a new backup AWS account in the backup OU
resource "aws_organizations_account" "backup_account" {
  name      = "backup"
  email     = "basraven+aws-backup@gmail.com" 
  role_name = "OrganizationAccountAccessRole"
  parent_id = aws_organizations_organizational_unit.backup_ou.id

  lifecycle {
    ignore_changes = [role_name]  # recommended to avoid Terraform wanting to change the default
  }
  depends_on = [ aws_organizations_organizational_unit.backup_ou ]
}

# Define SCP to restrict users to only use the us-east-1 region
resource "aws_organizations_policy" "restrict_regions" {
  name        = "${var.resource_prefix}-RestrictToUSEast1"
  description = "Policy to restrict users to only use the us-east-1 region."

  content = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "DenyAllOutsideUSEast1",
        "Effect": "Deny",
        "Action": "*",
        "Resource": "*",
        "Condition": {
          "StringNotEquals": {
            "aws:RequestedRegion": "us-east-1"
          }
        }
      }
    ]
  })
}

# Attach the SCP to the backup OU
resource "aws_organizations_policy_attachment" "attach_restrict_regions" {
  policy_id = aws_organizations_policy.restrict_regions.id
  target_id = aws_organizations_organizational_unit.backup_ou.id
}