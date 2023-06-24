dependency "iam" {
  config_path  = "../iam_role_assume"
  skip_outputs = true
}

dependency "iam" {
  config_path  = "../iam_role_codebuild"
  skip_outputs = true
}
