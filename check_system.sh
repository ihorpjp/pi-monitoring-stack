#!/bin/bash

# check_system.sh
# System health monitor — checks CPU, memory, disk, network, processes
# Author: Ihor Bezruchko
# Usage: bash check_system.sh [--log] [--quiet]
#   --log    save output to ~/lab/logs/system_YYYY-MM-DD.log
#   --quiet  only show warnings and alerts (hide OK lines)

# ─── Colors ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Thresholds ──────────────────────────────────────────────────────────────
# Change these values to adjust when alerts trigger
CPU_WARN=70       # % CPU usage — warning
CPU_CRIT=90       # % CPU usage — critical
MEM_WARN=75       # % memory used — warning
MEM_CRIT=90       # % memory used — critical
DISK_WARN=80      # % disk used — warning
DISK_CRIT=95      # % disk used — critical

# ─── Arguments ───────────────────────────────────────────────────────────────
LOG_MODE=false
QUIET_MODE=false
LOG_DIR="$HOME/lab/logs"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_SHORT=$(date '+%Y-%m-%d')
LOG_FILE="$LOG_DIR/system_${DATE_SHORT}.log"

for arg in "$@"; do
    case $arg in
        --log)   LOG_MODE=true ;;
        --quiet) QUIET_MODE=true ;;
        --help)
            echo "Usage: bash check_system.sh [--log] [--quiet]"
            echo "  --log    Save output to ~/lab/logs/system_YYYY-MM-DD.log"
            echo "  --quiet  Only show warnings and alerts"
            exit 0
            ;;
    esac
done

# ─── Setup log file ──────────────────────────────────────────────────────────
if [ "$LOG_MODE" = true ]; then
    mkdir -p "$LOG_DIR"
    exec > >(tee -a "$LOG_FILE") 2>&1
fi

# ─── Functions ───────────────────────────────────────────────────────────────

# Print section header
section() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━  $1  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Status line with color based on value vs thresholds
# Usage: status_line "label" value warn_threshold crit_threshold "unit"
status_line() {
    local label="$1"
    local value="$2"
    local warn="$3"
    local crit="$4"
    local unit="$5"

    if [ "$value" -ge "$crit" ] 2>/dev/null; then
        echo -e "  ${RED}[CRITICAL]${NC} $label: ${RED}${value}${unit}${NC} (threshold: ${crit}${unit})"
    elif [ "$value" -ge "$warn" ] 2>/dev/null; then
        echo -e "  ${YELLOW}[WARNING] ${NC} $label: ${YELLOW}${value}${unit}${NC} (threshold: ${warn}${unit})"
    else
        if [ "$QUIET_MODE" = false ]; then
            echo -e "  ${GREEN}[OK]      ${NC} $label: ${value}${unit}"
        fi
    fi
}

# Simple info line (no threshold check)
info_line() {
    if [ "$QUIET_MODE" = false ]; then
        echo -e "  ${BLUE}[INFO]    ${NC} $1"
    fi
}

# ─── Header ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║         System Health Monitor            ║${NC}"
echo -e "${BOLD}${BLUE}║         by Ihor Bezruchko                ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════╝${NC}"
echo -e "  ${BLUE}Time:${NC} $TIMESTAMP"
echo -e "  ${BLUE}Host:${NC} $(hostname)"
if [ "$LOG_MODE" = true ]; then
    echo -e "  ${BLUE}Log: ${NC} $LOG_FILE"
fi

# ─── 1. System Info ──────────────────────────────────────────────────────────
section "SYSTEM INFO"

info_line "OS:      $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || uname -s)"
info_line "Kernel:  $(uname -r)"
info_line "Uptime:  $(uptime -p 2>/dev/null || uptime | awk '{print $3, $4}' | tr -d ',')"
info_line "User:    $(whoami)"

# ─── 2. CPU ──────────────────────────────────────────────────────────────────
section "CPU"

# Get CPU usage — idle % from top, subtract from 100
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | tr -d '%' | cut -d'.' -f1 2>/dev/null)
if [ -z "$CPU_IDLE" ]; then
    CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | sed 's/.*,\s*\([0-9.]*\)\s*id.*/\1/' | cut -d'.' -f1)
fi
CPU_USED=$((100 - CPU_IDLE))

status_line "CPU Usage" "$CPU_USED" "$CPU_WARN" "$CPU_CRIT" "%"
info_line "Cores:   $(nproc) logical CPU(s)"
info_line "Load:    $(cat /proc/loadavg | awk '{print $1, $2, $3}') (1m 5m 15m)"

# ─── 3. Memory ───────────────────────────────────────────────────────────────
section "MEMORY"

MEM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
MEM_USED=$(free -m  | awk '/^Mem:/{print $3}')
MEM_FREE=$(free -m  | awk '/^Mem:/{print $4}')
MEM_PCT=$(( MEM_USED * 100 / MEM_TOTAL ))

SWAP_TOTAL=$(free -m | awk '/^Swap:/{print $2}')
SWAP_USED=$(free -m  | awk '/^Swap:/{print $3}')

status_line "RAM Usage" "$MEM_PCT" "$MEM_WARN" "$MEM_CRIT" "%"
info_line "RAM:     ${MEM_USED}MB used / ${MEM_TOTAL}MB total / ${MEM_FREE}MB free"

