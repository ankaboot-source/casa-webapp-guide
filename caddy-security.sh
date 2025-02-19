#!/bin/bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Author: Ankaboot.io - Zied - tech@ankaboot.io

# GitHub SSO Setup with Caddy Security module
# -----------------------------------
# This script configures GitHub SSO authentication with Caddy Security
# to secure a self-hosted Supabase Studio dashboard. It performs the following:
#
# 1. Installs required dependencies, including Go and xcaddy.
# 2. Builds Caddy with the caddy-security module.
# 3. Creates a dedicated Caddy user and group.
# 4. Sets up a systemd service for Caddy.
# 5. Generates a Caddyfile to reverse proxy Supabase while securing Supabase Studio with GitHub SSO.
#
# Required Inputs:
# ----------------
# - GITHUB_CLIENT_ID       (Create a GitHub OAuth app at https://github.com/settings/developers)
# - GITHUB_CLIENT_SECRET   (Create a GitHub OAuth app at https://github.com/settings/developers)
# - DOMAIN                 (e.g., example.io)
# - GITHUB_USERNAME        (e.g., zieddhf)
# - AUTH_SUBDOMAIN         (e.g., https://auth.example.io)
# - APP_SUBDOMAIN          (e.g., https://myapp.example.io)
#
# Compatibility:
# -------------
# - Works on Debian-based distributions (e.g., Ubuntu).
# - Requires root privileges.


set -e

# Get the latest Go version dynamically
GO_LATEST=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
GO_VERSION="${GO_LATEST}"
GO_TAR="${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://golang.org/dl/${GO_TAR}"
CADDY_SERVICE_PATH="/usr/lib/systemd/system/caddy.service"
CADDY_CONF_PATH="/etc/caddy"

# Function to prompt for required informations
prompt() {
    local var_name=$1
    local prompt_message=$2
    local secret=$3  # If "true", hide input

    if [[ "$secret" == "true" ]]; then
        read -s -p "${prompt_message}" user_input
    else

    read -p "${prompt_message}" user_input

    fi
    echo "${user_input}"
}



echo "Installing latest Go version: ${GO_VERSION}..."
wget -q ${GO_URL}
sudo tar -xf ${GO_TAR} -C /usr/local
rm -f ${GO_TAR}
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile > /dev/null
source /etc/profile

echo "Installing xcaddy..."
sudo apt update && sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/xcaddy/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-xcaddy-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/xcaddy/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-xcaddy.list
sudo apt update && sudo apt install -y xcaddy

echo "Building Caddy with security module..."
xcaddy build --with github.com/greenpau/caddy-security
sudo mv caddy /usr/bin/caddy
sudo chmod +x /usr/bin/caddy

echo "Creating caddy user and group..."
sudo groupadd --system caddy || true
sudo useradd --system --gid caddy --create-home --home-dir /var/lib/caddy --shell /usr/sbin/nologin caddy || true

echo "Setting up Caddy systemd service..."
sudo tee ${CADDY_SERVICE_PATH} > /dev/null <<EOL
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=caddy
Group=caddy
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOL

echo "Setting up Caddyfile..."


if [ ! -d "${CADDY_CONF_PATH}" ]; then
    echo "Directory ${CADDY_CONF_PATH} not found. Creating it..."
    sudo mkdir -p "${CADDY_CONF_PATH}"
    echo "Directory ${CADDY_CONF_PATH} created successfully."
else
    echo "Directory ${CADDY_CONF_PATH} already exists."
fi

# Prompt user for necessary informations
GITHUB_CLIENT_ID=$(prompt "GITHUB_CLIENT_ID" "Enter your GitHub OAuth Client ID: ")
GITHUB_CLIENT_SECRET=$(prompt "GITHUB_CLIENT_SECRET" "Enter your GitHub OAuth Client Secret: " "true")
echo ""
DOMAIN=$(prompt "DOMAIN" "Enter the domain name: ")
GITHUB_USERNAME=$(prompt "GITHUB_USERNAME" "Enter your GitHub username: ")
AUTH_SUBDOMAIN=$(prompt "AUTH_SUBDOMAIN" "Enter the Auth subdomain: ")
APP_SUBDOMAIN=$(prompt "APP_SUBDOMAIN" "Enter the App subdomain: ")


# Create Caddyfile with user input
echo "Generating Caddyfile..."
sudo tee ${CADDY_CONF_PATH}/Caddyfile > /dev/null <<EOL
{
    order authenticate before respond
    order authorize before basicauth

    security {
        oauth identity provider github ${GITHUB_CLIENT_ID} ${GITHUB_CLIENT_SECRET}

        authentication portal myportal {
            crypto default token lifetime 3600
            cookie domain ${DOMAIN}
            enable identity provider github
            ui {
                links {
                    "My Identity" "/whoami" icon "las la-user"
                }
            }

            transform user {
                match realm github
                action add role authp/user
            }

            transform user {
                match realm github
                match sub github.com/${GITHUB_USERNAME}
                action add role authp/admin
            }
        }

        authorization policy mypolicy {
            set auth url ${AUTH_SUBDOMAIN}/oauth2/github
            allow roles authp/admin
            validate bearer header
            inject headers with claims
        }
    }
}

${AUTH_SUBDOMAIN} {
    authenticate with myportal
}

${APP_SUBDOMAIN} {

    reverse_proxy /rest/v1/* localhost:8000
    reverse_proxy /auth/v1/* localhost:8000
    reverse_proxy /realtime/v1/* localhost:8000
    reverse_proxy /storage/v1/* localhost:8000

    route /project* {
        authorize with mypolicy
        reverse_proxy localhost:3000
    }
    reverse_proxy * localhost:3000

}
EOL

echo "Caddyfile has been created at /etc/caddy/Caddyfile"

echo "Reloading systemd and enabling Caddy service..."
sudo systemctl daemon-reload
sudo systemctl enable --now caddy

echo "Installation complete. Verify Caddy status with: sudo systemctl status caddy"
