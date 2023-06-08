data "aws_iam_policy_document" "this" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = [format("%s/%s", data.terraform_remote_state.s3.outputs.arn, data.terraform_remote_state.cf.outputs.default_object)]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [data.terraform_remote_state.cf.outputs.arn]
    }
  }
}

data "terraform_remote_state" "cf" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "cloudfront_runtime")
  }
}

data "terraform_remote_state" "s3" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "s3_runtime")
  }
}
