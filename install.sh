#!/usr/bin/env bash
# install.sh — Install monitor-layout for Hyprland + Omarchy
# https://github.com/bryanmarin/monitor-layout

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
ML_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/monitor-layout"
SHARE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/monitor-layout"
HYPR_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"

BIND_MARKER="# monitor-layout"

c_green='\e[32m'; c_yellow='\e[33m'; c_red='\e[31m'; c_blue='\e[34m'; c_bold='\e[1m'; c_reset='\e[0m'
ok()   { printf "${c_green}  ✓${c_reset} %s\n" "$*"; }
info() { printf "${c_blue}  →${c_reset} %s\n" "$*"; }
warn() { printf "${c_yellow}  !${c_reset} %s\n" "$*"; }
die()  { printf "${c_red}error:${c_reset} %s\n" "$*" >&2; exit 1; }
header() { printf "\n${c_bold}%s${c_reset}\n" "$*"; }

# ── Preflight ──────────────────────────────────────────────────────────────────
header "monitor-layout installer"

info "Checking dependencies..."
for cmd in hyprctl jq; do
    command -v "$cmd" &>/dev/null || die "Missing required dependency: $cmd"
done
ok "hyprctl and jq found"

# ── Scripts ────────────────────────────────────────────────────────────────────
header "Installing scripts"

mkdir -p "$BIN_DIR"
install -m 755 "$SCRIPT_DIR/monitor-layout"        "$BIN_DIR/monitor-layout"
install -m 755 "$SCRIPT_DIR/monitor-layout-config" "$BIN_DIR/monitor-layout-config"
ok "monitor-layout        → $BIN_DIR/monitor-layout"
ok "monitor-layout-config → $BIN_DIR/monitor-layout-config"

# ── Default config (shared, for reset) ────────────────────────────────────────
header "Installing default config"

mkdir -p "$SHARE_DIR"
install -m 644 "$SCRIPT_DIR/monitor-layout.conf" "$SHARE_DIR/config"
ok "Default config → $SHARE_DIR/config"

# ── User config (not overwritten if it exists) ─────────────────────────────────
if [[ -f "$ML_CONFIG_DIR/config" ]]; then
    warn "Existing config found — skipping to preserve your settings"
    warn "  $ML_CONFIG_DIR/config"
else
    mkdir -p "$ML_CONFIG_DIR"
    cp "$SHARE_DIR/config" "$ML_CONFIG_DIR/config"
    ok "User config created → $ML_CONFIG_DIR/config"
fi

# ── Hyprland keybinds ──────────────────────────────────────────────────────────
header "Configuring Hyprland keybinds"

BINDINGS_FILE="$HYPR_CONFIG_DIR/bindings.lua"

if [[ ! -f "$BINDINGS_FILE" ]]; then
    warn "bindings.lua not found at $BINDINGS_FILE"
    warn "Add these lines manually to your Hyprland bindings file:"
    printf '\n'
    printf '  hl.unbind("SUPER + P")\n'
    printf '  o.bind("SUPER + P",       "Monitor layouts",    "monitor-layout")\n'
    printf '  o.bind("SUPER + ALT + P", "Monitor WS config",  "monitor-layout-config")\n\n'
else
    if grep -q "$BIND_MARKER" "$BINDINGS_FILE" 2>/dev/null; then
        warn "Keybinds already present in $BINDINGS_FILE — skipping"
    else
        # Update existing SUPER+P bind if it points to the old script
        if grep -q "monitor-layout.sh" "$BINDINGS_FILE" 2>/dev/null; then
            sed -i 's|monitor-layout\.sh|monitor-layout|g' "$BINDINGS_FILE"
            ok "Updated existing SUPER+P bind to use new script name"
        fi

        # Add Super+Alt+P for config UI
        cat >> "$BINDINGS_FILE" << 'EOF'

# monitor-layout
o.bind("SUPER + ALT + P", "Monitor WS config", "monitor-layout-config")
EOF
        ok "Added Super+Alt+P → monitor-layout-config to $BINDINGS_FILE"
    fi
fi

# ── PATH check ────────────────────────────────────────────────────────────────
if ! printf '%s\n' "${PATH//:/$'\n'}" | grep -qx "$BIN_DIR"; then
    warn "$BIN_DIR is not in your PATH"
    warn "Add to ~/.config/fish/config.fish or ~/.bashrc:"
    printf '      fish: fish_add_path %s\n' "$BIN_DIR"
    printf '      bash: export PATH="%s:$PATH"\n\n' "$BIN_DIR"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
header "Done!"
printf "  ${c_bold}Super+P${c_reset}         → layout menu (extend / mirror / primary / secondary)\n"
printf "  ${c_bold}Super+Alt+P${c_reset}     → workspace distribution config\n\n"
printf "Config file:  %s\n" "$ML_CONFIG_DIR/config"
printf "Edit config:  monitor-layout-config\n"
printf "Apply now:    hyprctl reload\n\n"
