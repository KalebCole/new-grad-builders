# Pre-Session Prereqs — New Grad Builders Session 1

Hey everyone 👋 Here's what to do before the session so we can spend the full 40 minutes building, not setting up. Takes ~10 minutes total.

Anything not listed here, we'll either do together live or you can explore after.

---

## ✅ Do These Before the Session (~10 min)

### 1. Link your personal GitHub to Copilot (1 min)

- Go to [aka.ms/copilot](https://aka.ms/copilot)
- Link your **personal GitHub account** (not your EMU/work account)
- This gives you unlimited Copilot access on any device — model access only, not Microsoft resources
- Verify it worked: [github.com/settings/copilot](https://github.com/settings/copilot)

### 2. Activate your $150/mo Azure credits (3 min)

- Go to [my.visualstudio.com](https://my.visualstudio.com) — sign in with your **@microsoft.com** account
- Find **Visual Studio Enterprise (FTE)** benefits
- Click **Azure $150 monthly credit**
- When prompted, use a **personal email** (outlook.com / gmail.com) — **NOT** your @microsoft.com
- Use an InPrivate / Incognito browser window to avoid account conflicts
- No credit card required
- Verify it worked: [portal.azure.com](https://portal.azure.com) → Cost Management

### 3. Install Azure CLI + sign in (2 min)

- Install: [aka.ms/installazurecli](https://aka.ms/installazurecli)
- Then run:
  ```bash
  az login
  ```
- Sign in with the **personal email** you used for Azure credits (not your @microsoft.com)

### 4. Create your Azure VM (3 min)

Run these two commands — your VM will be ready by the time the session starts:

```bash
az group create --name personal-agents --location westus2

az vm create \
  --resource-group personal-agents \
  --name openclaw-vm \
  --image Ubuntu2204 \
  --size Standard_B2ms \
  --admin-username azureuser \
  --generate-ssh-keys
```

Save the **public IP** from the output — we'll need it to SSH in during the session.

### 5. Install Telegram on your phone (1 min)

- Download from [telegram.org](https://telegram.org) (iOS / Android)
- We'll create the bot together in the session — just have the app ready
- Why Telegram? I use it because I have no other contacts on it, so it's a dedicated channel for the agent

---

## 🕐 We'll Do These Together in the Session

- SSH into your VM and bootstrap it with OpenClaw (the agent runtime)
- Walk through the security layers (SSH hardening, firewall, user isolation, secrets management)
- Run OpenClaw onboarding and customize your agent
- Create your Telegram bot and connect it to your agent
- Test it end-to-end — your agent talks to you from your phone

---

## 📌 Optional Stuff to Explore After

- **Tailscale** — WireGuard VPN so you can drop the public IP entirely and SSH from anywhere
- **Google Calendar integration** — let your agent read/manage your calendar via [gogcli](https://github.com/steipete/gogcli)
- **Emergency coding agent** — install a non-autonomous agent (Copilot CLI / Claude Code) on root for debugging at 2 AM
- **Termius** — mobile SSH client, pairs great with Tailscale for phone access ([termius.com](https://termius.com))
