resource "aws_codebuild_project" "this" {
  name          = var.q.name
  description   = var.q.description
  build_timeout = var.q.build_timeout
  service_role  = data.terraform_remote_state.codebuild.outputs.arn

  source {
    type            = "NO_SOURCE"
    git_clone_depth = 1
    buildspec       = templatefile(var.q.file, {
      role_arn = data.terraform_remote_state.assume.outputs.arn
    })
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = var.q.compute_type
    image                       = var.q.image
    type                        = var.q.type
    image_pull_credentials_type = var.q.image_pull_credentials_type
    privileged_mode             = var.q.privileged_mode

    dynamic "environment_variable" {
      for_each = local.environment_variables
      content {
        name  = environment_variable.value.name
        type  = environment_variable.value.type
        value = environment_variable.value.value
      }
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = format("%s/%s", var.q.group_name_prefix, var.q.name)
    }

    s3_logs {
      status   = var.q.s3_logs_status
      location = format("%s/%s", var.backend_bucket[data.aws_region.this.name], var.q.s3_logs_location)
    }
  }
}
