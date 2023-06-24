locals {
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
      actions = "s3:GetBucketAcl,s3:GetBucketLocation"
      resources = format(
        "arn:aws:s3:::%s,arn:aws:s3:::%s",
        values(var.backend_bucket)[0], values(var.backend_bucket)[1]
      )
    },
    {
      actions = "s3:GetObject,s3:GetObjectVersion,s3:PutObject"
      resources = format(
        "arn:aws:s3:::%s/*,arn:aws:s3:::%s/*",
        values(var.backend_bucket)[0], values(var.backend_bucket)[1]
      )
    },
  ]
}
