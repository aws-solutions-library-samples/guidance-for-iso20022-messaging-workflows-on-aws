resource "aws_cloudfront_origin_access_control" "this" {
  name             = substr(data.terraform_remote_state.s3.outputs.domain, 0, 64)
  description      = data.terraform_remote_state.s3.outputs.domain
  signing_behavior = var.q.signing_behavior
  signing_protocol = var.q.signing_protocol

  origin_access_control_origin_type = var.q.origin_type
}

resource "aws_cloudfront_response_headers_policy" "this" {
  name    = data.terraform_remote_state.s3.outputs.id
  comment = data.terraform_remote_state.s3.outputs.domain

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override = true
    }

    referrer_policy {
      referrer_policy = "same-origin"
      override = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
      preload                    = true
    }
  }
}

resource "aws_cloudfront_distribution" "this" {
  #checkov:skip=CKV_AWS_68:WAF not needed -- restricted to get health.txt object
  #checkov:skip=CKV_AWS_174:Checkov issue -- cannot read value from default.tfvars
  #checkov:skip=CKV_AWS_216:Checkov issue -- cannot read value from default.tfvars
  #checkov:skip=CKV_AWS_310:Failover not needed -- expected behavior to receive failed requests
  #checkov:skip=CKV2_AWS_42:Custom SSL not needed -- health check works with default domain
  #checkov:skip=CKV2_AWS_47:WAFv2 not needed -- restricted to get health.txt object

  origin {
    domain_name              = data.terraform_remote_state.s3.outputs.domain
    origin_id                = data.terraform_remote_state.s3.outputs.domain
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  enabled             = var.q.enabled
  is_ipv6_enabled     = var.q.is_ipv6_enabled
  comment             = data.terraform_remote_state.s3.outputs.id
  default_root_object = var.q.default_object

  default_cache_behavior {
    allowed_methods  = split(",", var.q.allowed_methods)
    cached_methods   = split(",", var.q.cached_methods)
    cache_policy_id  = var.q.cache_policy_id
    target_origin_id = data.terraform_remote_state.s3.outputs.domain

    compress    = var.q.compress
    default_ttl = var.q.default_ttl
    min_ttl     = var.q.min_ttl
    max_ttl     = var.q.max_ttl

    viewer_protocol_policy     = var.q.viewer_policy
    response_headers_policy_id = aws_cloudfront_response_headers_policy.this.id
  }

  dynamic "logging_config" {
    for_each = local.logging_config
    content {
      bucket = logging_config.value.bucket
      prefix = logging_config.value.prefix
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.q.viewer_cert
    minimum_protocol_version       = var.q.minimum_version
  }
}
