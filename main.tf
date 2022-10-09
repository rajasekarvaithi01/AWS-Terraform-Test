provider "aws" {
  region =var.aws_region
}
provider "archive" {}
data "archive_file" "zip" {
  type        = "zip"
  source_file = "welcome.py"
  output_path = "welcome.zip"
}
data "aws_iam_policy_document" "policy" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.policy.json
}
resource "aws_lambda_function" "lambda" {
  function_name = "welcome"
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  role    = aws_iam_role.iam_for_lambda.arn
  handler = "welcome.lambda_handler"
  runtime = "python3.9"
}
resource "aws_dynamodb_table" "someTable" {
  name              = "someTable"
  read_capacity     = 5
  write_capacity    = 5
  hash_key          = "id"
  range_key         = "version"
  stream_enabled    = true
  stream_view_type  = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "version"
    type = "N"
  }
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  batch_size        = 100
  event_source_arn  = "${aws_dynamodb_table.someTable.arn}"
  enabled           = true
  function_name     = "${aws_lambda_function.someFunction.function_name}"
  starting_position = "TRIM_HORIZON"
}
