#!/usr/bin/env bash
# ─── SCX Scheduler Manager ────────────────────────────────────
# Shows active sched_ext scheduler and allows switching
# Requires: scx (AUR: scx-scheds), systemd service: scx.service

get_active_sched() {
  # Read from sched_ext kernel interface
  if [[ -f /sys/kernel/sched_ext/state ]]; then
    local state
    state=$(cat /sys/kernel/sched_ext/state 2>/dev/null)
    if [[ "$state" == "enabled" || "$state" == "active" ]]; then
      local sched
      sched=$(cat /sys/kernel/sched_ext/root_cgroup/prog_name 2>/dev/null \
           || cat /sys/kernel/sched_ext/ops 2>/dev/null \
           || echo "unknown")
      echo "$sched"
      return
    fi
  fi

  # Fallback: check systemd service
  if systemctl is-active --quiet scx.service 2>/dev/null; then
    local sched
    sched=$(systemctl show scx.service -p Environment 2>/dev/null \
      | grep -oP 'SCX_SCHEDULER=\K\S+' \
      | head -1)
    echo "${sched:-scx_active}"
    return
  fi

  echo "none"
}

get_status_json() {
  local sched
  sched=$(get_active_sched)

  local icon tooltip class
  case "$sched" in
    none)
      icon="󰔟"
      class="disabled"
      tooltip="SCX: Disabled (using CFS)"
      ;;
    scx_lavd)
      icon="󱎴"
      class="lavd"
      tooltip="SCX Scheduler: scx_lavd\nLatency-Aware Virtual Deadline\nOptimal for gaming & interactive"
      ;;
    scx_rusty)
      icon="󱎴"
      class="rusty"
      tooltip="SCX Scheduler: scx_rusty\nRust-based multi-domain scheduler"
      ;;
    scx_bpfland)
      icon="󱎴"
      class="bpfland"
      tooltip="SCX Scheduler: scx_bpfland\nBPF-powered balanced scheduler"
      ;;
    scx_simple)
      icon="󱎴"
      class="simple"
      tooltip="SCX Scheduler: scx_simple\nSimple weighted vruntime"
      ;;
    *)
      icon="󱎴"
      class="active"
      tooltip="SCX Scheduler: $sched"
      ;;
  esac

  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
    "$sched" "$tooltip" "$class"
}

get_status_json
