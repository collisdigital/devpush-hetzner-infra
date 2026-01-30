data "hcloud_ssh_key" "main" {
  name = var.ssh_key_name
}

resource "hcloud_primary_ip" "devpush_ipv4" {
  name          = "devpush_ipv4"
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = false
  location      = "nbg1"
}

resource "hcloud_primary_ip" "devpush_ipv6" {
  name          = "devpush_ipv6"
  type          = "ipv6"
  assignee_type = "server"
  auto_delete   = false
  location      = "nbg1"
}

resource "hcloud_server" "devpush" {
  name         = "devpush"
  image        = "ubuntu-24.04"
  server_type  = "cax11"
  location     = "nbg1"
  ssh_keys     = [data.hcloud_ssh_key.main.id]
  firewall_ids = [hcloud_firewall.devpush.id]
  backups      = true

  user_data = templatefile("${path.module}/devpush-config.yaml", {
    ssh_public_key                    = data.hcloud_ssh_key.main.public_key
    domain_name                       = var.domain_name
    devpush_cloudflare_api_token      = var.devpush_cloudflare_api_token
    devpush_github_app_id             = var.devpush_github_app_id
    devpush_github_app_name           = var.devpush_github_app_name
    devpush_github_app_private_key    = replace(var.devpush_github_app_private_key, "\n", "\\n")
    devpush_github_app_webhook_secret = var.devpush_github_app_webhook_secret
    devpush_github_app_client_id      = var.devpush_github_app_client_id
    devpush_github_app_client_secret  = var.devpush_github_app_client_secret
    devpush_resend_api_key            = var.devpush_resend_api_key
    merge_env_script                  = file("${path.module}/scripts/merge_env.sh")
  })

  public_net {
    ipv4 = hcloud_primary_ip.devpush_ipv4.id
    ipv6 = hcloud_primary_ip.devpush_ipv6.id
  }
}
