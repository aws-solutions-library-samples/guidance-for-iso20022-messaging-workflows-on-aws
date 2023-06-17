resource "aws_ecr_repository" "this" {
  #checkov:skip=CKV_AWS_51:Checkov issue -- cannot read value from default.tfvars
  #checkov:skip=CKV_AWS_136:Checkov issue -- cannot read value from default.tfvars
  #checkov:skip=CKV_AWS_163:Checkov issue -- cannot read value from default.tfvars

  name                 = var.q.name
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
