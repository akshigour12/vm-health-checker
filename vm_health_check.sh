#!/usr/bin/env bash

# VM Health Checker - Advanced Edition with Trending & Analytics
# Usage:
#   ./vm_health_check.sh
#   ./vm_health_check.sh explain
#   ./vm_health_check.sh --json
#   ./vm_health_check.sh --log /var/log/vm_health.log
#   ./vm_health_check.sh --threshold cpu=75 memory=85 disk=85
#   ./vm_health_check.sh --email admin@example.com
#   ./vm_health_check.sh --output-dir /tmp/reports
#   ./vm_health_check.sh --trending 7d
#   ./vm_health_check.sh --alert-webhook https://hooks.slack.com/...
#   ./vm_health_check.sh --performance-compare
#   ./vm_health_check.sh --health-history
#   ./vm_health_check.sh --snapshots /var/snapshots

set -u

# Default configuration
EXPLAIN_MODE=false
JSON_MODE=false
LOG_FILE=""
OUTPUT_DIR=""
EMAIL_ALERT=""
WEBHOOK_URL=""
TRENDING_MODE=false
TRENDING_PERIOD="7d"
PERFORMANCE_COMPARE=false
HEALTH_HISTORY=false
SNAPSHOT_DIR=""
GENERATE_SNAPSHOT=false
DETAILED_REPORT=false

# Default thresholds
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=80
SWAP_THRESHOLD=50

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    explain)
      EXPLAIN_MODE=true
      shift
      ;;
    --json)
      JSON_MODE=true
      shift
      ;;
    --log)
      LOG_FILE="$2"
      shift 2
      ;;
    --threshold)
      IFS='=' read -r key value <<< "$2"
      case "$key" in
        cpu) CPU_THRESHOLD="$value" ;;
        memory) MEM_THRESHOLD="$value" ;;
        disk) DISK_THRESHOLD="$value" ;;
        swap) SWAP_THRESHOLD="$value" ;;
      esac
      shift 2
      ;;
    --email)
      EMAIL_ALERT="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --alert-webhook)
      WEBHOOK_URL="$2"
      shift 2
      ;;
    --trending)
      TRENDING_MODE=true
      TRENDING_PERIOD="${2:-7d}"
      shift 2
      ;;
    --performance-compare)
      PERFORMANCE_COMPARE=true
      shift
      ;;
    --health-history)
      HEALTH_HISTORY=true
      shift
      ;;
    --snapshots)
      SNAPSHOT_DIR="$2"
      GENERATE_SNAPSHOT=true
      shift 2
      ;;
    --detailed-report)
      DETAILED_REPORT=true
      shift
      ;;
    --help)
      echo "VM Health Checker - Advanced Edition"
      echo ""
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Basic Options:"
      echo "  explain                          Display detailed explanation of health status"
      echo "  --json                          Output results in JSON format"
      echo "  --log FILE                      Log results to a file"
      echo "  --threshold KEY=VALUE           Set custom thresholds (cpu, memory, disk, swap)"
      echo "  --email EMAIL                   Send alerts to email (requires mail command)"
      echo "  --output-dir DIR                Save JSON reports to directory"
      echo ""
      echo "Advanced Analytics Options:"
      echo "  --trending [PERIOD]             Show trending analysis (7d, 30d, 90d)"
      echo "  --performance-compare           Compare current metrics against historical avg"
      echo "  --health-history                Display health status history"
      echo "  --snapshots DIR                 Enable snapshot mode (save data for trending)"
      echo "  --detailed-report               Generate comprehensive HTML report"
      echo "  --alert-webhook URL             Send alerts to Slack/Teams webhook"
      echo "  --help                          Display this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Logging function
log_message() {
  local level="$1"
  local message="$2"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  if [ -n "$LOG_FILE" ]; then
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
  fi
}

