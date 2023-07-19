locals {
  rp2_id = data.terraform_remote_state.s3.outputs.rp2_id
  rules = [
    {
      vendor_name = "AWS"
      name        = "AWSManagedRulesCommonRuleSet"
      priority    = 1
    },
    {
      vendor_name = "AWS"
      name        = "AWSManagedRulesLinuxRuleSet"
      priority    = 2
    },
    {
      vendor_name = "AWS"
      name        = "AWSManagedRulesKnownBadInputsRuleSet"
      priority    = 3
    },
  ]
}
