dependency "s3" {
  config_path  = "../s3_runtime"
  mock_outputs = {
    role_name = "rp2-cicd-assume-role"
    region    = "us-east-1"
  }

  mock_outputs_merge_with_state           = true
  mock_outputs_allowed_terraform_commands = ["init", "plan", "apply", "destroy", "validate"]
}

inputs = {
  ROLE_NAME  = dependency.s3.outputs.role_name
  RP2_REGION = dependency.s3.outputs.region
}

terraform {
  after_hook "after_hook" {
    commands     = ["apply"]
    execute      = ["${find_in_parent_folders("bin")}/docker.sh", "-q", "rp2-release"]
    run_on_error = false
  }
}
