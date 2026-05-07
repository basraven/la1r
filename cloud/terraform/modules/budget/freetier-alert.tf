
resource "aws_sns_topic" "budget_alert" {
  name = "budget-alert-topic"
}

data "aws_iam_policy_document" "budget_alert_sns" {
  statement {
    sid    = "AllowBudgetToPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.budget_alert.arn]
  }
}

resource "aws_sns_topic_policy" "budget_alert" {
  arn    = aws_sns_topic.budget_alert.arn
  policy = data.aws_iam_policy_document.budget_alert_sns.json
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.budget_alert.arn
  protocol  = "email"
  endpoint  = "basraven+aws-budget@gmail.com" # Replace with your actual email
}

resource "aws_budgets_budget" "free_tier_budget" {
  name         = "FreeTierBudget"
  budget_type  = "COST"
  limit_amount = "0.01"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 0.01
    threshold_type            = "ABSOLUTE_VALUE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_alert.arn]
  }
}

resource "aws_budgets_budget" "predicted_cost_2" {
  name         = "PredictedCostAlert-2USD"
  budget_type  = "COST"
  limit_amount = "2"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 2
    threshold_type            = "ABSOLUTE_VALUE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_alert.arn]
  }
}

resource "aws_budgets_budget" "predicted_cost_5" {
  name         = "PredictedCostAlert-5USD"
  budget_type  = "COST"
  limit_amount = "5"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 5
    threshold_type            = "ABSOLUTE_VALUE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_alert.arn]
  }
}

resource "aws_budgets_budget" "predicted_cost_10" {
  name         = "PredictedCostAlert-10USD"
  budget_type  = "COST"
  limit_amount = "10"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 10
    threshold_type            = "ABSOLUTE_VALUE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_alert.arn]
  }
}