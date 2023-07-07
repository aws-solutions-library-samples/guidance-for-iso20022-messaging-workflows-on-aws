resource "aws_wafv2_web_acl" "this" {
  name  = var.q.name
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = var.q.metric_name
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = data.terraform_remote_state.apigw.outputs.stage_arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
