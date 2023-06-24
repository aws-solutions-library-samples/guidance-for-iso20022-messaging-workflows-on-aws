locals {
  environment_variables = [
    {
      name  = "AWS_DEFAULT_REGION"
      type  = "PLAINTEXT"
      value = "us-east-1"
    },
    {
      name  = "AWS_REGION"
      type  = "PLAINTEXT"
      value = "us-east-1"
    },
    {
      name  = "RP2_REGION"
      type  = "PLAINTEXT"
      value = "us-east-1"
    },
    {
      name  = "RP2_GITHUB"
      type  = "PLAINTEXT"
      value = "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"
    },
    {
      name  = "RP2_DOMAIN"
      type  = "PLAINTEXT"
      value = var.custom_domain
    },
    {
      name  = "RP2_BACKEND"
      type  = "PLAINTEXT"
      value = format("{%s}", join(",", [for key, value in var.backend_bucket : "\"${key}\"=\"${value}\""]))
    },
  ]
}
