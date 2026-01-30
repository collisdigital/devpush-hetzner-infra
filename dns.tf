# Look up the existing zone id
data "cloudflare_zone" "main" {
  filter = {
    name = var.domain_name
  }
}

# A record for devpush.collis.digital (Proxied for Web/SSL)
resource "cloudflare_dns_record" "devpush_app" {
  zone_id = data.cloudflare_zone.main.id
  name    = "devpush"
  content = hcloud_primary_ip.devpush_ipv6.ip_address
  type    = "AAAA"
  proxied = true
  ttl     = 1 # Automatic
}

resource "cloudflare_dns_record" "devpush_app_v4" {
  zone_id = data.cloudflare_zone.main.id
  name    = "devpush"
  content = hcloud_primary_ip.devpush_ipv4.ip_address
  type    = "A"
  proxied = true
  ttl     = 1 # Automatic
}

# Wildcard CNAME *.collis.digital pointing to devpush.collis.digital
resource "cloudflare_dns_record" "wildcard" {
  zone_id = data.cloudflare_zone.main.id
  name    = "*"
  content = "devpush.${var.domain_name}"
  type    = "CNAME"
  proxied = false
  ttl     = 1 # Automatic

}

# Unproxied A record for SSH access (direct.collis.digital)
resource "cloudflare_dns_record" "direct" {
  zone_id = data.cloudflare_zone.main.id
  name    = "direct"
  content = hcloud_primary_ip.devpush_ipv6.ip_address
  type    = "AAAA"
  proxied = false
  ttl     = 1 # Automatic
}

resource "cloudflare_dns_record" "direct_v4" {
  zone_id = data.cloudflare_zone.main.id
  name    = "direct"
  content = hcloud_primary_ip.devpush_ipv4.ip_address
  type    = "A"
  proxied = false
  ttl     = 1 # Automatic
}
