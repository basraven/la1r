provider "aws" {
  region = "us-east-1"
}

# resource "aws_s3_bucket" "example" {
#   bucket = "${var.resource_prefix}-my-example-bucket"
#   tags = {
#     Name = "My example bucket"
#   }
# }


# Fetch the AWS organization details
data "aws_organizations_organization" "this" {}

# data "aws_organizations_organizational_units" "root_ou" {
#   parent_id = data.aws_organizations_organization.this.roots[0].id
# }


module "organizations" {
  source = "../modules/organizations"
  resource_prefix = var.resource_prefix
  target_organization_id = data.aws_organizations_organization.this.roots[0].id
}

module "budget" {
  source = "../../../modules/budget"
  resource_prefix = var.resource_prefix
}
module "users" {
  source = "../modules/users"
}