resource "aws_ecr_repository" "this" {
  #checkov:skip=CKV_AWS_51:This solution leverages mutable ECR repository tags (false positive)
  #checkov:skip=CKV_AWS_136:This solution leverages KMS encryption using AWS managed keys instead of CMKs (false positive)
  #checkov:skip=CKV_AWS_163:This solution leverages scan on push (false positive)

  name                 = format("%s-%s", var.q.name, local.rp2_id)
  image_tag_mutability = var.q.image_tag_mutability

  encryption_configuration {
    encryption_type = var.q.encryption_type
  }

  image_scanning_configuration {
    scan_on_push = var.q.scan_on_push
  }

  lifecycle {
    create_before_destroy = true
  }
}
