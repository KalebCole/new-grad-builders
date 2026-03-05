#!/usr/bin/env bash
# setup-openclaw-vm.sh — Bootstrap an Ubuntu 22.04 VM for OpenClaw
# Usage: curl -fsSL <raw-url>/setup-openclaw-vm.sh | bash
# Run as root or with sudo

set -euo pipefail

echo "============================================"
echo "  New Grad Builders — OpenClaw VM Setup"
echo "============================================"
echo ""

# --- 1. System updates ---
echo "[1/11] Updating system packages..."
apt-get update -qq && apt-get upgrade -y -qq

# --- 2. Install essentials ---
echo "[2/11] Installing essential tools..."
apt-get install -y -qq \
  curl wget git unzip jq htop tmux \
  build-essential ca-certificates gnupg lsb-release \
  fail2ban iptables-persistent

# --- 3. Install Node.js 20 ---
echo "[3/11] Installing Node.js 20 LTS..."
if ! command -v node &>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y -qq nodejs
fi
echo "  Node.js $(node --version) installed"
echo "  npm $(npm --version) installed"

# --- 4. Install OpenClaw ---
echo "[4/11] Installing OpenClaw..."
npm install -g openclaw
echo "  OpenClaw $(openclaw --version 2>/dev/null || echo 'installed') ready"

# --- 5. Install Chromium + Xvfb + nodriver (headed browser on a headless VM) ---
echo "[5/11] Installing Chromium + Xvfb + nodriver..."
apt-get install -y -qq xvfb python3-pip
snap install chromium
pip3 install --quiet nodriver>=0.38
# Create a systemd service for Xvfb so the virtual display persists
cat > /etc/systemd/system/xvfb.service << 'XVFB'
[Unit]
Description=Xvfb Virtual Framebuffer
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/Xvfb :99 -screen 0 1920x1080x24 -ac
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
XVFB
systemctl daemon-reload
systemctl enable --now xvfb
echo "  Chromium $(chromium --version 2>/dev/null || echo 'installed')"
echo "  nodriver $(pip3 show nodriver 2>/dev/null | grep Version | cut -d' ' -f2 || echo 'installed')"
echo "  Xvfb running on display :99"
echo "  TIP: Set DISPLAY=:99 for headed browser automation"

# --- 6. Create dedicated openclaw user ---
echo "[6/11] Creating dedicated 'openclaw' user..."
if ! id -u openclaw &>/dev/null; then
  useradd -m -s /bin/bash -r openclaw
  echo "  User 'openclaw' created (system user)"
else
  echo "  User 'openclaw' already exists"
fi

# Lock down root files from openclaw user
chmod 700 /root
chmod 600 /root/.bashrc /root/.profile 2>/dev/null || true

# --- 6. Secrets management (systemd LoadCredential) ---
echo "[7/11] Setting up secrets management..."
mkdir -p /etc/openclaw/secrets
chmod 700 /etc/openclaw
chmod 700 /etc/openclaw/secrets
chown root:root /etc/openclaw /etc/openclaw/secrets

# Create a template .env file for reference
cat > /etc/openclaw/secrets/.env.template << 'TEMPLATE'
# Add secrets as individual files in this directory.
# Example:
#   echo "sk-your-key" > /etc/openclaw/secrets/anthropic_key
#   chmod 600 /etc/openclaw/secrets/anthropic_key
#
# These get loaded via systemd LoadCredential into the openclaw service.
# The openclaw user NEVER has direct filesystem access to these files.
#
# Supported secret files:
#   anthropic_key       - Anthropic API key
#   openrouter_key      - OpenRouter API key
#   telegram_token      - Telegram bot token
#   github_pat          - GitHub personal access token
#   openai_key          - OpenAI API key
TEMPLATE
chmod 600 /etc/openclaw/secrets/.env.template

