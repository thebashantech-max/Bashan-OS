#!/bin/sh
# Bashan OS — TEST ONLY. Runs INSIDE a QEMU guest and writes its findings
# to the shared disk for the host to read.
#
# ######################################################################
# #  THIS FILE MUST NEVER BE IN THE SHIPPED ISO.                       #
# #  hooks/chroot/0930-no-test-harness.hook.chroot fails the build if  #
# #  anything from test/ reaches the image.                            #
# ######################################################################
#
# It exists because driving the guest by typing characters through QEMU's
# monitor drops keys on long commands, which silently mangles the very
# diagnostics you are relying on. One short typed command starts this; the
# answers come back as a file.
# RUN AS THE DESKTOP USER, never with sudo. The Plasma checks talk to the
# session bus, which root does not have, and $HOME must be the user's or
# the config paths are wrong. Individual commands that need root use sudo
# themselves. Learned by running it the other way and getting
# "Could not connect to D-Bus server" for every Plasma question.
set -u
if [ "$(id -u)" = "0" ]; then
    echo "run this as your normal user, not with sudo" >&2
    exit 2
fi
OUT=/mnt/bashan-test/results.txt
: > "$OUT"
say() { printf '%s\n' "$*" >> "$OUT"; }
run() { say "### $1"; shift; "$@" >> "$OUT" 2>&1; say ""; }

say "=== BASHAN OS TEST HARNESS ==="
say "date: $(date -Is)"
say "whoami: $(whoami)   host: $(hostname)"
say ""

run "boot time"            systemd-analyze
run "memory"               free -m
run "top 10 by memory"     sh -c "ps -eo rss,comm --sort=-rss | head -11"
run "idle cpu"             sh -c "top -bn2 -d1 | grep -E '^%?Cpu' | tail -1"
run "firewall"             sh -c "sudo ufw status verbose 2>&1 | head -6"
run "listening ports"      sh -c "sudo ss -lntup 2>/dev/null | head -15"
run "tor"                  systemctl is-enabled tor
run "unattended-upgrades"  systemctl is-enabled unattended-upgrades
run "apt sources"          ls /etc/apt/sources.list.d/
run "failed units"         sh -c "systemctl --failed --no-legend | head -10"
run "enabled services"     sh -c "systemctl list-unit-files --state=enabled --type=service --no-legend | wc -l"

say "### desktop containment"
Q="qdbus6 org.kde.plasmashell /PlasmaShell evaluateScript"
$Q 'print(desktops()[0].type)' >> "$OUT" 2>&1
say ""
say "### applet geometry keys in appletsrc"
grep -n 'ItemGeometries' "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" >> "$OUT" 2>&1
say ""
say "### widgets present"
$Q 'var d=desktops()[0]; var w=d.widgets(); var s=""; for(var i=0;i<w.length;i++){s+=w[i].type+" ";} print(w.length+": "+s)' >> "$OUT" 2>&1
say ""

run "fonts syr/ar/he" sh -c "for l in syr ar he; do printf '%s -> ' \$l; fc-match -f '%{family}\n' :lang=\$l; done"
run "default apps"    sh -c "for m in image/jpeg video/mp4 application/pdf; do printf '%s -> ' \$m; xdg-mime query default \$m; done"
run "bashan-action"   sh -c "xdg-mime query default x-scheme-handler/bashan-action"

say "### key binaries present"
for b in brave-browser-stable vlc gimp kdenlive kolourpaint converseen \
         ghb okular gwenview plasma-discover torbrowser-launcher \
         bashan-welcome bashan-theme-toggle bashan-action \
         bashan-install-chrome bashan-install-nvidia; do
    if command -v "$b" >/dev/null 2>&1; then say "  OK      $b"; else say "  MISSING $b"; fi
done
say ""

say "### harness finished"
sync
