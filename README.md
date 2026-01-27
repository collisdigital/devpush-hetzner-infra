# Infrastructure: DevPush on Hetzner

This repository contains the Terraform configuration to bootstrap a foundational VPS running [devpush](https://github.com/hunvreus/devpush) on Hetzner Cloud.

## Architecture

*   **Server**: Hetzner Cloud `cpx11` (Ubuntu 24.04) in `nbg1` (Nuremberg).
*   **Firewall**: Only ports 22 (SSH), 80 (HTTP), and 443 (HTTPS) are open.
*   **DNS**: Managed by Cloudflare.
    *   `devpush.collis.digital` -> Server IP (Proxied)
    *   `*.collis.digital` -> `devpush.collis.digital` (Proxied)
    *   `direct.collis.digital` -> Server IP (Unproxied, for SSH)
*   **State**: Terraform state is stored in Hetzner Object Storage (S3-compatible).

## Prerequisites

1.  **Terraform** (>= 1.5.0) installed.
2.  **Hetzner Cloud Token** (Read/Write).
3.  **Cloudflare API Token** (Edit DNS).
4.  **Hetzner Object Storage Credentials** (Access Key & Secret Key).
5.  **SSH Key** already added to Hetzner Cloud.

## Initialization

Since we use Hetzner Object Storage for the backend, we face a "chicken-and-egg" problem: the bucket must exist before we can store the state in it.

### Step 1: Create the Bucket

1.  Initialize Terraform locally (without the backend configuration):
    ```bash
    terraform init
    ```
2.  Create a `terraform.tfvars` file (DO NOT COMMIT THIS FILE) with your secrets:
    ```hcl
    hcloud_token         = "your-hcloud-token"
    cloudflare_api_token = "your-cf-token"
    ssh_key_name         = "your-ssh-key-name"
    domain_name          = "collis.digital"
    s3_access_key        = "your-access-key"
    s3_secret_key        = "your-secret-key"
    s3_bucket_name       = "your-unique-bucket-name"
    ```
3.  Apply the configuration to create the bucket (and other resources):
    ```bash
    terraform apply -target=aws_s3_bucket.terraform_state -target=aws_s3_bucket_versioning.terraform_state
    ```
    *Note: You can run a full `terraform apply` here, but targeting the bucket first is safer if you plan to migrate state immediately.*

### Step 2: Configure the Backend

1.  Create a file named `backend.tf` with the following content (replacing values matching your variables):

    ```hcl
    terraform {
      backend "s3" {
        bucket   = "your-unique-bucket-name"
        key      = "devpush/terraform.tfstate"
        region   = "nbg1" # or your s3_region
        endpoint = "https://nbg1.your-objectstorage.com"

        # S3-compatible configuration
        skip_credentials_validation = true
        skip_region_validation      = true
        skip_requesting_account_id  = true
        skip_metadata_api_check     = true
        use_path_style              = true

        # Credentials can be provided via environment variables or file
        # AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=...
      }
    }
    ```

2.  Re-initialize Terraform to migrate the local state to the bucket:
    ```bash
    export AWS_ACCESS_KEY_ID="your-access-key"
    export AWS_SECRET_ACCESS_KEY="your-secret-key"
    terraform init -migrate-state
    ```

## Deployment

1.  Run the full apply to provision the server and DNS:
    ```bash
    terraform apply
    ```

2.  The server will be provisioned with `cloud-init`. It creates a user `deploy` and installs `devpush`.

## Configuration & GitHub App

After the server is up:

1.  **Create a GitHub App**:
    *   Follow the guide: [Create GitHub App](https://devpu.sh/docs/guides/create-github-app/)
    *   Homepage URL: `https://devpush.collis.digital`
    *   Callback URL: `https://devpush.collis.digital/auth/github/callback`
    *   Webhook URL: `https://devpush.collis.digital/api/webhooks/github`

2.  **Configure the Server**:
    *   SSH into the server (using the direct unproxied record):
        ```bash
        ssh deploy@direct.collis.digital
        ```
    *   Edit the configuration file using the provided template:
        ```bash
        sudo nano /var/lib/devpush/.env
        ```
    *   Copy the content from `devpush.env` in this repository, filling in your GitHub App credentials, Resend API key, and Cloudflare Token.
    *   Save and exit.

3.  **Start DevPush**:
    ```bash
    sudo systemctl enable --now devpush
    ```

## Adding a New Project

1.  Go to your dashboard at `https://devpush.collis.digital`.
2.  Click **New Project**.
3.  Select your GitHub repository (e.g., `children-holiday-spending`).
4.  DevPush will auto-detect the configuration (Dockerfile, etc.).
5.  Deploy!
    *   The project will be available at `children-holiday-spending.collis.digital` (thanks to the wildcard DNS).
