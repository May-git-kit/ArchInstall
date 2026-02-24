#!/usr/bin/env bash
# ─── Current Focused App (niri) ───────────────────────────────
# Reads focused window app_id via niri msg

WINDOW_JSON=$(niri msg --json focused-window 2>/dev/null)

if [[ -z "$WINDOW_JSON" || "$WINDOW_JSON" == "null" ]]; then
  printf '{"text":"Desktop","tooltip":"No focused window","alt":"default"}\n'
  exit 0
fi

# Parse app_id and title
APP_ID=$(echo "$WINDOW_JSON" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d.get('app_id',''))" 2>/dev/null \
  || echo "$WINDOW_JSON" | grep -oP '"app_id"\s*:\s*"\K[^"]+')

TITLE=$(echo "$WINDOW_JSON" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d.get('title',''))" 2>/dev/null \
  || echo "$WINDOW_JSON" | grep -oP '"title"\s*:\s*"\K[^"]+')

# Truncate title
SHORT_TITLE="${TITLE:0:25}"
[[ "${#TITLE}" -gt 25 ]] && SHORT_TITLE="${SHORT_TITLE}…"

# Lowercase app_id for alt class
ALT=$(echo "$APP_ID" | tr '[:upper:]' '[:lower:]' | sed 's/\..*$//')

printf '{"text":"%s","tooltip":"%s","alt":"%s"}\n' \
  "$SHORT_TITLE" "$APP_ID: $TITLE" "$ALT"
