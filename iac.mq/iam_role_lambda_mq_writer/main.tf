resource "aws_iam_role" "this" {
  count              = data.aws_region.this.name == element(keys(var.backend_bucket), 0) ? 1 : 0
  name               = format("%s-%s", var.q.name, data.terraform_remote_state.s3.outputs.rp2_id)
  description        = var.q.description
  path               = var.q.path
  assume_role_policy = data.aws_iam_policy_document.role.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_policy" "this" {
  count       = data.aws_region.this.name == element(keys(var.backend_bucket), 0) ? 1 : 0
  name        = format("%s-%s", var.q.name, data.terraform_remote_state.s3.outputs.rp2_id)
  description = var.q.description
  policy      = data.aws_iam_policy_document.policy.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = data.aws_region.this.name == element(keys(var.backend_bucket), 0) ? 1 : 0
  role       = element(aws_iam_role.this.*.name, 0)
  policy_arn = element(aws_iam_policy.this.*.arn, 0)
}
