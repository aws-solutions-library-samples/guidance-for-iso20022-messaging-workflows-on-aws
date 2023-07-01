dependency "s3" {
  config_path  = "../s3_runtime"
  mock_outputs = {
    region = "us-east-1"
  }

  mock_outputs_merge_with_state           = true
  mock_outputs_allowed_terraform_commands = ["init", "plan", "apply", "validate"]
}

inputs = {
  RP2_REGION = dependency.s3.outputs.region
}

terraform {
  after_hook "after_hook" {
    commands     = ["apply"]
    execute      = ["${find_in_parent_folders("bin")}/docker.sh", "-q", "rp2-outbox"]
    run_on_error = false
  }
}
