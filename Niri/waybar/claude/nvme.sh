#!/usr/bin/env bash
# ─── NVMe Health + Read/Write Speed Monitor ───────────────────
# Requires: smartmontools, sysstat (iostat), or ioping
# Usage: nvme.sh [details]

NVME_DEV=""
for dev in /dev/nvme0 /dev/nvme0n1; do
  [[ -b "$dev" ]] && NVME_DEV="$dev" && break
done
[[ -z "$NVME_DEV" ]] && NVME_DEV="/dev/nvme0n1"

# ── Block device name for iostat (e.g. nvme0n1) ───────────────
BLK_NAME=$(basename "$NVME_DEV")

# ── NVMe Health via smartctl ───────────────────────────────────
get_health() {
  if command -v smartctl &>/dev/null; then
    local pct worn remaining
    worn=$(smartctl -A "$NVME_DEV" 2>/dev/null \
      | awk '/Percentage Used/{print $NF}' | tr -d '%')
    remaining=$(( 100 - ${worn:-0} ))
    echo "${remaining}%"
  else
    echo "N/A"
  fi
}

# ── I/O speed via /proc/diskstats ─────────────────────────────
get_io_speed() {
  local sectors_read1 sectors_write1 sectors_read2 sectors_write2
  local r1 w1 r2 w2

  read_diskstats() {
    awk -v dev="$BLK_NAME" '$3==dev{print $6, $10}' /proc/diskstats
  }

  read r1 w1 < <(read_diskstats)
  sleep 1
  read r2 w2 < <(read_diskstats)

  # Sectors are 512 bytes
  local read_kbs=$(( ( (r2 - r1) * 512 ) / 1024 ))
  local write_kbs=$(( ( (w2 - w1) * 512 ) / 1024 ))

  # Human-readable
  format_speed() {
    local kb=$1
    if (( kb >= 1024 )); then
      printf "%.1fM" "$(echo "scale=1; $kb / 1024" | bc)"
    else
      echo "${kb}K"
    fi
  }

  echo "$(format_speed $read_kbs)/s ↓ $(format_speed $write_kbs)/s ↑"
}

# ── Main Output ────────────────────────────────────────────────
if [[ "$1" == "details" ]]; then
  # Detailed output for terminal popup
  echo "=== NVMe Status: $NVME_DEV ==="
  smartctl -a "$NVME_DEV" 2>/dev/null | grep -E \
    'Model|Temperature|Percentage|Available|Power|Unsafe|Media|Error' \
    | sed 's/^/  /'
  exit 0
fi

HEALTH=$(get_health)
IO=$(get_io_speed)

# Determine health class
HEALTH_NUM=$(echo "$HEALTH" | tr -d '%')
if [[ "$HEALTH_NUM" =~ ^[0-9]+$ ]]; then
  if (( HEALTH_NUM > 80 )); then
    CLASS="good"
    ICON="󰋊"
  elif (( HEALTH_NUM > 50 )); then
    CLASS="warning"
    ICON="󰋈"
  else
    CLASS="critical"
    ICON="󰋉"
  fi
else
  CLASS="unknown"
  ICON="󰋊"
fi

printf '{"text":"%s %s  %s","tooltip":"NVMe Health: %s\\nI/O: %s\\nDevice: %s","class":"%s"}\n' \
  "$ICON" "$HEALTH" "$IO" "$HEALTH" "$IO" "$NVME_DEV" "$CLASS"
