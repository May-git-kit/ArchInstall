# Waybar — HyDE × end4 Pill Bar
### Niri · Arch Linux · AMD · 2026 Design

---

## 📦 Dependencies

### Required
```bash
# Core
pacman -S waybar niri

# Fonts (Nerd Font for icons)
pacman -S ttf-jetbrains-mono-nerd

# Launchers
pacman -S fuzzel          # app launcher (or rofi/nwg-drawer)

# Notification daemon
pacman -S swaync          # for notification pill

# Media control
pacman -S playerctl       # for media pill

# Bluetooth
pacman -S blueman         # blueman-manager GUI

# Brightness
pacman -S brightnessctl

# Power profiles
pacman -S power-profiles-daemon
systemctl enable --now power-profiles-daemon

# Wlogout
yay -S wlogout

# NVMe health (optional but recommended)
pacman -S smartmontools
```

### For SCX Scheduler pill
```bash
# Install sched_ext schedulers
yay -S scx-scheds         # provides scx_lavd, scx_rusty, scx_bpfland, etc.
yay -S scx-manager        # optional GUI

# Enable SCX service
systemctl enable --now scx.service

# Configure default scheduler
echo 'SCX_SCHEDULER=scx_lavd' | sudo tee /etc/scx.conf
```

### AMD GPU monitoring
```bash
# Option A: sysfs (built-in, no extra packages)
# Scripts read /sys/class/drm/card*/device/gpu_busy_percent
# and /sys/class/hwmon/hwmon*/temp1_input  — works out of box

# Option B: rocm-smi (more detailed stats)
pacman -S rocm-smi-lib
```

---

## 📁 Installation

```bash
# 1. Copy config files
mkdir -p ~/.config/waybar/scripts
cp config.jsonc   ~/.config/waybar/config
cp style.css      ~/.config/waybar/style.css
cp colors.css     ~/.config/waybar/colors.css
cp scripts/*.sh   ~/.config/waybar/scripts/

# 2. Make scripts executable
chmod +x ~/.config/waybar/scripts/*.sh

# 3. Start waybar with niri
# Add to your niri config.kdl:
```

### niri config.kdl snippet
```kdl
spawn-at-startup "waybar"
```

Or add to your niri environment:
```bash
# ~/.config/niri/autostart.sh
waybar &
```

---

## ⚙️ Auto-Hide Behavior

The bar uses CSS `margin-top: -45px` to hide itself, leaving a **3px shimmer strip** at the top of the screen as a hover target.

- **`exclusive-zone: -1`** → windows fill the full screen height (maximized) when bar is hidden
- **Hover the 3px strip** → bar slides down with a spring animation
- **Mouse leaves** → bar slides back up after 0.35s

> **Note:** waybar doesn't have a native "timeout" auto-hide.
> For timeout-based hiding, use this wrapper:

```bash
# ~/.config/waybar/scripts/autohide.sh
#!/usr/bin/env bash
# Hide waybar after 3s of no interaction — requires xdotool
HIDE_DELAY=3
while true; do
  # Check if mouse is near top 10px
  Y=$(xdotool getmouselocation 2>/dev/null | grep -oP 'y:\K\d+')
  if [[ "$Y" -lt 10 ]]; then
    pkill -SIGUSR1 waybar  # Toggle show (requires waybar toggle support)
  fi
  sleep "$HIDE_DELAY"
done
```

---

## 🎨 Customization

### Change color scheme
Edit `colors.css` — it uses Catppuccin Mocha by default.
Swap for any palette: Catppuccin Latte, Gruvbox, Tokyo Night, Rosé Pine, etc.

### Pinned apps
Edit `scripts/pinned.sh` — change the `PINNED_APPS` associative array:
```bash
declare -A PINNED_APPS=(
  ["󰈹"]="firefox"
  ["󰄛"]="kitty"
  # Add more: ["ICON"]="app-command"
)
```

### Temperature sensor path
If `temperature` module shows wrong value, find your sensor:
```bash
for f in /sys/class/hwmon/hwmon*/name; do echo "$f: $(cat $f)"; done
# Find the 'k10temp' or 'zenpower' entry for AMD CPU
```
Then set in `config.jsonc`:
```json
"hwmon-path": "/sys/class/hwmon/hwmonX/temp1_input"
```

### SCX Scheduler
The SCX pill shows your active sched_ext scheduler. Click to switch via fuzzel menu.
Supported: `scx_lavd` (gaming), `scx_rusty` (balanced), `scx_bpfland`, `scx_simple`.

---

## 🔧 Troubleshooting

| Issue | Fix |
|-------|-----|
| Icons not showing | Install `ttf-jetbrains-mono-nerd` |
| GPU shows N/A | Check `/sys/class/drm/card0/device/gpu_busy_percent` exists |
| NVMe health N/A | Install `smartmontools`, run `sudo smartctl -a /dev/nvme0n1` |
| SCX shows "none" | Install & enable `scx-scheds` + `scx.service` |
| Bar doesn't hide | Ensure `exclusive-zone: -1` in config.jsonc |
| Workspaces missing | Confirm `niri` is running and socket is accessible |

---

## 🏗️ Architecture

```
~/.config/waybar/
├── config           → Main bar layout & modules
├── style.css        → Pill design + auto-hide CSS
├── colors.css       → Catppuccin Mocha palette
└── scripts/
    ├── gpu.sh           → AMD GPU (sysfs + rocm-smi fallback)
    ├── nvme.sh          → NVMe health + I/O speed
    ├── scx.sh           → SCX scheduler status
    ├── scx_switch.sh    → SCX scheduler switcher (fuzzel)
    ├── battery_health.sh→ Battery wear + cycle count
    ├── notifications.sh → swaync notification count
    ├── current_app.sh   → niri focused window
    └── pinned.sh        → Dock-style pinned apps
```
