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
echo "[1/7] Updating system packages..."
apt-get update -qq && apt-get upgrade -y -qq

# --- 2. Install essentials ---
echo "[2/7] Installing essential tools..."
apt-get install -y -qq \
  curl wget git unzip jq htop tmux \
  build-essential ca-certificates gnupg lsb-release

# --- 3. Install Node.js 20 ---
echo "[3/7] Installing Node.js 20 LTS..."
if ! command -v node &>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y -qq nodejs
fi
echo "  Node.js $(node --version) installed"
echo "  npm $(npm --version) installed"

# --- 4. Install OpenClaw ---
echo "[4/7] Installing OpenClaw..."
npm install -g openclaw
echo "  OpenClaw $(openclaw --version 2>/dev/null || echo 'installed') ready"

# --- 5. Create dedicated openclaw user ---
echo "[5/7] Creating dedicated 'openclaw' user..."
if ! id -u openclaw &>/dev/null; then
  useradd -m -s /bin/bash openclaw
  echo "  User 'openclaw' created"
else
  echo "  User 'openclaw' already exists"
fi

# Lock down root files from openclaw user
chmod 700 /root
chmod 600 /root/.bashrc /root/.profile 2>/dev/null || true

# Create env injection mechanism
cat > /root/inject-env.sh << 'ENVSCRIPT'
#!/usr/bin/env bash
# Inject environment variables into openclaw user's session
# Add secrets to /root/.openclaw-env (one per line: KEY=VALUE)
ENV_FILE="/root/.openclaw-env"
if [ -f "$ENV_FILE" ]; then
  while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    export "$key=$value"
  done < "$ENV_FILE"
fi
exec sudo -u openclaw -E "$@"
ENVSCRIPT
chmod 700 /root/inject-env.sh

# Create the env file
touch /root/.openclaw-env
chmod 600 /root/.openclaw-env
echo "  Env injection mechanism ready at /root/.openclaw-env"

# --- 6. Configure UFW firewall ---
echo "[6/7] Configuring firewall (UFW)..."
apt-get install -y -qq ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
echo "y" | ufw enable
echo "  Firewall active — all inbound blocked except SSH (22)"

# --- 7. Install Tailscale ---
echo "[7/7] Installing Tailscale..."
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
echo "NEXT STEPS (manual):"
echo ""
echo "  1. Connect Tailscale:"
echo "     sudo tailscale up"
echo ""
echo "  2. Run OpenClaw onboarding as the openclaw user:"
echo "     /root/inject-env.sh openclaw onboard"
echo ""
echo "  3. Add secrets to /root/.openclaw-env:"
echo "     echo 'TELEGRAM_BOT_TOKEN=your-token' >> /root/.openclaw-env"
echo "     echo 'GITHUB_TOKEN=your-token' >> /root/.openclaw-env"
echo ""
echo "  4. Set up your Telegram bot:"
echo "     - Message @BotFather on Telegram"
echo "     - Create a new bot, get the token"
echo "     - Add to /root/.openclaw-env"
echo ""
echo "  5. Connect data sources (Google Calendar, etc.):"
echo "     /root/inject-env.sh bash"
echo "     # Then follow OpenClaw docs for gogcli setup"
echo ""
echo "  6. Install an emergency coding agent on root:"
echo "     npm install -g @anthropics/claude-code"
echo "     # or: npm install -g @anthropics/opencode"
echo ""
echo "  7. Install Termius on your phone for mobile SSH access"
echo ""
echo "  Happy building! 🤖"
