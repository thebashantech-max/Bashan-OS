#!/bin/sh
# Self-check for bashan-apply-keyboard, run by ./build.sh test.
#
# The rule: four layouts maximum, us and ara never displaced, and whatever
# the person picked during install must actually end up active.
set -eu
FIX=$(readlink -f "${1:-branding/rootfs/usr/libexec/bashan/bashan-apply-keyboard}")
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
# want <description> <command...>
want() { d=$1; shift; if "$@"; then ok "$d"; else bad "$d"; fi; }

setup() { # chosen-layout
    rm -rf "${tmp:?}/etc"; mkdir -p "$tmp/etc/xdg" "$tmp/etc/default"
    printf '[Layout]\nLayoutList=us,ara,es,fr\nVariantList=,,,\nDisplayNames=EN,AR,ES,FR\n' \
        > "$tmp/etc/xdg/kxkbrc"
    printf 'XKBLAYOUT="%s"\n' "$1" > "$tmp/etc/default/keyboard"
}
layouts() { sed -n 's/^LayoutList=//p' "$tmp/etc/xdg/kxkbrc"; }
run() { BASHAN_ETC="$tmp/etc" sh "$FIX" >"$tmp/out" 2>&1; }

echo "a layout already in the defaults"
setup fr; run
want "leaves the four alone" test "$(layouts)" = "us,ara,es,fr"

echo "a layout that is not"
setup de; run
got=$(layouts)
case "$got" in us,ara,de,*) ok "German became active: $got" ;; *) bad "got $got" ;; esac
want "still at most four" test "$(printf '%s' "$got" | tr ',' '\n' | grep -c .)" -le 4
want "US kept" sh -c "printf '%s' \"$got\" | tr ',' '\\n' | grep -qx us"
want "Arabic kept" sh -c "printf '%s' \"$got\" | tr ',' '\\n' | grep -qx ara"

echo "the script-specific ones from the list"
for l in sy ir tr ru cn; do
    setup "$l"; run
    want "$l becomes active" sh -c "printf '%s' \"$(layouts)\" | tr ',' '\\n' | grep -qx $l"
done

echo "a variant list that matches the layout count"
setup de; run
n=$(printf '%s' "$(layouts)" | tr ',' '\n' | grep -c .)
v=$(sed -n 's/^VariantList=//p' "$tmp/etc/xdg/kxkbrc" | awk -F, '{print NF}')
want "variants line up with layouts ($n)" test "$n" = "$v"

echo "nothing to read"
setup de; rm -f "$tmp/etc/default/keyboard"; run
want "leaves defaults when the choice is unreadable" test "$(layouts)" = "us,ara,es,fr"

echo ""
echo "  $pass passed, $fail failed"
[ "$fail" = 0 ]
