# Create IAM user
resource "aws_iam_user" "readonly_user" {
  name = "read-only"
}

# Allow password change
resource "aws_iam_user_policy_attachment" "iamuserchangepassword_readonly_user_attach" {
  user       = aws_iam_user.readonly_user.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

# Attach the AWS managed ReadOnlyAccess policy
resource "aws_iam_user_policy_attachment" "readonly_user_attach" {
  user       = aws_iam_user.readonly_user.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Attach the AWS managed AwsBillingReadOnlyAccess policy
# (Needs to be manually activated in the console by root user)
resource "aws_iam_user_policy_attachment" "awsbillingreadonly_readonly_user_attach" {
  user       = aws_iam_user.readonly_user.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBillingReadOnlyAccess"
}

# Give AWS Console access
resource "aws_iam_user_login_profile" "readonly_user_login" {
    user    = aws_iam_user.readonly_user.name
    password_reset_required = true
}