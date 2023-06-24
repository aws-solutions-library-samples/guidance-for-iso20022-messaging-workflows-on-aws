resource "rabbitmq_vhost" "this" {
  name = "default"
}

resource "rabbitmq_queue" "this" {
  for_each = toset(local.queues)

  vhost = rabbitmq_vhost.this.name
  name  = each.value

  settings {
    durable        = var.q.durable
    auto_delete    = var.q.auto_delete
    arguments_json = jsonencode(var.q.arguments)
  }
}

resource "rabbitmq_exchange" "this" {
  for_each = toset(local.queues)

  vhost = rabbitmq_vhost.this.name
  name  = each.value

  settings {
    type        = var.q.exchange_type
    durable     = var.q.durable
    auto_delete = var.q.auto_delete
  }

  depends_on = [rabbitmq_queue.this]
}

resource "rabbitmq_binding" "this" {
  for_each = toset(local.queues)

  vhost            = rabbitmq_vhost.this.name
  source           = rabbitmq_exchange.this[each.key].name
  destination      = rabbitmq_queue.this[each.key].name
  destination_type = var.q.destination_type
  routing_key      = rabbitmq_queue.this[each.key].name
}

provider "rabbitmq" {
  endpoint = local.secrets["RP2_RMQ_HOST"]
  username = local.secrets["RP2_RMQ_USER"]
  password = local.secrets["RP2_RMQ_PASS"]
  insecure = true
}
