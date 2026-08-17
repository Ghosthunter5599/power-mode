#!/usr/bin/env bash
set -e

echo "⚡ Installing power-mode..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_PATH="$SCRIPT_DIR/bin/power-mode"

if [ ! -f "$BIN_PATH" ]; then
    echo "Error: $BIN_PATH not found."
    exit 1
fi

chmod +x "$BIN_PATH"

# Install to /usr/local/bin or ~/.local/bin
if [ "$EUID" -eq 0 ]; then
    cp "$BIN_PATH" /usr/local/bin/power-mode
    echo "✓ Installed power-mode to /usr/local/bin/power-mode"
else
    mkdir -p "$HOME/.local/bin"
    cp "$BIN_PATH" "$HOME/.local/bin/power-mode"
    echo "✓ Installed power-mode to $HOME/.local/bin/power-mode"
fi

# Optional Omarchy plugin installation
if [ -d "$HOME/.config/omarchy" ]; then
    echo "Omarchy environment detected. Installing Quickshell bar extension..."
    mkdir -p "$HOME/.config/omarchy/plugins/local.power-mode"
    cp -r "$SCRIPT_DIR/extensions/omarchy-quickshell/"* "$HOME/.config/omarchy/plugins/local.power-mode/"
    echo "✓ Installed Omarchy plugin to ~/.config/omarchy/plugins/local.power-mode"
fi

echo "✓ Installation complete! Run 'power-mode' in your terminal or 'power-mode --help'."
