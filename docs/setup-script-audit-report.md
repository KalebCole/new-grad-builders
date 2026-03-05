# Setup Script Audit Report

**Date:** 2026-03-05
**Method:** Created fresh Azure VM via `create-vm.sh`, ran `setup-openclaw-vm.sh` and `setup-secret-proxy.sh`, then compared against known-good production VM audit.

---

## Test Results

**Both scripts completed successfully (exit code 0) after fixes were applied.**

| Check | Status |
|-------|--------|
| VM creation | Pass |
| setup-openclaw-vm.sh | Pass (exit 0) |
| setup-secret-proxy.sh | Pass (exit 0) |
| Node.js v22.22.0 | Pass |
| OpenClaw installed | Pass |
| Chromium + Xvfb + nodriver | Pass |
| Dedicated `openclaw` user (UID 998) | Pass |
| Secrets directory (root:root, 700) | Pass |
| openclaw.service (full sandboxing) | Pass |
| SSH hardening (99-hardened.conf) | Pass |
| UFW firewall (deny incoming) | Pass |
| iptables metadata blocks (both IPs) | Pass |
| Kernel sysctl hardening | Pass |
| fail2ban active | Pass |
| Tailscale installed | Pass |
| unattended-upgrades active | Pass |
| chrony active | Pass |
| secret-proxy.service (running, socket created) | Pass |
| Logrotate for secret-proxy | Pass |

---

## Issues Found and Fixed

### CRITICAL (3 issues — would have blocked execution)

| # | Issue | Fix Applied |
|---|-------|-------------|
| 1 | **CRLF line endings** — All `.sh` files had Windows `\r\n` endings. `#!/usr/bin/env bash\r` fails on Linux with "command not found". Heredocs embed `\r` into systemd unit files. | Added `.gitattributes` with `*.sh text eol=lf` to enforce LF in git. |
| 2 | **`iptables-persistent` interactive prompt** — Asks "Save current IPv4/v6 rules?" during install, hanging the headless `curl \| bash` pipeline indefinitely. | Added `debconf-set-selections` to preseed yes answers. Added `export DEBIAN_FRONTEND=noninteractive` at script top. |
| 3 | **Missing IMDS metadata block** — Script only blocked `168.63.129.16` (Azure WireServer) but NOT `169.254.169.254` (Azure Instance Metadata Service). This left the classic cloud SSRF attack vector wide open — the `openclaw` user could query IMDS for managed identity tokens. | Now blocks both `169.254.169.254` and `168.63.129.16`. Uses `iptables -C` (check) before `-A` (append) for idempotency. |

### HIGH (9 issues — significant functional gaps)

| # | Issue | Fix Applied |
|---|-------|-------------|
| 4 | **Node.js 20 vs 22** — Script installed Node 20 LTS; production VM runs Node 22.22.0. | Changed to `setup_22.x`. Added version check so re-runs upgrade if needed. |
| 5 | **Missing `DEBIAN_FRONTEND=noninteractive`** — `apt-get upgrade` could prompt for config file conflicts in headless mode. | Added `export DEBIAN_FRONTEND=noninteractive` and `--force-confdef --force-confold` flags. |
| 6 | **Missing `unattended-upgrades`** — Production VM has automatic security patches; script didn't install or configure it. | Now installs `unattended-upgrades` and writes `/etc/apt/apt.conf.d/20auto-upgrades`. |
| 7 | **Missing `chrony`** — Production VM runs chrony for NTP time sync; script didn't install it. | Added `chrony` to apt-get install list. |
| 8 | **Missing kernel sysctl hardening** — Production VM has explicit settings for `tcp_syncookies`, `accept_redirects`, `accept_source_route`, `rp_filter`, `icmp_echo_ignore_broadcasts`. Script set none of these. | Added step [11/12] that writes `/etc/sysctl.d/99-hardened.conf` and applies with `sysctl -p`. |
| 9 | **Missing sandboxing on app service** — `openclaw.service` was missing `ProtectHome=true`, `ProtectKernelModules=true`, `ProtectKernelLogs=true` (all present on `secret-proxy.service` and implied by the production audit). | Added all three directives to `openclaw.service`. |
| 10 | **`pip3 install` PEP 668 failure** — On newer Ubuntu, `pip3 install` outside a venv fails. | Added `--break-system-packages` flag with fallback for older pip. |
| 11 | **Missing `ufw default deny routed`** — Production VM has this; script only set `deny incoming` and `allow outgoing`. | Added `ufw default deny routed`. |
| 12 | **Missing logrotate for secret-proxy** — Audit log at `/var/log/openclaw/secret-proxy.log` would grow unbounded. | Added logrotate config in `setup-secret-proxy.sh` (weekly, rotate 4, compress). |

