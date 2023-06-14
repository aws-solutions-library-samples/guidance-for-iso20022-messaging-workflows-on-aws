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

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_s3_object" "this" {
#   bucket  = aws_s3_bucket.this.id
#   key     = var.q.object_name
#   content = tostring(var.q.object_lock_enabled)
# }

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
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

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json

  depends_on = [aws_s3_bucket_acl.this]
}

resource "aws_s3_bucket_logging" "this" {
  bucket        = aws_s3_bucket.this.id
  target_bucket = data.terraform_remote_state.s3.outputs.id
  target_prefix = var.q.logs_prefix
}
