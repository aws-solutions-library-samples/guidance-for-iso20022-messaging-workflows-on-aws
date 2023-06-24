dependency "mq" {
  config_path  = "../mq_broker"
  mock_outputs = {
    region = "us-east-1"
  }

  mock_outputs_merge_with_state           = true
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  RP2_REGION = dependency.mq.outputs.region
}

terraform {
  after_hook "after_hook" {
    commands     = ["apply"]
    execute      = ["${find_in_parent_folders("bin")}/docker.sh", "-q", "rp2-mq-writer", "-d", "app.mq"]
    run_on_error = false
  }
}
