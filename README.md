# monitor-layout

Dynamic monitor management for **Hyprland + Omarchy** on CachyOS.

Solves a core conflict with the [`split-monitor-workspaces`](https://github.com/Duckonaut/split-monitor-workspaces) plugin: the plugin blocks `moveworkspacetomonitor` after reload, making runtime workspace reassignment impossible. This tool rewrites `monitors.lua` *before* the reload, so `monitor_priority` is set correctly from the start.

## Features

- Switch between **Extend**, **Mirror**, **Primary only**, **Secondary only** — via a `Super+P` menu
- **Auto workspace distribution** across any number of monitors (remainder goes to the first):
  - 2 monitors, 10 WS → `1–5` | `6–10`
  - 3 monitors, 10 WS → `1–4` | `5–7` | `8–10`
- **Custom distribution** per monitor via a simple config (`Super+Alt+P`)
- Supports **2+ monitors** — not just dual
- **Horizontal or vertical** extend arrangement
- Queries actual monitor resolution to compute positions (no hardcoded 1920)
- Restarts the desktop shell automatically on layout change (Waybar by default; see [Quickshell compatibility](https://claude.ai/chat/a1de214e-dce5-44ee-a3f8-36f524736435#quickshell-compatibility))
- XDG-compliant config at `~/.config/monitor-layout/config`

## Requirements

- Hyprland with [split-monitor-workspaces](https://github.com/Duckonaut/split-monitor-workspaces) plugin
- [Omarchy](https://github.com/basecamp/omarchy) (or any Lua-based Hyprland setup)
- `hyprctl`, `jq`
- `walker` (default menu) — or any dmenu-compatible launcher via `MENU_CMD`

## Installation

```bash
git clone https://github.com/KendallMM/monitor-layout
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

| Keybind       | Action                              |
| ------------- | ----------------------------------- |
| `Super+P`     | Interactive layout menu             |
| `Super+Alt+P` | Workspace distribution configurator |

## Layouts

| Command     | Description                                    |
| ----------- | ---------------------------------------------- |
| `extend`    | All monitors active, side by side (or stacked) |
| `mirror`    | Secondary mirrors primary                      |
| `primary`   | Only primary monitor active                    |
| `secondary` | Only secondary monitor active                  |

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

# Monitor priority — controls workspace numbering order (primary gets lowest numbers)
# Leave empty for auto-detect
PRIMARY_MONITOR=""
SECONDARY_MONITOR=""
TERTIARY_MONITOR=""

# Extend layout direction: horizontal (default) or vertical
EXTEND_DIRECTION=horizontal

# Physical position order for extend mode (left→right or top→bottom)
# Set automatically by the "monitors" configurator, or manually:
#   EXTEND_ORDER="HDMI-A-2 DP-2"   (HDMI on top/left, DP on bottom/right)
# Leave empty to use the monitor priority order above
EXTEND_ORDER=""

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
3. **Direction** — horizontal or vertical extend arrangement
4. **Monitors** — set workspace priority and physical position in one flow:
   - Step 1: pick the **primary** monitor (receives the lowest workspace numbers)
   - Step 2+: for each remaining monitor, select its physical position relative to the previous one (`above` / `below` / `left` / `right`) — this sets both the extend direction and the physical mouse-crossing order

After each change the configurator asks **"Apply now?"** so the layout reloads immediately without needing to use `Super+P`.

For non-uniform distributions (e.g. 4 + 3 + 3), the script generates Hyprland workspace rules alongside the plugin config. Behavior depends on your plugin version — uniform distribution always works perfectly.

## Quickshell compatibility

If you use [Quickshell](https://quickshell.outfoxxed.me/) instead of Waybar as your desktop shell, two changes are needed to make `monitor-layout` work correctly with it.

**1. Update the shell restart function in `monitor-layout`**

In `~/.local/bin/monitor-layout`, replace the `restart_waybar` function:

```bash
restart_waybar() {
    pkill waybar 2>/dev/null || true
    sleep 0.3
    waybar &>/dev/null & disown
}
```

With:

```bash
restart_shell() {
    pkill qs 2>/dev/null || true
    sleep 0.3
    qs -n -d -c desktop &>/dev/null & disown
}
```

And replace all 4 calls to `restart_waybar` in the file with `restart_shell`.

> Adjust `qs -n -d -c desktop` to match your Quickshell config name if different.

**2. Fix the Quickshell bar to follow the primary monitor**

By default Quickshell may place the bar on the wrong monitor after a layout change. To fix it, open your Quickshell config's `Bar.qml` and:

Add `import Quickshell.Hyprland` to the imports block, then set the `screen` property on the `PanelWindow`:

```qml
screen: Quickshell.screens.find(s => s.name === Hyprland.monitors[0]?.name) ?? Quickshell.screens[0]
```

This makes the bar dynamically follow whichever monitor Hyprland reports as primary — no hardcoded monitor names needed.

> Tested with [bjarneo/quickshell](https://github.com/bjarneo/quickshell) `desktop` config on CachyOS + Omarchy 4.0 alpha with Hyprland 0.55.

## Uninstall

```bash
rm ~/.local/bin/monitor-layout ~/.local/bin/monitor-layout-config
rm -rf ~/.config/monitor-layout
rm -rf ~/.local/share/monitor-layout
```

Remove the `# monitor-layout` block from `~/.config/hypr/bindings.lua`.

## Special thanks

- [@Duckonaut](https://github.com/Duckonaut): Original creator of the [split-monitor-workspaces](https://github.com/Duckonaut/split-monitor-workspaces) plugin
- [@zjeffer](https://github.com/zjeffer): Current maintainer of [split-monitor-workspaces](https://github.com/zjeffer/split-monitor-workspaces)

## License

MIT
