locals {
  rp2_id = (var.rp2_id == null ? data.terraform_remote_state.iam.outputs.rp2_id : var.rp2_id)
  statements = [
    {
      actions = "codebuild:CreateReportGroup,codebuild:CreateReport,codebuild:UpdateReport,codebuild:BatchPutTestCases,codebuild:BatchPutCodeCoverages"
      resources = format(
        "arn:aws:codebuild:*:%s:report-group/rp2-*",
        data.aws_caller_identity.this.account_id
      )
    },
    {
      actions = "logs:CreateLogGroup,logs:CreateLogStream,logs:PutLogEvents"
      resources = format(
        "arn:aws:logs:*:%s:log-group:/aws/codebuild/rp2-*",
        data.aws_caller_identity.this.account_id
      )
    },
    {
      actions = "s3:GetBucket*,s3:ListBucket*"
      resources = format(
        "arn:aws:s3:::%s",
        var.backend_bucket[data.aws_region.this.name]
      )
    },
    {
      actions = "s3:GetObject*,s3:PutObject*"
      resources = format(
        "arn:aws:s3:::%s/*",
        var.backend_bucket[data.aws_region.this.name]
      )
    },
  ]
}
