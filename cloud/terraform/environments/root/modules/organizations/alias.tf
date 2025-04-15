#  Create an alias for the AWS account
resource "aws_iam_account_alias" "account_alias" {
  account_alias = "la1r-root"
}