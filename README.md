# New Grad Builders 🤖

A community for Microsoft new grads who want to build with AI agents outside of work — and bring those skills in.

## What Is This?

Open, hands-on sessions where new grads share practical AI tools, build automations, and learn from each other. Not a lecture series — a builder community.

**Organizers:** Kaleb Cole & Kevin Granados

## Session 1: Autonomous AI Agents — Running 24/7, For Free

How to set up an always-on AI agent on an Azure VM using free credits, GitHub Copilot, and OpenClaw.

| Resource | Path |
|----------|------|
| 🖥️ Slides | `slides/slides.md` |
| 🛠️ VM Setup Script | `demo/setup-openclaw-vm.sh` |
| 📄 Getting Started | `docs/getting-started.md` |
| 📋 Future Sessions | `docs/backlog.md` |

## Quick Start

Point your Copilot at the getting started doc:

```
Open docs/getting-started.md and do everything in it for me
```

## Building the Slides

```powershell
# Install Marp CLI
npm install -g @marp-team/marp-cli

# Preview in browser
npx @marp-team/marp-cli slides/slides.md --preview

# Export to PPTX
npx @marp-team/marp-cli slides/slides.md --pptx

# Export to PDF
npx @marp-team/marp-cli slides/slides.md --pdf
```

Or use the [Marp for VS Code](https://marketplace.visualstudio.com/items?itemName=marp-team.marp-vscode) extension for live preview.

## Resources

- 🤖 [OpenClaw](https://github.com/openinterface/openclaw) — Agent runtime
- 🔍 [skills.sh](https://skills.sh) — Community agent skills
- 📚 [awesome-copilot](https://github.com/github/awesome-copilot) — Agents, skills, hooks, recipes
- 🔐 [Tailscale](https://tailscale.com) — Mesh VPN for secure access
- 📱 [Termius](https://termius.com) — Mobile SSH client
