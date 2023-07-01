resource "aws_iam_role" "this" {
  name               = format("%s-%s-%s", var.q.name, data.aws_region.this.name, local.rp2_id)
  description        = var.q.description
  path               = var.q.path
  assume_role_policy = data.aws_iam_policy_document.role.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = length(local.policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = element(local.policy_arns, count.index)
}

resource "random_id" "this" {
  byte_length = 4

  keepers = {
    custom_domain = var.custom_domain
  }

  lifecycle {
    create_before_destroy = true
  }
}
