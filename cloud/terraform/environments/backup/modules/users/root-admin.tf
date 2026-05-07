resource "aws_iam_user" "rootadmin_user" {
  name = "root-admin"
}

resource "aws_iam_user_policy_attachment" "awsbillingreadonly_rootadmin_user_attach" {
  user       = aws_iam_user.rootadmin_user.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBillingReadOnlyAccess"
}

resource "aws_iam_user_policy_attachment" "iamuserchangepassword_rootadmin_user_attach" {
  user       = aws_iam_user.rootadmin_user.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

resource "aws_iam_user_login_profile" "rootadmin_user_login" {
  user                    = aws_iam_user.rootadmin_user.name
  password_reset_required = true
}
