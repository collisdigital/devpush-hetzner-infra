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
4.  **Hetzner Object Storage Credentials** (Access Key & Secret Key).
2.  **Hetzner Cloud Token** (Read/Write).
3.  **Cloudflare API Token** (Edit DNS).
5.  **SSH Key** already added to Hetzner Cloud.

## CI/CD with GitHub Actions

This repository is configured with GitHub Actions to automate Infrastructure changes.

### Required Secrets

Go to **Settings > Secrets and variables > Actions** in your GitHub repository and add the following repository secrets:

*   `AWS_S3_ACCESS_KEY`: Access Key for Hetzner Object Storage.
*   `AWS_S3_SECRET_KEY`: Secret Key for Hetzner Object Storage.
*   `HCLOUD_TOKEN`: Your Hetzner Cloud API Token.
*   `CLOUDFLARE_API_TOKEN`: Your Cloudflare API Token.
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
