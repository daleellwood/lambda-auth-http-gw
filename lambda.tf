resource "aws_iam_role" "lambda_role" {
  name = "api-authorizer-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "api_authorizer_zip" {
  type        = "zip"
  source_file = "lambda_authorizer.py"
  output_path = "lambda-authorizer.zip"
}

resource "aws_lambda_function" "api_authorizer" {
  function_name = "api-authorizer"
  filename      = data.archive_file.api_authorizer_zip.output_path
  handler       = "lambda_authorizer.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      IP_RANGE = jsonencode(local.combined_ip_whitelist)
    }
  }
}

