terraform {
  backend "s3" {
    bucket = "collis-digital-devpush-hetzner"
    key    = "devpush/terraform.tfstate"
    region = "nbg1"

    endpoints = {
      s3 = "https://nbg1.your-objectstorage.com"
    }

    # S3-compatible configuration for Hetzner Object Storage
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    use_path_style              = true
  }
}
