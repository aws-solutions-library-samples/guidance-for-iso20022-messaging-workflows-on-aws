output "arn" {
  value = aws_codebuild_project.this.arn
}

output "id" {
  value = aws_codebuild_project.this.id
}

output "badge_url" {
  value = aws_codebuild_project.this.badge_url
}

output "rp2_id" {
  value = local.rp2_id
}
