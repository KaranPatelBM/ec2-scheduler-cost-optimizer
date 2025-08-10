output "ec2_instance_id" {
  value = aws_instance.dev_ec2.id
}

output "ec2_public_ip" {
  value = aws_instance.dev_ec2.public_ip
}

output "start_lambda_arn" {
  description = "ARN of the Lambda function that starts the EC2 instance"
  value       = aws_lambda_function.start_ec2.arn
}

output "stop_lambda_arn" {
  description = "ARN of the Lambda function that stops the EC2 instance"
  value       = aws_lambda_function.stop_ec2.arn
}

output "start_schedule_expression" {
  description = "CloudWatch EventBridge schedule expression for starting EC2"
  value       = aws_cloudwatch_event_rule.start_rule.schedule_expression
}

output "stop_schedule_expression" {
  description = "CloudWatch EventBridge schedule expression for stopping EC2"
  value       = aws_cloudwatch_event_rule.stop_rule.schedule_expression
}
