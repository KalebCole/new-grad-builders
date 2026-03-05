/**
 * Build script: Convert Session 1 HTML slides to PowerPoint (.pptx)
 * Uses the html2pptx.js skill from the powerpoint agent skill.
 *
 * Usage: node slides/build-session1-pptx.js
 * Output: slides/session1.pptx
 */

const pptxgen = require('pptxgenjs');
const path = require('path');
const fs = require('fs');

const html2pptxPath = path.join(
  process.env.USERPROFILE,
  '.agents', 'skills', 'powerpoint', 'scripts', 'html2pptx.js'
);
const html2pptx = require(html2pptxPath);

const htmlDir = path.join(__dirname, 'meeting-1');
const outputFile = path.join(__dirname, 'meeting-1.pptx');

const slideDefinitions = [
  {
    file: '01-title.html',
    notes: 'Title slide. Quick intro: "Welcome to New Grad Builders. Today we\'re building an autonomous AI agent on an Azure VM — from scratch, together, for free."\n\nTiming: ~30 seconds.'
  },
  {
    file: '02-agenda.html',
    notes: 'Walk through the agenda quickly. "We\'re going to talk about security first, then create the VM, bootstrap it, and onboard OpenClaw. Tailscale and emergency access if we have time."\n\nTiming: ~30 seconds.'
  },
  {
    file: '03-prereqs.html',
    notes: '"Quick check — did everyone link their Copilot and activate Azure credits? If not, do it now while I talk. The getting-started doc has step-by-step."\n\nKey points:\n- aka.ms/copilot for Copilot linking (personal GitHub, NOT EMU)\n- my.visualstudio.com for Azure credits (personal MSA, NOT @microsoft.com)\n- Azure CLI installed and logged in\n\nTiming: ~1.5 minutes.'
  },
  {
    file: '04-stack.html',
    notes: '"Here\'s what we\'re building today. Every layer is free or effectively free. GitHub Copilot — unlimited through Microsoft. Azure VM — covered by your $150/mo credits. OpenClaw — open source. Telegram, Tailscale, gogcli — all free."\n\nTiming: ~1 minute.'
  },
  {
    file: '05-create-vm.html',
    notes: '"Now let\'s create the VM. Two commands. Resource group, then the VM itself."\n\nRun create-vm.sh or paste the commands. Wait for it to complete (~1-2 min).\n\n"See that public IP? Right now, anyone on the internet can try to SSH into this. That\'s why we did the security talk first."\n\nTiming: ~3-4 minutes (including wait time).'
  },
  {
    file: '06-security.html',
    notes: '"Before we create anything, let\'s talk about security. When you create an Azure VM, it gets a public IP. Port 22 is open. Anyone on the internet can try to brute-force SSH. That\'s the default. So here\'s what the setup script does to fix that."\n\nWalk through each:\n1. SSH Hardening — no root login, key-only auth, AllowUsers whitelist, 3 max attempts, modern crypto only\n2. UFW Firewall — deny all inbound except SSH. After Tailscale, tighten to VPN only\n3. fail2ban — auto-bans IPs after failed SSH attempts\n4. Azure Metadata Lockdown — blocks non-root from querying the Instance Metadata Service\n5. User isolation — dedicated openclaw user, no sudo, no docker\n6. systemd LoadCredential — secrets on root, injected via tmpfs at runtime\n7. Process Sandboxing — NoNewPrivileges, ProtectSystem=strict, PrivateTmp\n8. Tailscale — WireGuard mesh VPN, no public SSH needed\n\n"I\'m still learning security too. But the goal isn\'t perfect — it\'s not being the low-hanging fruit."\n\nTiming: ~5-6 minutes. This is the core teaching section.'
  },
  {
    file: '07-bootstrap.html',
    notes: '"SSH in and run the bootstrap script. One curl command. Let\'s watch it run and I\'ll explain each step."\n\nSSH into the VM, then run the curl command. As it runs:\n- [1-2] System updates + essentials (includes fail2ban, iptables-persistent)\n- [3-4] Node.js + OpenClaw\n- [5] Chromium + Xvfb — "headed browser on a headless VM, display :99"\n- [6] Dedicated user — "blast radius containment"\n- [7] Secrets dir — "individual files, root-owned, systemd LoadCredential"\n- [8] systemd service — "NoNewPrivileges, ProtectSystem=strict, DISPLAY=:99"\n- [9] SSH hardening — "no root, key-only, AllowUsers, modern crypto"\n- [10] UFW — "deny all except SSH"\n- [11] Azure metadata lockdown + fail2ban + Tailscale\n\nTiming: ~8-10 minutes.'
  },
  {
    file: '08-onboard.html',
    notes: '"Now we run openclaw onboard. This creates the workspace files the agent reads every time it starts."\n\nRun the onboard command. Show the workspace:\n- USER.md — "who you are. Name, timezone, preferences."\n- AGENTS.md — "operating instructions. What to do, what not to do."\n- SOUL.md — "personality and boundaries. The more context, the less dumb it acts."\n\nTiming: ~6-7 minutes.'
  },
  {
    file: '09-telegram.html',
    notes: '"Now let\'s give the agent a way to talk to you. Open Telegram on your phone, search @BotFather, send /newbot, follow the prompts, copy the token."\n\nWait for everyone to do this (~2 min). Then:\n\n"Now paste the token into your VM."\n\nShow the commands:\n  echo \'your-token\' | sudo tee /etc/openclaw/secrets/telegram_token\n  sudo chmod 600 /etc/openclaw/secrets/telegram_token\n\n"Why Telegram? Dedicated window. You don\'t want your AI agent mixed in with your iMessages."\n\nTiming: ~4 minutes.'
  },
  {
    file: '10-tailscale.html',
    notes: '"If we have time — Tailscale. Two commands: tailscale up, follow the auth link, done."\n\n"Now you have a private IP. You can SSH via 100.x.x.x instead of the public IP. You can even remove the public IP from Azure if you want."\n\n"Install Tailscale on your phone too. Termius + Tailscale = SSH from anywhere."\n\nTiming: ~3 minutes. Skip if running behind.'
  },
  {
    file: '11-emergency.html',
    notes: '"Last thing — emergency access. When your agent breaks at 2 AM."\n\n"SSH from your phone as root. You have a non-autonomous coding agent there — Copilot CLI, Claude Code, whatever. Tell it to debug OpenClaw."\n\n"The pattern: OpenClaw tells you the error in Telegram. You copy it. You paste it into the coding agent. It debugs and fixes. You\'re using an agent to fix an agent."\n\nTiming: ~3 minutes. Skip if running behind.'
  },
  {
    file: '12-resources.html',
    notes: '"Everything is in the repo. Point your Copilot at the getting-started doc and say: do this for me. It will walk you through the rest — Google Calendar, data sources, whatever you want to set up."\n\n"You have free compute, free model access, and a weekend. Go build something."\n\nTiming: ~1 minute.'
  }
];

