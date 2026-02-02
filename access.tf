resource "cloudflare_zero_trust_access_application" "devpush_access_app" {
  account_id = var.cloudflare_account_id
  name       = "DevPush Protected Ecosystem"
  type       = "self_hosted"
  destinations = [
    {
      uri = "devpush.${var.domain_name}"
    },
    {
      uri = "*.${var.domain_name}"
    }
  ]

  policies = [
    {
      name     = "Allow Admin Email"
      decision = "allow"
      include = [
        {
          email = {
            email = var.cloudflare_access_email
          }
        }
      ]
    }
  ]
}
