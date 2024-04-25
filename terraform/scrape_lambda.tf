// scrape lambda
resource "aws_lambda_function" "scraper" {
  function_name = "scraper"
  filename         = var.scraper_file_path
  source_code_hash = filebase64sha256(var.scraper_file_path)
  handler          = "scrape.Handler::handleRequest"
  runtime          = "java21"
  role             = aws_iam_role.lambda_execution_role.arn
  timeout          = 900 # Function timeout in seconds
  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids         = [aws_subnet.private_1.id]
  }
  environment {
    variables = {
      DB_HOST = aws_db_instance.librarian.address
      DB_USER = var.db_username
      DB_PASS = var.db_password
    }
  }
}

resource "aws_cloudwatch_event_rule" "every_ten_minutes" {
  name                = "every-ten-minutes"
  description         = "Trigger Lambda every 10 minutes"
  schedule_expression = "cron(0 0 1 1 ? *)"  # We don't need to run it every 10 minutes, this is just a demo!
  //schedule_expression = "rate(10 minutes)"
}

resource "aws_cloudwatch_event_target" "invoke_lambda_every_ten_minutes" {
  rule      = aws_cloudwatch_event_rule.every_ten_minutes.name
  target_id = "TriggerLambdaEvery10Minutes"
  arn       = aws_lambda_function.scraper.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_scraper" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scraper.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_ten_minutes.arn
}