data "hcloud_ssh_key" "main" {
  name = var.ssh_key_name
}

resource "hcloud_server" "devpush" {
  name        = "devpush"
  image       = "ubuntu-24.04"
  server_type = "cpx11"
  location    = "nbg1"
  ssh_keys    = [data.hcloud_ssh_key.main.id]
  firewall_ids = [hcloud_firewall.devpush.id]

  user_data = templatefile("${path.module}/cloud-config.yaml", {
    ssh_public_key = data.hcloud_ssh_key.main.public_key
  })

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
}