# Backward-compat: also create inject-env.sh for manual use
cat > /root/inject-env.sh << 'ENVSCRIPT'
#!/usr/bin/env bash
# Inject secrets from /etc/openclaw/secrets/ as env vars for one-off commands.
# For the systemd service, secrets are loaded via LoadCredential instead.
SECRETS_DIR="/etc/openclaw/secrets"
if [ -d "$SECRETS_DIR" ]; then
  for f in "$SECRETS_DIR"/*; do
    [ -f "$f" ] || continue
    key=$(basename "$f" | tr '[:lower:]' '[:upper:]')
    value=$(cat "$f")
    export "$key=$value"
  done
fi
exec sudo -u openclaw -E "$@"
ENVSCRIPT
chmod 700 /root/inject-env.sh

echo "  Secrets directory ready at /etc/openclaw/secrets/"
echo "  Manual injection script at /root/inject-env.sh"

# --- 7. OpenClaw systemd service (with sandboxing) ---
echo "[8/11] Creating OpenClaw systemd service..."
cat > /etc/systemd/system/openclaw.service << 'SERVICE'
[Unit]
Description=OpenClaw AI Assistant
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=openclaw
Group=openclaw
WorkingDirectory=/home/openclaw
Environment=DISPLAY=:99

# Secrets: systemd reads root-owned files, exposes via tmpfs-backed $CREDENTIALS_DIRECTORY
# Add more LoadCredential lines as you add secrets to /etc/openclaw/secrets/
LoadCredential=anthropic_key:/etc/openclaw/secrets/anthropic_key
LoadCredential=telegram_token:/etc/openclaw/secrets/telegram_token
# LoadCredential=openrouter_key:/etc/openclaw/secrets/openrouter_key
# LoadCredential=github_pat:/etc/openclaw/secrets/github_pat
# LoadCredential=openai_key:/etc/openclaw/secrets/openai_key

ExecStart=/usr/bin/openclaw start
Restart=on-failure
RestartSec=10

# --- Process Sandboxing ---
NoNewPrivileges=true
ProtectSystem=strict
PrivateTmp=true
ProtectKernelTunables=true
ProtectControlGroups=true
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX AF_NETLINK

# Allow OpenClaw to write to its own directories
ReadWritePaths=/home/openclaw

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
# Don't enable yet — user needs to add secrets and run onboard first
echo "  openclaw.service created (not enabled yet — run onboard first)"

# --- 8. SSH hardening ---
echo "[9/11] Hardening SSH configuration..."
cat > /etc/ssh/sshd_config.d/99-hardened.conf << 'SSHCONFIG'
# New Grad Builders — SSH Hardening
# Applied on top of default sshd_config

# Authentication
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey
ChallengeResponseAuthentication no
PermitEmptyPasswords no

# Limits
MaxAuthTries 3
MaxSessions 3
LoginGraceTime 30

# Disable unused features
X11Forwarding no
AllowTcpForwarding no

# Restrict to the admin user only
AllowUsers azureuser

# Modern crypto only
KexAlgorithms curve25519-sha256@libssh.org,curve25519-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
SSHCONFIG

# Validate config before restarting
if sshd -t 2>/dev/null; then
  systemctl restart sshd
  echo "  SSH hardened: root login disabled, key-only auth, modern crypto"
else
  echo "  WARNING: SSH config validation failed — reverting"
  rm -f /etc/ssh/sshd_config.d/99-hardened.conf
fi

# --- 9. Configure UFW firewall ---
echo "[10/11] Configuring firewall (UFW)..."
apt-get install -y -qq ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
echo "y" | ufw enable
echo "  Firewall active — all inbound blocked except SSH (22)"
echo "  TIP: After setting up Tailscale, tighten SSH to Tailscale only:"
echo "       sudo ufw delete allow ssh"
echo "       sudo ufw allow from 100.64.0.0/10 to any port 22"

# --- 10. Azure metadata + fail2ban + Tailscale ---
echo "[11/11] Final hardening + Tailscale..."

# Azure metadata endpoint lockdown — prevent non-root from querying IMDS
# This blocks SSRF attacks from reaching the Azure Instance Metadata Service
iptables -A OUTPUT -d 168.63.129.16 -m owner ! --uid-owner 0 -m state --state NEW -j DROP
# Persist the rule across reboots
netfilter-persistent save 2>/dev/null || true
echo "  Azure metadata endpoint locked down (root-only access)"

# fail2ban (installed in step 2, just make sure it's enabled)
systemctl enable --now fail2ban
echo "  fail2ban active on SSH"

# Tailscale
if ! command -v tailscale &>/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
  echo "  Tailscale installed — run 'sudo tailscale up' to authenticate"
else
  echo "  Tailscale already installed"
fi

echo ""
echo "============================================"
echo "  ✅ Setup Complete!"
echo "============================================"
echo ""
echo "SECURITY SUMMARY:"
echo "  ✓ SSH hardened (key-only, no root, modern crypto, 3 max attempts)"
echo "  ✓ fail2ban active on SSH"
echo "  ✓ UFW firewall (deny all inbound except SSH)"
echo "  ✓ Azure metadata locked to root only"
echo "  ✓ Dedicated openclaw user (no sudo, no docker)"
echo "  ✓ Secrets in /etc/openclaw/secrets/ (root-owned, 600 perms)"
echo "  ✓ systemd service with sandboxing (NoNewPrivileges, ProtectSystem)"
echo "  ✓ Chromium + Xvfb + nodriver (stealth browser on display :99)"
echo "  ✓ Tailscale ready for VPN access"
echo ""
echo "NEXT STEPS:"
echo ""
echo "  1. Connect Tailscale:"
echo "     sudo tailscale up"
echo ""
echo "  2. (Recommended) Restrict SSH to Tailscale only:"
echo "     sudo ufw delete allow ssh"
echo "     sudo ufw allow from 100.64.0.0/10 to any port 22"
echo ""
echo "  3. Add secrets:"
echo "     echo 'sk-your-key' | sudo tee /etc/openclaw/secrets/anthropic_key"
echo "     sudo chmod 600 /etc/openclaw/secrets/anthropic_key"
echo "     echo 'your-token' | sudo tee /etc/openclaw/secrets/telegram_token"
echo "     sudo chmod 600 /etc/openclaw/secrets/telegram_token"
echo ""
echo "  4. Run OpenClaw onboarding:"
echo "     /root/inject-env.sh openclaw onboard"
echo ""
echo "  5. Enable and start the service:"
echo "     sudo systemctl enable --now openclaw"
echo ""
echo "  6. Install an emergency coding agent on root:"
echo "     npm install -g @anthropics/claude-code"
echo "     # or: copilot-cli, opencode"
echo ""
echo "  7. Install Termius on your phone for mobile SSH access"
echo ""
echo "  Happy building! 🤖"
