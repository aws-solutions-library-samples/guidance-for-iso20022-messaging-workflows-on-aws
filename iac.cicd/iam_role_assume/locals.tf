locals {
  policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  ips = {
    for val in jsondecode(data.http.this.response_body)["prefixes"]: val["service"] => val... if (
      val["service"] == "CODEBUILD" && (
        val["region"] == element(keys(var.backend_bucket), 0)
        || val["region"] == element(keys(var.backend_bucket), 1)
      )
    )
  }
}
