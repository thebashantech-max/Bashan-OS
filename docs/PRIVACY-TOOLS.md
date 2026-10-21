# Privacy and proxy tools

**Nothing here is switched on.** Nothing connects anywhere until you set it
up yourself. No VPN service is bundled, no server list ships, nothing needs
an account, a sign-up or a card.

Measured cost: **69.2 MB, 33 packages.** Idle cost: **zero** — the tor
daemon is disabled and everything else runs only when you start it.

---

## Tor Browser

### What it does

Tor hides **which websites you visit** from whoever runs your internet
connection, by passing your traffic through several volunteer-run computers
around the world before it reaches the site. The site sees the last of those
computers, not you.

It does **not** make you anonymous in general. If you log in to an account,
that account knows who you are.

### What happens on first run — exactly

Bashan OS ships `torbrowser-launcher`, **not Tor Browser itself.** The first
time you open "Tor Browser" from the menu, the launcher:

1. **Needs an internet connection.** Without one it can do nothing.
2. Downloads Tor Browser from the Tor Project, from
   **`https://dist.torproject.org/`** (with
   `https://aus1.torproject.org/` used to work out the current version).
   The download is roughly **100 MB**.
3. **Verifies the Tor Project developers' GPG signature** on what it
   downloaded, and refuses to run it if the signature does not match.
4. Unpacks it into your own home folder, under `~/.local/share/torbrowser/`.
5. Afterwards Tor Browser updates itself, and the launcher is not involved
   again.

### Why ship the launcher instead of the browser

Shipping Tor Browser itself would mean an ISO that goes stale: an
out-of-date Tor Browser is a security problem, and we would have to rebuild
the ISO every time the Tor Project released one. The launcher always fetches
the current version and checks its signature.

The cost is honest and worth stating: **Tor Browser does not work offline on
a fresh install.** It needs that one download first.

### Two honest warnings

- **It is noticeably slower.** Your traffic is taking three hops around the
  world. Video is painful.
- **Some sites block it outright**, banks especially. This is not a fault in
  Tor; it is the sites' choice.

---

## The tor daemon — installed, switched off

The `tor` package is installed but the service is **disabled and masked** by
`hooks/chroot/0320-tor-disabled.hook.chroot`, which **fails the build** if it
is enabled. It therefore costs **no idle RAM and opens no socket**.

**Tor Browser does not need it** — Tor Browser carries its own tor.

It is there for someone who deliberately wants a system-wide Tor proxy. To
start it:

```
sudo systemctl unmask tor
sudo systemctl enable --now tor
```

`proxychains4` is installed alongside it for routing a chosen command
through that proxy. Its shipped default points at `127.0.0.1:9050`, which is
where tor would listen **if you started it**. Until then it does nothing.

---

## VPN — the client, never a service

### What a VPN is, in plain words

A VPN sends **all** your internet traffic through one other computer first.
Whoever runs your connection — a café, an airport, an internet provider —
then sees only that you are talking to that one computer, not which sites
you visit.

### A VPN needs a server, and Bashan OS does not include one

This is the part that is usually left out. A VPN is not a thing you switch
on; it is a connection **to a computer somewhere else**. You need either:

- **your own server** — see `docs/WIREGUARD-HOME-SERVER.md`, which is the
  option we recommend and have written up; or
- **a company's server**, which you pay for.

### Be careful with free VPN services

A VPN provider can see everything your internet provider could see. You are
choosing who to trust, not removing the need to trust anyone.

**Many free VPN services keep records of what you do and sell them.** That
is how a free service pays for its servers. The result is the opposite of
what you wanted: instead of your internet provider knowing, a company you
have never heard of knows, and sells it.

Bashan OS deliberately bundles **no VPN service and no server list**, so
nothing here is steering you towards anyone's product.

### Importing a VPN with no terminal

Both work from the network icon in the dock.

**WireGuard** (a `.conf` file): NetworkManager 1.52 speaks WireGuard
natively — there is no plugin to install — and the kernel module ships with
the stock Debian kernel (verified: `wireguard.ko.xz` in
`6.12.111+deb13-amd64`).

1. Click the network icon in the dock.
2. Open the network settings.
3. **Add** a connection, then **Import VPN connection**.
4. Choose your `.conf` file.
5. It appears in the network menu. Click to connect.

**OpenVPN** (an `.ovpn` file): `network-manager-openvpn` is installed so
OpenVPN appears in that same list. Same steps, choose the `.ovpn` file.

If the import asks for a password, that is your VPN's password, not the
computer's.

---

## What each piece costs

| Package | Size | Idle cost |
|---|---|---|
| `torbrowser-launcher` | 60.0 MB (21 packages) | none — runs when opened |
| `tor` | 31.9 MB (5 packages) | **none — disabled and masked** |
| `proxychains4` | 0.1 MB | none |
| `wireguard-tools` | 0.3 MB | none |
| `openvpn` + `network-manager-openvpn` | 8.8 MB (10 packages) | none |
| **total** | **69.2 MB, 33 packages** | **zero at idle** |

Nothing above adds a service that starts at boot. Verified by the build hook
for tor; the others ship no enabled unit.

---

## Legal note

Tor and VPN tools are ordinary software in most countries and restricted in
some. Export rules may also apply to distributing cryptographic software.
Both are recorded in Bashan Tech LLC's internal legal notes (not published) as questions for
a lawyer. **Nothing here is legal advice.**
