# Automatic day / night theme switching

**Off by default.** Bashan OS boots dark and stays dark until someone asks
otherwise.

## Turning it on

```
systemctl --user enable --now bashan-theme-day.timer bashan-theme-night.timer
```

Light at 07:00, dark at 19:00, local time.

## Turning it off again

```
systemctl --user disable --now bashan-theme-day.timer bashan-theme-night.timer
```

## Changing the times

```
systemctl --user edit bashan-theme-day.timer
```

and set another `OnCalendar=`, for example `*-*-* 06:30:00`.

## Why fixed times and not real sunrise and sunset

Real sunrise and sunset need the machine's coordinates. Asking a laptop
where it is, so it can choose a colour scheme, is not a trade worth making
on an OS that ships no telemetry. Fixed local times need nothing and are
adjustable in one command.

## What it does not do

It does not override a manual choice. If the user presses the toggle at
20:00 to go light, the next change is the 07:00 timer. There is no "auto"
mode that fights the user.
