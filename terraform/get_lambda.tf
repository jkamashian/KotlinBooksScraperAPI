// get lambda setup
resource "aws_lambda_function" "book_get" {
  function_name = "book_get"
  filename         = var.get_file_path # .JAR path
  source_code_hash = filebase64sha256(var.get_file_path)
  handler          = "get.Handler::handleRequest"
  runtime          = "java21"
  role             = aws_iam_role.lambda_execution_role.arn
  timeout          = 900 # Function timeout in seconds
  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids         = [aws_subnet.private_2.id]
  }
  # switch to AWS Secrets Manager
  environment {
    variables = {
      DB_HOST = aws_db_instance.librarian.address
      DB_USER = var.db_username
      DB_PASS = var.db_password
    }
  }
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.book_get.function_name
  principal     = "apigateway.amazonaws.com"

  # Important to restrict source ARN to API Gateway ARN
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}



// gateway setup
resource "aws_api_gateway_rest_api" "api" {
  name        = "BookScrapeAPI"
  description = "API Gateway for Kotlin Lambda Function"
}

resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "list"
}

resource "aws_api_gateway_method" "api_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.api_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.book_get.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.api_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "test"
}


output "base_url" {
  value = aws_api_gateway_deployment.api_deployment.invoke_url
}


output "lambda_function_name" {
  value = aws_lambda_function.book_get.function_name
}

output "api_gateway_invoke_url" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url} "
}