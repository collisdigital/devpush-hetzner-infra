terraform {
  backend "s3" {
    bucket   = "devpush-terraform-state" # REPLACE THIS WITH YOUR UNIQUE BUCKET NAME
    key      = "devpush/terraform.tfstate"
    region   = "fsn1"
    endpoint = "https://fsn1.your-objectstorage.com"

    # S3-compatible configuration for Hetzner Object Storage
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    use_path_style              = true
  }
}
