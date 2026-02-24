#!/usr/bin/env bash
# ─── Notification Center Status (swaync) ──────────────────────

count=$(swaync-client -c 2>/dev/null || echo 0)
dnd=$(swaync-client -D 2>/dev/null && echo "true" || echo "false")

if [[ "$dnd" == "true" ]]; then
  if [[ "$count" -gt 0 ]]; then
    class="dnd-notification"
  else
    class="dnd-none"
  fi
else
  if [[ "$count" -gt 0 ]]; then
    class="notification"
  else
    class="none"
  fi
fi

tooltip="Notifications: ${count} unread"
[[ "$dnd" == "true" ]] && tooltip="$tooltip\nDo Not Disturb: ON"

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
  "$count" "$tooltip" "$class"
