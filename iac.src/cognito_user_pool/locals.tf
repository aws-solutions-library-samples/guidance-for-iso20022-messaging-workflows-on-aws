locals {
  rp2_id = data.terraform_remote_state.s3.outputs.rp2_id
  scopes = [
    {
      name        = "read"
      description = "read only"
    },
    {
      name        = "write"
      description = "write only"
    }
  ]
}
