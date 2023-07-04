data "aws_iam_policy_document" "role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "policy" {
  #checkov:skip=CKV_AWS_109:This solution defines IAM policies have constrains with conditions in place (false positive)

  dynamic "statement" {
    for_each = local.statements
    content {
      effect    = "Allow"
      actions   = split(",", statement.value.actions)
      resources = split(",", statement.value.resources)
    }
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
