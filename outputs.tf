output "server_ipv4" {
  value       = hcloud_primary_ip.devpush_ipv4.ip_address
  description = "Public IPv4 address of the DevPush server"
}

output "server_ipv6" {
  value       = hcloud_primary_ip.devpush_ipv6.ip_address
  description = "Public IPv6 address of the DevPush server"
}

output "ssh_command" {
  value       = "ssh -i <ssh_key_path> ${var.ssh_login_username}@${cloudflare_dns_record.devpush_direct_v4.name}.${var.domain_name}"
  description = "Command to SSH into the server"
}

output "devpush_url" {
  value       = "https://${cloudflare_dns_record.devpush_app.name}.${var.domain_name}"
  description = "URL of the DevPush dashboard"
}

output "hetzner_location" {
  value       = var.hetzner_location
  description = "Hetzner datacenter location"
}
