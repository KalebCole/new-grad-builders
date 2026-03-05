# OpenClaw VM Setup — E2E Session Log

**Date:** 2026-03-05
**Stack:** Azure VM + GitHub Copilot + Telegram Bot
**Model:** `github-copilot/claude-opus-4.6`

---

## 1. Create Azure VM

**User:** Create the new Azure VM and give me the step-by-step on setting up the Telegram bot e2e.

Ran `demo/create-vm.sh` which provisions a Standard_B2ms Ubuntu 22.04 VM:

```
============================================
  New Grad Builders — Create Azure VM
============================================

Subscription: Visual Studio Enterprise Subscription

[1/2] Creating resource group 'personal-agents' in westus2...
  ✓ Resource group ready
[2/2] Creating VM 'openclaw-vm' (Standard_B2ms, Ubuntu2204)...
  ✓ VM created

  Public IP: [REDACTED]
```

---

## 2. Run Setup Script (`setup-openclaw-vm.sh`)

SSH'd into the VM and ran the bootstrap script from the PR branch (with `tr -d '\r'` to strip CRLF):

```bash
curl -fsSL https://raw.githubusercontent.com/KalebCole/new-grad-builders/add-vm-security-presentation-script/demo/setup-openclaw-vm.sh \
  | tr -d '\r' | sudo bash
```

All 12 steps completed:

```
[1/12]  Updating system packages...          ✓
[2/12]  Installing essential tools...         ✓
[3/12]  Installing Node.js 22 LTS...         ✓  (v22.22.0)
[4/12]  Installing OpenClaw...                ✓
[5/12]  Installing Chromium + Xvfb...         ✓
[6/12]  Creating dedicated 'openclaw' user... ✓
[7/12]  Setting up secrets management...      ✓
[8/12]  Creating OpenClaw systemd service...  ✓
[9/12]  Hardening SSH configuration...        ✓
[10/12] Configuring firewall (UFW)...         ✓
[11/12] Applying kernel hardening...          ✓
[12/12] Final hardening + Tailscale...        ✓
```

**Security summary:** SSH hardened, fail2ban active, UFW deny-all, Azure IMDS locked, kernel hardened, dedicated user, sandboxed systemd service, automatic security updates, Tailscale ready.

---

## 3. Run Secret Proxy Script (`setup-secret-proxy.sh`)

Ran the optional per-command secret scoping proxy:

```
[1/4] Creating secret proxy...
  Proxy application written to /opt/secret-proxy/index.js
  Logrotate configured for /var/log/openclaw/secret-proxy.log
  secret-proxy.service enabled and started

  ✓ Secret Proxy Installed!
```

The proxy scopes each secret to specific commands (e.g., `ynab_key` only available to the `ynab` command). Rate limited to 60 req/min.

---

## 4. GitHub Copilot Instead of Anthropic API

**User:** Instead of Anthropic API key — I want to use my GHCP subscription. How?

Discovered OpenClaw has **built-in GitHub Copilot support** via `openclaw models auth login-github-copilot`. Available models include:

```
github-copilot/claude-haiku-4.5
github-copilot/claude-opus-4.6
github-copilot/claude-sonnet-4.6
github-copilot/gemini-2.5-pro
github-copilot/gpt-5
...
```

No separate API key needed — the Copilot subscription covers all model access.

---

## 5. Add Telegram Bot Token

**User:** Created a bot via @BotFather and provided the token.

Saved the token to the secrets directory:

```bash
echo '[REDACTED]' | sudo tee /etc/openclaw/secrets/telegram_token
sudo chmod 600 /etc/openclaw/secrets/telegram_token
```

---

## 6. GitHub Copilot Device Auth

Ran `openclaw models auth login-github-copilot --yes` as the `openclaw` user. This uses GitHub's device flow (same as signing into VS Code).

Required `ssh -tt` for forced TTY allocation since the CLI renders a TUI. After two expired device codes, the third succeeded:

```
GitHub Copilot login

✓ Device code ready
✓ Authorize
  Visit: https://github.com/login/device
  Code:  EE73-0B4A

  Waiting for GitHub authorization...
  ✓ GitHub access token acquired

Updated ~/.openclaw/openclaw.json
Auth profile: github-copilot:github (github-copilot/token)
  Done
```

---

## 7. Set Model & Configure Telegram

```bash
# Set the default model
sudo -u openclaw openclaw models set github-copilot/claude-sonnet-4.6

# Configure Telegram channel
sudo -u openclaw openclaw config set channels.telegram.botToken '[REDACTED]'
sudo -u openclaw openclaw config set channels.telegram.dmPolicy open
sudo -u openclaw openclaw config set channels.telegram.allowFrom '["*"]'
sudo -u openclaw openclaw config set gateway.mode local
```

Key config decisions:
- `dmPolicy: open` — anyone can DM the bot (for testing)
- `allowFrom: ["*"]` — wildcard access (lock down later with specific Telegram user IDs)
- `gateway.mode: local` — required for the gateway to start without wide-area discovery

