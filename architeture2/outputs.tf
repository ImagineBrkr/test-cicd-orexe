output "lambda_arn" {
  description = "Deployment invoke url"
  value       = aws_apigatewayv2_stage.lambda.invoke_url
}

output "api_url" {
  description = "Deployment invoke url"
  value     = "${aws_apigatewayv2_stage.lambda.invoke_url}/hello"
}