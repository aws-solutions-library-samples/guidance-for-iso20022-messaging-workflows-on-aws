output "arn" {
  value = aws_api_gateway_rest_api.this.arn
}

output "id" {
  value = aws_api_gateway_rest_api.this.id
}

output "execution_arn" {
  value = aws_api_gateway_rest_api.this.execution_arn
}

output "root_resource_id" {
  value = aws_api_gateway_rest_api.this.root_resource_id
}

output "created_date" {
  value = aws_api_gateway_rest_api.this.created_date
}

output "deploy_id" {
  value = aws_api_gateway_deployment.this.id
}

output "deploy_invoke_url" {
  value = aws_api_gateway_deployment.this.invoke_url
}

output "deploy_created_date" {
  value = aws_api_gateway_deployment.this.created_date
}

output "stage_id" {
  value = aws_api_gateway_stage.this.id
}

output "stage_name" {
  value = aws_api_gateway_stage.this.stage_name
}

output "stage_arn" {
  value = aws_api_gateway_stage.this.arn
}

output "stage_invoke_url" {
  value = aws_api_gateway_stage.this.invoke_url
}
