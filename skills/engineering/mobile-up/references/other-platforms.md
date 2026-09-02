# macOS and Windows hosts

The script needs `bash`, `ss`, `ip`, `curl` and `/proc`, so it runs on Linux. On another host, follow the
same procedure by hand, in this order, and hand back the same summary. Untested on those hosts:
the commands below are the platform equivalents, not a recorded run.

| Step | Linux (script) | macOS | Windows (PowerShell) |
|---|---|---|---|
| LAN IP | `ip -4 route get 1.1.1.1` | `ipconfig getifaddr en0` | `Get-NetIPAddress -AddressFamily IPv4` |
| Who holds a port | `ss -ltnp "sport = :N"` + `/proc/PID/cwd` | `lsof -nP -iTCP:N -sTCP:LISTEN` + `lsof -p PID -d cwd` | `netstat -ano \| findstr :N` + `Get-Process -Id PID` |
| Start detached | `nohup setsid … &` | `nohup … &` | `Start-Process -WindowStyle Hidden` |
| Wait for bind | loop on the port check | same | same |
| Server ready | `curl -s -o /dev/null -w '%{http_code}' http://localhost:N/` | same | `Invoke-WebRequest` status |
| Metro ready | `curl http://localhost:8081/status` → `packager-status:running` | same | same |
| Env sync | write `EXPO_PUBLIC_*URL=http://<ip>:<port>` in the app's `.env`, restart Metro if it was up | same | same |
| Firewall hint | ufw / firewalld | macOS firewall prompts on first bind | Windows Defender prompts on first bind |
| Emulator | `emulator -avd <name>`; `adb` with `-s` | same (SDK under `~/Library/Android/sdk`) | same (`%LOCALAPPDATA%\Android\Sdk`) |

Every `adb` command in `android.md` applies unchanged; the bash helper there that reads the state
file needs a local equivalent. iOS Simulator needs macOS and is out of
scope here; a physical iPhone with Expo Go reads the same `exp://` URL.
