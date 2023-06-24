locals {
  ips = {
    for val in jsondecode(data.http.this.response_body)["prefixes"]: val["service"] => val... if (
      val["service"] == "CODEBUILD" && (
        val["region"] == element(keys(var.backend_bucket), 0)
        || val["region"] == element(keys(var.backend_bucket), 1)
      )
    )
  }
  policy_ips  = local.ips["CODEBUILD"].*.ip_prefix
  policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}
