# Lock screen

This overrides `LockScreenUi.qml` in the **shell** package, at

    /usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/

It was first put in our look-and-feel package, which did nothing. In
Plasma 6 a look-and-feel package cannot carry a lock screen: Breeze's
contains `defaults, layouts, logout, osd, previews, splash,
systemdialog` and no `lockscreen` at all. The lock screen UI comes from
the shell, and nowhere else. The look-and-feel still decides the lock
screen *wallpaper*; it just cannot change the *buttons*.

The only change from the stock file is two extra buttons, Restart and
Shut Down, in the `actionItems` list. The stock lock screen offers Sleep,
Hibernate and Switch User, so a machine whose password is unknown - or
which has none - cannot be turned off from it. On real hardware that left
a woken laptop with no way out at all.

shortcut: this path is owned by the plasma-workspace package, so
upgrading plasma-workspace on a running machine restores the stock file
until the next image is built. Upgrade to a dpkg-divert if that has to
survive package updates.
