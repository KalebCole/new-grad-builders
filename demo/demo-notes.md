# Demo Notes — Session 1: Autonomous AI Agents

> Presenter reference only. These are the step-by-step commands and talking points for the live walkthrough.

## Pre-Demo Checklist

- [ ] Fresh Azure VM ready (or create one live)
- [ ] SSH key set up
- [ ] Telegram bot token ready (create one before or live)
- [ ] Google Cloud project with Calendar API enabled (or do live)
- [ ] Termius on phone for emergency access demo
- [ ] OpenClaw car-hunting project running for the hook demo

---

## PART 1: THE HOOK (5 min)

### Talking points:
- Open Telegram on phone → show agent conversation
- Show the car-hunting results ("Here's what my agent found overnight")
- Show calendar summary ("It checked my calendar at 7 AM and texted me a briefing")
- Frame: "All of this is running on a $0/month Azure VM. Let me show you how."

---

## PART 2: THE SETUP (25 min)

### Step 1: GitHub Copilot (2 min)

**Show on screen:** [aka.ms/copilot](https://aka.ms/copilot)

```
Walk through:
1. Click "Link personal account"
2. Show the confirmation: "GitHub Copilot enabled for your <username> personal GitHub account for use everywhere"
3. Show: "Access granted through your MicrosoftCopilot GitHub organization membership"
```

**Key talking point:** "This is NOT your EMU account. This is your personal GitHub. Microsoft gives you unlimited Copilot through the MicrosoftCopilot org. Model access only — it can't see your work repos or data."

### Step 2: Azure VM (5 min)

```bash
# Option A: Azure CLI
az group create --name personal-agents --location westus2

az vm create \
  --resource-group personal-agents \
  --name openclaw-vm \
  --image Ubuntu2204 \
  --size Standard_B2ms \
  --admin-username azureuser \
  --generate-ssh-keys

# Option B: Azure Portal (show the UI flow)
# portal.azure.com → Create a resource → Virtual Machine
```

**Key talking points:**
- "Every Microsoft employee gets $150/mo Azure credits via Visual Studio subscription"
- "B2ms is 2 vCPU, 8GB RAM — ~$60/mo — well within free credits"
- "B2s is cheaper (~$30/mo) if you want to be conservative"
- "Ubuntu 22.04 LTS — stable, well-supported"

```bash
# SSH in
ssh azureuser@<vm-public-ip>
```

### Step 3: Bootstrap Script (5 min)

```bash
# Download and run the bootstrap script
curl -fsSL https://raw.githubusercontent.com/KalebCole/new-grad-builders/main/demo/setup-openclaw-vm.sh | sudo bash
```

**Walk through what it does as it runs:**
1. System updates (apt-get update/upgrade)
2. Essential tools (curl, git, jq, tmux, build-essential)
3. Node.js 20 LTS (via nodesource)
4. OpenClaw (npm install -g openclaw)
5. Dedicated `openclaw` user (restricted permissions)
6. UFW firewall (deny all inbound except SSH)
7. Tailscale (WireGuard-based mesh VPN)

**Then run OpenClaw onboarding:**
```bash
sudo /root/inject-env.sh openclaw onboard
```

**Show the workspace files it creates:**
```bash
ls -la /home/openclaw/.openclaw/workspace/
# USER.md — who you are
# AGENTS.md — operating instructions
# SOUL.md — personality and boundaries
```

### Step 4: Telegram Bot (3 min)

```bash
# On your phone:
# 1. Open Telegram → search @BotFather
# 2. Send /newbot
# 3. Follow prompts → copy the bot token

# Back on VM:
sudo sh -c 'echo "TELEGRAM_BOT_TOKEN=<your-token>" >> /root/.openclaw-env'
```

**Key talking point:** "Why Telegram? Dedicated window. You don't want your AI agent mixed in with your iMessages or WhatsApp. Discord works too if that's your thing."

### Step 5: Data Sources — gogcli (5 min)

**Install gogcli:**
```bash
# On Mac (for local use)
brew install steipete/tap/gogcli

# On Linux VM (build from source)
git clone https://github.com/steipete/gogcli.git
cd gogcli && make
sudo cp bin/gog /usr/local/bin/
```

**Set up Google OAuth:**
```bash
# Option A: Use gcloud CLI (tell your agent to do this)
gcloud projects create my-openclaw-project
gcloud services enable calendar-json.googleapis.com --project my-openclaw-project
gcloud services enable gmail.googleapis.com --project my-openclaw-project

# Option B: Console UI
# 1. console.cloud.google.com → Create project
# 2. APIs & Services → Enable Calendar API, Gmail API
# 3. Credentials → Create OAuth 2.0 Client ID
# 4. Download the JSON credentials file
```

**Authenticate gogcli:**
```bash
gog account add --client-id <id> --client-secret <secret>
# Browser opens → authorize → done
```

**Live demo:**
```bash
gog calendar list         # Show today's events
gog gmail list            # Show recent emails
gog calendar list --json  # JSON output for agents
```

**Key talking point:** "You can literally tell your coding agent: 'Set up Google Calendar integration via GCP CLI.' It'll do most of this for you. That's the whole point."

### Step 6: Security (3 min)

**Walk through each layer and explain WHY:**

```bash
# Show the firewall
sudo ufw status
# "deny all inbound except SSH — one door in"

# Show user isolation
id openclaw
ls -la /root/
# "openclaw user can't read root files — blast radius containment"

# Show file permissions
ls -la /root/.openclaw-env
# "-rw------- — only root can read secrets"

# Show env injection
cat /root/inject-env.sh
# "Reads secrets from root, passes them to openclaw at startup"
```

**Tailscale:**
```bash
sudo tailscale up
tailscale ip -4
# "Now you can SSH via Tailscale IP — no public SSH needed"
```

**Optional proxy user pattern:**
```bash
# Mention but don't demo:
# 3rd user that executes commands for the agent
# Filters sensitive output before returning
# Extra paranoia — not required
```

### Step 7: Emergency Access (2 min)

**On your phone (Termius):**
```bash
ssh root@<tailscale-ip>
# Install a coding agent on root
npm install -g @anthropics/claude-code
# or: copilot-cli, opencode

# Tell it to fix OpenClaw
> "OpenClaw is stuck in a loop. Check the logs and restart it."
```

**Key talking point:** "You're using an agent to fix an agent. This is real life in 2026."

---

## PART 3: DISCUSSION (15 min)

### Opening:
- "I gave this presentation because I wanted to showcase what I'm building and learning"
- "I'm not going to be the only one presenting — this is your community"

### Discussion prompts:
1. "What would you build with a 24/7 agent? What problems would you solve?"
2. "What should this group become? Weekly? Biweekly? Rotating presenters?"
3. "Who wants to present next? You don't have to go as deep as I did."

### Gauge interest:
- Regular meetings — weekly vs biweekly?
- Show-and-tell format vs deep dives?
- Hackathon / "Automate Your Life" challenge?
- Guest speakers?

### Close:
- Share the repo: `docs/getting-started.md`
- "Point your Copilot at that doc and say: 'do this for me'"
- Remind: session is recorded for async viewers
