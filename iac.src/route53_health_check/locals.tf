locals {
  fqdn = (data.aws_region.this.name == element(keys(var.backend_bucket), 0)
    ? replace(
      data.terraform_remote_state.s3.outputs.bucket_regional_domain_name,
      element(keys(var.backend_bucket), 0), element(keys(var.backend_bucket), 1)
    )
    : replace(
      data.terraform_remote_state.s3.outputs.bucket_regional_domain_name,
      element(keys(var.backend_bucket), 1), element(keys(var.backend_bucket), 0)
    )
  )
  path = (startswith(data.terraform_remote_state.s3.outputs.object_name, "/")
    ? data.terraform_remote_state.s3.outputs.object_name
    : format("/%s", data.terraform_remote_state.s3.outputs.object_name)
  )
}
