resource "aws_s3_bucket" "this" {
  #checkov:skip=CKV_AWS_18:Checkov issue -- access logging is implemented separate resource
  #checkov:skip=CKV_AWS_21:Checkov issue -- versioning is implemented separate resource
  #checkov:skip=CKV_AWS_144:Checkov issues -- cross region replication is implemented as separate resource
  #checkov:skip=CKV_AWS_145:Checkov issue -- encryption is implemented as separate resource
  #checkov:skip=CKV2_AWS_6:Checkov issue -- public access is implemented as separate resource
  #checkov:skip=CKV2_AWS_61:Checkov issue -- lifecycle is implemented as separate resource
  #checkov:skip=CKV2_AWS_62:Checkov issue -- events notification is implemented as separate resource

  bucket              = format("%s-%s-%s", var.q.bucket, data.aws_region.this.name, local.rp2_id)
  force_destroy       = var.q.force_destroy
  object_lock_enabled = var.q.object_lock_enabled

  lifecycle {
    create_before_destroy = true
  }
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

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.q.block_access
  block_public_policy     = var.q.block_access
  ignore_public_acls      = var.q.block_access
  restrict_public_buckets = var.q.block_access
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.q.object_ownership
  }

  depends_on = [aws_s3_bucket_public_access_block.this]
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = var.q.acl

  depends_on = [aws_s3_bucket_ownership_controls.this]
}
