dependency "agw_healthy" {
  config_path  = "../api_gateway_rest"
  skip_outputs = true
}

dependency "agw_unhealthy" {
  config_path  = "../api_gateway_mock"
  skip_outputs = true
}
