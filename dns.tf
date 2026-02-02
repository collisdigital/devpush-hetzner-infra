# Look up the existing zone id
data "cloudflare_zone" "main" {
  filter = {
    name = var.domain_name
  }
}

# CNAME record for devpush.collis.digital pointing to Tunnel
resource "cloudflare_dns_record" "devpush_tunnel_cname" {
  zone_id = data.cloudflare_zone.main.id
  name    = "devpush"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.devpush_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1 # Automatic
}

# Wildcard CNAME *.collis.digital pointing to Tunnel
resource "cloudflare_dns_record" "wildcard" {
  zone_id = data.cloudflare_zone.main.id
  name    = "*"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.devpush_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1 # Automatic
}

# Unproxied A record for SSH access (devpush-direct.collis.digital)
resource "cloudflare_dns_record" "devpush_direct_v6" {
  zone_id = data.cloudflare_zone.main.id
  name    = "devpush-direct"
  content = hcloud_primary_ip.devpush_ipv6.ip_address
  type    = "AAAA"
  proxied = false
  ttl     = 1 # Automatic
}

resource "cloudflare_dns_record" "devpush_direct_v4" {
  zone_id = data.cloudflare_zone.main.id
  name    = "devpush-direct"
  content = hcloud_primary_ip.devpush_ipv4.ip_address
  type    = "A"
  proxied = false
  ttl     = 1 # Automatic
}
