q = {
  durable          = true
  auto_delete      = false
  arguments        = "{\"x-queue-mode\": \"default\"}"
  exchange_type    = "topic"
  destination_type = "queue"
}
