resource "aws_scheduler_schedule" "this" {
  name       = data.terraform_remote_state.lambda.outputs.function_name
  group_name = var.q.group_name

  schedule_expression = var.q.schedule_expression

  flexible_time_window {
    mode = var.q.mode
  }

  target {
    arn      = data.terraform_remote_state.lambda.outputs.arn
    role_arn = data.terraform_remote_state.iam.outputs.arn
  }
}