# Kanagawa Dragon

A dark-mode theme for [Omarchy](https://github.com/basecamp/omarchy), based on the [Kanagawa Dragon](https://github.com/rebelot/kanagawa.nvim) palette (slightly modified).

Light-mode counterpart: [omarchy-kanagawa-lotus-theme](https://github.com/bjarneo/omarchy-kanagawa-lotus-theme).

![Preview](preview.png)
![Preview](preview2.png)

https://github.com/user-attachments/assets/5c1d4f2b-e2e7-40fe-b25a-00e0e66a17a3

## Installation

```sh
omarchy-theme-install https://github.com/bjarneo/omarchy-kanagawa-dragon-theme
```

## Quickshell

Two optional Quickshell components ship under `quickshell/`:

| File | What it is |
| --- | --- |
| `quickshell/navbar.qml` | Top bar that replaces Waybar |
| `quickshell/quickapps.qml` | Radial app selector |
| `quickshell/quickapps.example.json` | Example app list |

Requirements: `quickshell`, `hyprctl`, `pamixer`, `bluetoothctl`, `nmcli`, a Nerd Font (the configs use `JetBrainsMono Nerd Font`).

### Navbar

A thin Kanagawa Dragon panel: kanji workspace numerals, autumn-red seal accents, and a centered serif clock on smoked sumi.

```sh
omarchy toggle waybar
quickshell -p ~/.config/omarchy/current/theme/quickshell/navbar.qml
```

The first command disables Waybar (the navbar owns the top layer-shell zone, so the two cannot run together). The second launches the panel. To autostart it, add the `quickshell` command to your Hyprland `exec-once` block.

Left-click triggers the primary action on each module; right-click on the Omarchy mark opens a terminal, and right-click on the audio module toggles mute.

### Quick apps selector

A radial app launcher. Apps sit on a faint slate ring on sumi paper; the selected one is filled with bone-white ink and marked with an autumn seal dot. Icons are tinted to follow the palette via a `MultiEffect` colorize pass, so a multi-color icon set still reads as one cohesive design.

Adapted from the `zen` shell in [omarchy-quickapps](https://github.com/bjarneo/omarchy-quickapps), with adjustments specific to this theme (icon colorization, soft circle backgrounds).

Configure your apps:

```sh
mkdir -p ~/.config/omarchy-quickapps
cp ~/.config/omarchy/current/theme/quickshell/quickapps.example.json ~/.config/omarchy-quickapps/apps.json
```

Edit `apps.json` to list the apps you want. Each entry takes `name`, `icon` (any icon name resolvable through your icon theme), and `exec`.

Run it:

```sh
quickshell -p ~/.config/omarchy/current/theme/quickshell/quickapps.qml
```

Bind it to a key in `~/.config/hypr/bindings.conf`, for example:

```
bind = SUPER, space, exec, quickshell -p ~/.config/omarchy/current/theme/quickshell/quickapps.qml
```

Keys: arrows / hjkl / Tab to navigate, 1-9 to jump and launch, Enter to open, Esc or right-click to dismiss.