### MEDIUM (5 issues — documented but not all fixed in this pass)

| # | Issue | Status |
|---|-------|--------|
| 13 | **Hardcoded `AllowUsers azureuser`** — If someone uses a different admin username, SSH locks them out. | Documented. Could parameterize but would complicate the `curl \| bash` flow. |
| 14 | **`PasswordAuthentication no` set in 1 place vs 3** — Production has it in main sshd_config, cloud-init config, and drop-in. Script only sets the drop-in. | Added `sed` to also set it in main `sshd_config`. Cloud-init config left as-is (Azure default). |
| 15 | **Step numbering mismatch in comments** — Duplicate `# --- 6.` comment, step numbers out of sync with echo output. | Fixed: renumbered to 1-12 consistently. |
| 16 | **Missing Node.js check in secret-proxy** — `setup-secret-proxy.sh` didn't verify Node.js was installed before creating a service that depends on it. | Added prerequisite check. |
| 17 | **UFW/iptables duplicate rules on re-run** — Running scripts twice creates duplicate firewall rules. | Partially fixed: iptables uses `-C` check. UFW duplicates are cosmetic (same effect). |

### LOW (not fixed — intentional differences from production)

| # | Issue | Rationale |
|---|-------|-----------|
| 18 | **No Docker installed** — Production has Docker; scripts don't install it. | Intentional. Docker is not needed for the workshop. Can be added later. |
| 19 | **No `gh` CLI installed** — Production has GitHub CLI. | Can be added as a post-setup step. Not critical for OpenClaw. |
| 20 | **No project scaffolding directories** — Production has `ai-outputs/`, `claude-logs/`, etc. | These are created organically during use, not by the setup script. |
| 21 | **No AppArmor custom profiles** — Production has 89 profiles. | Ubuntu ships with AppArmor defaults. Custom profiles for OpenClaw would be a future enhancement. |
| 22 | **No NVM (uses NodeSource instead)** — Production uses nvm-managed Node. | NodeSource is simpler for a workshop. NVM can be added by users who prefer it. |
| 23 | **`inject-env.sh` bypasses 3-layer model** — It reads secrets directly as env vars. | Intentional for the `openclaw onboard` one-off command. Documented in the script. |
| 24 | **UFW allows SSH from anywhere (not Tailscale-only)** — Production restricts to `100.64.0.0/10`. | Intentional: SSH from public IP is needed during initial Tailscale setup. Instructions to lock down are printed in NEXT STEPS. |

---

## Files Changed

| File | Changes |
|------|---------|
| `demo/setup-openclaw-vm.sh` | DEBIAN_FRONTEND, debconf preseed, Node 22, unattended-upgrades, chrony, sysctl hardening, both IMDS endpoints, ProtectHome/KernelModules/KernelLogs on app service, deny routed, pip3 fix, step renumbering, sed for PasswordAuth |
| `demo/setup-secret-proxy.sh` | Node.js prerequisite check, logrotate config |
| `.gitattributes` | New file: `*.sh text eol=lf` |

---

## Verification

All fixes verified on a clean Azure VM (Standard_B2ms, Ubuntu 22.04):

```
Node.js:            v22.22.0           ✓
Services running:   xvfb, secret-proxy, fail2ban, tailscaled, unattended-upgrades, chrony   ✓
User isolation:     openclaw (UID 998, no sudo, no docker)   ✓
Secrets:            /etc/openclaw/secrets/ (root:root, 700)  ✓
IMDS blocked:       169.254.169.254 + 168.63.129.16          ✓
Sysctl:             syncookies=1, redirects=0, source_route=0, rp_filter=2   ✓
Sandboxing:         NoNewPrivileges, ProtectSystem=strict, ProtectHome, ProtectKernelModules, ProtectKernelLogs, PrivateTmp, RestrictAddressFamilies   ✓
Secret proxy:       Socket at /run/openclaw/secret-proxy.sock, logrotate configured   ✓
```

Test VM was destroyed after verification.
