# json-station (Windows)

Documentation and config for native Windows services on json-station that can't be managed by Nix/WSL.

## Network

- **Hostname**: json-station
- **DNS**: `sunshine.json.lab` → json-station IP (via Firewalla local DNS mapping)
- **DHCP reservation**: Set via Firewalla to ensure stable IP

## Sunshine (Game Streaming)

Sunshine is a self-hosted game streaming server (Moonlight-compatible).

### Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 47990 | TCP | Web UI / API |
| 47984 | TCP | RTSP (stream negotiation) |
| 47989 | TCP | Control |
| 48010+ | UDP | Video, audio, input |

- **Web UI**: `http://sunshine.json.lab` (via Caddy reverse proxy)
- **Streaming**: Moonlight connects directly via hostname; port negotiation is automatic

### Windows Firewall

Ensure ports 47984, 47989, 47990 (TCP) and 48010+ (UDP) are allowed inbound.

## Caddy (Reverse Proxy)

Caddy runs on Windows to proxy `http://sunshine.json.lab` (port 80) → `localhost:47990`, so the Sunshine web UI is accessible without remembering the port.

### Setup

1. Download Caddy from https://caddyserver.com/download (Windows amd64)
2. Place `Caddyfile` alongside the binary (see `Caddyfile` in this directory)
3. Install as a Windows service: `caddy install`

### Caddyfile

```
sunshine.json.lab {
    reverse_proxy localhost:47990
}
```
