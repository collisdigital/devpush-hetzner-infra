resource "random_password" "tunnel_secret" {
  length  = 64
  special = false
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "devpush_tunnel" {
  account_id    = var.cloudflare_account_id
  name          = "devpush-cloudflare-tunnel"
  tunnel_secret = base64encode(random_password.tunnel_secret.result)
  config_src    = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "devpush_config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.devpush_tunnel.id

  config = {
    ingress = [
      {
        hostname = "devpush.${var.domain_name}"
        service  = "http://localhost:80"
      },
      {
        hostname = "*.${var.domain_name}"
        service  = "http://localhost:80"
      },
      {
        service  = "http_status:404"
        hostname = null
      }
    ]
  }
}
