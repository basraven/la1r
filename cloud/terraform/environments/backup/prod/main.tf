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
module "users" {
  source = "../modules/users"
}