# Install Scripts

Curl install scripts for inference.sh, served via Cloudflare Pages.

- `cli.inference.sh` → `cli/index.html` (bash; also handles Git Bash on Windows)
- `cli.inference.sh/install.ps1` → `cli/install.ps1` (PowerShell)
- `engine.inference.sh` → `engine/index.html`

## Updating

Edit the scripts here and push — Cloudflare Pages auto-deploys from this repo.

Two Pages projects point to this repo:
- **install-cli** — root directory `cli/`, custom domain `cli.inference.sh`
- **install-engine** — root directory `engine/`, custom domain `engine.inference.sh`

## Checking

`cli/index.html` and `engine/index.html` share blocks marked `# >>> shared <name>` … `# <<< shared <name>`. Change a shared block in both files, then run:

```sh
scripts/check.sh
```

It fails when a shared block differs (apart from the binary name) or a script does not parse.
