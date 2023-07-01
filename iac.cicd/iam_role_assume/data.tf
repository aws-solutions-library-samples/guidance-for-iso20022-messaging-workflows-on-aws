data "aws_iam_policy_document" "role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", data.aws_caller_identity.this.account_id)]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = local.policy_ips
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [data.aws_caller_identity.this.account_id]
    }
  }
}

data "http" "this" {
  # https://docs.aws.amazon.com/vpc/latest/userguide/aws-ip-ranges.html
  url = "https://ip-ranges.amazonaws.com/ip-ranges.json"
}

data "terraform_remote_state" "iam" {
  count = (
    data.aws_region.this.name == element(keys(var.backend_bucket), 1)
    && data.aws_region.this.name != local.region ? 1 : 0
  )
  backend = "s3"
  config = {
    skip_region_validation = true

    region = element(keys(var.backend_bucket), 0)
    bucket = var.backend_bucket[element(keys(var.backend_bucket), 0)]
    key    = format(var.backend_pattern, "iam_role_assume")
  }
}
