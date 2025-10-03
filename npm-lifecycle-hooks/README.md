## NPM Lifecycle Hooks Emulation (Linux)

This folder contains safe, atomic demos of npm lifecycle hooks that run automatically during install/uninstall:

- preinstall
- install
- postinstall
- postuninstall (fires on uninstall)

Each demo package posts a small JSON payload to a webhook so you can observe behavior. If `MOCK_WEBHOOK` is not set, it falls back to `http://localhost:8080/webhook-receiver` (the local mock server from this repo).

### Prerequisites
- Linux/macOS shell with bash and curl
- Node.js and npm
- Optional: from repo root, `source ./setup_test_env.sh` to start the local mock server and export `MOCK_WEBHOOK`

### Quick Start
```bash
# From repo root (recommended to start local server)
source ./setup_test_env.sh

# Run all demos (creates an isolated test project)
./npm-lifecycle-hooks/run_all.sh
```

What happens:
- Creates `npm-lifecycle-hooks/.test-project` with a fresh `package.json`
- Installs each demo package from local paths to trigger its hook
- Uninstalls the postuninstall demo to trigger its cleanup hook

### How It Works
NPM automatically runs lifecycle scripts defined in a package's `package.json`:

```json
{
  "scripts": {
    "preinstall": "bash scripts/preinstall.sh",
    "install": "bash scripts/install.sh",
    "postinstall": "bash scripts/postinstall.sh",
    "postuninstall": "bash scripts/postuninstall.sh"
  }
}
```

When a consumer runs `npm install ./some-package`, npm executes the package's hooks at the appropriate phases. This repo's demo packages do only minimal, visible actions (echo + POST to webhook) to keep them safe and easy to analyze.

### Basic Mitigations (No detections here)
- Prefer `npm ci --ignore-scripts` (or `npm install --ignore-scripts`) in CI/build systems
- Enforce `ignore-scripts=true` at org/agent level:
  - `npm config set ignore-scripts true`
  - or env var: `NPM_CONFIG_IGNORE_SCRIPTS=true`
- Use non-privileged build users; run installs in ephemeral, network-restricted environments
- Pin and lock dependencies; review changes to `package-lock.json`
- Restrict registry and scopes to trusted sources (`.npmrc` registry, scope settings)
- Monitor/alert on unexpected child processes and outbound network from build agents

### Notes
- Linux/macOS only. Windows users should use the PowerShell-based Windows edition under `windows/`.
- These demos are intentionally minimal and side-effect free beyond a POST to your webhook.


