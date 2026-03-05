# VM Security Architecture - Presentation Script

*Follow the diagram top-to-bottom. Each section maps to a visual layer.*

---

## 1. The Perimeter (top of diagram)

"So I have an Azure VM running Ubuntu. Before any traffic even reaches this machine, it goes through an **Azure Network Security Group** - that's a cloud-level firewall that Azure provides. Think of it as the first bouncer. It filters traffic before packets even hit the VM's network interface."

---

## 2. Tailscale VPN Mesh

"Inside that, I have a **Tailscale mesh network**. Tailscale uses WireGuard under the hood, which is an encrypted tunneling protocol - it's not SSH, it's a separate encrypted layer. What it does is create a private network between my devices. My laptop, my desktop, my phone, and this VM all get private IP addresses and can talk to each other over encrypted channels, no matter where they physically are. It's like they're all on the same local network."

"The important thing here is: **this VM has zero public-facing ports.** There's no way to reach it from the open internet. You have to be a member of my Tailscale network to even see it exists."

---

## 3. UFW Firewall

"Even within Tailscale, I have another firewall layer - **UFW**, which stands for Uncomplicated Firewall. It's the VM's own firewall. The policy is: **deny everything incoming by default**, and then I have exactly one exception - SSH, but **only from Tailscale IP addresses.**"

"There's also an iptables rule - iptables is the underlying Linux firewall that UFW sits on top of - its default policy is DROP, meaning if a packet doesn't match any allow rule, it gets silently discarded. No response, no error, nothing. The sender doesn't even get acknowledgment that the machine exists."

*[If someone asks about the metadata thing: "There's also a rule that blocks non-root users from querying the Azure metadata endpoint - that's an internal Azure service that can leak information about the VM's configuration and sometimes access tokens. Only root can reach it."]*

---

## 4. SSH Hardening (red box)

"Now we're inside the VM. Even though the only way in is through Tailscale, I still harden SSH as a defense-in-depth measure. If Tailscale ever had a vulnerability, or if one of my devices got compromised, SSH is the next wall."

"Key settings: **no root login** - you can't SSH in as root at all. **Key-only authentication** - no passwords, you need a cryptographic key pair. There's a **whitelist of exactly one user** who's allowed to SSH in. And **you get three tries** - if you fail three times, Fail2Ban steps in and bans your IP address. The ciphers are all modern, high-strength algorithms - no legacy crypto."

---

## 5. Running Services (purple box)

"On the VM itself, I'm running a few services:"

"**OpenClaw Gateway** - this is the main application. OpenClaw is an AI agent, and the gateway is its main process - it's the front door that accepts requests and routes them to the right handler. It runs on a localhost-only port, so it's not reachable from outside the machine."

"**Secret Proxy** - I'll come back to this in the secrets section, but it's a separate service that mediates access to API keys."

"**Xvfb** - a virtual display. This lets OpenClaw run a headless browser for web automation without needing a physical monitor."

"**Tailscale daemon** - keeps the VPN mesh running."

"**sshd** - the SSH server. And **chrony** for time sync."

---

## 6. User Isolation (blue bar)

"I've got three users on this system with very different privilege levels:"

"**admin-user** - that's me, the human admin. I have sudo and Docker access. This is the only account that can SSH in."

"**service-user** - this is the dedicated user that OpenClaw runs as. It has **no sudo, no Docker access**. It can't escalate privileges. It can't manage containers. It can only do what OpenClaw needs to do."

"**root** - owns the secret files. No one logs in as root - it just owns the sensitive data."

"The key idea: **OpenClaw runs as a non-privileged user.** Even if someone compromised the AI agent, they'd be stuck in a limited account with no path to escalate."

---

## 7. Secrets Management (purple container with 3 layers)

"This is probably the most interesting part. When you run an AI agent, you're handing it API keys for a bunch of services. The question is: how do you prevent the agent from leaking or misusing those keys? I built three layers:"

### Layer 1: Filesystem

"All API keys are stored as individual files in a root-owned directory. Permissions are 0600 - only root can read them. The service user that OpenClaw runs as **physically cannot read these files.** If you tried `cat` on any of them as the service user, you'd get 'permission denied.'"

### Layer 2: systemd LoadCredential

"When the OpenClaw service starts, systemd - which runs as root - reads the specific secret files that OpenClaw actually needs and passes them through a **tmpfs-backed credentials directory.** Tmpfs means it lives in RAM, not on disk. The service user can read from this temporary mount, but only the secrets that were explicitly listed in the service config. And it never touches the original files."

"So the LLM provider keys that OpenClaw needs to function - those get loaded this way. OpenClaw can see them in memory, but they're not on disk from its perspective."

### Layer 3: Secret Proxy

"For the other API keys - things like GitHub tokens, finance APIs, task management - I didn't want OpenClaw to see those raw keys at all. So there's a **secret proxy** that runs as a separate root-level service on a Unix socket."

"Here's how it works: OpenClaw doesn't get the API key. Instead, it sends a request to the proxy saying 'run this specific command.' The proxy has a mapping - it knows which key goes with which command. It injects the key, runs the command in its own process, and sends back just the output. **OpenClaw never sees the actual key value.**"

"On top of that, the proxy has per-command scoping - a key can only be used for its designated tool. It's rate-limited to 60 requests per minute with a max of 5 concurrent. And every access is logged."

---

## 8. Process Isolation / Sandboxing (green box)

"The last layer is systemd sandboxing. Even with all the user isolation and secrets management, I wanted to restrict what these processes can physically do at the OS level."

"**NoNewPrivileges** - the process can't gain elevated permissions through any mechanism. Even if there was a setuid binary sitting around, it couldn't use it."

"**ProtectSystem=strict** - the entire filesystem is mounted read-only from this process's perspective, except for the specific paths I've explicitly allowed."

"**PrivateTmp** - the process gets its own isolated /tmp directory. It can't see other processes' temp files."

"**RestrictAddressFamilies** - limits what types of network connections the process can make. No Bluetooth, no raw sockets, just regular internet and Unix sockets."

"The secret proxy service gets **even more restrictions** - it can't see the home directory, can't load kernel modules, can't read kernel logs."

"Basically: even if someone fully compromised the OpenClaw process, they're in a box. They can't write to the filesystem, can't escalate privileges, can't snoop on other processes, can't query the cloud provider for metadata. The blast radius is contained."

---

## 9. Security Modules (yellow box - mention briefly)

"And then there's a few more standard security tools running: **Fail2Ban** auto-bans IPs after failed SSH attempts. **AppArmor** has 89 mandatory access control profiles enforced. The kernel has **SYN flood protection, ICMP redirect blocking, and source routing disabled.** And **automatic security patches** are enabled - the system updates itself."

---

## Wrap-up / Summary

"So to summarize the security posture: **zero public attack surface** - you can't reach this VM from the internet. **Defense in depth** - even if one layer fails, there are more behind it. **Least privilege** - the AI agent runs as a restricted user with no admin access. **Secrets are compartmentalized** across three layers so the agent only sees what it absolutely needs. And **process sandboxing** means even a full compromise has a contained blast radius."
