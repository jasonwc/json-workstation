# Coding Agents Setup Guide

CLI coding agents installed via `modules/home/coding-agents.nix`. This doc covers subscription requirements and per-device setup for each tool.

## Subscriptions

| Provider | Tier | Price | What It Covers |
|----------|------|-------|---------------|
| Anthropic | Max (or API) | $100-200/mo | claude, aider, goose, opencode, pi |
| OpenAI | ChatGPT Pro | $200/mo | codex, aider, goose, opencode, pi |
| Google | AI Pro ($19.99/mo) or AI Ultra ($249.99/mo) | varies | gemini, aider, goose, opencode, pi |

Google AI Ultra ($249.99/mo, $124.99 intro) is the ChatGPT Pro equivalent — highest limits, Deep Think reasoning, Project Mariner, YouTube Premium, $100/mo GCP credits. Google AI Pro ($19.99/mo) is sufficient for generous Gemini CLI access with 1M token context.

Sign up: https://gemini.google/subscriptions/

## First-Run Setup

### OAuth-based (browser login, no API keys needed)

```bash
claude        # Opens browser -> Anthropic OAuth
codex         # Opens browser -> ChatGPT OAuth
gemini        # Opens browser -> Google OAuth (select "Sign in with Google")
```

### Interactive config

```bash
goose configure    # Wizard: pick provider, paste API key or OAuth
opencode           # Then /connect -> pick provider -> browser or API key
pi                 # Then /login -> pick provider -> browser or API key
```

### API key only

```bash
# aider reads env vars directly — no login command
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
export GEMINI_API_KEY="..."
aider
```

The same env vars also work for goose, opencode, and pi as fallbacks.

## Credential Storage Locations

| Tool | Storage |
|------|---------|
| claude | `~/.claude/.credentials.json` (Linux), macOS Keychain (mac) |
| codex | OS keyring or `~/.codex/auth.json` |
| gemini | `~/.gemini/` |
| goose | OS keyring or `~/.config/goose/secrets.yaml` |
| opencode | `~/.local/share/opencode/auth.json` |
| pi | `~/.pi/agent/auth.json` |
| aider | None — reads env vars / `.env` files only |

## Config File Locations

| Tool | Global Config | Project Config |
|------|--------------|----------------|
| aider | `~/.aider.conf.yml` | `.aider.conf.yml` in repo root |
| claude | `~/.claude/settings.json` | `.claude/settings.json` |
| codex | `~/.codex/config.toml` | `.codex/config.toml` |
| gemini | `~/.gemini/.env` | `.env` in project dir |
| goose | `~/.config/goose/config.yaml` | — |
| opencode | — | `opencode.json` in project root |
| pi | `~/.pi/agent/settings.json` | — |

## Notes on Secrets and Nix

API keys should NOT go in Nix config — the Nix store is world-readable. Options for managing secrets:

- **`.env` files** outside Nix (e.g., `~/.env` or `~/.config/coding-agents.env`)
- **OS keyring** (used by claude, codex, goose automatically)
- **OAuth browser login** (claude, codex, gemini) — credentials stored per-machine automatically
- For headless/remote: `claude setup-token`, `codex login --device-auth`, or set env vars via SSH
