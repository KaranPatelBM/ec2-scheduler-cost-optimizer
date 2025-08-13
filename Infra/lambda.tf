# ------------------------
# Lambda Packaging
# ------------------------
data "archive_file" "start_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/start_ec2.py"
  output_path = "${path.module}/../lambda/start_ec2.zip"
}

data "archive_file" "stop_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/stop_ec2.py"
  output_path = "${path.module}/../lambda/stop_ec2.zip"
}

# ------------------------
# IAM Role for Lambda
# ------------------------
resource "aws_iam_role" "lambda_role" {
  name = "ec2-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach policies for EC2 control & basic Lambda logging
resource "aws_iam_role_policy_attachment" "lambda_ec2_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ------------------------
# Lambda Functions
# ------------------------
resource "aws_lambda_function" "start_ec2" {
  filename      = data.archive_file.start_lambda_zip.output_path
  function_name = "start-ec2"
  role          = aws_iam_role.lambda_role.arn
  handler       = "start_ec2.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      INSTANCE_ID = aws_instance.dev_ec2.id
      REGION      = var.aws_region
    }
  }
}

resource "aws_lambda_function" "stop_ec2" {
  filename      = data.archive_file.stop_lambda_zip.output_path
  function_name = "stop-ec2"
  role          = aws_iam_role.lambda_role.arn
  handler       = "stop_ec2.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      INSTANCE_ID = aws_instance.dev_ec2.id
      REGION      = var.aws_region
    }
  }
}
