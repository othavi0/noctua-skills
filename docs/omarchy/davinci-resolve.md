# DaVinci Resolve no Omarchy (Arch + Hyprland)

Guia reutilizável para instalar e manter **DaVinci Resolve free** em Omarchy,
especialmente em **notebook híbrido Intel iGPU + NVIDIA dGPU**.

Validado em: **Resolve 21.0.2** · Omarchy (Arch) · Hyprland/Wayland ·
**Intel Iris Xe + RTX 3050 Mobile** · `nvidia-open-dkms` · `yay`.

Não é skill de agente — é runbook. Atualize este arquivo se o maintainer do AUR
mudar o fluxo ou se a Blackmagic mudar o nome do zip.

---

## Resumo em 30 segundos

1. O AUR **não baixa** o instalador (só `file://` local).
2. Você baixa o zip na Blackmagic e coloca no cache do `yay`.
3. `makepkg`/`yay` empacota e `pacman -U` instala em `/opt/resolve`.
4. Em hybrid + Wayland, **abrir `/opt/resolve/bin/resolve` direto quebra GPU**.
5. Use sempre o wrapper `~/.local/bin/davinci-resolve` (menu Super+Space já pode
   apontar pra ele via `.desktop` em `~/.local`).

---

## Por que o AUR “falha” no download

```text
curl: (3) URL rejected: Bad file:// URL
ERROR: Failure while downloading file://DaVinci_Resolve_21.0.2_Linux.zip
```

O PKGBUILD declara:

```bash
source=("file://DaVinci_Resolve_${pkgver}_Linux.zip" ...)
```

`file://` = arquivo **local**, não URL HTTP. Desde **19.1.3-2** o maintainer
removeu o download automático: a Blackmagic exige formulário/login e não permite
redistribuir o zip.

Isso vale para:

| Pacote AUR | Zip esperado |
|------------|----------------|
| `davinci-resolve` (free) | `DaVinci_Resolve_<ver>_Linux.zip` |
| `davinci-resolve-studio` | `DaVinci_Resolve_Studio_<ver>_Linux.zip` |

**Não instale free e studio juntos** — há `conflicts` mútuo no PKGBUILD.

### O que o AUR atualiza e o que não

| Peça | Atualiza com `yay -Syu`? |
|------|---------------------------|
| PKGBUILD, scripts, `patchelf`, deps pacman | Sim |
| Binário/app da Blackmagic (zip multi-GB) | **Não** — baixar de novo na mão a cada `pkgver` |

---

## Instalação (free)

### 0. Pré-requisitos de GPU (NVIDIA)

```bash
# OpenCL da NVIDIA (preenche opencl-driver do PKGBUILD com a dGPU)
sudo pacman -S --needed opencl-nvidia

# Opcional, mas recomendado (Preferências → CUDA)
sudo pacman -S --needed cuda
```

Em hybrid Dell/etc. com `nvidia-open-dkms` + `nvidia-utils`, `opencl-nvidia` é o
mínimo para o stack NVIDIA aparecer no Resolve.

### 1. Baixar o zip na Blackmagic

1. https://www.blackmagicdesign.com/support/family/davinci-resolve-and-fusion  
2. **DaVinci Resolve** (não Studio), versão = `pkgver` do AUR, **Linux**.  
3. Nome típico: `DaVinci_Resolve_21.0.2_Linux.zip` (ajuste a versão).

Conferir o `pkgver` atual:

```bash
# se o cache do yay já existir
grep '^pkgver=' ~/.cache/yay/davinci-resolve/PKGBUILD

# ou
yay -Si davinci-resolve | head -20
```

### 2. Colocar o zip no cache do yay

```bash
# 1ª vez: deixa o yay clonar o PKGBUILD (vai falhar no file:// — ok)
yay -S davinci-resolve --answerclean None --answerdiff None || true

cp ~/Downloads/DaVinci_Resolve_21.0.2_Linux.zip \
   ~/.cache/yay/davinci-resolve/
```

(Ajuste nome/versão e o path de download.)

### 3. Validar o checksum do PKGBUILD

