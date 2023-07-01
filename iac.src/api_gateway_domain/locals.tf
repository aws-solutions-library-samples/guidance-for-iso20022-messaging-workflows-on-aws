locals {
  domains = {
    global = format("api.%s", var.custom_domain)
    element(keys(var.backend_bucket), 0) = format("api-%s.%s", element(keys(var.backend_bucket), 0), var.custom_domain)
    element(keys(var.backend_bucket), 1) = format("api-%s.%s", element(keys(var.backend_bucket), 1), var.custom_domain)
  }
}
