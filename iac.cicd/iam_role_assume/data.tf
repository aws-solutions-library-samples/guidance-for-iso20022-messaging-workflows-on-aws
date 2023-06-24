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
  }
}

data "http" "this" {
  # https://docs.aws.amazon.com/vpc/latest/userguide/aws-ip-ranges.html
  url = "https://ip-ranges.amazonaws.com/ip-ranges.json"
}
