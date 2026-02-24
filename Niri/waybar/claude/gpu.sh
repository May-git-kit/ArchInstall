#!/usr/bin/env bash
# ─── AMD GPU Monitor ──────────────────────────────────────────
# Reads from /sys/class/drm for AMD iGPU/dGPU (no ROCm required)
# Falls back to rocm-smi if available
# Usage: gpu.sh [usage|temp|vram]

MODE="${1:-usage}"

# ── Detect AMD GPU hwmon path ──────────────────────────────────
GPU_HWMON=""
for card in /sys/class/drm/card*/device/hwmon/hwmon*; do
  name_file="$card/name"
  if [[ -f "$name_file" ]]; then
    name=$(cat "$name_file")
    if [[ "$name" == "amdgpu" ]]; then
      GPU_HWMON="$card"
      break
    fi
  fi
done

# ── Fallback: try rocm-smi ─────────────────────────────────────
if command -v rocm-smi &>/dev/null 2>&1; then
  case "$MODE" in
    usage)
      val=$(rocm-smi --showuse 2>/dev/null | grep -m1 'GPU use' | awk '{print $NF}' | tr -d '%')
      echo "${val:-0}%"
      ;;
    temp)
      val=$(rocm-smi --showtemp 2>/dev/null | grep -m1 'Temperature' | awk '{print $NF}' | tr -d 'c°C')
      echo "${val:-0}°C"
      ;;
    vram)
      used=$(rocm-smi --showmemuse 2>/dev/null | grep -m1 'VRAM' | awk '{print $(NF-1)}')
      total=$(rocm-smi --showmeminfo vram 2>/dev/null | grep -m1 'Total Memory' | awk '{print $NF}')
      used_mb=$(( ${used:-0} / 1024 / 1024 ))
      total_mb=$(( ${total:-1} / 1024 / 1024 ))
      pct=$(( used_mb * 100 / total_mb ))
      printf '{"text":"%dM/%dM","tooltip":"VRAM: %dMiB / %dMiB (%d%%)"}\n' \
        "$used_mb" "$total_mb" "$used_mb" "$total_mb" "$pct"
      ;;
  esac
  exit 0
fi

# ── sysfs hwmon path ───────────────────────────────────────────
if [[ -z "$GPU_HWMON" ]]; then
  # Last fallback: find any amdgpu via sysfs
  for hwmon in /sys/class/hwmon/hwmon*; do
    [[ "$(cat "$hwmon/name" 2>/dev/null)" == "amdgpu" ]] && GPU_HWMON="$hwmon" && break
  done
fi

case "$MODE" in
  usage)
    # GPU busy percent
    busy_file=""
    for f in /sys/class/drm/card*/device/gpu_busy_percent; do
      [[ -f "$f" ]] && busy_file="$f" && break
    done
    if [[ -n "$busy_file" ]]; then
      echo "$(cat "$busy_file")%"
    else
      echo "N/A"
    fi
    ;;

  temp)
    if [[ -n "$GPU_HWMON" && -f "$GPU_HWMON/temp1_input" ]]; then
      raw=$(cat "$GPU_HWMON/temp1_input")
      echo "$(( raw / 1000 ))°C"
    else
      echo "N/A"
    fi
    ;;

  vram)
    # VRAM via drm memory info
    vram_used=0
    vram_total=0
    for mem_file in /sys/class/drm/card*/device/mem_info_vram_used; do
      [[ -f "$mem_file" ]] && vram_used=$(cat "$mem_file") && break
    done
    for mem_file in /sys/class/drm/card*/device/mem_info_vram_total; do
      [[ -f "$mem_file" ]] && vram_total=$(cat "$mem_file") && break
    done

    used_mb=$(( vram_used  / 1024 / 1024 ))
    total_mb=$(( vram_total / 1024 / 1024 ))
    pct=0
    [[ $total_mb -gt 0 ]] && pct=$(( used_mb * 100 / total_mb ))

    printf '{"text":"%dM/%dM","tooltip":"VRAM: %dMiB used / %dMiB total (%d%%)"}\n' \
      "$used_mb" "$total_mb" "$used_mb" "$total_mb" "$pct"
    ;;
esac
