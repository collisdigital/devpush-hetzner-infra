variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID (required for Zero Trust resources)"
  type        = string
  sensitive   = true
}

variable "cloudflare_access_email" {
  description = "Email address allowed to access the protected applications"
  type        = string
  sensitive   = true
}

variable "ssh_key_name" {
  description = "Name of the existing SSH key in Hetzner Cloud"
  type        = string
}

variable "domain_name" {
  description = "Base domain name (e.g., collis.digital)"
  type        = string
  default     = "collis.digital"
}

variable "ssh_login_username" {
  description = "Username for SSH login (separate from the devpush service account)"
  type        = string
  default     = "admin"
}

variable "hetzner_location" {
  description = "Hetzner datacenter location (e.g., nbg1, fsn1, hel1)"
  type        = string
  default     = "nbg1"
}

variable "devpush_volume_size" {
  description = "Size of the DevPush storage volume in GB"
  type        = number
  default     = 10
}
