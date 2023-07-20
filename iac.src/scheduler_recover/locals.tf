locals {
  rp2_id = data.terraform_remote_state.s3.outputs.rp2_id
  dlq = format("scheduler-dlq-%s", local.rp2_id)
}
