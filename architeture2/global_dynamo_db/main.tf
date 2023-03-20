data "aws_region" "current" {}

data "aws_region" "alternate" {
  name = "us-west-2"
}

provider "aws" {
  alias  = "main"
  region = "us-east-1"
}

provider "aws" {
    alias = "alternate"
    region = "us-west-2"
}

resource "aws_dynamodb_table" "clients_table" {
  provider = aws.main
  name           = "Clients"
  billing_mode   = "PROVISIONED"
  hash_key       = "ClientId"
  range_key      = "Last_Name"
  read_capacity = 1
  write_capacity = 1
  deletion_protection_enabled = false
  lifecycle {
    ignore_changes = [
      read_capacity, write_capacity, replica
    ]
  }

  attribute {
    name = "ClientId"
    type = "N"
  }

  attribute {
    name = "Last_Name"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  tags = {
    Name        = "dynamodb_table"
    Environment = "production"
  }
}

resource "aws_appautoscaling_target" "dynamodb_table_read_target" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "table/${aws_dynamodb_table.clients_table.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"

}

resource "aws_appautoscaling_policy" "dynamodb_table_read_policy" {
  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.dynamodb_table_read_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_read_target.resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_read_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_read_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = 70
  }

}

resource "aws_appautoscaling_target" "dynamodb_table_write_target" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "table/${aws_dynamodb_table.clients_table.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"

}

resource "aws_appautoscaling_policy" "dynamodb_table_write_policy" {
  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.dynamodb_table_write_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_write_target.resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_write_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_write_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = 70
  }
}

resource "aws_dynamodb_table_replica" "table_replica" {
  # We use depends_on and reference back to the original table ARN to ensure
  # that this resource will be create only after the original table, plus its
  # auto-scaling rules, have already been created
  depends_on = [
    aws_appautoscaling_target.dynamodb_table_read_target,
    aws_appautoscaling_policy.dynamodb_table_read_policy,
    aws_appautoscaling_target.dynamodb_table_write_target,
    aws_appautoscaling_policy.dynamodb_table_write_policy,
  ]
  global_table_arn = aws_dynamodb_table.clients_table.arn

  provider = aws.alternate
}