---

## 8. Fix systemd Service & Start Gateway

Hit several issues getting the systemd service running:

| Issue | Cause | Fix |
|-------|-------|-----|
| exit 243/CREDENTIALS | `LoadCredential=anthropic_key` — file doesn't exist (using GHCP) | Commented out the line |
| exit 200/CHDIR | `ProtectHome=true` blocked `/home/openclaw` | Changed to `ProtectHome=false` |
| exit 226/NAMESPACE | `ProtectHome=tmpfs` failed on this kernel | Settled on `ProtectHome=false` |
| "unknown command 'start'" | `openclaw start` not valid in v2026.3.2 | Changed to `openclaw gateway --port 18789` |
| "Gateway start blocked" | Missing gateway mode config | Set `gateway.mode=local` |

After all fixes, the gateway started:

```
openclaw.service - OpenClaw AI Assistant
  Active: active (running)

[canvas]     host mounted at http://localhost:18789/__openclaw__/canvas/
[heartbeat]  started
[gateway]    agent model: github-copilot/claude-sonnet-4.6
[gateway]    listening on ws://localhost:18789 (PID 13713)
[browser]    Browser control listening on http://localhost:18791/
[telegram]   [default] starting provider (@KalebVM2bot)
```

---

## 9. Upgrade to Opus 4.6 & Security Audit

**User:** Make it Claude Opus 4.6. Also — is this publicly exposed?

```bash
sudo -u openclaw openclaw models set github-copilot/claude-opus-4.6
```

Security audit — **all hardening active:**

| Check | Status | Details |
|-------|--------|---------|
| UFW Firewall | ✓ | deny incoming, allow outgoing, deny routed. Only SSH (22) in. |
| Gateway Ports | ✓ | 18789, 18791, 18792 all **localhost only** — not public |
| IMDS Blocked | ✓ | Both 169.254.169.254 and 168.63.129.16 DROP for non-root |
| Kernel Hardening | ✓ | tcp_syncookies=1, accept_redirects=0 |
| SSH Hardening | ✓ | Key-only, no root, modern crypto, MaxAuthTries 3 |
| fail2ban | ✓ | Active on SSH |
| User Isolation | ✓ | Dedicated `openclaw` user, no sudo, no docker |
| Secret Proxy | ✓ | Per-command scoping, rate limited, audit logged |
| Unattended Upgrades | ✓ | Automatic security patches |

Telegram works via **outbound long-polling** — no inbound port needed or exposed.

**Remaining step:** Lock SSH to Tailscale-only:

```bash
sudo tailscale up
sudo ufw delete allow ssh
sudo ufw allow from 100.64.0.0/10 to any port 22
```

---

## Architecture

```
                        Internet
                           |
                    +--------------+
                    |  Azure NSG   |  (only port 22 open)
                    +--------------+
                           |
                    +--------------+
                    |   UFW        |  deny incoming / allow outgoing / deny routed
                    |   + fail2ban |  (SSH brute force protection)
                    +--------------+
                           |
              +------------+------------+
              |                         |
      +-------+-------+        +-------+-------+
      |  SSH (port 22) |        | OpenClaw GW   |
      |  key-only auth |        | localhost:18789|
      |  no root       |        | (NOT public)  |
      +----------------+        +-------+-------+
                                        |
                              +---------+---------+
                              |                   |
                       +------+------+    +-------+-------+
                       |  Telegram   |    | GitHub Copilot|
                       |  (outbound  |    | Claude Opus   |
                       |   polling)  |    | 4.6           |
                       +-------------+    +---------------+

      Secrets: /etc/openclaw/secrets/ (root:root, 700)
      Proxy:   /run/openclaw/secret-proxy.sock (per-command scoping)
      User:    openclaw (no sudo, no docker, sandboxed systemd)
      IMDS:    Both endpoints DROP'd for non-root
      Kernel:  syncookies, no redirects, no source routing, rp_filter
```

---

## Final Configuration

### `openclaw.json` (key fields)

```json
{
  "auth": {
    "profiles": {
      "github-copilot:github": {
        "provider": "github-copilot",
        "mode": "token"
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "github-copilot/claude-opus-4.6"
      }
    }
  },
  "channels": {
    "telegram": {
      "botToken": "[REDACTED]",
      "dmPolicy": "open",
      "allowFrom": ["*"]
    }
  },
  "gateway": {
    "mode": "local"
  }
}
```

### `openclaw.service` (final)

```ini
[Service]
Type=simple
User=openclaw
Group=openclaw
WorkingDirectory=/home/openclaw
Environment=DISPLAY=:99
# LoadCredential=anthropic_key  (commented out — using GHCP)
LoadCredential=telegram_token:/etc/openclaw/secrets/telegram_token
ExecStart=/usr/bin/openclaw gateway --port 18789
Restart=on-failure
RestartSec=10

# Sandboxing
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=false
PrivateTmp=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectControlGroups=true
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX AF_NETLINK
ReadWritePaths=/home/openclaw
```
