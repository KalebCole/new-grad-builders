# OpenClaw Setup Playbook — Free Edition
### Azure VM + GitHub Copilot + VS Code (No Credit Card Required)

> **Who this is for:** You watched Tech with Tim's OpenClaw deep-dive and want to do
> everything he showed — but free, using Microsoft employee perks instead of Hostinger.
> You'll follow along with a live demo, building alongside the presenter.
>
> **End result:** A fully optimized OpenClaw instance running 24/7 on Azure at $0,
> with memory flush, prompt caching, and VS Code remote access configured.

---

## Before the Session (Do These First)

These take 5-10 minutes and must be done before you can follow along live.

### 1. Activate Azure $150/month Credits

1. Go to [my.visualstudio.com](https://my.visualstudio.com) — sign in with your **@microsoft.com** account
2. Find **Visual Studio Enterprise (FTE)** → click **Azure $150 monthly credit**
3. When prompted, use a **personal MSA** (outlook.com / hotmail.com) — **not** your @microsoft.com
4. Use an InPrivate/Incognito window
5. Verify at [portal.azure.com](https://portal.azure.com) → Cost Management → you should see $150 available

> ⚠️ The B2ms VM we'll create costs ~$60-70/month. Your credits cover it with room to spare.

### 2. Link GitHub Copilot to Your Personal GitHub

1. Go to [aka.ms/copilot](https://aka.ms/copilot)
2. Link your **personal GitHub account** (not your EMU/work account)
3. Verify at [github.com/settings/copilot](https://github.com/settings/copilot) — should show active

> This is your free LLM. OpenClaw will use GitHub Copilot as the model — no Anthropic/OpenAI key needed.

### 3. Install Tools on Your Local Machine

```bash
# Azure CLI
# Mac:
brew install azure-cli
# Windows: https://aka.ms/installazurecliwindows

# Log in with your personal MSA (same one you used for Azure credits)
az login

# VS Code (if you don't have it)
# https://code.visualstudio.com/download

# VS Code Remote SSH extension
# Open VS Code → Extensions (Cmd+Shift+X) → search "Remote - SSH" → Install
```

---

## Part 1: Spin Up the VM (5 min)

```bash
# Clone the repo to get the setup scripts
git clone https://github.com/KalebCole/new-grad-builders.git
cd new-grad-builders

# Create the Azure VM
bash demo/create-vm.sh
```

When it finishes, you'll see your VM's public IP. Save it.

```bash
# SSH in to verify it works
ssh azureuser@<YOUR_VM_IP>

# You should land on an Ubuntu 22.04 prompt
# Type 'exit' to come back to your local machine
exit
```

---

## Part 2: Install OpenClaw (5 min)

```bash
# SSH in and run the setup script
ssh azureuser@<YOUR_VM_IP>

curl -fsSL https://raw.githubusercontent.com/KalebCole/new-grad-builders/main/demo/setup-openclaw-vm.sh | sudo bash
```

This installs Node.js, OpenClaw, Chromium, and configures the system. Takes about 3 minutes.

When it finishes:

```bash
# Check OpenClaw is running
sudo systemctl status openclaw

# Get your gateway token (you'll need this to log in)
sudo openclaw gateway token
```

Save the gateway token somewhere — it's how you authenticate to the web UI.

---

## Part 3: Connect VS Code to Your VM (5 min)

This is how you browse and edit the OpenClaw file system visually, the way Tim showed in his video.

### Add SSH config entry

On your **local machine**, add this to `~/.ssh/config`:

```
Host openclaw-vm
    HostName <YOUR_VM_IP>
    User azureuser
    IdentityFile ~/.ssh/id_rsa
```

### Connect in VS Code

1. Open VS Code
2. `Cmd+Shift+P` → type `Remote-SSH: Connect to Host`
3. Select `openclaw-vm`
4. Once connected, click **Open Folder**
5. Navigate to `/home/openclaw/.openclaw/workspace`
6. Click **OK** → Trust the folder

You now have full visual access to the OpenClaw file system — MEMORY.md, SOUL.md, skills, scripts, all of it.

---

## Part 4: Install Tailscale (3 min)

Tailscale lets you SSH into your VM from anywhere (phone, another laptop) without exposing a public IP. It's free for personal use.

```bash
# On the VM
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Follow the auth link it prints — log in with your personal account. Once connected:

```bash
# Get your Tailscale IP
tailscale ip -4
```

From now on, use this IP instead of the public IP. You can also SSH from your phone using [Termius](https://termius.com).

---

## Part 5: Configure GitHub Copilot as Your Model (2 min)

Open `openclaw.json` in VS Code (it's in `/home/openclaw/.openclaw/`):

Find the `agents.defaults` block and set the model:

```json
{
  "agents": {
    "defaults": {
      "model": "github-copilot/claude-sonnet-4-5"
    }
  }
}
```

Save the file. OpenClaw hot-reloads config — no restart needed.

> **Why this matters:** This routes all LLM calls through GitHub Copilot instead of Anthropic directly. Free.

---

## Part 6: Enable Memory Flush (3 min)

This is the most important optimization from Tim's video. Without it, OpenClaw forgets things whenever a session compacts.

In `openclaw.json`, add to your `agents.defaults` block:

```json
{
  "agents": {
    "defaults": {
      "model": "github-copilot/claude-sonnet-4-5",
      "compaction": {
        "reserveTokenFloor": 20000,
        "memoryFlush": {
          "enabled": true,
          "softTokenThreshold": 150000,
          "systemPrompt": "Review this session. Write lasting notes to memory if needed. Reply NO_REPLY if nothing important."
        }
      }
    }
  }
}
```

**What this does:** Before OpenClaw compacts a long session, it first saves anything important to long-term memory (`MEMORY.md`). You stop losing context.

Verify it worked — open the OpenClaw web UI, start a chat, type:

```
Is memory flush enabled?
```

It should confirm yes with the config values.

---

## Part 7: Enable Prompt Caching (2 min)

This cuts your token costs by ~90% for repeated context (system prompt, memory, tool lists). Since GitHub Copilot is free, this matters less for cost — but it also makes responses faster.

In `openclaw.json`:

```json
{
  "agents": {
    "defaults": {
      "promptCaching": {
        "enabled": true,
        "warmOnHeartbeat": true
      }
    }
  }
}
```

`warmOnHeartbeat: true` keeps the cache alive by refreshing it during your scheduled heartbeat, so it doesn't invalidate after the default 1-hour window.

---

## Part 8: Tune the Context Window (2 min)

By default OpenClaw waits until ~200k tokens before auto-compacting. That's a lot of accumulated cost (and slowdown) before it resets. Cap it lower:

```json
{
  "agents": {
    "defaults": {
      "contextWindow": {
        "softLimit": 80000,
        "hardLimit": 120000
      }
    }
  }
}
```

Now it auto-compacts (and triggers memory flush) before sessions get bloated.

---

## Part 9: Audit and Trim Your Skills (5 min)

Every skill file gets loaded into the prompt on every message. If you have 50+ skills, that's thousands of tokens burned before OpenClaw even starts thinking.

In the OpenClaw web UI:

```
/context list
```

Look at the skills section — how many tokens are they using? Then:

```
Which skills am I not using? Disable any that I haven't used in the last 7 days.
```

Or manually in VS Code: navigate to `/home/openclaw/.openclaw/workspace/skills/` and delete or comment out any you're not using.

---

## Part 10: Open the Web UI + Verify Everything (2 min)

```bash
# Get your gateway URL
# Default port is 3000
# Access via: http://<YOUR_TAILSCALE_IP>:3000
```

Open it in your browser. Log in with your gateway token from Part 2.

Run a quick health check:

```
/status
```

You should see:
- Model: github-copilot/claude-sonnet-4-5 (or similar)
- Memory flush: enabled
- Cache hit rate: climbing after a few messages
- Context: well under your soft limit

---

## What You Built

| Component | Tool | Cost |
|-----------|------|------|
| VM (always-on compute) | Azure B2ms | Free (VS credits) |
| LLM | GitHub Copilot | Free (MS benefit) |
| Agent runtime | OpenClaw | Free (open source) |
| Remote file access | VS Code Remote SSH | Free |
| Secure remote access | Tailscale | Free (personal) |
| **Total** | | **$0/month** |

---

## Next Steps

- Browse [clawhub.ai](https://clawhub.ai) for community skills
- Set up a Telegram bot for mobile access (`@BotFather` → `/newbot`)
- Add Google Calendar integration via `gws` CLI
- Set up a morning briefing cron job

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| VM ran out of credits | Check Azure portal → Cost Management. Switch to B1ms (~$15/mo) if needed. |
| OpenClaw won't start | `sudo journalctl -u openclaw -n 50` then `sudo systemctl restart openclaw` |
| Can't SSH from VS Code | Make sure `~/.ssh/config` entry is correct. Try `ssh -v openclaw-vm` for debug output. |
| Copilot not working as model | Verify GitHub is linked at [aka.ms/copilot](https://aka.ms/copilot). Re-link if needed. |
| Memory flush not triggering | Check `openclaw.json` is valid JSON (`jq . openclaw.json` to validate). |
| Can't reach web UI | Make sure port 3000 is open: `az vm open-port --port 3000 --resource-group personal-agents --name openclaw-vm` |

---

*Built for New Grad Builders — a community of Microsoft new grads building with AI agents.*
*[github.com/KalebCole/new-grad-builders](https://github.com/KalebCole/new-grad-builders)*
