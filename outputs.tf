output "server_ips" {
    value = scaleway_instance_server.devbox.public_ips
}

output "server_state" {
    value = scaleway_instance_server.devbox.state
}
