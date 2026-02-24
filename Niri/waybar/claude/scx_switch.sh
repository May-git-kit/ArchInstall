#!/usr/bin/env bash
# ─── SCX Scheduler Switcher ───────────────────────────────────
# Interactive scheduler selection via fuzzel/rofi

SCHEDS=("scx_lavd" "scx_rusty" "scx_bpfland" "scx_simple" "scx_flatcg" "none (CFS)")

chosen=$(printf '%s\n' "${SCHEDS[@]}" | \
  fuzzel --dmenu --prompt='  Scheduler: ' --lines=7 --width=30 2>/dev/null \
  || printf '%s\n' "${SCHEDS[@]}" | \
  rofi -dmenu -p "Scheduler" -theme-str 'window { width: 300px; }')

[[ -z "$chosen" ]] && exit 0

if [[ "$chosen" == "none (CFS)" ]]; then
  pkexec systemctl stop scx.service
  notify-send "SCX" "Switched to CFS (default scheduler)" -i dialog-information
else
  # Update scx config
  CONFIG="/etc/scx.conf"
  if [[ -f "$CONFIG" ]]; then
    pkexec sed -i "s/^SCX_SCHEDULER=.*/SCX_SCHEDULER=$chosen/" "$CONFIG"
  else
    echo "SCX_SCHEDULER=$chosen" | pkexec tee "$CONFIG" > /dev/null
  fi
  pkexec systemctl restart scx.service
  sleep 0.5
  notify-send "SCX" "Switched to $chosen" -i dialog-information
fi

pkill -SIGRTMIN+8 waybar 2>/dev/null
