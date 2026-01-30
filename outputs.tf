output "server_ip" {
  value       = hcloud_primary_ip.devpush_ipv4.ip_address
  description = "Public IP of the DevPush server"
}

output "ssh_command" {
  value       = "ssh deploy@direct.${var.domain_name}"
  description = "Command to SSH into the server"
}

output "devpush_url" {
  value       = "https://devpush.${var.domain_name}"
  description = "URL of the DevPush dashboard"
}
