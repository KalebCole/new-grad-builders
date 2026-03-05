/**
 * Build script: Convert Meeting 1 HTML slides to PowerPoint (.pptx)
 * Uses the html2pptx.js skill from the powerpoint agent skill.
 *
 * Usage: node slides/build-meeting-1-pptx.js
 * Output: slides/meeting-1.pptx
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
    notes: 'Walk through the agenda quickly. "We\'ll cover the state of AI, security, then hands-on: create the VM, bootstrap it, onboard OpenClaw, set up Telegram. Tailscale and emergency access if we have time."\n\nTiming: ~30 seconds.'
  },
  {
    file: '03-prereqs.html',
    notes: '"Quick check — did everyone link their Copilot and activate Azure credits? If not, do it now while I talk. The getting-started doc has step-by-step."\n\nKey points:\n- aka.ms/copilot for Copilot linking (personal GitHub, NOT EMU)\n- my.visualstudio.com for Azure credits (personal MSA, NOT @microsoft.com)\n- Azure CLI installed and logged in\n\nTiming: ~1.5 minutes.'
  },
  {
    file: '04-state-of-ai.html',
    notes: '"Before we build, let me show you where this fits. Most of you use M365 Copilot — that\'s Tier 1, cloud AI. Chat, summarize, search. Then there are coding agents — Copilot CLI, Claude Code — they run on your machine, execute commands, but you\'re still driving. What we\'re building today is Tier 3: a proactive agent. It runs 24/7 on a VM, has a heartbeat, checks on tasks periodically, acts without being asked. Most people are at Tier 1. We\'re going to Tier 3 today."\n\nTiming: ~2-3 minutes.'
  },
  {
    file: '05-stack.html',
    notes: '"Here\'s what we\'re building today. Every layer is free or effectively free. GitHub Copilot — unlimited through Microsoft. Azure VM — covered by your $150/mo credits. OpenClaw — open source. Telegram, Tailscale — all free."\n\nTiming: ~1 minute.'
  },
  {
    file: '06-create-vm.html',
    notes: '"Now let\'s create the VM. Two commands. Resource group, then the VM itself."\n\nRun create-vm.sh or paste the commands. Wait for it to complete (~1-2 min).\n\n"See that public IP? Right now, anyone on the internet can try to SSH into this. That\'s why we\'re going to talk about security next."\n\nTiming: ~3-4 minutes (including wait time).'
  },
  {
    file: '07-security.html',
    notes: '"I\'m not a security engineer. But this thing probably has all my API keys, so I went through all this hardening so you don\'t have to."\n\n"I have a setup script for you all — take the parts you want. I wanted to explain it before anyone blindly runs it — build trust in what it does."\n\nWalk through each item. Goal: minimize blast radius. Don\'t be low-hanging fruit.\n\nClose with: "This is my implementation. Poke holes in it."\n\nTiming: ~5 minutes.'
  },
  {
    file: '08-bootstrap.html',
    notes: '"SSH in and run the bootstrap script. One curl command. Let\'s watch it run and I\'ll explain each step."\n\nSSH into the VM, then run the curl command. As it runs:\n- [1-2] System updates + essentials (includes fail2ban, iptables-persistent)\n- [3-4] Node.js + OpenClaw\n- [5] Chromium + Xvfb + nodriver — "stealth browser on a headless VM, display :99"\n- [6] Dedicated user — "blast radius containment"\n- [7] Secrets dir — "individual files, root-owned, systemd LoadCredential"\n- [8] systemd service — "NoNewPrivileges, ProtectSystem=strict, DISPLAY=:99"\n- [9] SSH hardening — "no root, key-only, AllowUsers, modern crypto"\n- [10] UFW — "deny all except SSH"\n- [11] Azure metadata lockdown + fail2ban + Tailscale\n\nTiming: ~8 minutes.'
  },
  {
    file: '09-onboard.html',
    notes: '"I used OpenClaw to set up OpenClaw. ClawCamp is a bootcamp-style setup guide from the AI Daily Brief podcast — it organizes setup into modules. I iterated through the modules using Edge TTS — talking to the agent via voice, agent executing setup steps."\n\nLive demo: screen share, have Edge TTS installed, point it at ClawCamp, let it iteratively configure itself.\n\nIMPORTANT CAVEAT: "The onboarding wizard installs the CLI tool, but my setup intentionally does NOT give OpenClaw access to its own API keys. This is a deliberate security friction layer — the agent can\'t use its own keys to install or modify things. This is a design choice."\n\nShow the workspace files: USER.md, AGENTS.md, SOUL.md.\n\nTiming: ~8 minutes.'
  },
  {
    file: '10-telegram.html',
    notes: '"Now let\'s give the agent a way to talk to you. Open Telegram on your phone, search @BotFather, send /newbot, follow the prompts, copy the token."\n\nWait for everyone to do this (~2 min). Then:\n\n"Now paste the token into your VM."\n\n"Why Telegram? Dedicated window. You don\'t want your AI agent mixed in with your iMessages."\n\nTiming: ~4 minutes.'
  },
  {
    file: '11-tailscale.html',
    notes: '"If we have time — Tailscale. Two commands: tailscale up, follow the auth link, done."\n\n"Now you have a private IP. You can SSH via 100.x.x.x instead of the public IP. You can even remove the public IP from Azure if you want."\n\n"Install Tailscale on your phone too. Termius + Tailscale = SSH from anywhere."\n\nTiming: ~3 minutes. Skip if running behind.'
  },
  {
    file: '12-emergency.html',
    notes: '"Last thing — emergency access. When your agent breaks at 2 AM."\n\n"SSH from your phone as root. You have a non-autonomous coding agent there — Copilot CLI, Claude Code, whatever. Tell it to debug OpenClaw."\n\n"The pattern: OpenClaw tells you the error in Telegram. You copy it. You paste it into the coding agent. It debugs and fixes. You\'re using an agent to fix an agent."\n\nTiming: ~3 minutes. Skip if running behind.'
  },
  {
    file: '13-resources.html',
    notes: '"Everything is in the repo. Point your Copilot at the getting-started doc and say: do this for me. It will walk you through the rest — Google Calendar, data sources, whatever you want to set up."\n\n"You have free compute, free model access, and a weekend. Go build something."\n\nTiming: ~1 minute.'
  },
  {
    file: '14-closing.html',
    notes: '"Here\'s what\'s coming next — Session 2 will cover browser automation, data sources, and making your agent actually useful. Stay connected in the Teams channel. Share the repo with any new grad friends who\'d want to join."\n\n"Whatever this community becomes, it starts here."\n\nTiming: ~1 minute.'
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
