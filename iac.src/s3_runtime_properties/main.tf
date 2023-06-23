resource "aws_s3_bucket_versioning" "this" {
  bucket = data.terraform_remote_state.s3.outputs.id
  versioning_configuration {
    status = var.q.versioning_status
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = data.terraform_remote_state.s3.outputs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.q.sse_algorithm
    }
  }
}

resource "aws_s3_bucket_object_lock_configuration" "this" {
  bucket = data.terraform_remote_state.s3.outputs.id
  rule {
    default_retention {
      mode = var.q.object_lock_mode
      days = var.q.object_lock_days
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = data.terraform_remote_state.s3.outputs.id
  rule {
    object_ownership = var.q.object_ownership
  }
}

resource "aws_s3_bucket_logging" "this" {
  bucket        = data.terraform_remote_state.s3.outputs.id
  target_bucket = data.terraform_remote_state.s3.outputs.id
  target_prefix = var.q.logs_prefix
}