async function build() {
  console.log('Building meeting-1.pptx...\n');

  const pptx = new pptxgen();
  pptx.layout = 'LAYOUT_16x9';
  pptx.author = 'Kaleb Cole';
  pptx.company = 'New Grad Builders';
  pptx.title = 'Session 1: Autonomous AI Agents — Running 24/7, For Free';

  for (const def of slideDefinitions) {
    const htmlPath = path.join(htmlDir, def.file);

    if (!fs.existsSync(htmlPath)) {
      console.error(`  MISSING: ${def.file}`);
      process.exit(1);
    }

    try {
      console.log(`  Converting ${def.file}...`);
      const { slide } = await html2pptx(htmlPath, pptx);

      // Apply marble texture as slide background if available
      const marblePath = path.join(__dirname, 'case-study', 'marble-bg.png');
      if (fs.existsSync(marblePath)) {
        slide.background = { path: marblePath };
      }

      if (def.notes) {
        slide.addNotes(def.notes);
      }

      console.log(`  ✓ ${def.file}`);
    } catch (err) {
      console.error(`  ✗ ${def.file}: ${err.message}`);
      process.exit(1);
    }
  }

  await pptx.writeFile({ fileName: outputFile });
  console.log(`\nDone! Output: ${outputFile}`);
}

build().catch(err => {
  console.error('Build failed:', err);
  process.exit(1);
});
