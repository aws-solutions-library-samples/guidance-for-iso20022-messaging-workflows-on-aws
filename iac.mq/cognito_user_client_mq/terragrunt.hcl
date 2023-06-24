dependency "mq" {
  config_path  = "../mq_broker"
  mock_outputs = {
    region  = "us-east-1"
    region2 = "us-west-2"
  }

  mock_outputs_merge_with_state           = true
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  RP2_SECRET  = "rp2-client-mq-_region_"
  RP2_REGION  = dependency.mq.outputs.region
  RP2_REGION2 = dependency.mq.outputs.region2
}

#terraform {
#  before_hook "before_hook" {
#    commands     = ["plan", "apply"]
#    execute      = ["${find_in_parent_folders("bin")}/secrets.sh"]
#    run_on_error = false
#  }
#}
