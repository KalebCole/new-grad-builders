# New Grad Builders 🤖

A community for Microsoft new grads who want to build with AI agents outside of work — and bring that back to the day job.

> *This is a personal project. It is not affiliated with, endorsed by, or supported by Microsoft.*

## What Is This?

Hands-on sessions where new grads share AI tools they're actually using, build automations, and learn from each other. Not a lecture series — a builder community.

**Organizers:** Kaleb Cole & Kevin Granados

## Meeting 1: Autonomous AI Agents — Running 24/7, For Free

How to set up an always-on AI agent on an Azure VM using free credits, GitHub Copilot, and OpenClaw.

| Resource | Path |
|----------|------|
| 🖥️ Slides (HTML → PPTX) | `slides/meeting-1/` |
| 📋 Agenda | `agendas/meeting-1.md` |
| 🛠️ VM Creation Script | `demo/create-vm.sh` |
| 🛠️ VM Setup Script | `demo/setup-openclaw-vm.sh` |
| 🔒 Secret Proxy (optional) | `demo/setup-secret-proxy.sh` |
| 📄 Getting Started | `docs/getting-started.md` |
| 📝 Prereqs | `docs/prereqs.md` |
| 📝 Demo Notes | `demo/demo-notes.md` |
| 📋 Future Sessions | `docs/backlog.md` |

### Case Study: OpenClaw Bought Me a Car

| Resource | Path |
|----------|------|
| 🖥️ Slides (HTML → PPTX) | `slides/case-study/` |
| 🎨 Design Spec | `slides/DESIGN-SPEC.md` |

## Quick Start

Point your Copilot at the getting started doc:

```
Open docs/getting-started.md and do everything in it for me
```

## Building the Slides

```powershell
# Set NODE_PATH for the html2pptx converter
$env:NODE_PATH = (Resolve-Path "node_modules").Path

# Build Meeting 1 slides
node slides/build-meeting-1-pptx.js

# Build Case Study slides
node slides/build-case-study-pptx.js
```

## Resources

- 🤖 [OpenClaw](https://github.com/openinterface/openclaw) — Agent runtime
- 🔍 [skills.sh](https://skills.sh) — Community agent skills
- 📚 [awesome-copilot](https://github.com/github/awesome-copilot) — Agents, skills, hooks, recipes
- 🔐 [Tailscale](https://tailscale.com) — Mesh VPN for secure access
- 📱 [Termius](https://termius.com) — Mobile SSH client
