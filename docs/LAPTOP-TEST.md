# Testing the live USB on the real laptop

Do this **before** installing anything. The whole point of a live USB is
that you can find out whether the hardware works while the laptop's existing
system is still untouched on its disk.

**Nothing in this checklist changes the laptop.** Do not click Install until
the end.

## Before you start

- [ ] Write down the laptop's make and model.
- [ ] **Back up anything on it that matters**, to something that is not the
      laptop. Do this even if you are only testing — you will be tempted to
      install if the test goes well.
- [ ] Have the Wi-Fi password to hand.
- [ ] Plug the charger in. Then unplug it for the battery test later.

## Booting

- [ ] The USB boots at all (boot menu key is usually F12, F9, Esc or F2).
- [ ] If it will not boot: try turning **Secure Boot** off in the firmware,
      then try again. Note which was needed — it matters for the install.
- [ ] The Bashan logo splash appears, not a text wall.
- [ ] It reaches the desktop without typing anything.
- [ ] Write down roughly how long that took.

## The nine things that actually decide this

### 1. Wi-Fi
- [ ] The network icon in the dock lists nearby networks.
- [ ] It connects to yours with the password.
- [ ] A web page loads in Brave.
- [ ] **If no networks appear at all**, the Wi-Fi chip's firmware is
      missing. Note the model — this is fixable but we need to know.

### 2. Sound
- [ ] Play something in VLC or a video in Brave.
- [ ] Sound comes from the **laptop's own speakers**.
- [ ] The volume keys on the keyboard change the volume.
- [ ] Plug in headphones: sound moves to them.
- [ ] Unplug them: sound moves back.

### 3. Touchpad
- [ ] The pointer moves.
- [ ] Tap-to-click works.
- [ ] Two-finger scrolling works in a browser.
- [ ] Two-finger right-click works.
- [ ] If there is a trackpoint or physical buttons, they work.

### 4. Screen brightness
- [ ] The brightness keys change the brightness.
- [ ] It goes genuinely dim at the bottom, not just slightly grey.
- [ ] The change survives a few seconds (it does not jump back).

### 5. Sleep and wake — **the one most likely to fail**
- [ ] Close the lid. The screen goes off.
- [ ] Wait **one full minute**.
- [ ] Open the lid.
- [ ] It comes back to the desktop, not a black screen.
- [ ] Wi-Fi reconnects on its own.
- [ ] Sound still works after waking.
- [ ] Do it **a second time** — some laptops only fail on the second sleep.

### 6. Battery
- [ ] Unplug the charger. The battery icon shows it is discharging.
- [ ] It shows a percentage and a time estimate.
- [ ] Plug it back in. It shows charging.
- [ ] Leave it unplugged for 15 minutes of normal use and note how much
      percentage it used. Old batteries drop fast; that is the battery, not
      Bashan OS.

### 7. Fan noise and heat
- [ ] Sit at the idle desktop for five minutes. The fan should settle down
      or stop.
- [ ] If the fan runs flat out the whole time at idle, note it. That is a
      real problem.
- [ ] Feel the underside. Warm is normal, too hot to touch is not.

### 8. Screen, keyboard, ports
- [ ] The whole screen is used, no black bars, nothing stretched.
- [ ] Every key types the right character, especially in your own language.
- [ ] A USB stick plugged in appears in the file manager.
- [ ] The webcam works (open the camera app).
- [ ] If there is an SD card slot or HDMI, try them.

### 9. Bluetooth
- [ ] Bluetooth turns on in the dock.
- [ ] It finds a nearby device (headphones, a phone).
- [ ] It pairs and audio plays over it, if they are headphones.

## Language, if the laptop will not be used in English

- [ ] Switch the language in System Settings.
- [ ] The desktop text changes.
- [ ] For Arabic, Hebrew, Syriac, Sorani or Persian: the whole layout
      **mirrors**, the dock reverses, and the Trash moves to the other
      bottom corner.
- [ ] Text is shaped and joined properly, not boxes or disconnected letters.

## Scoring it

**Wi-Fi, sound, touchpad, brightness and sleep/wake are the five that
matter.** If all five work, this laptop is a good candidate.

If sleep/wake fails, the laptop is still usable — shut it down instead of
closing the lid — but say so before anyone relies on it.

If Wi-Fi fails, stop. Do not install until that is sorted out.

## Only then

- [ ] Everything above recorded, with the laptop's model.
- [ ] A backup exists, on something that is not this laptop.
- [ ] Now, and only now, consider clicking Install.
