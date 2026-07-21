# Docs úteis

Notas operacionais que **não** são skills de agente, mas valem versionar: instalação,
workarounds de desktop, e “como refazer daqui a 6 meses”.

Cada doc deve ser **auto-contida**: comando, caminho, versão esperada, e o que
falha se você pular um passo.

| Doc | Quando usar |
|-----|-------------|
| [omarchy/davinci-resolve.md](./omarchy/davinci-resolve.md) | Instalar / reinstalar DaVinci Resolve no Omarchy (Arch + Hyprland), notebook híbrido Intel + NVIDIA |

## Convenções

- Preferir caminhos absolutos de usuário (`~/.local/...`) e de sistema (`/opt/...`).
- Marcar o que **não** atualiza sozinho via AUR (ex.: zip da Blackmagic).
- Separar: **instalação do pacote** · **launcher / GPU** · **troubleshooting**.
- Se um atalho de menu for crítico (ex.: Super+Space), documentar *qual* `.desktop`
  vence no XDG e como validar com `gtk-launch`.
