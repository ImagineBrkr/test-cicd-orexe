provider "aws" {
  region      = "us-east-1"
}

# resource "aws_lambda_function" "hello-terraform" {
#     filename = "${local.building_path}/${local.lambda_code_filename}"
#     handler = "lambda_function.lambda_handler"
#     runtime = "python3.9"
#     function_name = "hello_function"
#     role = aws_iam_role.iam_for_lambda.arn
#     timeout = 30
# }

//Creates lambda function
module "hello_function" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "4.6.0"
  create_role   = false 
  timeout       = 30
  create_package         = false
  local_existing_package = "${local.building_path}/${local.lambda_code_filename}"
  function_name = "hello_function"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  lambda_role   = aws_iam_role.iam_for_lambda.arn
  attach_cloudwatch_logs_policy = false
  attach_dead_letter_policy     = false
  attach_network_policy         = false
  attach_tracing_policy         = false
  attach_async_event_policy     = false

}

//IAM Role policy for lambda function
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda_usage"

  assume_role_policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
        }
    ]
    }
    EOF
}

//Creating api gateway
resource "aws_apigatewayv2_api" "lambda" {
  name          = "lambda_api_service"
  protocol_type = "HTTP"
}

//Creating stage
resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id
  name        = "prod"
  auto_deploy = true

}

//Integrating lambda function with api
resource "aws_apigatewayv2_integration" "get_hello_function" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = module.hello_function.lambda_function_invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

//Route
resource "aws_apigatewayv2_route" "hello_function" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.get_hello_function.id}"
}

//Giving permission for invoking lambda function
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.hello_function.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}