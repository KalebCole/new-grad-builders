# Demo Notes — Session 1: Autonomous AI Agents

> My cheat sheet for the 40-minute hands-on workshop. Commands to run + what to say.
> Pre-session message sent ahead of time (see `docs/pre-session-message.md`).

## Pre-Demo Checklist

- [ ] Your own Azure VM already running (for showing the end state)
- [ ] SSH key set up
- [ ] Termius on phone for emergency access demo
- [ ] Slides open: `slides/meeting-1/` (built via `node slides/build-meeting-1-pptx.js`)
- [ ] Pre-session message sent in Teams (Copilot + Azure credits + VM creation + Telegram install)

---

## PREREQ CHECK (0:00–2:00)

**Slide:** 03-prereqs.html

Quick check — don't linger here. They should have done this already.

```
"Quick check — did everyone link their Copilot and activate Azure credits?
 If not, do it now while I talk. The getting-started doc has step-by-step."
```

- aka.ms/copilot → link personal GitHub (NOT EMU)
- my.visualstudio.com → VS Enterprise (FTE) → activate with personal MSA
- VM created via `bash demo/create-vm.sh` or the two `az` commands
- Telegram installed on phone (we'll create the bot together)

If anyone hasn't created their VM yet, have them run `create-vm.sh` now — it takes 1-2 min and will be ready by the time we SSH in.

---

## SECURITY & DESIGN DECISIONS (2:00–7:00)

**Slide:** 05-security.html

This is the core teaching section. Walk through the script design decisions BEFORE running anything.

```
"Before we create anything, let's talk about what we're building and why.

When you create an Azure VM, it gets a public IP. Port 22 is open to the internet.
Anyone can try to brute-force SSH. That's the default. So here's what the setup
script does to fix that."
```

**Walk through each layer:**

1. **SSH Hardening** — "No root login, key-only auth, AllowUsers whitelist, max 3 attempts, 30-second grace time, modern-only crypto (chacha20, curve25519). No password auth, no X11, no TCP forwarding."
2. **UFW Firewall** — "Deny all inbound except SSH. One door in. After Tailscale, we tighten it further — SSH only from the VPN subnet."
3. **fail2ban** — "Auto-bans IPs after failed SSH attempts. Defense-in-depth on top of UFW."
4. **Azure Metadata Lockdown** — "Azure VMs have an Instance Metadata Service at 168.63.129.16. If your agent gets compromised, an attacker could query it for subscription info, tokens, etc. We block non-root users from reaching it."
5. **User isolation** — "OpenClaw runs as its own user, not root. No sudo, no docker group. If the agent does something dumb, it can't destroy the whole machine. Blast radius containment."
6. **systemd LoadCredential** — "Secrets live in `/etc/openclaw/secrets/` owned by root with `chmod 600`. systemd reads them and exposes them via a tmpfs-backed credential directory. The openclaw user literally never has filesystem access to the raw secrets."
7. **Process Sandboxing** — "The systemd service runs with `NoNewPrivileges`, `ProtectSystem=strict`, `PrivateTmp`. The agent can't escalate privileges, can't write outside its home dir, gets its own /tmp."
8. **Tailscale** — "WireGuard-based mesh VPN. Once connected, you can remove the public IP entirely."

```
"I'm still learning security too. But the goal isn't perfect security —
it's not being the low-hanging fruit."
```

**Show the setup script on screen** — walk through `demo/setup-openclaw-vm.sh`:
```bash
# Open it or cat it
cat demo/setup-openclaw-vm.sh
# Point out each section: user creation, chmod, env injection, UFW, Tailscale
```

---

## SSH + BOOTSTRAP (7:00–15:00)

**Slide:** 07-bootstrap.html

```bash
# SSH in
ssh azureuser@<vm-public-ip>

# Run the bootstrap script
curl -fsSL https://raw.githubusercontent.com/KalebCole/new-grad-builders/main/demo/setup-openclaw-vm.sh | sudo bash
```

**Explain each step as it runs:**
- [1/11] System updates — "Standard Linux hygiene"
- [2/11] Essential tools — "curl, git, jq, tmux, build-essential, fail2ban, iptables-persistent"
- [3/11] Node.js 20 — "OpenClaw is Node-based"
- [4/11] OpenClaw — "The agent runtime — `npm install -g openclaw`"
- [5/11] Chromium + Xvfb — "Headed browser on a headless VM — needed for browser automation (nodriver, Playwright). Xvfb gives us display :99"
- [6/11] Dedicated user — "This is the blast radius containment we talked about"
- [7/11] Secrets dir — "Individual files in `/etc/openclaw/secrets/`, root-owned, 600 perms"
- [8/11] systemd service — "OpenClaw as a daemon with sandboxing: NoNewPrivileges, ProtectSystem=strict"
- [9/11] SSH hardening — "No root login, key-only, AllowUsers whitelist, modern crypto"
- [10/11] UFW — "Deny all except SSH — tighten to Tailscale only after connecting"
- [11/11] Final hardening — "Azure metadata lockdown, fail2ban, Tailscale"

**After completion, show the security layers in action:**
```bash
# Show the firewall
sudo ufw status

# Show user isolation
id openclaw
sudo ls -la /root/
# "openclaw user can't read root files"

# Show file permissions on secrets
sudo ls -la /etc/openclaw/secrets/
# "drwx------ root:root — only root can enter"

# Show SSH hardening
cat /etc/ssh/sshd_config.d/99-hardened.conf

# Show the systemd service sandboxing
systemctl cat openclaw.service
```

---

## OPENCLAW ONBOARD (15:00–22:00)

**Slide:** 08-onboard.html

```bash
# Run onboarding as the openclaw user (via env injection)
sudo /root/inject-env.sh openclaw onboard
```

**Walk through the workspace files it creates:**
```bash
ls -la /home/openclaw/.openclaw/workspace/
```

- **USER.md** — "Who you are. Name, timezone, preferences. The agent reads this every time it starts."
- **AGENTS.md** — "Operating instructions. What to do, what not to do."
- **SOUL.md** — "Personality and boundaries. The more context, the less dumb it acts."

```
"Throw everything in there. The more context it has, the better it performs.
This is where you make the agent yours."
```

---

## TELEGRAM BOT SETUP (22:00–29:00)

**Slide:** 09-telegram.html

```
"Now let's give the agent a way to talk to you."
```

**On your phone (everyone does this together):**
1. Open Telegram → search **@BotFather**
2. Send `/newbot`
3. Follow prompts (name your bot, pick a username)
4. Copy the bot token

```
"Why Telegram? Dedicated window. You don't want your AI agent mixed in with
your iMessages or WhatsApp. Discord works too if that's your thing."
```

**Back on the VM:**
```bash
# Add the token to secrets
echo 'your-token-here' | sudo tee /etc/openclaw/secrets/telegram_token
sudo chmod 600 /etc/openclaw/secrets/telegram_token
```

**If OpenClaw is running, restart to pick up the new secret:**
```bash
sudo systemctl restart openclaw
```

**Quick test — send a message to your bot in Telegram:**
```
"What's your name?"
```

```
"That's it. Your agent can now talk to you. This is how you'll interact with it
day-to-day — not SSH, not a web UI. Just a chat window on your phone."
```

---

## TAILSCALE (29:00–35:00) — IF TIME

**Slide:** 10-tailscale.html

```bash
sudo tailscale up
# Follow the auth link in the terminal

tailscale ip -4
# Shows 100.x.x.x — your private Tailscale IP
```

```
"Now you can SSH via the Tailscale IP instead of the public IP.
You can even remove the public IP from Azure entirely.
Install Tailscale on your phone too — Termius + Tailscale = SSH from anywhere."
```

---

## EMERGENCY ACCESS (35:00–40:00) — IF TIME

**Slide:** 11-emergency.html

```
"Last thing — emergency access. When your agent breaks at 2 AM."
```

**The pattern:**
1. SSH from phone (Termius) as root via Tailscale IP
2. Root has a non-autonomous coding agent: Copilot CLI
3. OpenClaw tells you the error → you paste it into Copilot CLI → it debugs and fixes

```bash
# On root:
copilot-cli
> "OpenClaw is stuck in a loop. Check the logs and restart it."
```

```
"You're using an agent to fix an agent. Welcome to 2026."
```

---

## CLOSE (if any time left)

**Slide:** 12-resources.html

```
"Everything is in the repo. Point your Copilot at docs/getting-started.md and
say 'do this for me.' It'll walk you through the rest — Telegram bot, Google
Calendar, whatever you want to set up."

"You have free compute, free model access, and a weekend. Go build something."
```

- Remind: session is recorded for async viewers
- Share the repo link in Teams chat
