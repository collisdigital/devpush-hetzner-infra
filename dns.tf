data "cloudflare_zone" "main" {
  name = var.domain_name
}

# A record for devpush.collis.digital (Proxied for Web/SSL)
resource "cloudflare_record" "devpush_app" {
  zone_id = data.cloudflare_zone.main.id
  name    = "devpush"
  value   = hcloud_server.devpush.ipv4_address
  type    = "A"
  proxied = true
}

# Wildcard CNAME *.collis.digital pointing to devpush.collis.digital
resource "cloudflare_record" "wildcard" {
  zone_id = data.cloudflare_zone.main.id
  name    = "*"
  value   = "devpush.${var.domain_name}"
  type    = "CNAME"
  proxied = true
}

# Unproxied A record for SSH access (direct.collis.digital)
resource "cloudflare_record" "direct" {
  zone_id = data.cloudflare_zone.main.id
  name    = "direct"
  value   = hcloud_server.devpush.ipv4_address
  type    = "A"
  proxied = false
}
