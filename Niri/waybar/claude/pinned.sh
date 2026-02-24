#!/usr/bin/env bash
# ─── Pinned Apps Launcher ─────────────────────────────────────
# Edit PINNED array below to customise your dock apps

declare -A PINNED_APPS=(
  ["󰈹"]="firefox"
  ["󰄛"]="kitty"
  ["󰉋"]="thunar"
  ["󰨞"]="code"
  ["󰙯"]="vesktop"
  ["󰓇"]="spotify"
)

# Display as space-separated icons
ICONS=""
for icon in "${!PINNED_APPS[@]}"; do
  ICONS+="$icon "
done

TOOLTIP="Pinned Apps:\n"
for icon in "${!PINNED_APPS[@]}"; do
  TOOLTIP+="  $icon → ${PINNED_APPS[$icon]}\n"
done

printf '{"text":"%s","tooltip":"%s"}\n' \
  "${ICONS% }" "$TOOLTIP"