if [ "$SWAP_TOTAL" -gt 0 ] 2>/dev/null; then
    SWAP_PCT=$(( SWAP_USED * 100 / SWAP_TOTAL ))
    status_line "Swap Usage" "$SWAP_PCT" "$MEM_WARN" "$MEM_CRIT" "%"
    info_line "Swap:    ${SWAP_USED}MB used / ${SWAP_TOTAL}MB total"
else
    info_line "Swap:    not configured"
fi

# ─── 4. Disk ─────────────────────────────────────────────────────────────────
section "DISK"

# Check each mounted filesystem
df -h --output=target,pcent,used,avail 2>/dev/null | tail -n +2 | while read mount pct used avail; do
    # Remove % sign for comparison
    pct_num=$(echo "$pct" | tr -d '%')
    # Skip non-real filesystems
    case "$mount" in
        /proc*|/sys*|/dev*|/run*|/snap*) continue ;;
    esac
    status_line "Disk $mount" "$pct_num" "$DISK_WARN" "$DISK_CRIT" "% used"
    if [ "$QUIET_MODE" = false ]; then
        echo -e "             Used: $used  |  Free: $avail"
    fi
done

# ─── 5. Network ──────────────────────────────────────────────────────────────
section "NETWORK"

# Show active network interfaces with IP
ip -4 addr show 2>/dev/null | awk '/^[0-9]+:/{iface=$2} /inet /{print iface, $2}' | grep -v "lo:" | while read iface ip; do
    info_line "Interface: ${iface} → ${ip}"
done

# Check internet connectivity
if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    if [ "$QUIET_MODE" = false ]; then
        echo -e "  ${GREEN}[OK]      ${NC} Internet: reachable (8.8.8.8)"
    fi
else
    echo -e "  ${RED}[CRITICAL]${NC} Internet: NOT reachable"
fi

# Check DNS
if ping -c 1 -W 2 google.com &>/dev/null; then
    if [ "$QUIET_MODE" = false ]; then
        echo -e "  ${GREEN}[OK]      ${NC} DNS: working (google.com resolved)"
    fi
else
    echo -e "  ${YELLOW}[WARNING] ${NC} DNS: not resolving (google.com)"
fi

# ─── 6. Top Processes ────────────────────────────────────────────────────────
section "TOP 5 PROCESSES (by CPU)"

if [ "$QUIET_MODE" = false ]; then
    echo -e "  ${BOLD}%-25s %5s %5s${NC}" "PROCESS" "CPU%" "MEM%"
    echo -e "  ──────────────────────────────────────"
    ps aux --sort=-%cpu 2>/dev/null | awk 'NR>1 && NR<=6 {printf "  %-25s %5s %5s\n", $11, $3, $4}'
fi

# ─── 7. Open Ports ───────────────────────────────────────────────────────────
section "LISTENING PORTS"

if [ "$QUIET_MODE" = false ]; then
    if command -v ss &>/dev/null; then
        echo -e "  ${BOLD}PORT      PROCESS${NC}"
        echo -e "  ──────────────────────────────────────"
        ss -tulpn 2>/dev/null | grep LISTEN | awk '{print $5, $7}' | while read addr proc; do
            port=$(echo "$addr" | rev | cut -d':' -f1 | rev)
            echo -e "  $port    $proc"
        done | sort -n | head -10
    else
        netstat -tulpn 2>/dev/null | grep LISTEN | awk '{print $4, $7}' | head -10
    fi
fi

# ─── 8. Failed Login Attempts ────────────────────────────────────────────────
section "SECURITY — FAILED LOGINS (last 24h)"

FAIL_COUNT=0
if [ -f /var/log/auth.log ]; then
    FAIL_COUNT=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null || echo 0)
elif [ -f /var/log/secure ]; then
    FAIL_COUNT=$(grep -c "Failed password" /var/log/secure 2>/dev/null || echo 0)
fi

if [ "$FAIL_COUNT" -gt 10 ] 2>/dev/null; then
    echo -e "  ${RED}[CRITICAL]${NC} Failed login attempts: ${RED}$FAIL_COUNT${NC}"
    # Show top attacking IPs
    echo -e "  ${BOLD}Top IPs:${NC}"
    grep "Failed password" /var/log/auth.log 2>/dev/null | \
        grep -oP 'from \K\S+' | sort | uniq -c | sort -rn | head -5 | \
        while read count ip; do
            echo -e "    ${RED}$ip${NC} → $count attempts"
        done
elif [ "$FAIL_COUNT" -gt 0 ] 2>/dev/null; then
    echo -e "  ${YELLOW}[WARNING] ${NC} Failed login attempts: $FAIL_COUNT"
else
    if [ "$QUIET_MODE" = false ]; then
        echo -e "  ${GREEN}[OK]      ${NC} No failed login attempts found"
    fi
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Summary${NC}"
echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  CPU:    ${CPU_USED}%  |  RAM: ${MEM_PCT}%  |  Time: $TIMESTAMP"
if [ "$LOG_MODE" = true ]; then
    echo -e "  ${GREEN}Report saved to:${NC} $LOG_FILE"
fi
echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
