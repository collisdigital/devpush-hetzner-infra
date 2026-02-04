# Infrastructure: DevPush on Hetzner

This repository contains the Terraform configuration to bootstrap a foundational
VPS running [devpush](https://github.com/hunvreus/devpush) on Hetzner Cloud using
Cloudflare for DNS and Zero Trust security.

## What is DevPush?

[DevPush](https://devpu.sh/) is an open source [MIT Licensed](https://github.com/hunvreus/devpush#MIT-1-ov-file) self-hosted platform designed to simplify the deployment and management of web applications. It provides a PaaS-like (Platform-as-a-Service) experience on your own infrastructure, allowing you to go from code to production with minimal friction. See the [DevPush](https://devpu.sh/) site for more details or visit the [GitHub Project](https://github.com/hunvreus/devpush).

### Why deploy it?

*   **Ownership & Privacy**: Maintain full control over your application and data by hosting on your own server.
*   **Cost Efficiency**: Leverage affordable VPS hosting from Hetzner instead of expensive managed providers.
*   **Automated Deployment**: Seamlessly integrates with GitHub for automated build and deployment workflows.
*   **Security by Default**: This infrastructure uses Cloudflare Zero Trust to protect your instance, removing the need for open public ports (80/443).

## Architecture

*   **Server**: Hetzner Cloud VPS (configurable type/image) in a configurable location (default `nbg1`).
*   **Security**: Zero Trust architecture via Cloudflare Tunnel.
    *   No public ingress ports (80/443 closed).
    *   SSH access (Port 22) open for direct access (not via CF tunnel) for operational support.
*   **DNS**: Managed by Cloudflare.
    *   `devpush.example.com` → Cloudflare Tunnel (Proxied)
    *   `*.example.com` → Cloudflare Tunnel (Proxied)
    *   `devpush-direct.example.com` → Server IP (Not proxied, for SSH)
*   **Networking**: Servers use explicitly allocated persistent IPv4 and IPv6 addresses.
*   **Access Control**: Cloudflare Access protects web endpoints, allowing only authorized email addresses.
*   **Storage**: Persistent Hetzner Volume attached to the server.
*   **State**: Terraform state is stored in Hetzner Object Storage (S3-compatible).

## Prerequisites

1.  **[Terraform](https://developer.hashicorp.com/terraform/downloads)** (≥ 1.14.3) installed.
2.  **[Hetzner Cloud Account](https://console.hetzner.cloud/)** with a Project and API Token.
3.  **[Hetzner Object Storage](https://docs.hetzner.com/storage/object-storage)** for Terraform state.
4.  **[Cloudflare Account](https://dash.cloudflare.com/)** with an active zone (domain) and API Token.
5.  **[Resend Account](https://resend.com/)** with an API key for login emails and invitations.

## Local Development

This project includes a development container configuration, making it easy to work using [GitHub Codespaces](https://github.com/features/codespaces) or VS Code with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/collisdigital/devpush-hetzner-infra)

The dev container provides a consistent environment with all necessary tools pre-installed:

*   **OS**: Ubuntu 24.04.3 LTS.
*   **Terraform**: Terraform and related extensions/linters (TFLint) are ready to use.
*   **VS Code Extensions**: Pre-bundled extensions for spelling, GitHub Action support, Makefile editing etc.
*   **GitHub CLI (`gh`)**: Authenticated and ready for PR management.
*   **Git**: Up-to-date version with Git LFS support.
*   **Utilities**: Common tools like `curl`, `wget`, `ssh`, `ssh-keygen` etc.

When running in Codespaces, you can easily access the infrastructure using the authenticated environment without setting up tools on your local machine. See the [SSH into the Server](#ssh-into-the-server) section below for details on how to connect.

## Initial Setup & Bootstrapping

Before running Terraform (locally or via GitHub Actions) for the first time,
you need to perform some manual steps.

### Terraform Backend Storage Setup (Hetzner S3)

Terraform needs somewhere to store information about the current state of the infrastructure it is managing, we use an S3 Bucket in Hetzner for this purpose, which you need to create manually:

1.  **Log in**: Go to the [Hetzner Cloud Console](https://console.hetzner.cloud/).
2.  **Select Project**: Open the project you want to use (or create a new one).
3.  **Create a Bucket**: Navigate to *Object Storage* and create an empty Bucket with a suitable name (e.g., `my-devpush-terraform-state`) in your desired region (e.g., `nbg1`). You will need the bucket name for the `TF_BACKEND_BUCKET` secret and the region for `TF_BACKEND_REGION`. Note: The region should ideally match your server location.
4.  **View the Bucket**: Navigate to the new Bucket's overview by selecting it from the list. The URL shown is needed for the `TF_BACKEND_ENDPOINT` secret, for example `https://nbg1.your-objectstorage.com`.
5.  **Manage Credentials**: In the Bucket overview, scroll down to *S3 Credentials*, choose *Manage Credentials*.
7.  **Create a Credential**: Create a new credential with a suitable description (e.g. `devpush-s3-cred`).
7.  **Get Keys**: For the newly created credential, copy the Access Key and Secret Key that are presented, you will use these for the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` secrets.

The `TF_BACKEND_KEY` secret required later is a path of your choosing in the bucket to store the
Terraform state file in e.g.,`devpush/terraform.tfstate`.

### Hetzner Cloud API Key

You need an API Token to allow Terraform to create and manage resources in your Hetzner Cloud project.

1.  **Log in**: Go to the [Hetzner Cloud Console](https://console.hetzner.cloud/).
2.  **Select Project**: Open the project you want to use (or create a new one).
3.  **Navigate to Security**: Click on **Security** in the left sidebar, then switch to the **API Tokens** tab.
4.  **Generate Token**: Click **Generate API Token**.
    *   **Name**: Give it a descriptive name (e.g., `devpush-terraform-token`).
    *   **Permissions**: Select **Read & Write**. Terraform needs write access to create servers and volumes.
5.  **Copy Token**: Click **Create Token** and copy the resulting string immediately. **You won't be able to see it again.** You will use this for the `HCLOUD_TOKEN` secret.

### SSH Key Generation

If you don't already have an SSH key pair to use with this project, you can generate one using `ssh-keygen`. It is recommended to use the Ed25519 algorithm for better security and performance.

1.  **Generate the Key Pair**:
    Open your terminal and run:
    ```bash
    ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_devpush
    ```
    *   `-t ed25519`: Specifies the Ed25519 algorithm.
    *   `-C "your_email@example.com"`: A comment to help you identify the key.
    *   `-f ~/.ssh/id_devpush`: The filename for the new key.
    
    *Press Enter when prompted for a passphrase (or provide one if you prefer).*

2.  **Identify your Keys**:
    *   **Public Key**: `~/.ssh/id_devpush.pub`. Safe to share. You will upload this to Hetzner.
        *   To view and copy the content: `cat ~/.ssh/id_devpush.pub`
    *   **Private Key**: `~/.ssh/id_devpush`. **Keep this secret.** You will need its content for the `HCLOUD_SSH_KEY` secret. **Do NOT commit to Git.**
        *   To view and copy the content: `cat ~/.ssh/id_devpush`

3.  **Upload to Hetzner**:
    *   Go to the [Hetzner Cloud Console](https://console.hetzner.cloud/).
    *   Select your project.
    *   Go to **Security** -> **SSH Keys** in the sidebar.
    *   Click **Add SSH Key** and paste the content of your **Public Key** (`id_devpush.pub`).
    *   Give it a name (e.g., `devpush-key`). Note this name; you will use it for the `HCLOUD_SSH_KEY_NAME` secret.

### Cloudflare API Tokens

This setup requires **two distinct** [Cloudflare API Tokens](#cloudflare-api-tokens) to adhere to the principle of least privilege. **Do not reuse the same token.**

1.  **Log in**: Go to the [Cloudflare Profile - API Tokens](https://dash.cloudflare.com/profile/api-tokens) page.
2.  **Infrastructure Token** (`CLOUDFLARE_API_TOKEN`): Used by Terraform to manage DNS, Tunnels, and Access.
    *   Click **Create Token**.
    *   Use the **Create Custom Token** section (at the bottom).
    *   **Token Name**: e.g. `devpush-infrastructure-token`.
    *   **Permissions**:
        *   Account | `Cloudflare Tunnel` | Edit
        *   Account | `Zero Trust` | Edit
        *   Account | `Access: Organizations, Identity Providers, and Groups` | Read
        *   Account | `Access: Apps and Policies` | Edit
        *   Zone | `DNS` | Edit
    *   **Zone Resources**: Include -> Specific zone -> (your domain).
    *   **Continue to summary** -> **Create Token** and copy it.

3.  **Application Token** (`DEVPUSH_CLOUDFLARE_API_TOKEN`): Used by the DevPush application (on the server) for DNS challenges.
    *   Click **Create Token**.
    *   Use the **Create Custom Token** section.
    *   **Token Name**: e.g. `devpush-app-dns-token`.
    *   **Permissions**:
        *   Zone | `DNS` | Edit
    *   **Zone Resources**: Include -> Specific zone -> (your domain).
    *   **Continue to summary** -> **Create Token** and copy it.

### Cloudflare Account ID

You will need your [Cloudflare Account ID](#cloudflare-account-id) for several Terraform resources.

1.  **Log in**: Go to the [Cloudflare Dashboard](https://dash.cloudflare.com/).
2.  **Copy account ID**: Select the Quick Search from the left sidebar and type "Copy account ID" - choose the matching command from the results,  you will use this value for the `CLOUDFLARE_ACCOUNT_ID` secret.

### Resend API Key

DevPush uses a free [Resend](https://resend.com/) account to send login emails and invitations. 

1.  **Log in**: Go to the [Resend Dashboard](https://resend.com/overview).
2.  **Navigate to API Keys**: Click on **API Keys** in the left sidebar.
3.  **Create Key**: Click **Create API Key**.
    *   **Name**: e.g. `devpush-api-key`.
    *   **Permission**: `Full Access`.
    *   **Domain**: You can restrict this to your specific domain after you have verified it in Resend.
4.  **Copy Token**: Click **Add** and copy the generated key string. You will use this for the `DEVPUSH_RESEND_API_KEY` secret.

### GitHub App Setup

The DevPush application requires a GitHub App for authentication and integration.

Detailed instructions on how to create the app and obtain the required secrets can be found in the **[DevPush Documentation: Create the GitHub App](https://devpu.sh/docs/installation/#2.-create-the-github-app)**.

Once created, you will need to configure the various `DEVPUSH_GH_APP_*` secrets listed in the next section.

**Note**: The automation in this repository takes care of setting all the required `/var/lib/devpush/.env` values - there is no need to edit this file. 

## Repository Settings (GitHub Actions)

Configure the following **Actions Secrets** in your **GitHub Repository**
to enable the automated workflow. Go to `Settings -> Secrets and variables -> Actions -> New repository secret`.

Use the values you noted down in [Initial Setup & Bootstrapping](#initial-setup--bootstrapping).

### Backend Configuration (S3)

| Secret Name             | Description                                                   |
| ----------------------- | ------------------------------------------------------------- |
| `TF_BACKEND_BUCKET`     | The name of your Hetzner Object Storage bucket.               |
| `TF_BACKEND_REGION`     | The region of your bucket (e.g., `nbg1`).                     |
| `TF_BACKEND_ENDPOINT`   | The endpoint URL (e.g., `https://nbg1.your-objectstorage.com`).|
| `TF_BACKEND_KEY`        | State file path (e.g., `devpush/terraform.tfstate`).          |
| `AWS_ACCESS_KEY_ID`     | Access Key for the bucket.                                    |
| `AWS_SECRET_ACCESS_KEY` | Secret Key for the bucket.                                    |

### Infrastructure & Application Secrets

> **WARNING**: This setup requires **two distinct** Cloudflare API Tokens for security. **Do not reuse the same token.** See the [Cloudflare API Tokens](#cloudflare-api-tokens) section above for detailed creation instructions and required permissions.

| Secret Name                      | Description                                                   |
| -------------------------------- | ------------------------------------------------------------- |
| `HCLOUD_TOKEN`                   | Hetzner Cloud API Token.                                      |
| `HCLOUD_SSH_KEY_NAME`            | Name of the SSH key uploaded to Hetzner Cloud.                |
| `CLOUDFLARE_API_TOKEN`           | Cloudflare API Token for DNS and Zero Trust.                  |
| `CLOUDFLARE_ACCOUNT_ID`          | Cloudflare Account ID.                                        |
| `CLOUDFLARE_ACCESS_EMAIL`        | Email address authorized to access the application.           |
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

| Variable Name                       | Description                                      | Default            | Required |
| ----------------------------------- | ------------------------------------------------ | ------------------ | :------: |
| `DOMAIN_NAME`                       | Base domain name (e.g., `example.com`).          | **None**           | **Yes**  |
| `HCLOUD_SERVER_TYPE`                | [Server type](https://www.hetzner.com/cloud/) (e.g., `cpx11`, `cax11`). | `cax11`            | No       |
| `HCLOUD_IMAGE`                      | OS Image.                                        | `ubuntu-24.04`     | No       |
| `HCLOUD_DEVPUSH_SERVICE_USERNAME`   | Service account username.                        | `devpush`          | No       |
| `HCLOUD_VOLUME_SIZE_GB`             | Size of the persistent volume (GB).              | `10`               | No       |
| `HCLOUD_LOCATION`                   | Hetzner Location (e.g. `nbg1`).                  | `nbg1`             | No       |
| `HCLOUD_SSH_LOGIN_USERNAME`         | SSH Username.                                    | `admin`            | No       |

## Codespaces

To facilitate SSH access within GitHub Codespaces, configure the following secret:

| Secret Name      | Description                                                           |
| ---------------- | --------------------------------------------------------------------- |
| `HCLOUD_SSH_KEY` | The **Private Key** content of the SSH key pair used for the server.  |

## GitHub Actions Provisioning

The provisioning process is automated via GitHub Actions and Cloud-Init:

1.  **Branch & PR**: Create a new branch for your changes and open a Pull Request.
2.  **Plan**: The `terraform.yml` workflow will run `terraform plan` on the PR, posting the output as a comment. Review this plan to ensure it does what you expect.
3.  **Apply**: Merge the PR to the `main` branch. The workflow will then run `terraform apply` to provision the infrastructure.
4.  **Server Provisioning**:
    *   Terraform provisions the server, creates the Cloudflare Tunnel, and injects the configuration via Cloud-Init.
    *   The `devpush` installation script runs automatically.
    *   The `cloudflared` service is installed and started, connecting the tunnel.
5.  **Completion**:
    *   Once the server is up (approx. 2-5 minutes), the application should be available at `https://devpush.yourdomain.com` (protected by Cloudflare Access).

Terraform will only apply *changes* to your infrastructure specified in the branch once you have previously provisioned everything for the first time, the `terraform plan` will detail what Terraform believes needs to changed each time.

## Local Usage

To run Terraform locally, you need to set the same variables as used by GitHub Actions.

1.  **Create a `terraform.tfvars` file**:
    *   **WARNING**: Never commit this file to Git! It is ignored by `.gitignore`.
    *   Copy the example file: `cp terraform.tfvars.example terraform.tfvars`
    *   Edit it to set your values, note the variable names are the same but in lowercase.

2.  **Export Environment Variables**:
    *   For the Terraform backend you need to set environment variables in your shell:
        ```bash
        export TF_BACKEND_BUCKET="..."
        export TF_BACKEND_REGION="..."
        export TF_BACKEND_ENDPOINT="..."
        export TF_BACKEND_KEY="..."
        export AWS_ACCESS_KEY_ID="..."
        export AWS_SECRET_ACCESS_KEY="..."
        ```

3.  **Initialize**:
    *   Run the init script  to initialize Terraform. 
        ```bash
        ./scripts/init.sh
        ```
    *   Alternatively, use Make: `make init` 

4.  **Validate**:
    *   Run `./scripts/validate.sh` (or `make validate`) to check if config is valid.

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
| `make init`       | Runs terraform init.                                               |
| `make check-env`  | Checks if required environment variables are set.                  |
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

The section contains some notes that may be useful if you encounter issues with provisioning, these require you to SSH into your server first.

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

The log of what happened is here:

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
