# HTTP API Gateway
resource "aws_apigatewayv2_api" "http_api" {
  name          = "example-http-api"
  protocol_type = "HTTP"
}

# Backend Integration via VPC Link
resource "aws_apigatewayv2_integration" "backend_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = data.aws_lb_listener.backend_443.arn
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.api_vpclink.id
  tls_config {
    server_name_to_verify = "backend.${var.domain_name}"
  }
}

# Lambda Authorizer
resource "aws_apigatewayv2_authorizer" "lambda_authorizer" {
  api_id                            = aws_apigatewayv2_api.http_api.id
  authorizer_type                   = "REQUEST"
  name                              = "lambda-authorizer"
  authorizer_uri                    = aws_lambda_function.api_authorizer.invoke_arn
  identity_sources                  = []
  authorizer_payload_format_version = "2.0"
  authorizer_credentials_arn        = aws_iam_role.apigw_authorizer_role.arn
  authorizer_result_ttl_in_seconds  = 0
}

# Default Route with Authorizer
resource "aws_apigatewayv2_route" "default_route_with_authorizer" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.backend_integration.id}"

  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
  depends_on = [
    aws_apigatewayv2_authorizer.lambda_authorizer
  ]
}


# IAM Role for API Gateway Authorizer
resource "aws_iam_role" "apigw_authorizer_role" {
  name = "APIGatewayAuthorizerInvokeLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action = "sts:AssumeRole",
      },
    ],
  })
}

# Policy to allow API Gateway to invoke the Lambda function
resource "aws_iam_policy" "apigw_lambda_invoke_policy" {
  name        = "APIGatewayLambdaInvokePolicy"
  description = "Allows API Gateway Authorizer to invoke the Lambda function"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "lambda:InvokeFunction",
        Resource = aws_lambda_function.api_authorizer.arn,
      },
    ],
  })
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "apigw_lambda_invoke_attachment" {
  role       = aws_iam_role.apigw_authorizer_role.name
  policy_arn = aws_iam_policy.apigw_lambda_invoke_policy.arn
}


