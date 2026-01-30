variable "devpush_github_app_id" {
  description = "GitHub App ID"
  type        = string
}

variable "devpush_github_app_name" {
  description = "GitHub App Name"
  type        = string
}

variable "devpush_github_app_private_key" {
  description = "GitHub App Private Key (PEM)"
  type        = string
  sensitive   = true
}

variable "devpush_github_app_webhook_secret" {
  description = "GitHub App Webhook Secret"
  type        = string
  sensitive   = true
}

variable "devpush_github_app_client_id" {
  description = "GitHub App Client ID"
  type        = string
}

variable "devpush_github_app_client_secret" {
  description = "GitHub App Client Secret"
  type        = string
  sensitive   = true
}

variable "devpush_resend_api_key" {
  description = "Resend API Key for emails"
  type        = string
  sensitive   = true
}

variable "devpush_cloudflare_api_token" {
  description = "Cloudflare API Token for the devpush application (DNS challenges)"
  type        = string
  sensitive   = true
}
