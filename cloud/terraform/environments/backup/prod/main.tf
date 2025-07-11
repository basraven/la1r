provider "aws" {
  region = "us-east-1"
}

# Fetch the AWS organization details
data "aws_organizations_organization" "this" {}


module "organizations" {
  source = "../modules/organizations"
}

module "budget" {
  source = "../../../modules/budget"
  resource_prefix = var.resource_prefix
}
module "s3" {
  source = "../modules/s3"
  resource_prefix = var.resource_prefix
}

module "users" {
  source = "../modules/users"
  backup_versioned_data_bucket_arn = module.s3.backup_versioned_data_bucket_arn
  backup_data_bucket_arn = module.s3.backup_data_bucket_arn
  depends_on = [ module.s3 ]
}