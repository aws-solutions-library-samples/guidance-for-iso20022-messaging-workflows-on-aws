q = {
  name                        = "rp2-cicd-pipeline"
  description                 = "RP2 CICD PIPELINE"
  build_timeout               = 60
  file                        = "buildspec.yml.tftpl"
  compute_type                = "BUILD_GENERAL1_LARGE"
  type                        = "ARM_CONTAINER"
  image                       = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
  image_pull_credentials_type = "CODEBUILD"
  privileged_mode             = true
  group_name                  = "/aws/codebuild"
  stream_name                 = null
  s3_logs_status              = "ENABLED"
  s3_logs_bucket              = "rp2-backend-us-east-1"
  s3_logs_location            = "codebuild"
}
