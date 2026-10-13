# Running your own WireGuard server at home

This is the honest answer to "how do I get a VPN without paying a company
to watch me instead". You run the server yourself, on a machine you own, at
home. Then the only person who can see your traffic is you.

**What it gets you:** when the laptop is on a café or hotel network, its
traffic comes out of **your home connection** instead. Also reaches things
on your home network — a printer, a file share — from anywhere.

**What it does not get you:** it is not anonymity. Websites still see your
home address. For hiding *which sites you visit*, use Tor Browser.

---

## What you need

- A machine at home that stays on — an old PC, a small server, a Raspberry
  Pi. It needs to run Linux.
- Your home internet connection, and access to the router's settings.
- About half an hour.

**One honest warning before you start:** this opens one port on your home
router to the internet. WireGuard is small, well-reviewed and silent to
anyone without a key — it does not even reply to an unauthorised packet —
but it is still a door where there was none. If that is not a trade you want
to make, use Tor Browser instead and skip this.

---

## 1. Install WireGuard on the home machine

On Debian or Bashan OS:

```bash
sudo apt install wireguard-tools
```

## 2. Make the server's keys

```bash
sudo mkdir -p /etc/wireguard && sudo chmod 700 /etc/wireguard
cd /etc/wireguard
wg genkey | sudo tee server-private.key | wg pubkey | sudo tee server-public.key
sudo chmod 600 /etc/wireguard/server-private.key
```

**The private key never leaves this machine.** The public key is not secret.

## 3. Make the laptop's keys

On the **laptop**:

```bash
wg genkey | tee laptop-private.key | wg pubkey | tee laptop-public.key
chmod 600 laptop-private.key
```

You now have four keys. The two **public** ones get swapped between the
machines; the two **private** ones stay where they were made.

## 4. Write the server's configuration

On the home machine, `/etc/wireguard/wg0.conf`:

```ini
[Interface]
Address = 10.9.0.1/24
ListenPort = 51820
PrivateKey = <paste server-private.key here>

# Let the laptop reach the internet through this machine.
# Replace eth0 with this machine's real network interface - find it with:
#   ip -br link
PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
# The laptop
PublicKey = <paste laptop-public.key here>
AllowedIPs = 10.9.0.2/32
```

Lock it down — it holds a private key:

```bash
sudo chmod 600 /etc/wireguard/wg0.conf
```

## 5. Let the server pass traffic through

```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-wireguard.conf
sudo sysctl --system
```

## 6. Start it, and have it start on boot

```bash
sudo systemctl enable --now wg-quick@wg0
sudo wg show
```

`wg show` should print the interface and the peer.

## 7. Open the port on your router

In the router's settings, forward **UDP port 51820** to the home machine's
local address. The setting is usually called **Port Forwarding** or **Virtual
Server**.

**UDP, not TCP.** This is the single commonest mistake.

### Finding your home address from outside

Most home connections get an address that changes. Use a free dynamic-DNS
name (DuckDNS and similar) so you have a name that follows it. Write that
name down for the next step.

**If your provider uses CGNAT** — common on mobile and some fibre — port
forwarding will not work at all, because you do not have your own public
address. Ask the provider for one, or this approach will not work for you.

## 8. Write the laptop's configuration

On the laptop, `laptop.conf`:

```ini
[Interface]
Address = 10.9.0.2/24
PrivateKey = <paste laptop-private.key here>
DNS = 10.9.0.1

[Peer]
PublicKey = <paste server-public.key here>
Endpoint = yourname.duckdns.org:51820
# 0.0.0.0/0 sends ALL traffic through home.
# For only reaching things on the home network, use 10.9.0.0/24, 192.168.1.0/24
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

## 9. Import it into Bashan OS — no terminal

1. Click the **network icon** in the dock.
2. Open the network settings.
3. **Add** a connection → **Import VPN connection**.
4. Choose `laptop.conf`.
5. It appears in the network menu. Click it to connect.

NetworkManager handles WireGuard natively, so there is nothing to install.

## 10. Check it worked

Before connecting, search the web for "what is my IP" and note the number.
Connect, reload, and check it changed to your home connection's address.

If it did not change, `AllowedIPs` on the laptop is probably not
`0.0.0.0/0`.

---

## Adding another device

Repeat step 3 on the new device for its own keys, add another `[Peer]` block
to the server with the next address (`10.9.0.3/32`), and restart:

```bash
sudo systemctl restart wg-quick@wg0
```

**Every device gets its own key pair.** Do not copy one config to two
devices; they will fight over the address and neither will work reliably.

---

## If it does not connect

| What you see | Usually means |
|---|---|
| Nothing at all, no error | The router port forward is missing, or set to TCP instead of UDP |
| Connects, no internet | `ip_forward` not set, or the wrong interface name in `PostUp` |
| Connects, no names resolve | The `DNS =` line is missing on the laptop |
| Works at home, not away | CGNAT, or a dynamic address that moved |

On the server, `sudo wg show` lists each peer and when it was last seen. A
peer that never shows a handshake is not reaching the server at all — that
is a router or address problem, not a WireGuard one.

---

## Keeping it safe

- The private keys are the whole of the security. Anyone with the laptop's
  private key is the laptop.
- Keep the home machine updated: `sudo apt update && sudo apt upgrade`.
- Remove peers you stop using, by deleting their `[Peer]` block.
- If a device is lost, delete its `[Peer]` block **immediately**. That is
  all it takes to lock it out.
