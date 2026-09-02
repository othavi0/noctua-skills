# Driving the app on the Android emulator

Everything here goes through `adb`. The summary and the state file give the path and the serial;
`adb` is rarely on PATH. Two habits on every call: `-s <serial>` (a phone next to the emulator
makes a bare `adb` answer "more than one device") and `timeout 20` (a stuck `adb` hangs the shell
for minutes).

```bash
ADB="$(grep ^ADB= ~/.cache/mobile-up/<slug>.state | cut -d= -f2-)"
SERIAL="$(grep ^SERIAL= ~/.cache/mobile-up/<slug>.state | cut -d= -f2-)"
adb_() { timeout 20 "$ADB" -s "$SERIAL" "$@"; }
```

## Proof is a capture you have read

```bash
adb_ exec-out screencap -p > shots/<step>.png   # then Read the file
```

Read every capture you take; an unread capture is not evidence. Capture only after the app has
settled: the `Bundled` line in the Metro log, then the splash and the "bundling" screen gone.
`sleep` guesses; the log line does not.

Before claiming a layout fits N dp, read the density: `adb_ shell wm density` (a 1080 px wide AVD
at 420 dpi is 411 dp, not 360). A measure by capture without the density is a guess.

## Fresh bundle: the only way to trust what you see

Fast Refresh is not proof: a change in a shared component may not apply, and internal state of a
library (a sheet's status ref, a query cache) survives the refresh and hides both the bug and the
fix. The `emulator` target does this for the root route; for a specific route:

```bash
adb_ shell am force-stop host.exp.exponent
sleep 3                                    # glued to the next line, the start is swallowed
adb_ shell am start -a android.intent.action.VIEW -d "exp://<ip>:<metro-port>/--/<route>" host.exp.exponent
# wait for "Android Bundled" in the Metro log, then capture
```

The package name is load-bearing: without `host.exp.exponent` the intent opens the launcher. With
the app already open, a deep link navigates but does not remount: state, scroll and selection
persist. Changing `font_scale` or reloading from the dev menu restarts on the initial route.

## Taps: capture, read, then tap

```bash
adb_ shell input tap X Y
```

Coordinates belong to the screen you last read. Any event that remounts (reload, deep link,
`font_scale`, keyboard) invalidates them; a blind sequence after one of those landed on a "clock
in" button in a real session and wrote a real row. When the focused screen is in doubt:

```bash
adb_ shell dumpsys window | grep -m1 mCurrentFocus   # ExperienceActivity = the app; HomeActivity = Expo Go home
```

Expo Go's floating dev button floats over the app near the top-right (measured once on a
1080×2400 AVD around x 760–860, y 520–620; it moves with the layout): a tap on it opens the dev
menu and reloads the app. Read the capture before tapping near it.

## Holding a button

`input swipe` crosses the drag threshold and cancels the pressed state. A real hold:

```bash
adb_ shell input motionevent DOWN X Y     # capture here to see the pressed state
adb_ shell input motionevent MOVE X 2000  # move off the target …
adb_ shell input motionevent UP X 2000    # … and release without firing onPress
```

## Typing

`input text` turns spaces into `%s` and sometimes drops characters. Type short strings, then read
the field back in a capture. If a text field opens no keyboard and shows a stylus tutorial (Gboard
handwriting mode on some AVDs):

```bash
adb_ shell settings put secure stylus_handwriting_enabled 0     # normal keyboard
adb_ shell settings delete secure stylus_handwriting_enabled    # revert when done
```

`keyboardType="numeric"` shows `-` and `.` on Android; `number-pad` is digits only.

## Logs

- JS console and errors: `adb_ logcat -d -s ReactNativeJS:I | tail -40`
- Native crash after a bundle: `adb_ logcat -b crash -d | tail -40`
- Which Metro the open app came from: `adb_ logcat -d -s ReactNativeJS:I | grep 'Running "main"' | tail -1`
  (the `initialUri` field). Another session's port there means the emulator is theirs right now:
  `coexistence.md`.
