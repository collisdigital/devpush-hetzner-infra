# Infrastructure: DevPush on Hetzner

This repository contains the Terraform configuration to bootstrap a foundational VPS running [devpush](https://github.com/hunvreus/devpush) on Hetzner Cloud.

## Architecture

*   **Server**: Hetzner Cloud `cpx11` (Ubuntu 24.04) in `nbg1` (Nuremberg).
*   **Firewall**: Only ports 22 (SSH), 80 (HTTP), and 443 (HTTPS) are open.
*   **DNS**: Managed by Cloudflare.
    *   `devpush.collis.digital` -> Server IP (Proxied)
    *   `*.collis.digital` -> `devpush.collis.digital` (Unproxied, managed by devpush)
    *   `direct.collis.digital` -> Server IP (Unproxied, for SSH)
*   **State**: Terraform state is stored in Hetzner Object Storage (S3-compatible).

## Prerequisites

1.  **Terraform** (>= 1.5.0) installed (for initial bootstrap).
2.  **Hetzner Cloud Token** (Read/Write).
3.  **Cloudflare API Token** (Edit DNS).
4.  **Hetzner Object Storage Credentials** (Access Key & Secret Key).
5.  **SSH Key** already added to Hetzner Cloud.

## Bootstrap (Initial Setup)

To get started, you must first create the S3 bucket and migrate the state.

### Step 1: Create the Bucket (Local)

1.  **Important**: Rename `backend.tf` to `backend.tf.disabled` temporarily. This prevents Terraform from trying to connect to the non-existent bucket during initialization.
    ```bash
    mv backend.tf backend.tf.disabled
    ```
2.  Initialize Terraform locally:
    ```bash
    terraform init
    ```
3.  Create a `terraform.tfvars` file (DO NOT COMMIT):
    ```hcl
    hcloud_token         = "your-hcloud-token"
    cloudflare_api_token = "your-cf-token"
    ssh_key_name         = "your-ssh-key-name"
    domain_name          = "collis.digital"
    s3_access_key        = "your-access-key"
    s3_secret_key        = "your-secret-key"
    s3_bucket_name       = "your-unique-bucket-name"
    ```
4.  Apply just the bucket resources:
    ```bash
    terraform apply -target=aws_s3_bucket.terraform_state -target=aws_s3_bucket_versioning.terraform_state
    ```

### Step 2: Configure the Backend

1.  Restore the `backend.tf` file:
    ```bash
    mv backend.tf.disabled backend.tf
    ```
2.  Edit `backend.tf`:
    *   Replace `devpush-terraform-state` with your actual bucket name (the one you set in `terraform.tfvars`).
    *   Ensure the `endpoint` matches your Object Storage region (default is `fsn1`).
3.  Initialize the backend (migrating local state to S3):
    ```bash
    export AWS_ACCESS_KEY_ID="your-access-key"
    export AWS_SECRET_ACCESS_KEY="your-secret-key"
    terraform init -migrate-state
    ```
4.  Commit and push the updated `backend.tf`.

## CI/CD with GitHub Actions

This repository is configured with GitHub Actions to automate Infrastructure changes.

### Required Secrets

Go to **Settings > Secrets and variables > Actions** in your GitHub repository and add the following repository secrets:

*   `HCLOUD_TOKEN`: Your Hetzner Cloud API Token.
*   `CLOUDFLARE_API_TOKEN`: Your Cloudflare API Token.
*   `S3_ACCESS_KEY`: Access Key for Hetzner Object Storage.
*   `S3_SECRET_KEY`: Secret Key for Hetzner Object Storage.
*   `S3_BUCKET_NAME`: The name of the S3 bucket you created.
*   `SSH_KEY_NAME`: The name of the SSH Key in Hetzner.

### Configuration Variables (Optional)

You can set these as **Variables** (not secrets):

*   `DOMAIN_NAME`: e.g., `collis.digital` (Defaults to `collis.digital` if unset).

### Workflow

1.  **Pull Request**: Terraform initializes and runs `plan`. The plan output is posted as a comment on the PR.
2.  **Push to Main**: Terraform runs `apply` automatically.

## Post-Provisioning Configuration

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
