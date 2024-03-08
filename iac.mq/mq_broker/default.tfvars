q = {
  name                       = "rp2-mq"
  description                = "RP2 MQ"
  engine_type                = "RabbitMQ"
  engine_version             = "3.10.20"
  host_instance_type         = "mq.t3.micro"
  publicly_accessible        = true
  auto_minor_version_upgrade = true
  apply_immediately          = true
  username                   = "rp2-admin"
  cw_group_name_prefix       = "/aws/amazonmq"
  retention_in_days          = 5
  skip_destroy               = true
  secret_name                = "rp2-service-mq"
}
