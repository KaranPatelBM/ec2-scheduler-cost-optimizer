# ------------------------
# EventBridge Rules
# ------------------------
resource "aws_cloudwatch_event_rule" "start_rule" {
  name                = "start-ec2-schedule"
  schedule_expression = var.workday_start_time_cron
}

resource "aws_cloudwatch_event_rule" "stop_rule" {
  name                = "stop-ec2-schedule"
  schedule_expression = var.workday_end_time_cron
}

# ------------------------
# Event Targets
# ------------------------
resource "aws_cloudwatch_event_target" "start_target" {
  rule      = aws_cloudwatch_event_rule.start_rule.name
  target_id = "startEC2"
  arn       = aws_lambda_function.start_ec2.arn
}

resource "aws_cloudwatch_event_target" "stop_target" {
  rule      = aws_cloudwatch_event_rule.stop_rule.name
  target_id = "stopEC2"
  arn       = aws_lambda_function.stop_ec2.arn
}

# ------------------------
# Lambda Permissions
# ------------------------
resource "aws_lambda_permission" "allow_start_event" {
  statement_id  = "AllowStartEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_ec2.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_rule.arn
}

resource "aws_lambda_permission" "allow_stop_event" {
  statement_id  = "AllowStopEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_ec2.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_rule.arn
}
