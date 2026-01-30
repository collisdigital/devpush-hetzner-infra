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
2.  **Hetzner Object Storage Credentials** (Access Key & Secret Key).
3.  **Hetzner Cloud Token** (Read/Write).
4.  **Cloudflare API Token** (Edit DNS).

## GitHub Repository Secrets

Configure the following secrets in your GitHub repository settings to enable the automated workflow and server configuration:

| Secret Name | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | Access Key for Terraform Backend (Hetzner Object Storage/S3) |
| `AWS_SECRET_ACCESS_KEY` | Secret Key for Terraform Backend |
| `HCLOUD_TOKEN` | Hetzner Cloud API Token |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API Token for DNS and SSL (Infrastructure) |
| `DEVPUSH_CLOUDFLARE_API_TOKEN` | Cloudflare API Token for Application (DNS Challenges) |
| `SSH_KEY_NAME` | Name of the SSH key uploaded to Hetzner Cloud |
| `DEVPUSH_GH_APP_ID` | GitHub App ID |
| `DEVPUSH_GH_APP_NAME` | GitHub App Name (slug) |
| `DEVPUSH_GH_APP_PRIVATE_KEY` | GitHub App Private Key (PEM format) |
| `DEVPUSH_GH_APP_WEBHOOK_SECRET` | GitHub App Webhook Secret |
| `DEVPUSH_GH_APP_CLIENT_ID` | GitHub App Client ID |
| `DEVPUSH_GH_APP_CLIENT_SECRET` | GitHub App Client Secret |
| `DEVPUSH_RESEND_API_KEY` | Resend.com API Key for emails |

## Repository Variables

| Variable Name | Description | Default |
|---|---|---|
| `DOMAIN_NAME` | Base domain name | `collis.digital` |

## Usage

The provisioning process is automated via GitHub Actions and Cloud-Init.

1.  **Push to Main**: The `terraform.yml` workflow applies the infrastructure changes.
2.  **Server Provisioning**:
    *   Terraform provisions the server and injects the configuration via Cloud-Init.
    *   The `devpush.env` file is automatically populated with values from the repository and secrets.
    *   The `/dev/push` installation script runs automatically.
3.  **Completion**:
    *   Once the server is up (approx. 2-5 minutes), the application should be available at `https://devpush.collis.digital`.

## Manual Verification

If needed, you can SSH into the server to verify the configuration:

```bash
ssh deploy@direct.collis.digital
cat /var/lib/devpush/.env
```
