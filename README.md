# monitor-layout

Dynamic monitor management for **Hyprland + Omarchy** on CachyOS.

Solves a core conflict with the [`split-monitor-workspaces`](https://github.com/Duckonaut/split-monitor-workspaces) plugin: the plugin blocks `moveworkspacetomonitor` after reload, making runtime workspace reassignment impossible. This tool rewrites `monitors.lua` _before_ the reload, so `monitor_priority` is set correctly from the start.

## Features

- Switch between **Extend**, **Mirror**, **Primary only**, **Secondary only** — via a `Super+P` menu
- **Auto workspace distribution** across any number of monitors (remainder goes to the first):
  - 2 monitors, 10 WS → `1–5` | `6–10`
  - 3 monitors, 10 WS → `1–4` | `5–7` | `8–10`
- **Custom distribution** per monitor via a simple config (`Super+Alt+P`)
- Supports **2+ monitors** — not just dual
- **Horizontal or vertical** extend arrangement
- Queries actual monitor resolution to compute positions (no hardcoded 1920)
- Restarts Waybar automatically on layout change
- XDG-compliant config at `~/.config/monitor-layout/config`

## Requirements

- Hyprland with [split-monitor-workspaces](https://github.com/Duckonaut/split-monitor-workspaces) plugin
- [Omarchy](https://github.com/basecamp/omarchy) (or any Lua-based Hyprland setup)
- `hyprctl`, `jq`
- `walker` (default menu) — or any dmenu-compatible launcher via `MENU_CMD`

## Installation

```bash
git clone https://github.com/bryanmarin/monitor-layout
cd monitor-layout
bash install.sh
hyprctl reload
```

The installer:
1. Copies `monitor-layout` and `monitor-layout-config` to `~/.local/bin/`
2. Creates `~/.config/monitor-layout/config` with defaults (never overwrites existing)
3. Adds `Super+Alt+P` → `monitor-layout-config` to `~/.config/hypr/bindings.lua`
4. Updates the existing `Super+P` bind if it points to the old `monitor-layout.sh`

## Keybinds

| Keybind | Action |
|---|---|
| `Super+P` | Interactive layout menu |
| `Super+Alt+P` | Workspace distribution configurator |

## Layouts

| Command | Description |
|---|---|
| `extend` | All monitors active, side by side (or stacked) |
| `mirror` | Secondary mirrors primary |
| `primary` | Only primary monitor active |
| `secondary` | Only secondary monitor active |

Run directly from the terminal:

```bash
monitor-layout extend
monitor-layout primary
```

## Configuration

Config lives at `~/.config/monitor-layout/config`. Edit it directly or run `monitor-layout-config`.

```bash
# Total workspaces distributed across active monitors
TOTAL_WORKSPACES=10

# Distribution — leave empty for auto, or set custom ranges:
#   "1-4 5-7 8-10"   (range format)
#   "4 3 3"           (count format)
WORKSPACE_DISTRIBUTION=""

# Monitor priority — leave empty for auto-detect
PRIMARY_MONITOR=""
SECONDARY_MONITOR=""
TERTIARY_MONITOR=""

# Extend layout direction: horizontal (default) or vertical
EXTEND_DIRECTION=horizontal

# Menu launcher
MENU_CMD="walker --dmenu --placeholder 'Monitor layout:'"
```

### Finding monitor names

```bash
hyprctl monitors all -j | jq -r '.[].name'
```

### Per-session environment overrides

```bash
PRIMARY=DP-2 SECONDARY=HDMI-A-2 monitor-layout extend
MENU_CMD="rofi -dmenu" monitor-layout
```

## Custom workspace distribution

The interactive configurator (`Super+Alt+P`) guides you through:

1. **Total workspaces** — change from 10 to any number
2. **Distribution** — auto, guided (per-monitor), or open in `$EDITOR`
3. **Extend direction** — horizontal or vertical
4. **Monitor priority** — reorder which monitor is "primary"

For non-uniform distributions (e.g. 4 + 3 + 3), the script generates Hyprland workspace rules alongside the plugin config. Behavior depends on your plugin version — uniform distribution always works perfectly.

## Uninstall

```bash
rm ~/.local/bin/monitor-layout ~/.local/bin/monitor-layout-config
rm -rf ~/.config/monitor-layout
rm -rf ~/.local/share/monitor-layout
```

Remove the `# monitor-layout` block from `~/.config/hypr/bindings.lua`.

## License

MIT
