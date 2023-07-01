locals {
  rp2_id = (var.rp2_id == null ? (
    data.aws_region.this.name == element(keys(var.backend_bucket), 0)
    ? random_id.this.hex : data.terraform_remote_state.iam.0.outputs.rp2_id
  ) : var.rp2_id)
  ips = {
    for val in jsondecode(data.http.this.response_body)["prefixes"]: lower(val["service"]) => val... if (
      lower(val["service"]) == "codebuild" && (
        val["region"] == element(keys(var.backend_bucket), 0)
        || val["region"] == element(keys(var.backend_bucket), 1)
      )
    )
  }
  policy_ips  = local.ips["codebuild"].*.ip_prefix
  policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}
