# Viewing a Paper Clearing from iOS (Termius + WireGuard)

Personal ops note. A Paper Compute **clearing** (local Kind-backed data plane:
console, tapes API, platform, paper proxy) runs on this machine
(`JSON-MACBOOK16`, the dev SSH server). Goal: view the clearing's web apps —
mainly the **console** — from an iPhone/iPad where Termius is the SSH client and
WireGuard is how the device reaches this box.

The clearing binds its services to **loopback** on the Mac, e.g.:

| Surface | Local address on the Mac |
|---|---|
| console (the app) | `http://localhost:5173` |
| tapes API | `http://127.0.0.1:18552/v1` |
| platform | `http://aie.localhost:18541` |
| paper proxy | `http://127.0.0.1:52001` |

`clearing forward --background` (run on the Mac) is what maps the Kind pods onto
these loopback ports. Everything below sits *on top of* that — run it first.

## The iOS catch (read this before picking a path)

iOS/iPadOS suspends any backgrounded app in ~20–30s, which **kills a Termius
port-forward the moment you switch to Safari**. This is an OS restriction, not a
Termius bug — it hits every SSH client. So the "hold a tunnel while I look at the
app in the browser" flow is fragile on iOS. Two ways to deal with it:

---

## Path A — Termius Local forward + iPad Split View (quick, no config)

Best for a quick look on **iPad**. Not viable on iPhone (no Split View).

1. On the Mac: `clearing up` then `clearing forward --background`, and
   `clearing console dev` (serves console on `:5173`).
2. In Termius → **Port Forwarding → New Rule → Local**:
   - Bind address: `127.0.0.1`
   - Ports: **`5173` → `5173`** (do not remap — see gotchas)
   - Destination (from the Mac): `127.0.0.1:5173`
   - Double-click the rule to start it.
3. Open **Safari in Split View next to Termius** (keep Termius on-screen so iOS
   doesn't suspend it) → browse `http://localhost:5173`.

Add more Local rules the same way if needed (`18552→18552` for the tapes API,
etc.). Fully backgrounding Termius drops the tunnel in ~20–30s.

---

## Path B — Direct over WireGuard (robust, works on iPhone too)

WireGuard already puts the device on the Mac's network, so reach the Mac by its
**VPN IP directly** — no phone-side tunnel to suspend. This is the better path
for recurring use or iPhone. It needs a little setup because of WorkOS auth.

**Non-auth surfaces (tapes API, etc.) — trivial:**
- Bind the service to the VPN interface instead of loopback, then hit
  `http://<mac-wg-ip>:18552/v1/...` from mobile Safari. No tunnel, no login.

**Console (has WorkOS login) — one-time setup:**
The OAuth `redirect_uri` must be an allowlisted origin; by default only
`localhost:5173` is allowlisted (why `clearing console dev` pins 5173). To serve
it over WireGuard:
1. Bind Vite to the VPN interface: `pnpm dev --host <mac-wg-ip>` (or the
   clearing's console host/`CONSOLE_PORT` options), keeping port **5173**.
2. Add `http://<mac-wg-ip>:5173/...` as an allowlisted callback in the **WorkOS
   *staging*** app and set `WORKOS_REDIRECT_URI` to match. (Needs someone with
   WorkOS staging access — the README notes additional allowlisted callbacks are
   a supported pattern.)
3. Browse `http://<mac-wg-ip>:5173` directly. A WireGuard peer IP is stable, so
   this is a one-time allowlist add.

---

## Gotchas

- **Keep the console on port 5173.** The WorkOS callback is port-specific;
  remapping to another local port breaks the `redirect_uri` match and login
  fails.
- **`aie.localhost` (platform) won't work on iOS Safari.** You can't edit
  `/etc/hosts` on iOS and Safari won't reliably resolve `*.localhost` to
  loopback. The platform vhost needs direct-IP access (Path B), not hostname.
- The console is TanStack Start SSR — its data hooks call tapes **server-side on
  the Mac**, so the *browser* only needs the console origin (`:5173`). You don't
  have to forward tapes just to use the console UI.

## Security

Binding clearing services to the WireGuard interface (Path B) is broader than the
clearing's loopback-only default. It's acceptable *because* exposure is limited
to the trusted VPN — but only bind the services you actually need remote, and
revert to loopback when done.

## Links

- Termius port forwarding: https://docs.termius.com/organize-and-connect-to-hosts/port-forwarding-and-tunneling
- iOS background limitation: https://support.termius.com/hc/en-us/articles/900006226306-Keep-your-Termius-sessions-alive-in-the-background
