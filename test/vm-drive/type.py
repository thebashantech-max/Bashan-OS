#!/usr/bin/env python3
"""Type a literal string into the QEMU guest through the monitor socket.

The monitor only takes key NAMES, so every character has to be mapped. It
also cannot produce "$" at all, so shell one-liners sent through here must
not use variables.

Lives in the repo because /tmp gets cleaned mid-session and took this with
it twice, once silently.

    ./test/vm-drive/type.py build/vm/monitor.sock "some text"
"""
import socket
import sys
import time

MAP = {' ': 'spc', '/': 'slash', '-': 'minus', '.': 'dot', ',': 'comma',
       '=': 'equal', ';': 'semicolon', "'": 'apostrophe',
       '*': 'shift-8', '&': 'shift-7', '_': 'shift-minus',
       ':': 'shift-semicolon', '>': 'shift-dot', '|': 'shift-backslash',
       '~': 'shift-grave_accent', '$': 'shift-4', '+': 'shift-equal',
       '%': 'shift-5', '!': 'shift-1', '"': 'shift-apostrophe',
       '(': 'shift-9', ')': 'shift-0', '?': 'shift-slash'}

s = socket.socket(socket.AF_UNIX)
s.connect(sys.argv[1])
time.sleep(0.3)
for ch in sys.argv[2]:
    if ch in MAP:
        k = MAP[ch]
    elif ch.isupper():
        k = 'shift-' + ch.lower()
    elif ch.isalnum():
        k = ch
    else:
        print("unmapped:", repr(ch), file=sys.stderr)
        continue
    s.sendall(("sendkey %s\n" % k).encode())
    time.sleep(0.05)
time.sleep(0.5)
s.close()
