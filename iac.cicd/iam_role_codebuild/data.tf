data "aws_iam_policy_document" "role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "policy" {
  dynamic "statement" {
    for_each = local.statements
    content {
      effect    = "Allow"
      actions   = split(",", statement.value.actions)
      resources = split(",", statement.value.resources)
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [data.terraform_remote_state.iam.outputs.arn]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = data.terraform_remote_state.iam.outputs.ips
    }
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = element(keys(var.backend_bucket), 0)
    bucket = var.backend_bucket[element(keys(var.backend_bucket), 0)]
    key    = format(var.backend_pattern, "iam_role_assume")
  }
}
