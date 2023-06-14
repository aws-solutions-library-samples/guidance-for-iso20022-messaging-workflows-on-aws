resource "aws_route53_health_check" "this" {
  disabled          = var.q.disabled
  fqdn              = local.fqdn
  type              = var.q.type
  port              = var.q.port
  resource_path     = local.path
  failure_threshold = var.q.failure_threshold
  request_interval  = var.q.request_interval

  tags = {
    "Name" = format("%s-%s", var.q.name, data.aws_region.this.name)
  }
}
