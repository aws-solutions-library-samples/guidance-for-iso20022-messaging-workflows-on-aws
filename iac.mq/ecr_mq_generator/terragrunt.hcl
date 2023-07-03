dependency "mq" {
  config_path  = "../mq_broker"
  mock_outputs = {
    region = "us-east-1"
  }

  mock_outputs_merge_with_state           = true
  mock_outputs_allowed_terraform_commands = ["init", "plan", "apply", "destroy", "validate"]
}

inputs = {
  ROLE_NAME  = dependency.mq.outputs.role_name
  RP2_REGION = dependency.mq.outputs.region
}

terraform {
  after_hook "after_hook" {
    commands     = ["apply"]
    execute      = ["${find_in_parent_folders("bin")}/docker.sh", "-q", "rp2-mq-generator", "-d", "app.mq"]
    run_on_error = false
  }
}
