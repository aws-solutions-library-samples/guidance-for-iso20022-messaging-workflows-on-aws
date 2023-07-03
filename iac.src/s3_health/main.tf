resource "aws_s3_bucket" "this" {
  #checkov:skip=CKV_AWS_18:This solution does not require access logging for S3 based health checks (false positive)
  #checkov:skip=CKV_AWS_21:This solution does not require versioning for S3 based health checks (false positive)
  #checkov:skip=CKV_AWS_144:This solution does not require cross region replication for S3 based health checks (false positive)
  #checkov:skip=CKV_AWS_145:This solution does not require encryption for S3 based health checks (false positive)
  #checkov:skip=CKV2_AWS_6:This solution does require public access for S3 based health checks (false positive)
  #checkov:skip=CKV2_AWS_61:This solution does not require lifecycle for S3 based health checks (false positive)
  #checkov:skip=CKV2_AWS_62:This solution does not events notification lifecycle for S3 based health checks (false positive)

  bucket        = format("%s-%s-%s", var.q.bucket, data.aws_region.this.name, local.rp2_id)
  force_destroy = var.q.force_destroy

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_account_public_access_block" "this" {
  #checkov:skip=CKV_AWS_53:This solution leverages block public ACLs feature as TRUE (false positive)
  #checkov:skip=CKV_AWS_54:This solution leverages block public policy feature as TRUE (false positive)
  #checkov:skip=CKV_AWS_55:This solution leverages ignore public ACLs feature as TRUE (false positive)
  #checkov:skip=CKV_AWS_56:This solution leverages restrict public buckets feature as TRUE (false positive)

  block_public_acls       = var.q.block_access
  block_public_policy     = var.q.block_access
  ignore_public_acls      = var.q.block_access
  restrict_public_buckets = var.q.block_access
}

resource "aws_s3_bucket_public_access_block" "this" {
  #checkov:skip=CKV_AWS_53:This solution does require public access for S3 based health checks (false positive)
  #checkov:skip=CKV_AWS_54:This solution does require public access for S3 based health checks (false positive)
  #checkov:skip=CKV_AWS_55:This solution does require public access for S3 based health checks (false positive)
  #checkov:skip=CKV_AWS_56:This solution does require public access for S3 based health checks (false positive)

  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.q.block_access
  block_public_policy     = var.q.block_access
  ignore_public_acls      = var.q.block_access
  restrict_public_buckets = var.q.block_access

  depends_on = [aws_s3_account_public_access_block.this]
}

resource "aws_s3_bucket_policy" "this" {
  count  = var.q.block_access ? 0 : 1
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.q.object_ownership
  }
}

resource "aws_s3_bucket_logging" "this" {
  bucket        = aws_s3_bucket.this.id
  target_bucket = data.terraform_remote_state.s3.outputs.id
  target_prefix = var.q.logs_prefix
}
