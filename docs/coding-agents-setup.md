# Coding Agents Setup Guide

CLI coding agents installed via `modules/home/coding-agents.nix`. This doc covers subscription requirements and per-device setup for each tool.

## Subscriptions

| Provider | Tier | Price | What It Covers |
|----------|------|-------|---------------|
| Anthropic | Max (or API) | $100-200/mo | claude |
| OpenAI | ChatGPT Pro | $200/mo | codex, opencode, pi, dsh |
| Google | AI Pro ($19.99/mo) or AI Ultra ($249.99/mo) | varies | agy, pi |
| GitHub | Copilot plan | varies | copilot |
| Cursor | Cursor plan | varies | cursor-agent |

Google AI Ultra ($249.99/mo, $124.99 intro) is the ChatGPT Pro equivalent — highest limits, Deep Think reasoning, Project Mariner, YouTube Premium, $100/mo GCP credits. Google AI Pro ($19.99/mo) is sufficient for generous access with 1M token context.

Google retired Gemini CLI in favour of Antigravity CLI, so this flake installs `antigravity-cli` (binary: `agy`) instead of `gemini-cli`.

Sign up: https://gemini.google/subscriptions/

## Switching between ChatGPT and the Sparks

opencode, pi and dsh are each set up with two backends: the ChatGPT subscription
and the DGX Sparks (`json-lab`, `modules/home/json-lab-models.nix`). Only one
Sparks model is served at a time; `curl -s http://inference.json.lab/v1/models`
says which.

| Tool | Switch model | Start on a given model |
|------|--------------|------------------------|
| opencode | `/models` (only OpenAI and json-lab are listed), F2 cycles recents | `opencode -m json-lab/<id>` |
| pi | Ctrl+P cycles ChatGPT + Sparks, `/model` to search | `pi --model json-lab/<id>` |
| dsh | model picker in the web composer | `dsh web`, pick there |

Claude is deliberately not wired into these: since April 2026 Anthropic bills
Claude subscription logins from third-party harnesses as paid extra usage. Use
Claude through Claude Code.

On macOS, these tools need the terminal app's **Local Network** permission
(System Settings → Privacy & Security → Local Network) to reach the Sparks.
Without it they fail with `EHOSTUNREACH` / "Connection error" while Apple's
own `curl` still works, so test with one of the agents, not curl.

## First-Run Setup

### OAuth-based (browser login, no API keys needed)

```bash
claude        # Opens browser -> Anthropic OAuth
codex         # Opens browser -> ChatGPT OAuth
agy           # Opens browser -> Google OAuth (select "Sign in with Google")
```

### Interactive config

```bash
opencode           # Then /connect -> OpenAI -> ChatGPT Pro/Plus (browser)
pi                 # Then /login -> ChatGPT
dsh web            # Then Models page -> openai-codex -> Sign in with ChatGPT
copilot            # Then /login -> GitHub device flow
cursor-agent login # Browser -> Cursor account
```

### API key only

```bash
# Optional API-key fallbacks
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
export GEMINI_API_KEY="..."
```

pi uses these env vars as fallbacks. opencode only picks up `OPENAI_API_KEY`, since its providers are limited to OpenAI and json-lab.

## Credential Storage Locations

| Tool | Storage |
|------|---------|
| claude | `~/.claude/.credentials.json` (Linux), macOS Keychain (mac) |
| codex | OS keyring or `~/.codex/auth.json` |
| agy | `~/.antigravity/` (not yet confirmed on a logged-in machine) |
| dsh | `~/.dsh/.credentials.yaml` |
| opencode | `~/.local/share/opencode/auth.json` |
| pi | `~/.pi/agent/auth.json` |
| copilot | not yet confirmed on a logged-in machine |
| cursor-agent | not yet confirmed on a logged-in machine |

## Config File Locations

| Tool | Global Config | Project Config |
|------|--------------|----------------|
| claude | `~/.claude/settings.json` | `.claude/settings.json` |
| codex | `~/.codex/config.toml` | `.codex/config.toml` |
| agy | `~/.antigravity/` (not yet confirmed on a logged-in machine) | `.antigravityignore` in repo root |
| dsh | `~/.dsh/profiles/<profile>/cordis.patch.yml` (Models page) | — |
| opencode | `~/.config/opencode/opencode.json` (written by `json-lab-inference.nix`) | `opencode.json` in project root |
| pi | `~/.pi/agent/settings.json` | — |

## Notes on Secrets and Nix

API keys should NOT go in Nix config — the Nix store is world-readable. Options for managing secrets:

- **`.env` files** outside Nix (e.g., `~/.env` or `~/.config/coding-agents.env`)
- **OS keyring** (used by claude and codex automatically)
- **OAuth browser login** (claude, codex, agy) — credentials stored per-machine automatically
- For headless/remote: `claude setup-token`, `codex login --device-auth`, or set env vars via SSH
