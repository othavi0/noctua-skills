# Troubleshooting: the device does not load the app

One entry per observable symptom. Confirm the check before applying the fix: several causes share
the vague "error on the phone" and the fix for one does nothing for the others. When no entry
matches, stop and ask the user for the exact text or a photo of the error instead of trying
fixes in the dark.

Start every diagnosis with `mobile-up.sh status`: it shows who owns each port, the URL in the env,
and the URL the running Metro was started with.

## The app opens, then no screen loads data ("Network request failed", spinners forever)

**Check**: the summary's `env` line and the `bundle` line of `status`. They must show the same URL,
and the URL must use the machine's LAN IP, not `localhost` (for the phone, `localhost` is itself).

**Cause**: the env is baked into the bundle when Metro starts. A Metro started before the env
changed (new Wi-Fi, server moved to another port) serves a bundle pointing at the old address.

**Fix**: restart Metro (user's call; see SKILL.md, Ownership), then rerun the target.

## Nothing connects: Expo Go times out or shows "Something went wrong"

**Check**: from the host, `curl -s -o /dev/null -w '%{http_code}' http://<lan-ip>:<metro-port>/status`
answers `200`. If the host answers on its own LAN IP and only the phone fails, the packet dies on
the way in.

**Cause**: host firewall with a default-deny inbound policy (`ufw`, `firewalld`). The server logs
nothing because nothing arrives.

**Fix**: the `app` target prints the allow commands with the current network range. They need
sudo, so the user runs them. Rules are per network: a different Wi-Fi needs them again. A phone
on USB can skip the network entirely with `adb reverse tcp:<metro-port> tcp:<metro-port>` (Expo Go
prints this suggestion itself); then the phone reaches Metro at `localhost`.

## "Project is incompatible with this version of Expo Go" / "Incompatible SDK version"

**Check**: the summary's `Expo Go <version>` against the project's `expo` major in the app's
`package.json`. The script warns when the majors differ.

**Cause**: Expo Go ships one SDK per major, and on a physical phone the Play Store often does not
offer the update for a freshly released SDK.

**Fix**: `npx expo-go download android <sdk>` (or https://expo.dev/go), then install: emulator
`adb -s <serial> install -r <apk>`; physical phone: sideload the APK (serving it from the dev
server's public directory over the LAN works; delete it afterwards). The durable exit is a
development build (EAS Build), which does not depend on Expo Go.

## Crash right after "Bundled": Expo Go returns to its home screen

**Check**: Metro log says `Android Bundled …` but `adb shell dumpsys window | grep mCurrentFocus`
shows `HomeActivity`, not `ExperienceActivity`. `adb logcat -b crash -d | tail -40` shows the
native crash (a `SIGSEGV` in Hermes is the common one). The Metro log often already printed
`An update for expo is available: X → Y`.

**Cause**: dependencies out of line with the project's SDK.

**Fix**: in the app directory `npx expo install --fix`, then restart Metro (the project's `dev`
script usually passes `--clear`; the script does when it starts Metro on an alternate port or
when the app has no `dev` script).

## "RangeError: Maximum call stack size exceeded" right after an update

**Check**: the error appears in the app right after `expo install --fix` or a dependency change,
and the Metro log shows no bundling error.

**Cause**: stale Metro cache after dependency changes.

**Fix**: restart Metro with `--clear`.

## The phone shows "Cannot connect to Expo CLI" as a console warning, but the app works

**Check**: the Metro log shows the bundle delivered and `curl http://<lan-ip>:<metro-port>/status`
answers `packager-status:running`.

**Cause**: the hot-reload channel dropped (app went to background, phone Wi-Fi slept). The bundle
was delivered; only Fast Refresh stopped.

**Fix**: none needed. Reload in Expo Go restores Fast Refresh.

## Deep link opens the launcher or does nothing

**Check**: `adb shell dumpsys window | grep mCurrentFocus` shows the launcher or `HomeActivity`
right after the `am start`, and the Metro log has no new `Bundled` line.

**Cause**: `am start` without the package, or the `force-stop` glued to the `am start`.

**Fix**: the recipe in `android.md` (package `host.exp.exponent`, `sleep 3` between the two).

## The phone on the LAN cannot reach an IP the summary shows, and the firewall is off

**Check**: the summary warned `default route goes through <vpn-interface>`; `ip -4 route get 1.1.1.1`
names the interface.

**Cause**: the default route is a VPN tunnel; its address is not on the Wi-Fi.

**Fix**: `MOBILE_UP_IP=<lan-ip> bash mobile-up.sh <target>`. The LAN IP is on
`ip -4 -o addr show` for the Wi-Fi interface.

## API answers 401/403 or old shapes after a change in a workspace package

**Check**: the summary warned `server started before the current HEAD commit`.

**Cause**: hot reload picked the app code but the server process still holds the old auth or API
package in memory.

**Fix**: restart the server (user's call), then rerun.
