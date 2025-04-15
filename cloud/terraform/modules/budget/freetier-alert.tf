
resource "aws_sns_topic" "budget_alert" {
  name = "budget-alert-topic"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.budget_alert.arn
  protocol  = "email"
  endpoint  = "basraven+aws-budget@gmail.com"  # Replace with your actual email
}

resource "aws_budgets_budget" "free_tier_budget" {
  name              = "FreeTierBudget"
  budget_type       = "COST"
  limit_amount      = "0.01"      # Alert if cost goes over $0.01
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 0.01
    threshold_type             = "ABSOLUTE_VALUE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alert.arn]
  }
}