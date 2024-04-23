// scrape lambda
resource "aws_lambda_function" "scraper" {
  function_name = "scraper"
  filename         = "../build/libs/ScrapeFunction-1.0-SNAPSHOT.jar"
  source_code_hash = filebase64sha256("../build/libs/ScrapeFunction-1.0-SNAPSHOT.jar")
  handler          = "scrape.Handler::handleRequest"
  runtime          = "java21"
  role             = aws_iam_role.lambda_execution_role.arn
  timeout          = 900 # Function timeout in seconds

  ephemeral_storage {
    size = 10240 # Min 512 MB and the Max 10240 MB
  }
}

resource "aws_cloudwatch_event_rule" "every_ten_minutes" {
  name                = "every-ten-minutes"
  description         = "Trigger Lambda every 10 minutes"
  schedule_expression = "rate(10 minutes)"
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