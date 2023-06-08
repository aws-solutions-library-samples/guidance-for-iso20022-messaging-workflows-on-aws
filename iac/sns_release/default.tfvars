q = {
  name            = "rp2-release"
  display_name    = "RP2 RELEASE"
  kms_key         = "alias/aws/sns"
  s3_bucket       = "rp2-runtime"
  delivery_policy = "delivery_policy.json"
}
