return {
  revision = 0,
  channels = 4,
  default_port = 6780,
  packets = {
    entity_add = 0,
    entity_remove = 1,
    entity_control = 2,
    client_input = 3,
    server_state = 4
  },
  connect = {
    normal = 0,
  },
  disconnect = {
    unknown = 0,
    closing = 1
  }
}
