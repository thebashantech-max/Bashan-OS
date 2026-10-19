#!/bin/sh
# Read the settings of the INSTALLED system and write the answers out to the
# harness disk. Screen-only facts (the login prompt, the lock screen
# buttons) are checked by screenshot instead; this covers what a file can
# answer, where a photograph of a screen cannot prove the setting behind it.
OUT=/mnt/bashan-test/installed-checks.txt
{
  echo "== timezone =="
  readlink -f /etc/localtime
  timedatectl show -p Timezone 2>/dev/null
  echo
  echo "== lock on wake =="
  for f in /etc/xdg/kscreenlockerrc "$HOME/.config/kscreenlockerrc"; do
    [ -f "$f" ] && { echo "-- $f"; grep -E "Autolock|LockOnResume|LockGrace" "$f"; }
  done
  echo
  echo "== keyboard layouts active =="
  for f in /etc/xdg/kxkbrc "$HOME/.config/kxkbrc"; do
    [ -f "$f" ] && { echo "-- $f"; grep -E "LayoutList|VariantList|Options|DisplayNames" "$f"; }
  done
  echo "-- what X/Wayland is actually using"
  setxkbmap -query 2>/dev/null || echo "(no setxkbmap; wayland session)"
  localectl status 2>/dev/null
  echo
  echo "== lock screen buttons =="
  Q=/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreenUi.qml
  if [ -f "$Q" ]; then
    grep -cn "requestShutdown\|requestReboot" "$Q" | sed 's/^/matches: /'
    grep -n "text:.*Shut Down\|text:.*Restart\|requestShutdown\|requestReboot" "$Q"
  else
    echo "MISSING $Q"
  fi
  echo
  echo "== live-only settings must NOT be here =="
  [ -e /lib/live/config/2000-bashan-live ] && echo "STILL PRESENT (should be gone)" || echo "absent (correct)"
  echo "kwallet:"; grep -H "Enabled" /etc/xdg/kwalletrc 2>/dev/null || echo "(no kwalletrc override)"
  echo "unattended-upgrades:"; systemctl is-enabled unattended-upgrades 2>&1
  echo
  echo "== the installer's own verifier, re-run on the installed system =="
  /usr/libexec/bashan/bashan-verify-install 2>&1; echo "exit: $?"
  echo
  echo "== users =="
  awk -F: '$3>=1000 && $7 !~ /nologin|false/ {print $1, $3, $7}' /etc/passwd
  echo
  echo "== locales compiled here =="
  localedef --list-archive 2>/dev/null | wc -l
  locale -a 2>/dev/null | grep -cE "^(tr_TR|it_IT|nl_NL|sr_RS|mk_MK|ro_RO|pl_PL|hu_HU|bg_BG|zh_CN)"
} > "$OUT" 2>&1
sync
echo "written to $OUT"