```bash
# hash esperado (muda a cada versão — leia o PKGBUILD)
grep -A2 '^sha256sums=' ~/.cache/yay/davinci-resolve/PKGBUILD

sha256sum ~/.cache/yay/davinci-resolve/DaVinci_Resolve_21.0.2_Linux.zip
```

Tem que bater com o **primeiro** `sha256sums` do PKGBUILD (o do zip).

### 4. Build + install

```bash
yay -S davinci-resolve --noconfirm --answerclean None --answerdiff None
```

Ou, se o pacote já foi buildado e só faltou `sudo`:

```bash
sudo pacman -U ~/.cache/yay/davinci-resolve/davinci-resolve-*-x86_64.pkg.tar.zst
```

Binário: `/opt/resolve/bin/resolve`.

### 5. (Opcional) Archive packages do Reddit

Alguns posts de 2026 pinam `qt5-webengine` / `gtk2` / `libpng12` do
[Arch Linux Archive](https://archive.archlinux.org/) para evitar horas de compile.

**No PKGBUILD 21.0.2 testado, esses pacotes não eram depends.** Só use se o build
ou o runtime pedir explicitamente — é partial upgrade e pode doer no próximo
`pacman -Syu`.

---

## Launcher obrigatório (hybrid Intel + NVIDIA)

### O erro

Diálogo:

> **Unable to Initialize GPU**  
> Please ensure that the system power profile is set to use the discrete GPU…

Log típico (`~/.local/share/DaVinciResolve/logs/ResolveDebug.txt`):

```text
Main Display GPU = Intel Iris Xe
Automatic GPU Selection = NVIDIA RTX …
OpenGL em um lado, OpenCL/player no outro
Failed to initialize OpenGL interop … integrated GPU when there are other GPUs
CRITICAL_PREF: Unable to Initialize GPU
```

Causa: tela no **iGPU**, compute na **dGPU**, interop GL↔CL/CUDA exige a mesma GPU.

### A correção (3 frentes)

1. **PRIME offload** — OpenGL na NVIDIA (`__NV_PRIME_RENDER_OFFLOAD=1`, etc.).  
2. **OpenCL só NVIDIA** — esconder o ICD da Intel **só para o processo do Resolve**
   via `OCL_ICD_VENDORS` apontando a um dir com só `nvidia.icd`.  
3. **Qt em XWayland** — `QT_QPA_PLATFORM=xcb` (Resolve não tem plugin Wayland).

### Script: `~/.local/bin/davinci-resolve`

```bash
#!/usr/bin/env bash
# DaVinci Resolve — hybrid Intel+NVIDIA no Omarchy/Hyprland
set -euo pipefail

RESOLVE_BIN="${RESOLVE_BIN:-/opt/resolve/bin/resolve}"
OCL_DIR="${HOME}/.local/share/DaVinciResolve/opencl-nvidia-only"

[[ -x "$RESOLVE_BIN" ]] || { echo "missing $RESOLVE_BIN" >&2; exit 1; }

mkdir -p "$OCL_DIR"
if [[ ! -f "$OCL_DIR/nvidia.icd" ]]; then
  if [[ -f /etc/OpenCL/vendors/nvidia.icd ]]; then
    cp /etc/OpenCL/vendors/nvidia.icd "$OCL_DIR/"
  else
    echo "libnvidia-opencl.so.1" >"$OCL_DIR/nvidia.icd"
  fi
fi

# Single-instance: se o binário não está vivo, limpa lock zumbi
resolve_alive=0
for pid_dir in /proc/[0-9]*; do
  exe=$(readlink "$pid_dir/exe" 2>/dev/null) || continue
  if [[ "$exe" == "$RESOLVE_BIN" ]]; then
    resolve_alive=1
    break
  fi
done
if [[ "$resolve_alive" -eq 0 ]]; then
  rm -f /tmp/qtsingleapp-DaVinc* 2>/dev/null || true
fi

export OCL_ICD_VENDORS="$OCL_DIR"
export QT_QPA_PLATFORM=xcb
export QT_AUTO_SCREEN_SCALE_FACTOR="${QT_AUTO_SCREEN_SCALE_FACTOR:-0}"
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
[[ -f /usr/share/vulkan/icd.d/nvidia_icd.json ]] && \
  export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json

cd /opt/resolve
exec "$RESOLVE_BIN" "$@"
```

```bash
chmod +x ~/.local/bin/davinci-resolve
# ICD dir (se o script ainda não criou)
mkdir -p ~/.local/share/DaVinciResolve/opencl-nvidia-only
cp /etc/OpenCL/vendors/nvidia.icd ~/.local/share/DaVinciResolve/opencl-nvidia-only/
```

### Desktop entry (Super+Space / menu)

O Omarchy launcher usa `gtk-launch <DesktopId>`. O XDG **prioriza**
`~/.local/share/applications/` sobre `/usr/share/applications/`.

Arquivo: `~/.local/share/applications/DaVinciResolve.desktop`

```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=DaVinci Resolve
GenericName=DaVinci Resolve
Comment=DaVinci Resolve (NVIDIA hybrid launcher for Omarchy/Hyprland)
Path=/opt/resolve/
TryExec=/home/SEU_USER/.local/bin/davinci-resolve
Exec=/home/SEU_USER/.local/bin/davinci-resolve %u
Terminal=false
MimeType=application/x-resolveproj;
Icon=davinci-resolve
StartupNotify=true
StartupWMClass=resolve
Categories=AudioVideo;Video;AudioVideoEditing;
```

Substitua `SEU_USER`. Depois:

```bash
update-desktop-database ~/.local/share/applications
```

Validar o que o Super+Space vai usar:

```bash
# o primeiro path que existir vence
ls -l ~/.local/share/applications/DaVinciResolve.desktop
rg '^(Name|Exec|TryExec)=' ~/.local/share/applications/DaVinciResolve.desktop
# deve ser ~/.local/bin/davinci-resolve — NÃO /opt/resolve/bin/resolve
```

O pacote AUR reinstala `/usr/share/applications/DaVinciResolve.desktop` em updates;
o override em `~/.local` **permanece**.

### Nunca faça (no hybrid)

```bash
/opt/resolve/bin/resolve          # sem PRIME + OpenCL Intel → GPU dialog
```

Sempre:

```bash
~/.local/bin/davinci-resolve
# ou Super+Space → "DaVinci Resolve"
```

---

## Como saber que a GPU ficou certa

Após abrir:

```bash
rg -n 'Unable to Initialize|Initialized OpenGL|OpenCL device|CUDA device|Automatic GPU|Selected compute|Main Display GPU|Ready' \
  ~/.local/share/DaVinciResolve/logs/ResolveDebug.txt | tail -40
```

**Bom (setup validado):**

```text
Main Display GPU … NVIDIA GeForce RTX …
Selected compute API: CUDA
Initialized OpenGL … NVIDIA … RTX …
MainPlayer … on CUDA device 'NVIDIA GeForce RTX …'
Ready
Launching main loop
```

**Ruim:**

```text
Main Display GPU … Intel Iris …
OpenCL device 'Intel(R) Iris …'
Unable to Initialize GPU
```

Dentro do app: **Preferences → Memory and GPU** → RTX marcada, modo **CUDA**.

---

## Troubleshooting

### “Abrindo…” e não aparece janela

Causa comum: **single-instance** + lockfile em `/tmp` de uma sessão morta/com diálogo
de GPU. O segundo clique fala com a instância zumbi e some.

```bash
# matar só o binário real (via /proc/exe — não use pkill -f no path no script agent)
for p in /proc/[0-9]*; do
  [ "$(readlink "$p/exe" 2>/dev/null)" = /opt/resolve/bin/resolve ] && kill -9 "${p#/proc/}"
done
rm -f /tmp/qtsingleapp-DaVinc*
~/.local/bin/davinci-resolve
```

O wrapper acima já limpa o lock se o processo não estiver vivo.

### Janela existe mas “sumiu”

No Hyprland multi-monitor, o Resolve pode abrir em **outro workspace/monitor**
(ex.: workspace 5 no HDMI).

```bash
hyprctl clients -j | python3 -c '
import json,sys
for c in json.load(sys.stdin):
  if c.get("class")=="resolve":
    print(c["title"], "ws", c["workspace"], "mon", c["monitor"], c["at"], c["size"])
'
```

Vá ao workspace indicado (ex. Super+5) ou foque a janela.

### Ruído no terminal (pode ignorar)

| Mensagem | Significado |
|----------|-------------|
| `ActCCMessage Already in Table` | Interno BMD |
| `log4cxx: No appender` / `./logs/rollinglog.txt` | Logger relativo; logs reais em `~/.local/share/DaVinciResolve/logs/` |
| `Failed to open /dev/hidraw*` / panel socket | Sem mesa/teclado DaVinci |
| `Could not find Qt platform plugin "wayland"` | Esperado — use `xcb` |
| `kvantum` style override ignored | Tema Qt do sistema; Resolve usa Fusion |
| DDM `/opt/resolve/Extras` Permission denied | Extras download; inofensivo no dia a dia |
| `libDeckLinkAPI.so` missing | Sem placa DeckLink |

### Free no Linux: H.264/H.265

A free **não decodifica** H.264/H.265. MP4 da câmera → “Media Offline” é limitação
de licença, não bug de install.

Transcodificar (exemplo DNxHR):

```bash
ffmpeg -i input.mp4 -c:v dnxhd -profile:v dnxhr_hq -pix_fmt yuv422p \
  -c:a pcm_s16le output.mov
```

### UI pequena / blur (HiDPI)

No `Exec` ou no wrapper:

```bash
export QT_SCALE_FACTOR=1.5   # ajuste: 1.25, 1.5, 1.75
```

Hyprland XWayland blur com scale fracionário: `force_zero_scaling` (ver wiki Hyprland).
Em escala 1.0 nativa costuma não precisar.

### Preferências de GPU travadas no diálogo

Se o diálogo fatal voltar: **Update Configuration** → desmarque Intel, force **CUDA**,
salve; depois sempre o wrapper.

---

## Checklist de reinstalação (máquina nova / reformat)

- [ ] Driver NVIDIA ok (`nvidia-smi`)
- [ ] `opencl-nvidia` (+ `cuda` opcional)
- [ ] `yay`/AUR deps (`base-devel`, etc.)
- [ ] Zip Blackmagic = `pkgver` do AUR; `sha256sum` confere
- [ ] Zip em `~/.cache/yay/davinci-resolve/`
- [ ] `yay -S davinci-resolve` ou `pacman -U` do `.pkg.tar.zst`
- [ ] Script `~/.local/bin/davinci-resolve` + ICD dir NVIDIA-only
- [ ] `~/.local/share/applications/DaVinciResolve.desktop` com `Exec` no wrapper
- [ ] `update-desktop-database ~/.local/share/applications`
- [ ] Abrir via Super+Space ou wrapper; log sem `Unable to Initialize GPU`
- [ ] Preferências → CUDA + RTX

---

## Atualizar o Resolve (nova versão Blackmagic)

1. Esperar o AUR publicar o novo `pkgver` / `sha256sums`.  
2. Baixar o zip novo no site (nome e hash novos).  
3. Colocar em `~/.cache/yay/davinci-resolve/`.  
4. `yay -S davinci-resolve`.  
5. **Não apagar** o wrapper nem o `.desktop` local — eles sobrevivem ao update do pacote.

---

## Referências

- [AUR davinci-resolve](https://aur.archlinux.org/packages/davinci-resolve) — aviso do maintainer sobre download manual  
- [ArchWiki: DaVinci Resolve](https://wiki.archlinux.org/title/DaVinci_Resolve) — codecs free, Wayland `xcb`, hybrid PRIME, lockfiles  
- [Blackmagic support downloads](https://www.blackmagicdesign.com/support/family/davinci-resolve-and-fusion)  
- Thread r/archlinux “How I installed DaVinci Resolve on Arch Linux in 2026” — zip manual + (opcional) packages do Archive  
- Omarchy launcher: `gtk-launch <id>` em `shell/plugins/launcher/Launcher.qml`

---

## Histórico (sessão de referência)

| Data | Notas |
|------|--------|
| 2026-07-21 | Install 21.0.2 free no Omarchy; `file://` + hybrid GPU; wrapper OCL_ICD_VENDORS + PRIME + xcb; Super+Space via `.desktop` local; lockfile zumbi documentado |

Quando reaplicar em outra máquina, copie este runbook e ajuste só `pkgver`, hash do zip e o path `SEU_USER` no `.desktop`.
