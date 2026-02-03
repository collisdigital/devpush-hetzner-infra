# Infrastructure: DevPush on Hetzner

This repository contains the Terraform configuration to bootstrap a foundational VPS running [devpush](https://github.com/hunvreus/devpush) on Hetzner Cloud using Cloudflare for DNS and Zero Trust security.

## Architecture

*   **Server**: Hetzner Cloud VPS (configurable type/image) in a configurable location (default `nbg1`).
*   **Security**: Zero Trust architecture via Cloudflare Tunnel.
    *   No public ingress ports (80/443 closed).
    *   SSH access (Port 22) open for direct access (not via CF tunnel) for operational support.
*   **DNS**: Managed by Cloudflare.
    *   `devpush.example.com` → Cloudflare Tunnel (Proxied)
    *   `*.example.com` → Cloudflare Tunnel (Proxied)
    *   `devpush-direct.example.com` → Server IP (Unproxied, for SSH)
*   **Networking**: Servers use explicitly allocated persistent IPv4 and IPv6 addresses.
*   **Access Control**: Cloudflare Access protects web endpoints, allowing only authorized email addresses.
*   **Storage**: Persistent Hetzner Volume attached to the server.
*   **State**: Terraform state is stored in Hetzner Object Storage (S3-compatible).

## Prerequisites

1.  **[Terraform](https://developer.hashicorp.com/terraform/downloads)** (≥ 1.14.3) installed.
2.  **[Hetzner Cloud Account](https://console.hetzner.cloud/)** with a Project and API Token.
3.  **[Hetzner Object Storage](https://docs.hetzner.com/cloud/networks-security/object-storage/)** (for Terraform state).
4.  **[Cloudflare Account](https://dash.cloudflare.com/)** with an active zone (domain) and API Token.

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
| `HCLOUD_SSH_KEY_NAME`            | Name of the SSH key uploaded to Hetzner Cloud.                |
| `DEVPUSH_CLOUDFLARE_API_TOKEN`   | Cloudflare API Token for Application (DNS Challenges).        |
| `DEVPUSH_RESEND_API_KEY`         | Resend.com API Key for emails.                                |
| `DEVPUSH_GH_APP_ID`              | GitHub App ID.                                                |
| `DEVPUSH_GH_APP_NAME`            | GitHub App Name (slug).                                       |
| `DEVPUSH_GH_APP_PRIVATE_KEY`     | GitHub App Private Key (PEM format).                          |
| `DEVPUSH_GH_APP_WEBHOOK_SECRET`  | GitHub App Webhook Secret.                                    |
| `DEVPUSH_GH_APP_CLIENT_ID`       | GitHub App Client ID.                                         |
| `DEVPUSH_GH_APP_CLIENT_SECRET`   | GitHub App Client Secret.                                     |

See the [DevPush Documentation](https://github.com/hunvreus/devpush) for more details on the application-specific secrets.

### Configuration Variables (Actions Variables)

These can be set as **Actions Variables** (or Secrets if preferred, but Variables are visible).

| Variable Name              | Description                                      | Default            | Required |
| -------------------------- | ------------------------------------------------ | ------------------ | :------: |
| `DOMAIN_NAME`              | Base domain name (e.g., `example.com`).          | **None**           | **Yes**  |
| `HCLOUD_SERVER_TYPE`       | [Server type](https://www.hetzner.com/cloud/) (e.g., `cpx11`, `cax11`). | `cax11`            | No       |
| `HCLOUD_IMAGE`             | OS Image.                                        | `ubuntu-24.04`     | No       |
| `DEVPUSH_SERVICE_USERNAME` | Service account username.                        | `devpush`          | No       |
| `DEVPUSH_VOLUME_SIZE`      | Size of the persistent volume (GB).              | `10`               | No       |

## Codespaces

To facilitate SSH access within GitHub Codespaces, configure the following secret:

| Secret Name      | Description                                                           |
| ---------------- | --------------------------------------------------------------------- |
| `HCLOUD_SSH_KEY` | The **Private Key** content of the SSH key pair used for the server.  |

## Usage

The provisioning process is automated via GitHub Actions and Cloud-Init.

1.  **Branch & PR**: Create a new branch for your changes and open a Pull Request.
2.  **Plan**: The `terraform.yml` workflow will run `terraform plan` on the PR, posting the output as a comment. Review this plan to ensure it does what you expect.
3.  **Apply**: Merge the PR to the `main` branch. The workflow will then run `terraform apply` to provision the infrastructure.
4.  **Server Provisioning**:
    *   Terraform provisions the server, creates the Cloudflare Tunnel, and injects the configuration via Cloud-Init.
    *   The `devpush` installation script runs automatically.
    *   The `cloudflared` service is installed and started, connecting the tunnel.
5.  **Completion**:
    *   Once the server is up (approx. 2-5 minutes), the application should be available at `https://devpush.yourdomain.com` (protected by Cloudflare Access).

## Local Usage

To run Terraform locally, you need to set the same environment variables.

1.  **Create a `terraform.tfvars` file**:
    *   **WARNING**: Never commit this file to Git! It is ignored by `.gitignore`.
    *   Copy the example file: `cp terraform.tfvars.example terraform.tfvars`
    *   Edit it to set your values (see `terraform.tfvars.example` for the list of available variables).

2.  **Export Environment Variables**:
    *   For sensitive values and backend config, export them in your shell:
        ```bash
        export TF_VAR_hcloud_token="your-token"
        export TF_BACKEND_BUCKET="your-bucket"
        # ... and so on
        ```

3.  **Initialize**:
    *   Run the init script to configure the environment and initialize Terraform:
        ```bash
        ./scripts/init.sh
        terraform init \
          -backend-config="bucket=$TF_BACKEND_BUCKET" \
          -backend-config="region=$TF_BACKEND_REGION" \
          -backend-config="endpoint=$TF_BACKEND_ENDPOINT" \
          -backend-config="access_key=$AWS_ACCESS_KEY_ID" \
          -backend-config="secret_key=$AWS_SECRET_ACCESS_KEY"
        ```
    *   Alternatively, use Make: `make init` (note: you still need to set the backend variables manually or in your shell).

4.  **Validate**:
    *   Run `./scripts/validate.sh` to check if all required variables are set and config is valid.

## SSH into the Server

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

> **Note**: The setup script attempts to use connection settings derived from your domain. If you have customized variables, you may need to adjust `scripts/ssh_setup.sh` or your `~/.ssh/config` manually.

## Development Helpers

A `Makefile` is included to provide shortcuts for common development tasks:

| Command           | Description                                                        |
| ----------------- | ------------------------------------------------------------------ |
| `make init`       | Runs the dynamic variable initialization script.                   |
| `make validate`   | Validates the Terraform configuration.                             |
| `make lint`       | Runs TFLint to check for potential errors and best practices.      |
| `make setup-ssh`  | Sets up the local SSH config using the `HCLOUD_SSH_KEY` secret.    |
| `make connect`    | Runs `setup-ssh` and then immediately connects to the server.      |

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
