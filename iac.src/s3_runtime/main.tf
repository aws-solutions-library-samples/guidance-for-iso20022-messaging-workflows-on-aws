resource "aws_s3_bucket" "this" {
  #checkov:skip=CKV_AWS_18:This solution implemented access logging as a separate terraform resource
  #checkov:skip=CKV_AWS_21:This solution implemented versioning as a separate terraform resource
  #checkov:skip=CKV_AWS_144:This solution implemented cross region replication as a separate terraform resource
  #checkov:skip=CKV_AWS_145:This solution implemented encryption as a separate terraform resource
  #checkov:skip=CKV2_AWS_6:This solution implemented public access as a separate terraform resource
  #checkov:skip=CKV2_AWS_61:This solution implemented lifecycle as a separate terraform resource
  #checkov:skip=CKV2_AWS_62:This solution implemented events notification as a separate terraform resource

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
  #checkov:skip=CKV_AWS_53:This solution leverages block public ACLs feature as TRUE
  #checkov:skip=CKV_AWS_54:This solution leverages block public policy feature as TRUE
  #checkov:skip=CKV_AWS_55:This solution leverages ignore public ACLs feature as TRUE
  #checkov:skip=CKV_AWS_56:This solution leverages restrict public buckets feature as TRUE

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
