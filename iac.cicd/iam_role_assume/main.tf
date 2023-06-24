resource "aws_iam_role" "this" {
  count              = data.aws_region.this.name == element(keys(var.backend_bucket), 0) ? 1 : 0
  name               = var.q.name
  description        = var.q.description
  path               = var.q.path
  assume_role_policy = data.aws_iam_policy_document.role.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = data.aws_region.this.name == element(keys(var.backend_bucket), 0) ? length(local.policy_arns) : 0
  role       = element(aws_iam_role.this.*.name, 0)
  policy_arn = element(local.policy_arns, count.index)
}