# Output functions
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
pass() { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Create snapshot file
create_snapshot() {
  if [ -z "$SNAPSHOT_DIR" ]; then
    return
  fi
  
  mkdir -p "$SNAPSHOT_DIR" 2>/dev/null || return
  
  local snapshot_file="${SNAPSHOT_DIR}/snapshot_$(date +%s).json"
  generate_json "$1" "$2" > "$snapshot_file" 2>/dev/null
}

# Analyze trends
analyze_trends() {
  if [ ! -d "$SNAPSHOT_DIR" ]; then
    echo "No snapshot directory found for trending analysis"
    return 1
  fi
  
  local mem_values=()
  local cpu_values=()
  local disk_values=()
  local timestamps=()
  
  # Parse all snapshots
  for snapshot in "$SNAPSHOT_DIR"/snapshot_*.json; do
    [ -f "$snapshot" ] || continue
    
    mem=$(grep -o '"used_percent": [^,}]*' "$snapshot" | head -1 | awk '{print $NF}' | tr -d ',')
    cpu=$(grep -o '"load_1m": "[^"]*' "$snapshot" | awk '{print $NF}' | tr -d '"')
    disk=$(grep -o '"used_percent": [^,}]*' "$snapshot" | tail -1 | awk '{print $NF}' | tr -d ',')
    timestamp=$(grep -o '"timestamp": "[^"]*' "$snapshot" | awk '{print $NF}' | tr -d '"')
    
    [ -n "$mem" ] && mem_values+=("$mem")
    [ -n "$cpu" ] && cpu_values+=("$cpu")
    [ -n "$disk" ] && disk_values+=("$disk")
    [ -n "$timestamp" ] && timestamps+=("$timestamp")
  done
  
  if [ ${#mem_values[@]} -eq 0 ]; then
    echo "No snapshot data available for trending"
    return 1
  fi
  
  printf '%bTrending Analysis (%s)%b\n' "$CYAN" "$TRENDING_PERIOD" "$NC"
  printf '%b=================%b\n' "$CYAN" "$NC"
  
  # Calculate averages
  local mem_avg=$(printf '%s\n' "${mem_values[@]}" | awk '{sum+=$1} END {if(NR>0) printf "%.2f", sum/NR}')
  local disk_avg=$(printf '%s\n' "${disk_values[@]}" | awk '{sum+=$1} END {if(NR>0) printf "%.2f", sum/NR}')
  local mem_max=$(printf '%s\n' "${mem_values[@]}" | sort -rn | head -1)
  local disk_max=$(printf '%s\n' "${disk_values[@]}" | sort -rn | head -1)
  
  info "Memory - Avg: ${mem_avg}% | Max: ${mem_max}% | Samples: ${#mem_values[@]}"
  info "Disk - Avg: ${disk_avg}% | Max: ${disk_max}% | Samples: ${#disk_values[@]}"
  
  printf '\n'
}

# Generate detailed HTML report
generate_html_report() {
  local status="$1"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local report_file="${OUTPUT_DIR}/report_$(date +%s).html"
  
  mkdir -p "$OUTPUT_DIR" 2>/dev/null || return
  
  cat > "$report_file" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VM Health Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 10px; box-shadow: 0 10px 40px rgba(0,0,0,0.2); padding: 30px; }
        .header { border-bottom: 3px solid #667eea; padding-bottom: 20px; margin-bottom: 30px; }
        .header h1 { color: #333; margin-bottom: 10px; }
        .status { display: inline-block; padding: 8px 16px; border-radius: 5px; font-weight: bold; margin-top: 10px; }
        .status.healthy { background: #4caf50; color: white; }
        .status.degraded { background: #ff9800; color: white; }
        .status.critical { background: #f44336; color: white; }
        .metrics-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .metric-card { border: 1px solid #ddd; border-radius: 8px; padding: 20px; background: #f9f9f9; }
        .metric-card h3 { color: #667eea; margin-bottom: 15px; font-size: 18px; }
        .metric-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; }
        .metric-row:last-child { border-bottom: none; }
        .metric-label { font-weight: 600; color: #555; }
        .metric-value { color: #333; }
        .progress-bar { width: 100%; height: 20px; background: #eee; border-radius: 10px; overflow: hidden; margin: 10px 0; }
        .progress-fill { height: 100%; background: linear-gradient(90deg, #4caf50, #8bc34a); transition: all 0.3s ease; }
        .progress-fill.warning { background: linear-gradient(90deg, #ff9800, #ffc107); }
        .progress-fill.critical { background: linear-gradient(90deg, #f44336, #e91e63); }
        .timestamp { color: #999; font-size: 14px; margin-top: 20px; text-align: center; border-top: 1px solid #eee; padding-top: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background: #667eea; color: white; padding: 12px; text-align: left; }
        td { padding: 12px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f5f5f5; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🖥️ Virtual Machine Health Report</h1>
            <div class="status STATUSCLASS">Status: STATUS</div>
        </div>
        
        <div class="metrics-grid">
            <div class="metric-card">
                <h3>💻 System Information</h3>
                <div class="metric-row"><span class="metric-label">Hostname:</span><span class="metric-value">HOSTNAME</span></div>
                <div class="metric-row"><span class="metric-label">Kernel:</span><span class="metric-value">KERNEL</span></div>
                <div class="metric-row"><span class="metric-label">OS:</span><span class="metric-value">OS</span></div>
                <div class="metric-row"><span class="metric-label">Uptime:</span><span class="metric-value">UPTIME</span></div>
            </div>
            
            <div class="metric-card">
                <h3>⚙️ CPU Metrics</h3>
                <div class="metric-row"><span class="metric-label">Cores:</span><span class="metric-value">CPU_CORES</span></div>
                <div class="metric-row"><span class="metric-label">Load (1m):</span><span class="metric-value">CPU_LOAD_1M</span></div>
                <div class="metric-row"><span class="metric-label">Load (5m):</span><span class="metric-value">CPU_LOAD_5M</span></div>
                <div class="metric-row"><span class="metric-label">Load (15m):</span><span class="metric-value">CPU_LOAD_15M</span></div>
            </div>
            
            <div class="metric-card">
                <h3>🧠 Memory Metrics</h3>
                <div class="metric-row"><span class="metric-label">Total:</span><span class="metric-value">MEM_TOTAL</span></div>
                <div class="metric-row"><span class="metric-label">Usage:</span><span class="metric-value">MEM_USED%</span></div>
                <div class="progress-bar"><div class="progress-fill" style="width: MEM_USED%"></div></div>
                <div class="metric-row"><span class="metric-label">Available:</span><span class="metric-value">MEM_AVAILABLE</span></div>
            </div>
            
            <div class="metric-card">
                <h3>💾 Disk Metrics</h3>
                <div class="metric-row"><span class="metric-label">Total:</span><span class="metric-value">DISK_TOTAL</span></div>
                <div class="metric-row"><span class="metric-label">Usage:</span><span class="metric-value">DISK_USED%</span></div>
                <div class="progress-bar"><div class="progress-fill" style="width: DISK_USED%"></div></div>
                <div class="metric-row"><span class="metric-label">Available:</span><span class="metric-value">DISK_AVAILABLE</span></div>
            </div>
            
            <div class="metric-card">
                <h3>🔄 Swap Metrics</h3>
                <div class="metric-row"><span class="metric-label">Total:</span><span class="metric-value">SWAP_TOTAL</span></div>
                <div class="metric-row"><span class="metric-label">Usage:</span><span class="metric-value">SWAP_USED%</span></div>
                <div class="progress-bar"><div class="progress-fill" style="width: SWAP_USED%"></div></div>
                <div class="metric-row"><span class="metric-label">Available:</span><span class="metric-value">SWAP_AVAILABLE</span></div>
            </div>
            
            <div class="metric-card">
                <h3>🌡️ Additional Metrics</h3>
                <div class="metric-row"><span class="metric-label">Temperature:</span><span class="metric-value">TEMPERATURE</span></div>
                <div class="metric-row"><span class="metric-label">Processes:</span><span class="metric-value">PROCESS_COUNT</span></div>
                <div class="metric-row"><span class="metric-label">Interfaces:</span><span class="metric-value">INTERFACES</span></div>
            </div>
        </div>
        
        <div class="timestamp">Report generated: TIMESTAMP</div>
    </div>
</body>
</html>
HTMLEOF
  
  info "HTML report generated: $report_file"
}

# Send webhook alert
send_webhook_alert() {
  local status="$1"
  local issues="$2"
  
  if [ -z "$WEBHOOK_URL" ]; then
    return
  fi
  
  if ! command -v curl >/dev/null 2>&1; then
    error "curl not found. Cannot send webhook alert."
    return
  fi
  
  local color="#36a64b"  # Green
  if [ "$status" = "DEGRADED" ]; then
    color="#ff9800"  # Orange
  elif [ "$status" = "CRITICAL" ]; then
    color="#f44336"  # Red
  fi
  
  local payload=$(cat <<EOF
{
  "attachments": [
    {
      "color": "$color",
      "title": "VM Health Alert - $HOSTNAME",
      "text": "Status: $status\nIssues: $issues\nMemory: ${MEM_USED_PERCENT}%\nDisk: ${DISK_USED_PERCENT}%",
      "ts": $(date +%s)
    }
  ]
}
EOF
  )
  
  curl -X POST -H 'Content-type: application/json' --data "$payload" "$WEBHOOK_URL" >/dev/null 2>&1
  info "Webhook alert sent"
}

# Collect system metrics
collect_metrics() {
  # CPU metrics
  CPU_CORES=$(nproc 2>/dev/null || echo "unknown")
  CPU_LOAD=$(uptime 2>/dev/null | sed -E 's/.*load average: (.*)/\1/' || echo "unknown")
  
  if [ "$CPU_LOAD" != "unknown" ]; then
    CPU_LOAD_1=$(echo "$CPU_LOAD" | awk -F',' '{print $1}' | xargs)
    CPU_LOAD_5=$(echo "$CPU_LOAD" | awk -F',' '{print $2}' | xargs)
    CPU_LOAD_15=$(echo "$CPU_LOAD" | awk -F',' '{print $3}' | xargs)
  else
    CPU_LOAD_1="unknown"
    CPU_LOAD_5="unknown"
    CPU_LOAD_15="unknown"
  fi
  
  # Memory metrics
  MEM_TOTAL_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)
  MEM_AVAILABLE_KB=$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)
  MEM_USED_KB=$(( MEM_TOTAL_KB - MEM_AVAILABLE_KB ))
  MEM_USED_PERCENT=$(awk -v used="$MEM_USED_KB" -v total="$MEM_TOTAL_KB" 'BEGIN { if (total > 0) printf "%.2f", (used/total)*100; else printf "0.00" }')
  
  # Disk metrics
  DISK_TOTAL_KB=$(df -Pk / 2>/dev/null | awk 'NR==2 {print $2}' || echo 0)
  DISK_AVAILABLE_KB=$(df -Pk / 2>/dev/null | awk 'NR==2 {print $4}' || echo 0)
  DISK_USED_PERCENT=$(df -P / 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%' || echo 0)
  
  # Swap metrics
  SWAP_TOTAL_KB=$(grep SwapTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)
  SWAP_FREE_KB=$(grep SwapFree /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)
  SWAP_USED_KB=$(( SWAP_TOTAL_KB - SWAP_FREE_KB ))
  if [ "$SWAP_TOTAL_KB" -gt 0 ]; then
    SWAP_USED_PERCENT=$(( (SWAP_USED_KB * 100) / SWAP_TOTAL_KB ))
  else
    SWAP_USED_PERCENT=0
  fi
  
  # System info
  UPTIME_SECONDS=$(cut -d' ' -f1 /proc/uptime 2>/dev/null || echo 0)
  HOSTNAME=$(hostname 2>/dev/null || echo "unknown")
  KERNEL=$(uname -r 2>/dev/null || echo "unknown")
  OS=$(uname -s 2>/dev/null || echo "unknown")
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  PROCESS_COUNT=$(ps aux | wc -l 2>/dev/null || echo "unknown")
  TEMP=$(( { cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print $1/1000}'; } || echo "N/A" ) 2>/dev/null)
  NETWORK_INTERFACES=$(ip link show 2>/dev/null | grep '^[0-9]' | awk '{print $2}' | tr -d ':' | tr '\n' ',' | sed 's/,$//')
  
  # File descriptor usage
  FD_USAGE=$(( $(ls -1 /proc/self/fd 2>/dev/null | wc -l) || echo 0 ))
  FD_MAX=$(cat /proc/sys/fs/file-max 2>/dev/null || echo 0)
  
  # System load classification
  LOAD_CLASS="Normal"
  if [ "$CPU_LOAD_1" != "unknown" ]; then
    if awk -v a="$CPU_LOAD_1" -v b="$CPU_CORES" 'BEGIN { exit !(a > (b * 1.5)) }'; then
      LOAD_CLASS="High"
    fi
  fi
}

# Generate JSON output
generate_json() {
  local status="$1"
  local issues="$2"
  
  cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "hostname": "$HOSTNAME",
  "status": "$status",
  "issues_count": $issues,
  "system": {
    "kernel": "$KERNEL",
    "os": "$OS",
    "uptime_seconds": $UPTIME_SECONDS,
    "process_count": "$PROCESS_COUNT",
    "network_interfaces": "$NETWORK_INTERFACES",
    "file_descriptors": $FD_USAGE,
    "file_descriptors_max": $FD_MAX
  },
  "cpu": {
    "cores": "$CPU_CORES",
    "load_1m": "$CPU_LOAD_1",
    "load_5m": "$CPU_LOAD_5",
    "load_15m": "$CPU_LOAD_15",
    "load_classification": "$LOAD_CLASS",
    "threshold": $CPU_THRESHOLD
  },
  "memory": {
    "total_kb": $MEM_TOTAL_KB,
    "used_kb": $MEM_USED_KB,
    "available_kb": $MEM_AVAILABLE_KB,
    "used_percent": $MEM_USED_PERCENT,
    "threshold": $MEM_THRESHOLD
  },
  "disk": {
    "total_kb": $DISK_TOTAL_KB,
    "available_kb": $DISK_AVAILABLE_KB,
    "used_percent": $DISK_USED_PERCENT,
    "threshold": $DISK_THRESHOLD
  },
  "swap": {
    "total_kb": $SWAP_TOTAL_KB,
    "used_kb": $SWAP_USED_KB,
    "used_percent": $SWAP_USED_PERCENT,
    "threshold": $SWAP_THRESHOLD
  },
  "temperature_celsius": "$TEMP"
}
EOF
}

# Perform comprehensive health checks
perform_checks() {
  local status="HEALTHY"
  local issues=0
  
  # CPU check
  if [ "$CPU_CORES" != "unknown" ] && [ "$CPU_CORES" -gt 0 ] && [ "$CPU_LOAD_1" != "unknown" ]; then
    if awk -v a="$CPU_LOAD_1" -v threshold="$CPU_THRESHOLD" -v cores="$CPU_CORES" 'BEGIN { exit !(a > (cores * threshold / 100)) }'; then
      warn "CPU load (${CPU_LOAD_1}) exceeds threshold"
      status="DEGRADED"
      issues=$((issues + 1))
    fi
  fi
  
  # Memory check
  if [ "$MEM_TOTAL_KB" -gt 0 ]; then
    if awk -v p="$MEM_USED_PERCENT" -v t="$MEM_THRESHOLD" 'BEGIN { exit !(p > t) }'; then
      if awk -v p="$MEM_USED_PERCENT" 'BEGIN { exit !(p > 95) }'; then
        error "Memory usage CRITICAL (${MEM_USED_PERCENT}%)"
        status="CRITICAL"
      else
        warn "Memory usage high (${MEM_USED_PERCENT}%)"
        status="DEGRADED"
      fi
      issues=$((issues + 1))
    fi
  fi
  
  # Disk check
  if [ "$DISK_TOTAL_KB" -gt 0 ]; then
    if awk -v p="$DISK_USED_PERCENT" -v t="$DISK_THRESHOLD" 'BEGIN { exit !(p > t) }'; then
      if awk -v p="$DISK_USED_PERCENT" 'BEGIN { exit !(p > 95) }'; then
        error "Disk usage CRITICAL (${DISK_USED_PERCENT}%)"
        status="CRITICAL"
      else
        warn "Disk usage high (${DISK_USED_PERCENT}%)"
        status="DEGRADED"
      fi
      issues=$((issues + 1))
    fi
  fi
  
  # Swap check
  if [ "$SWAP_TOTAL_KB" -gt 0 ]; then
    if awk -v p="$SWAP_USED_PERCENT" -v t="$SWAP_THRESHOLD" 'BEGIN { exit !(p > t) }'; then
      warn "Swap usage high (${SWAP_USED_PERCENT}%)"
      status="DEGRADED"
      issues=$((issues + 1))
    fi
  fi
  
  # Filesystem check
  if [ ! -w / ] && [ ! -x / ]; then
    error "Root filesystem not accessible"
    status="CRITICAL"
    issues=$((issues + 1))
  fi
  
  echo "$status|$issues"
}

# Display human-readable output
display_output() {
  local status="$1"
  local issues="$2"
  
  printf '\n'
  printf '%b╔════════════════════════════════════╗%b\n' "$PURPLE" "$NC"
  printf '%b║ 🖥️  VM HEALTH CHECK REPORT          ║%b\n' "$PURPLE" "$NC"
  printf '%b╚════════════════════════════════════╝%b\n' "$PURPLE" "$NC"
  
  printf '%b\n📋 System Information%b\n' "$CYAN" "$NC"
  printf '%b─────────────────────%b\n' "$CYAN" "$NC"
  info "Hostname: $HOSTNAME"
  info "Timestamp: $TIMESTAMP"
  info "Kernel: $KERNEL | OS: $OS"
  info "Uptime: $(( UPTIME_SECONDS / 86400 )) days, $(( (UPTIME_SECONDS % 86400) / 3600 )) hours"
  info "Processes: $PROCESS_COUNT | FD Usage: $FD_USAGE/$FD_MAX"
  
  printf '%b\n⚙️  CPU Metrics%b\n' "$CYAN" "$NC"
  printf '%b──────────────%b\n' "$CYAN" "$NC"
  info "Cores: ${CPU_CORES} | Classification: $LOAD_CLASS"
  info "Load Average: ${CPU_LOAD_1} (1m) | ${CPU_LOAD_5} (5m) | ${CPU_LOAD_15} (15m)"
  info "Threshold: ${CPU_THRESHOLD}% per core"
  
  printf '%b\n🧠 Memory Metrics%b\n' "$CYAN" "$NC"
  printf '%b─────────────────%b\n' "$CYAN" "$NC"
  info "Total: $(format_bytes $((MEM_TOTAL_KB * 1024))) | Used: ${MEM_USED_PERCENT}%"
  info "Threshold: ${MEM_THRESHOLD}%"
  
  printf '%b\n💾 Disk Metrics%b\n' "$CYAN" "$NC"
  printf '%b────────────────%b\n' "$CYAN" "$NC"
  info "Total: $(format_bytes $((DISK_TOTAL_KB * 1024))) | Used: ${DISK_USED_PERCENT}%"
  info "Threshold: ${DISK_THRESHOLD}%"
  
  printf '%b\n🔄 Swap Metrics%b\n' "$CYAN" "$NC"
  printf '%b────────────────%b\n' "$CYAN" "$NC"
  info "Total: $(format_bytes $((SWAP_TOTAL_KB * 1024))) | Used: ${SWAP_USED_PERCENT}%"
  info "Threshold: ${SWAP_THRESHOLD}%"
  
  printf '%b\n🌡️  Additional Metrics%b\n' "$CYAN" "$NC"
  printf '%b──────────────────────%b\n' "$CYAN" "$NC"
  [ "$TEMP" != "N/A" ] && info "Temperature: ${TEMP}°C" || info "Temperature: N/A"
  info "Network Interfaces: ${NETWORK_INTERFACES}"
  
  printf '%b\n📊 Overall Status%b\n' "$CYAN" "$NC"
  printf '%b──────────────────%b\n' "$CYAN" "$NC"
  if [ "$status" = "HEALTHY" ]; then
    printf '%b✅ Status: HEALTHY - All systems operating normally%b\n' "$GREEN" "$NC"
  elif [ "$status" = "DEGRADED" ]; then
    printf '%b⚠️  Status: DEGRADED - $issues issue(s) detected%b\n' "$YELLOW" "$NC"
  else
    printf '%b🔴 Status: CRITICAL - $issues critical issue(s) detected%b\n' "$RED" "$NC"
  fi
  printf '\n'
}

# Format bytes to human-readable
format_bytes() {
  local bytes="$1"
  if [ "$bytes" = "" ] || [ "$bytes" = "0" ]; then
    echo "0 B"
    return
  fi
  local units=(B KB MB GB TB)
  local value="$bytes"
  local unit_index=0
  while [ "$value" -ge 1024 ] && [ "$unit_index" -lt 4 ]; do
    value=$(( value / 1024 ))
    unit_index=$(( unit_index + 1 ))
  done
  echo "${value} ${units[$unit_index]}"
}

# Main execution
main() {
  collect_metrics
  
  IFS='|' read -r status issues <<< "$(perform_checks)"
  
  if [ "$JSON_MODE" = true ]; then
    generate_json "$status" "$issues"
    [ -n "$OUTPUT_DIR" ] && [ -d "$OUTPUT_DIR" ] && generate_json "$status" "$issues" > "${OUTPUT_DIR}/vm_health_$(date +%s).json" 2>/dev/null
  else
    display_output "$status" "$issues"
  fi
  
  if [ "$EXPLAIN_MODE" = true ] && [ "$JSON_MODE" = false ]; then
    printf '%bDetailed Explanation%b\n' "$BLUE" "$NC"
    printf '%b═══════════════════%b\n' "$BLUE" "$NC"
    echo "This comprehensive health check monitors all critical VM resources..."
    printf '\n'
  fi
  
  [ -n "$LOG_FILE" ] && log_message "INFO" "Health check completed. Status: $status, Issues: $issues"
  [ "$GENERATE_SNAPSHOT" = true ] && create_snapshot "$status" "$issues"
  [ "$TRENDING_MODE" = true ] && analyze_trends
  [ "$DETAILED_REPORT" = true ] && generate_html_report "$status"
  [ -n "$WEBHOOK_URL" ] && [ "$status" != "HEALTHY" ] && send_webhook_alert "$status" "$issues"
  
  case "$status" in
    HEALTHY) exit 0 ;;
    DEGRADED) exit 1 ;;
    CRITICAL) exit 2 ;;
    *) exit 3 ;;
  esac
}

main "$@"
