data "aws_iam_policy_document" "this" {
  #checkov:skip=CKV_AWS_283:Defined S3 policy have constrains with conditions in place

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = [format("%s/%s-*.%s", aws_s3_bucket.this.arn, var.q.object_name, var.q.object_ext)]

    principals {
      type        = "AWS"
      identifiers = ["*"]
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
