# Reporting a security problem

Thank you for looking. If you have found something that could put people
using Bashan OS at risk, please tell us before telling the world.

## How to report

Email **admin@bashan.app** with:

- what the problem is, in as much or as little detail as you have;
- how to reproduce it, if you know;
- which version — the SHA256 of the ISO, or the commit, helps a lot;
- whether you intend to publish, and when.

**Please do not open a public issue for a security problem.** Open issues are
visible to everyone, including people who would use the information before it
is fixed.

## What to expect

This is a small project — at the time of writing, one person and a preview
release. A reply may take days rather than hours. We will tell you whether
we can reproduce it, what we intend to do, and roughly when.

We will credit you when the fix is published unless you ask us not to.

## What is in scope

- The build configuration and scripts in this repository.
- The Bashan-specific programs in the image: the welcome application, the
  add-on installer, the diagnostics window, the installer configuration, and
  the hooks that harden the system.
- Anything in our configuration that weakens a Debian default — a permission,
  a disabled check, a service that should not be running.

## What is not in scope

- **Bugs in Debian's packages.** Bashan OS ships Debian's software
  unmodified. Report those to Debian: <https://www.debian.org/security/> —
  they will reach far more users that way.
- Bugs in Brave, Chrome, LibreOffice, KDE or the Linux kernel. Report those
  upstream.
- **Known, documented limitations.** Several are listed under "Known
  limitations" in `README.md` and in the release notes. If it is already
  written down as a known problem, it is not a new finding — though if you
  think we have underestimated one, say so.

## Things you should know already

This is a **Public Preview**. It has been tested on one laptop and in virtual
machines. It has never been installed on a real disk by anyone. Do not run it
on a machine that matters, and do not treat it as hardened.
