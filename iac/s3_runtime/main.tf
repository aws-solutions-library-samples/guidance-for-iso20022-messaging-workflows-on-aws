resource "aws_s3_bucket" "this" {
  #checkov:skip=CKV_AWS_18:Checkov issue -- access logging is implemented separate resource
  #checkov:skip=CKV_AWS_21:Checkov issue -- versioning is implemented separate resource
  #checkov:skip=CKV_AWS_144:Checkov issues -- cross region replication is implemented as separate resource
  #checkov:skip=CKV_AWS_145:Checkov issue -- encryption is implemented as separate resource
  #checkov:skip=CKV2_AWS_6:Checkov issue -- public access is implemented as separate resource
  #checkov:skip=CKV2_AWS_61:Checkov issue -- lifecycle is implemented as separate resource
  #checkov:skip=CKV2_AWS_62:Checkov issue -- events notification is implemented as separate resource

  bucket              = format("%s-%s", var.q.bucket, data.aws_region.this.name)
  force_destroy       = var.q.force_destroy
  object_lock_enabled = var.q.object_lock_enabled

  lifecycle {
    create_before_destroy = true
  }
}
