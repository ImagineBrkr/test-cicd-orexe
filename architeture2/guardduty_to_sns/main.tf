resource "aws_guardduty_detector" "new_detector" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }
}

resource "aws_cloudwatch_event_bus" "guardduty_event_bus" {
  name = "guardduty_event_bus"
}

resource "aws_cloudwatch_event_rule" "guardduty_detects_event" {
  name        = "capture_guardduty_event"
  description = "It activates when guardduty detects an event"

  event_pattern = jsonencode({
    detail-type = ["GuardDuty Finding"],
    source = ["aws.guardduty", "mock_guarduty"],
    detail= {severity = [{ "numeric": [ ">", 0, "<=", 5 ] } ] }
    #
  })
  event_bus_name = aws_cloudwatch_event_bus.guardduty_event_bus.name
  is_enabled = true

}

#Sends 
resource "aws_cloudwatch_event_target" "send_to_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_detects_event.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.aws_guardduty_detected_event.arn
  event_bus_name = aws_cloudwatch_event_bus.guardduty_event_bus.name
  input_transformer {
    input_paths = {
        severity = "$.detail.severity",
        Account_ID = "$.detail.accountId",
        Finding_ID = "$.detail.id",
        Finding_Type = "$.detail.type",
        region = "$.region",
        Finding_description = "$.detail.description"
    }
    input_template = "\"AWS <Account_ID> has a severity <severity> GuardDuty finding type <Finding_Type> in the <region> region. Finding Description: <Finding_description>. For more details open the GuardDuty console at https://console.aws.amazon.com/guardduty/home?region=<region>#/findings?search=id%3D<Finding_ID>\""   

# Finding Description:
# <Finding_description>. 
# For more details open the GuardDuty console at https://console.aws.amazon.com/guardduty/home?region=<region>#/findings?search=id%3D<Finding_ID>\"
#                 EOF             
  }
}
    # "\"AWS <Account_ID> has a severity <severity> GuardDuty finding type <Finding_Type> in the <region> region.\nFinding Description:\n<Finding_description>.\nFor more details open the GuardDuty console at https://console.aws.amazon.com/guardduty/home?region=<region>#/findings?search=id%3D<Finding_ID>\""
    #
#Topic where the message will be published
resource "aws_sns_topic" "aws_guardduty_detected_event" {
  name = "aws_guardduty_detected_event"
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.aws_guardduty_detected_event.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.aws_guardduty_detected_event.arn]
  }
}

#Topic subscription for sending email
resource "aws_sns_topic_subscription" "send_email_guardduty" {
  topic_arn = aws_sns_topic.aws_guardduty_detected_event.arn
  protocol  = "email"
  endpoint  = "salvattore_25@hotmail.com"
}

#Sending fake data
resource "aws_cloudwatch_event_rule" "mock_guardduty_data" {
  name        = "mock_guardduty_data"
  description = "Sending mock GuardDuty data"

  schedule_expression = "rate(2 minutes)"
  #event_bus_name = default
  is_enabled = true
}

resource "aws_cloudwatch_event_target" "send_mock_data" {
  target_id = "send_mock_data"
  rule      = aws_cloudwatch_event_rule.mock_guardduty_data.name
  arn       = aws_lambda_function.mock_data_function.arn
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

### ROLE AND POLICY FOR INVOKING EVENT BUS
# resource "aws_iam_role" "lambda_put_event_guardduty" {
#   name               = "event-bus-invoke-remote-event-bus"
#   assume_role_policy = data.aws_iam_policy_document.assume_role.json
# }

data "aws_iam_policy_document" "lambda_put_event_guardduty" {
  statement {
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = [aws_cloudwatch_event_bus.guardduty_event_bus.arn]
  }
}

resource "aws_iam_policy" "lambda_put_event_guardduty" {
  name   = "lambda_put_event_guardduty"
  policy = data.aws_iam_policy_document.lambda_put_event_guardduty.json
}

resource "aws_iam_role_policy_attachment" "lambda_put_event_guardduty" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_put_event_guardduty.arn
}


resource "aws_lambda_function" "mock_data_function" {
    filename = "${local.building_path}/${local.lambda_code_filename}"
    handler = "lambda_mock.lambda_handler"
    runtime = "python3.9"
    function_name = "mock_data_function"
    role = aws_iam_role.iam_for_lambda.arn
    timeout = 30
    # depends_on = [
    #   null_resource.build_lambda_function
    # ]
}

# resource "null_resource" "build_lambda_function" {

#     provisioner "local-exec" {
#         command =  "powershell.exe -File .\\PyBuild.ps1 ${local.lambda_src_path} ${local.building_path} ${local.lambda_code_filename} Function"
#     }
# }


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
            "Service": ["lambda.amazonaws.com",
                        "events.amazonaws.com"]
        },
        "Effect": "Allow",
        "Sid": ""
        }
    ]
    }
    EOF
}

//Giving permission for invoking lambda function
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mock_data_function.function_name
  principal     = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.mock_guardduty_data.arn
}