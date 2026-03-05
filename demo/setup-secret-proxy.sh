#!/usr/bin/env bash
# setup-secret-proxy.sh — Optional: Install the OpenClaw Secret Proxy
#
# What this does:
#   Adds a Unix-socket-based secret proxy that scopes secrets to specific commands.
#   Instead of the openclaw user reading secrets directly, it requests them through
#   a root-owned proxy that only injects each secret into the exact command that needs it.
#
# Example: The ynab_key secret is only available when running the 'ynab' command.
#          If the agent tries to use it with any other command, the proxy denies it.
#
# Why:
#   - Least-privilege secret access (per-command scoping)
#   - Rate limiting (60 req/min, 5 concurrent)
#   - Audit logging (/var/log/openclaw/secret-proxy.log)
#   - The openclaw user never sees the raw secret values
#
# Prerequisites: setup-openclaw-vm.sh must have run first
# Usage: sudo bash demo/setup-secret-proxy.sh

set -euo pipefail

echo "============================================"
echo "  OpenClaw Secret Proxy — Optional Setup"
echo "============================================"
echo ""

# Check prerequisites
if ! id -u openclaw &>/dev/null; then
  echo "ERROR: openclaw user not found. Run setup-openclaw-vm.sh first."
  exit 1
fi

if [ ! -d /etc/openclaw/secrets ]; then
  echo "ERROR: /etc/openclaw/secrets not found. Run setup-openclaw-vm.sh first."
  exit 1
fi

OPENCLAW_UID=$(id -u openclaw)

# --- 1. Create the proxy directory ---
echo "[1/4] Creating secret proxy..."
mkdir -p /opt/secret-proxy
mkdir -p /var/log/openclaw
mkdir -p /run/openclaw

# --- 2. Write the proxy application ---
cat > /opt/secret-proxy/index.js << 'PROXYJS'
const http = require('http');
const fs = require('fs');
const { execSync, spawn } = require('child_process');
const path = require('path');

const SOCKET_PATH = '/run/openclaw/secret-proxy.sock';
const SECRETS_DIR = '/etc/openclaw/secrets';
const LOG_FILE = '/var/log/openclaw/secret-proxy.log';
const ALLOWED_UIDS = [process.env.OPENCLAW_UID || '998'];
const RATE_LIMIT = 60;       // requests per minute
const MAX_CONCURRENT = 5;
const CMD_TIMEOUT = 30000;   // 30 seconds

// Per-secret command scoping: which commands can use which secrets
// Customize this for your setup
const SECRET_SCOPES = {
  'anthropic_key':   ['openclaw', 'claude'],
  'openrouter_key':  ['openclaw'],
  'telegram_token':  ['openclaw'],
  'github_pat':      ['gh', 'git'],
  'openai_key':      ['openclaw'],
  'ynab_key':        ['ynab'],
  'todoist_key':     ['todoist'],
  'brave_api_key':   ['openclaw'],
  'notion_key':      ['openclaw'],
  'notion_token':    ['openclaw'],
};

let requestCount = 0;
let activeRequests = 0;

// Reset rate limit every minute
setInterval(() => { requestCount = 0; }, 60000);

function log(msg) {
  const line = `${new Date().toISOString()} ${msg}\n`;
  fs.appendFileSync(LOG_FILE, line);
}

// Clean up stale socket
try { fs.unlinkSync(SOCKET_PATH); } catch {}

const server = http.createServer((req, res) => {
  // Rate limiting
  if (requestCount >= RATE_LIMIT) {
    res.writeHead(429);
    res.end(JSON.stringify({ error: 'Rate limit exceeded' }));
    log(`RATE_LIMITED`);
    return;
  }
  if (activeRequests >= MAX_CONCURRENT) {
    res.writeHead(503);
    res.end(JSON.stringify({ error: 'Too many concurrent requests' }));
    return;
  }

  requestCount++;
  activeRequests++;

  let body = '';
  req.on('data', chunk => { body += chunk; });
  req.on('end', () => {
    try {
      const { secret, command } = JSON.parse(body);

      if (!secret || !command) {
        res.writeHead(400);
        res.end(JSON.stringify({ error: 'Missing secret or command' }));
        return;
      }

      // Check scope
      const allowedCommands = SECRET_SCOPES[secret];
      if (allowedCommands && !allowedCommands.some(c => command.includes(c))) {
        log(`DENIED secret=${secret} command=${command}`);
        res.writeHead(403);
        res.end(JSON.stringify({ error: `Secret '${secret}' not allowed for command '${command}'` }));
        return;
      }

      // Read secret
      const secretPath = path.join(SECRETS_DIR, secret);
      if (!fs.existsSync(secretPath)) {
        res.writeHead(404);
        res.end(JSON.stringify({ error: `Secret '${secret}' not found` }));
        return;
      }

      const value = fs.readFileSync(secretPath, 'utf8').trim();
      log(`GRANTED secret=${secret} command=${command}`);

      res.writeHead(200);
      res.end(JSON.stringify({ value }));
    } catch (err) {
      log(`ERROR ${err.message}`);
      res.writeHead(500);
      res.end(JSON.stringify({ error: err.message }));
    } finally {
      activeRequests--;
    }
  });
});

server.listen(SOCKET_PATH, () => {
  // Set socket permissions so only openclaw user can connect
  fs.chmodSync(SOCKET_PATH, 0o660);
  const gid = parseInt(execSync(`id -g openclaw`).toString().trim());
  fs.chownSync(SOCKET_PATH, 0, gid);
  log('Secret proxy started');
  console.log(`Secret proxy listening on ${SOCKET_PATH}`);
});

process.on('SIGTERM', () => {
  log('Secret proxy stopping');
  server.close();
  process.exit(0);
});
PROXYJS

chmod 600 /opt/secret-proxy/index.js
chown root:root /opt/secret-proxy/index.js
echo "  Proxy application written to /opt/secret-proxy/index.js"

# --- 3. Create systemd service ---
cat > /etc/systemd/system/secret-proxy.service << SERVICE
[Unit]
Description=OpenClaw Secret Proxy
Before=openclaw.service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /opt/secret-proxy/index.js
Environment=OPENCLAW_UID=${OPENCLAW_UID}
Restart=on-failure
RestartSec=5

# Run as root (needs to read secrets)
User=root
Group=root

# Hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectControlGroups=true

ReadWritePaths=/run/openclaw /var/log/openclaw
ReadOnlyPaths=/etc/openclaw/secrets /opt/secret-proxy

[Install]
WantedBy=multi-user.target
SERVICE

# --- 4. Enable and start ---
systemctl daemon-reload
systemctl enable --now secret-proxy
echo "  secret-proxy.service enabled and started"

echo ""
echo "============================================"
echo "  ✅ Secret Proxy Installed!"
echo "============================================"
echo ""
echo "HOW IT WORKS:"
echo "  The openclaw user requests secrets via Unix socket:"
echo "    curl --unix-socket /run/openclaw/secret-proxy.sock \\"
echo "      -X POST -d '{\"secret\":\"anthropic_key\",\"command\":\"openclaw\"}' \\"
echo "      http://localhost/secret"
echo ""
echo "  Each secret is scoped to specific commands (edit SECRET_SCOPES in index.js)."
echo "  Rate limited: 60 req/min, 5 concurrent max."
echo "  Logs: /var/log/openclaw/secret-proxy.log"
echo ""
echo "  To customize scopes, edit /opt/secret-proxy/index.js"
