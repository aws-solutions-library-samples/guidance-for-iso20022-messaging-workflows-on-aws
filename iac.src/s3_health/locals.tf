locals {
  rp2_id      = data.terraform_remote_state.s3.outputs.rp2_id
  object_name = format("%s-%s.%s", var.q.object_name, data.aws_region.this.name, var.q.object_ext)
}
