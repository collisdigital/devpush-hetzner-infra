# Infrastructure: DevPush on Hetzner

This repository contains the Terraform configuration to bootstrap a foundational VPS running [devpush](https://github.com/hunvreus/devpush) on Hetzner Cloud.

## Architecture

*   **Server**: Hetzner Cloud `cpx11` (Ubuntu 24.04) in `nbg1` (Nuremberg).
*   **Security**: Zero Trust architecture via Cloudflare Tunnel.
    *   No public ingress ports (80/443 closed).
    *   SSH access (Port 22) retained for operational support.
*   **DNS**: Managed by Cloudflare.
    *   `devpush.collis.digital` → Cloudflare Tunnel (Proxied)
    *   `*.collis.digital` → Cloudflare Tunnel (Proxied)
    *   `devpush-direct.collis.digital` → Server IP (Unproxied, for SSH)
*   **Access Control**: Cloudflare Access protects web endpoints, allowing only authorized email addresses.
*   **State**: Terraform state is stored in Hetzner Object Storage (S3-compatible).

## Prerequisites

1.  **Terraform** (≥ 1.14.3) installed (for initial bootstrap).
2.  **Hetzner Object Storage Credentials** (Access Key & Secret Key).
3.  **Hetzner Cloud Token** (Read/Write).
4.  **Cloudflare API Token** (Edit DNS, Zero Trust/Teams).

## Repository Settings

These values can be found in the GitHub repository **Settings → Secrets and variables**

### Actions 

Configure the following Action **Actions Secrets** to enable automated workflow and server
configuration:

| Secret Name                      | Description                                                   |
| -------------------------------- | ------------------------------------------------------------- |
| `AWS_ACCESS_KEY_ID`              | Access Key for Terraform Backend (Hetzner Object Storage/S3)  |
| `AWS_SECRET_ACCESS_KEY`          | Secret Key for Terraform Backend                              |
| `HCLOUD_TOKEN`                   | Hetzner Cloud API Token                                       |
| `CLOUDFLARE_API_TOKEN`           | Cloudflare API Token for DNS and SSL (Infrastructure)         |
| `CLOUDFLARE_ACCOUNT_ID`          | Cloudflare Account ID (Required for Zero Trust/Tunnel)        |
| `CLOUDFLARE_ACCESS_EMAIL`        | Email address authorized to access the application via Access |
| `DEVPUSH_CLOUDFLARE_API_TOKEN`   | Cloudflare API Token for Application (DNS Challenges)         |
| `SSH_KEY_NAME`                   | Name of the SSH key uploaded to Hetzner Cloud                 |
| `DEVPUSH_GH_APP_ID`              | GitHub App ID                                                 |
| `DEVPUSH_GH_APP_NAME`            | GitHub App Name (slug)                                        |
| `DEVPUSH_GH_APP_PRIVATE_KEY`     | GitHub App Private Key (PEM format)                           |
| `DEVPUSH_GH_APP_WEBHOOK_SECRET`  | GitHub App Webhook Secret                                     |
| `DEVPUSH_GH_APP_CLIENT_ID`       | GitHub App Client ID                                          |
| `DEVPUSH_GH_APP_CLIENT_SECRET`   | GitHub App Client Secret                                      |
| `DEVPUSH_RESEND_API_KEY`         | Resend.com API Key for emails                                 |

The following Action **Actions Variables** are optional:

| Variable Name | Description      | Default          |
| ------------- | ---------------- | ---------------- |
| `DOMAIN_NAME` | Base domain name | `collis.digital` |

### Codespaces

To facilitate SSH access within GitHub Codespaces, configure the following secret:

| Secret Name      | Description                                                           |
| ---------------- | --------------------------------------------------------------------- |
| `HCLOUD_SSH_KEY` | The **Private Key** content of the SSH key pair used for the server.  |

## Usage

The provisioning process is automated via GitHub Actions and Cloud-Init.

1.  **Push to Main**: The `terraform.yml` workflow applies the infrastructure changes.
2.  **Server Provisioning**:
    *   Terraform provisions the server, creates the Cloudflare Tunnel, and injects the configuration via Cloud-Init.
    *   The `devpush` installation script runs automatically.
    *   The `cloudflared` service is installed and started, connecting the tunnel.
3.  **Completion**:
    *   Once the server is up (approx. 2-5 minutes), the application should be available at `https://devpush.collis.digital` (protected by Cloudflare Access).

## SSH into the Server

To easily SSH into the server, use the provided setup script. This script configures
your SSH client to use the private key from the `HCLOUD_SSH_KEY` secret and sets up
a convenient alias.

**1. Authorization Setup (One-time):**

```bash
./scripts/ssh_setup.sh
```

**2. Connect:**

```bash
ssh devpush
```

> **Note**: The setup script attempts to use default connection settings
> (`admin@devpush-direct.collis.digital`). If you have customized variables,
> you may need to adjust `scripts/ssh_setup.sh` or your `~/.ssh/config` manually.

## Development Helpers

A `Makefile` is included to provide shortcuts for common development tasks:

| Command           | Description                                                        |
| ----------------- | ------------------------------------------------------------------ |
| `make validate`   | Validates the Terraform configuration.                             |
| `make lint`       | Runs TFLint to check for potential errors and best practices.      |
| `make setup-ssh`  | Sets up the local SSH config using the `HCLOUD_SSH_KEY` secret.    |
| `make connect`    | Runs `setup-ssh` and then immediately connects to the server.      |

## Useful Notes

### Cloud-Init

After provisioning the server and on first boot, the [devpush-config.yaml](devpush-config.yaml)
script is executed by cloud-init. The actual shell script is stored at `/var/lib/cloud/instance/scripts/runcmd`

Cloud-init looks into that directory and executes whatever is inside. If you
manually edit this file and then re-run the final modules, it will execute your edits.

To view the deployed cloud-init script:

```bash
sudo more /var/lib/cloud/instance/scripts/runcmd
```

If you want to see exactly what Terraform sent to the server (the unparsed YAML),
it is mirrored at:

```bash
sudo more /var/lib/cloud/instance/user-data.txt
```

The log of what happend is here:

```bash
sudo more /var/log/cloud-init-output.log
```

If you want to see the technical details of the cloud-init engine itself—like
which module it's starting, if it found the YAML file, or if there was a Python crash—look here:

```bash
sudo more /var/log/cloud-init.log
```

To re-run the cloud-init:

```bash
sudo cloud-init modules --mode final
```

If you want to trick the server into thinking it's booting for the first time
(to re-run everything including write_files and runcmd), you can run:

```bash
sudo cloud-init clean --logs
sudo reboot
```

NOTE: This re-downloads the `devpush-config.yaml` from the Hetzner metadata server


#### Manual Overwrite 
It is possible to edit the local copy of the `devpush-config.yaml` on the server.

SSH into the server, then:

```bash
# 1. Wipe the old state (this deletes the /instance folder)
sudo cloud-init clean --logs

# 2. Manually recreate the seed link so cloud-init sees your NEW file
sudo mkdir -p /var/lib/cloud/seed/nocloud

# Paste your new YAML content into this file and save it.
sudo nano /var/lib/cloud/seed/nocloud/user-data

# Validates the syntax of your local user-data (don't skip this!)
sudo cloud-init schema --config-file /var/lib/cloud/seed/nocloud/user-data

# 3. Force cloud-init to re-initialize using that specific local seed
sudo cloud-init init --local
sudo cloud-init init
sudo cloud-init modules --mode final
```

### Useful Paths

| Path                            | Description                          |
| ------------------------------- | ------------------------------------ |
| `/opt/devpush`                  | Application code                     |
| `/var/lib/devpush`              | Data directory                       |
| `/var/lib/devpush/.env`         | Configuration                        |
| `/var/lib/devpush/traefik`      | Traefik config and certificates      |
| `/var/lib/devpush/upload`       | Uploaded files                       |
| `/var/lib/devpush/version.json` | Installed version info               |
| `/var/backups/devpush`          | Backups                              |
