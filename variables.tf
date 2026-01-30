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

variable "ssh_key_name" {
  description = "Name of the existing SSH key in Hetzner Cloud"
  type        = string
}

variable "domain_name" {
  description = "Base domain name (e.g., collis.digital)"
  type        = string
  default     = "collis.digital"
}

variable "s3_access_key" {
  description = "Access Key for Hetzner Object Storage"
  type        = string
  sensitive   = true
}

variable "s3_secret_key" {
  description = "Secret Key for Hetzner Object Storage"
  type        = string
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
}

variable "s3_region" {
  description = "Region for Hetzner Object Storage (e.g., nbg1)"
  type        = string
  default     = "nbg1"
}
