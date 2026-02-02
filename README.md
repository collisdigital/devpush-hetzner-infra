# Infrastructure: DevPush on Hetzner

This repository contains the Terraform configuration to bootstrap a foundational VPS running [devpush](https://github.com/hunvreus/devpush) on Hetzner Cloud.

## Architecture

*   **Server**: Hetzner Cloud VPS (configurable type/image) in a configurable location (default `nbg1`).
*   **Security**: Zero Trust architecture via Cloudflare Tunnel.
    *   No public ingress ports (80/443 closed).
    *   SSH access (Port 22) retained for operational support.
*   **DNS**: Managed by Cloudflare.
    *   `devpush.example.com` → Cloudflare Tunnel (Proxied)
    *   `*.example.com` → Cloudflare Tunnel (Proxied)
    *   `devpush-direct.example.com` → Server IP (Unproxied, for SSH)
*   **Access Control**: Cloudflare Access protects web endpoints, allowing only authorized email addresses.
*   **Storage**: Persistent Hetzner Volume attached to the server.
*   **State**: Terraform state is stored in Hetzner Object Storage (S3-compatible).

## Prerequisites

1.  **Terraform** (≥ 1.14.3) installed.
2.  **Hetzner Cloud Account** with a Project and API Token.
3.  **Hetzner Object Storage** (for Terraform state).
4.  **Cloudflare Account** with an active zone (domain) and API Token.

## Initial Setup & Bootstrapping

Before running Terraform (locally or via GitHub Actions), you must manually set up the remote backend state storage.

1.  **Create a Bucket**: Log in to the Hetzner Console and create an Object Storage bucket (e.g., `my-devpush-terraform-state`) in your desired region (e.g., `nbg1`).
2.  **Get Credentials**: Create Access Key and Secret Key for this bucket.
3.  **Notes**:
    *   The bucket name must be unique.
    *   The region should ideally match your server location.
    *   The endpoint URL is usually `https://<region>.your-objectstorage.com`.

## Repository Settings (GitHub Actions)

Configure the following **Actions Secrets** to enable the automated workflow.

### Backend Configuration (S3)

| Secret Name             | Description                                                   |
| ----------------------- | ------------------------------------------------------------- |
| `TF_BACKEND_BUCKET`     | The name of your Hetzner Object Storage bucket.               |
| `TF_BACKEND_REGION`     | The region of your bucket (e.g., `nbg1`).                     |
| `TF_BACKEND_ENDPOINT`   | The endpoint URL (e.g., `https://nbg1.your-objectstorage.com`).|
| `TF_BACKEND_KEY`        | (Optional) State file path. Default: `devpush/terraform.tfstate`.|
| `AWS_ACCESS_KEY_ID`     | Access Key for the bucket.                                    |
| `AWS_SECRET_ACCESS_KEY` | Secret Key for the bucket.                                    |

### Infrastructure & Application Secrets

| Secret Name                      | Description                                                   |
| -------------------------------- | ------------------------------------------------------------- |
| `HCLOUD_TOKEN`                   | Hetzner Cloud API Token.                                      |
| `CLOUDFLARE_API_TOKEN`           | Cloudflare API Token for DNS and Zero Trust.                  |
| `CLOUDFLARE_ACCOUNT_ID`          | Cloudflare Account ID.                                        |
| `CLOUDFLARE_ACCESS_EMAIL`        | Email address authorized to access the application.           |
| `SSH_KEY_NAME`                   | Name of the SSH key uploaded to Hetzner Cloud.                |
| `DEVPUSH_CLOUDFLARE_API_TOKEN`   | Cloudflare API Token for Application (DNS Challenges).        |
| `DEVPUSH_RESEND_API_KEY`         | Resend.com API Key for emails.                                |
| `DEVPUSH_GH_APP_ID`              | GitHub App ID.                                                |
| `DEVPUSH_GH_APP_NAME`            | GitHub App Name (slug).                                       |
| `DEVPUSH_GH_APP_PRIVATE_KEY`     | GitHub App Private Key (PEM format).                          |
| `DEVPUSH_GH_APP_WEBHOOK_SECRET`  | GitHub App Webhook Secret.                                    |
| `DEVPUSH_GH_APP_CLIENT_ID`       | GitHub App Client ID.                                         |
| `DEVPUSH_GH_APP_CLIENT_SECRET`   | GitHub App Client Secret.                                     |

### Configuration Variables (Actions Variables)

These can be set as **Actions Variables** (or Secrets if preferred, but Variables are visible).

| Variable Name              | Description                                      | Default            | Required |
| -------------------------- | ------------------------------------------------ | ------------------ | :------: |
| `DOMAIN_NAME`              | Base domain name (e.g., `example.com`).          | **None**           | **Yes**  |
| `HCLOUD_SERVER_TYPE`       | Server type (e.g., `cpx11`, `cax11`).            | `cax11`            | No       |
| `HCLOUD_IMAGE`             | OS Image.                                        | `ubuntu-24.04`     | No       |
| `DEVPUSH_SERVICE_USERNAME` | Service account username.                        | `devpush`          | No       |
| `DEVPUSH_VOLUME_SIZE`      | Size of the persistent volume (GB).              | `10`               | No       |

## Local Usage

To run Terraform locally, you need to set the same environment variables.

1.  **Create a `terraform.tfvars` file**:
    *   **WARNING**: Never commit this file to Git! It is ignored by `.gitignore`.
    *   Add your non-sensitive variables here:
        ```hcl
        domain_name = "example.com"
        hcloud_server_type = "cpx21"
        ```

2.  **Export Environment Variables**:
    *   For sensitive values and backend config, export them in your shell:
        ```bash
        export TF_VAR_hcloud_token="your-token"
        export TF_BACKEND_BUCKET="your-bucket"
        # ... and so on
        ```

3.  **Initialize**:
    ```bash
    terraform init \
      -backend-config="bucket=$TF_BACKEND_BUCKET" \
      -backend-config="region=$TF_BACKEND_REGION" \
      -backend-config="endpoint=$TF_BACKEND_ENDPOINT" \
      -backend-config="access_key=$AWS_ACCESS_KEY_ID" \
      -backend-config="secret_key=$AWS_SECRET_ACCESS_KEY"
    ```

4.  **Validate**:
    *   Run `./scripts/validate.sh` to check if all required variables are set and config is valid.

## Codespaces

To facilitate SSH access within GitHub Codespaces, configure the following secret:

| Secret Name      | Description                                                           |
| ---------------- | --------------------------------------------------------------------- |
| `HCLOUD_SSH_KEY` | The **Private Key** content of the SSH key pair used for the server.  |

## Storage Architecture & Persistence

Data persistence is handled by a separate **Hetzner Volume** attached to the server. This ensures that if the server instance is destroyed and recreated (e.g., via Terraform), your application data remains safe.

*   **Volume Mount**: The volume is mounted at `/mnt/devpush-volume`.
*   **Symlinks**: The application directories are symlinked to the volume:
    *   `/opt/devpush` → `/mnt/devpush-volume/devpush/opt` (Application Code/Home)
    *   `/var/lib/devpush` → `/mnt/devpush-volume/devpush/var-lib` (Data)
    *   `/var/backups/devpush` → `/mnt/devpush-volume/devpush/var-backups` (Backups)

This setup is handled automatically by the Cloud-Init script (`devpush-config.yaml`).

## User Accounts

The provisioning script creates two distinct user accounts:

1.  **SSH User** (`admin` by default):
    *   Used for SSH access (`ssh admin@...`).
    *   Has `sudo` privileges.
    *   Configured via `ssh_login_username` variable.

2.  **Service User** (`devpush` by default):
    *   System account used to run the DevPush application.
    *   No shell login (`/usr/sbin/nologin`).
    *   Owns the application data and process.
    *   Configured via `devpush_service_username` variable.

## Environment Merging

The `scripts/merge_env.sh` script runs on the server to merge custom environment variables (injected via Terraform) with the application's configuration. This allows you to update configuration via Terraform variables without manually editing files on the server.

## SSH Access

To easily SSH into the server, use the provided setup script. It supports passing the domain name as an argument or environment variable.

**1. Authorization Setup (One-time):**

```bash
# Pass your domain name explicitly
./scripts/ssh_setup.sh example.com

# OR set it as an env var
export DOMAIN_NAME=example.com
./scripts/ssh_setup.sh
```

**2. Connect:**

```bash
ssh devpush
```
