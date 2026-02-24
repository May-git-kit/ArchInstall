#!/usr/bin/env bash
# ─── Battery Health Monitor ───────────────────────────────────
# Reads from /sys/class/power_supply for health % and cycle count

BAT=""
for b in /sys/class/power_supply/BAT{0,1,2}; do
  [[ -d "$b" ]] && BAT="$b" && break
done

[[ -z "$BAT" ]] && echo '{"text":"N/A","tooltip":"No battery found"}' && exit 0

# Health = (energy_full / energy_full_design) * 100
energy_full=$(cat "$BAT/energy_full"        2>/dev/null || echo 0)
energy_design=$(cat "$BAT/energy_full_design" 2>/dev/null || echo 0)
cycles=$(cat "$BAT/cycle_count"              2>/dev/null || echo "?")
tech=$(cat "$BAT/technology"                 2>/dev/null || echo "Unknown")

if [[ "$energy_design" -gt 0 ]]; then
  health=$(( energy_full * 100 / energy_design ))
else
  health="N/A"
fi

# Determine class
class="good"
[[ "$health" =~ ^[0-9]+$ ]] && (( health < 80 )) && class="warning"
[[ "$health" =~ ^[0-9]+$ ]] && (( health < 60 )) && class="critical"

tooltip="Battery Health: ${health}%\nCycle Count: ${cycles}\nTechnology: $tech\nMax Capacity: $(( energy_full / 1000 ))mWh / $(( energy_design / 1000 ))mWh design"

printf '{"text":"%s%%","tooltip":"%s","class":"%s"}\n' \
  "$health" "$tooltip" "$class"
