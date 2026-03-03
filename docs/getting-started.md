# Getting Started — New Grad Builders Session 1

> **Point your Copilot at this doc and say: "do this for me." Seriously, that's it.**

## What You Need

- [ ] **Personal GitHub account** linked to Microsoft org — go to [aka.ms/copilot](https://aka.ms/copilot) and link your personal account
- [ ] **GitHub Copilot** enabled — you get unlimited access through Microsoft, just make sure it's on at [github.com/settings/copilot](https://github.com/settings/copilot)
- [ ] **Azure subscription** with free credits — check at [portal.azure.com](https://portal.azure.com) → Cost Management
- [ ] **Telegram** on your phone ([telegram.org](https://telegram.org))
- [ ] **SSH client** — Terminal (Mac/Linux), Windows Terminal, or [Termius](https://termius.com) on your phone

## Quick Start (5 minutes)

### 1. Create your Azure VM

```bash
az vm create \
  --resource-group personal-agents \
  --name openclaw-vm \
  --image Ubuntu2204 \
  --size Standard_B2ms \
  --admin-username azureuser \
  --generate-ssh-keys
```

### 2. SSH in and run setup

```bash
ssh azureuser@<your-vm-ip>
curl -fsSL https://raw.githubusercontent.com/<your-username>/new-grad-builders/main/demo/setup-openclaw-vm.sh | sudo bash
```

### 3. Run OpenClaw onboarding

```bash
sudo /root/inject-env.sh openclaw onboard
```

### 4. Set up Telegram bot

1. Open Telegram → message **@BotFather**
2. Send `/newbot` → follow prompts → copy the bot token
3. Add to your VM:
   ```bash
   sudo sh -c 'echo "TELEGRAM_BOT_TOKEN=<your-token>" >> /root/.openclaw-env'
   ```

### 5. Connect Google Calendar (optional but cool)

Grab [gogcli](https://github.com/steipete/gogcli) — it puts Google Calendar, Gmail, Drive, Contacts, and Tasks in your terminal:

```bash
# On Linux VM (build from source)
git clone https://github.com/steipete/gogcli.git
cd gogcli && make
sudo cp bin/gog /usr/local/bin/

# On Mac (for local use)
brew install steipete/tap/gogcli
```

Set up Google OAuth (or just tell your agent: *"Set up Google Calendar integration via GCP CLI"* and let it figure it out):

```bash
# Create project + enable APIs
gcloud projects create my-openclaw-project
gcloud services enable calendar-json.googleapis.com --project my-openclaw-project
gcloud services enable gmail.googleapis.com --project my-openclaw-project

# Create OAuth credentials
# Go to console.cloud.google.com → APIs & Services → Credentials → Create OAuth 2.0 Client ID
# Download the JSON file

# Authenticate gogcli
gog account add --client-id <id> --client-secret <secret>
```

### 6. Secure your VM

Setup already locks down the firewall and isolates users. Want extra credit?
```bash
sudo tailscale up   # Mesh VPN — access your VM from anywhere securely
```

## Now Go Break Stuff

- Ask your agent: *"What's on my calendar today?"*
- Ask your agent: *"Summarize my unread emails"*
- Ask your agent: *"Set up a daily morning briefing at 7 AM"*
- Browse [skills.sh](https://skills.sh) for Copilot agent skills
- Browse [ClawHub](https://clawhub.com) for OpenClaw skills (vector search registry)

## Resources

| Resource | Link |
|----------|------|
| OpenClaw | [github.com/openinterface/openclaw](https://github.com/openinterface/openclaw) |
| gogcli | [github.com/steipete/gogcli](https://github.com/steipete/gogcli) |
| Copilot setup | [aka.ms/copilot](https://aka.ms/copilot) |
| Skills (Copilot) | [skills.sh](https://skills.sh) |
| Skills (OpenClaw) | [clawhub.com](https://clawhub.com) |
| awesome-copilot | [github.com/github/awesome-copilot](https://github.com/github/awesome-copilot) |
| Tailscale | [tailscale.com](https://tailscale.com) |
| Termius (mobile SSH) | [termius.com](https://termius.com) |

## Troubleshooting

| Problem | Fix |
|---------|-----|
| VM ran out of free credits | Check your spending in Azure portal. B2s is cheaper (~$30/mo) |
| OpenClaw won't start | SSH in as root, then tell your coding agent: *"Check OpenClaw logs, find the error, and fix it."* Manual: `journalctl -u openclaw --no-pager -n 50`, then `sudo systemctl restart openclaw`. Common causes: expired tokens (re-run `gog account add`), out of disk (`df -h`), Node crashed (check `~/.openclaw/logs/`) |
| Can't SSH from phone | Install Termius, use your Tailscale IP instead of public IP |
| Agent seems slow | Make sure your personal GitHub is linked via [aka.ms/copilot](https://aka.ms/copilot) for unlimited access |

## Stuck?

Drop a message in the **New Grad Builders** Teams chat. Someone's probably hit the same wall.
