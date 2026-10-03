# VM Health Checker - Advanced Edition

A comprehensive Bash script for monitoring virtual machine health with support for advanced features like JSON output, custom thresholds, email alerts, logging, trending analysis, and webhook integrations.

## 🌟 Features

### Core Monitoring
- ✅ CPU load and utilization tracking
- ✅ Memory usage and available resources
- ✅ Disk space usage on root filesystem
- ✅ Swap memory usage
- ✅ System uptime and process count
- ✅ Network interface detection
- ✅ System temperature monitoring
- ✅ File descriptor usage tracking
- ✅ Core process monitoring

### Advanced Analytics & Reporting
- 📊 **Trending Analysis** - Track metrics over 7/30/90 days
- 📈 **Performance Comparison** - Compare against historical averages
- 📉 **Health History** - View status history over time
- 🔬 **Snapshot Mode** - Automatic data collection for trending
- 📄 **HTML Reports** - Beautiful HTML reports with charts
- 🎨 **Interactive Dashboard** - Visual metric representation

### Integration & Alerts
- 📧 **Email Alerts** - Send notifications on issues
- 🔔 **Webhook Integration** - Slack/Teams/Discord alerts
- 📝 **Logging** - Persistent file logging
- 📦 **JSON Export** - Structured data for APIs
- 🔧 **Custom Thresholds** - Configurable alert levels
- 📋 **Report Generation** - Save timestamped reports

### Smart Features
- 🎯 **Multi-level Alerts** - HEALTHY, DEGRADED, CRITICAL
- 🎨 **Color-Coded Output** - Easy-to-read terminal display
- 📊 **Exit Codes** - Proper codes for scripting (0/1/2/3)
- 🔄 **Auto-Snapshot** - Automatic data collection
- 🧪 **Load Classification** - Normal/High load detection

## Installation

```bash
git clone https://github.com/akshigour12/vm-health-checker.git
cd vm-health-checker
chmod +x vm_health_check.sh
```

## Quick Start

```bash
# Simple health check
./vm_health_check.sh

# With detailed explanation
./vm_health_check.sh explain

# JSON output
./vm_health_check.sh --json

# With all advanced features
./vm_health_check.sh \
  --json \
  --snapshots /var/snapshots \
  --log /var/log/vm_health.log \
  --email admin@example.com \
  --alert-webhook https://hooks.slack.com/... \
  --threshold cpu=75 memory=85 disk=85
```

## Advanced Usage

### 1. Trending Analysis

```bash
# Analyze trends over 7 days (default)
./vm_health_check.sh --snapshots /var/snapshots --trending

# 30-day trend analysis
./vm_health_check.sh --snapshots /var/snapshots --trending 30d

# 90-day trend analysis
./vm_health_check.sh --snapshots /var/snapshots --trending 90d
```

Output shows:
- Average memory usage
- Peak memory usage
- Average disk usage
- Peak disk usage
- Number of samples collected

### 2. Snapshot Mode for Data Collection

```bash
# Collect snapshots automatically
./vm_health_check.sh --snapshots /var/snapshots

# Run in cron every 5 minutes
*/5 * * * * /path/to/vm_health_check.sh --snapshots /var/snapshots

# Then analyze trends later
./vm_health_check.sh --snapshots /var/snapshots --trending 7d
```

### 3. Webhook Integration (Slack/Teams/Discord)

```bash
# Send alerts to Slack
./vm_health_check.sh --alert-webhook https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Combine with other features
./vm_health_check.sh \
  --alert-webhook https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  --snapshots /var/snapshots \
  --threshold memory=75
```

### 4. Custom Thresholds

```bash
# Set individual thresholds
./vm_health_check.sh --threshold cpu=70 --threshold memory=80 --threshold disk=85

# Lower thresholds for stricter monitoring
./vm_health_check.sh --threshold cpu=60 memory=70 disk=75 swap=40
```

### 5. Email Alerts

```bash
# Send email when issues detected
./vm_health_check.sh --email admin@example.com

# With snapshot and logging
./vm_health_check.sh \
  --email admin@example.com \
  --log /var/log/vm_health.log \
  --snapshots /var/snapshots
```

### 6. Logging

```bash
# Log all checks to file
./vm_health_check.sh --log /var/log/vm_health.log

# View logs
tail -f /var/log/vm_health.log

# Parse logs for specific events
grep "CRITICAL" /var/log/vm_health.log
grep "Status:" /var/log/vm_health.log
```

### 7. Report Generation

```bash
# Save JSON reports
./vm_health_check.sh --json --output-dir /var/reports/vm_health

# Generate HTML reports
./vm_health_check.sh --detailed-report --output-dir /var/reports

# List all reports
ls -la /var/reports/vm_health/
```

### 8. Performance Comparison

```bash
# Compare current metrics against historical data
./vm_health_check.sh --performance-compare --snapshots /var/snapshots

# Shows percentage changes from average
```

### 9. Health History

```bash
# Display health status history
./vm_health_check.sh --health-history --snapshots /var/snapshots

# Shows timeline of status changes
```

## Complete Production Setup

```bash
#!/bin/bash
# /usr/local/bin/vm_monitor.sh

SCRIPT=/opt/vm-health-checker/vm_health_check.sh
SNAPSHOT_DIR=/var/lib/vm_health/snapshots
REPORT_DIR=/var/lib/vm_health/reports
LOG_FILE=/var/log/vm_health.log
WEBHOOK=https://hooks.slack.com/services/YOUR/WEBHOOK
EMAIL=ops-team@company.com

# Create directories
mkdir -p "$SNAPSHOT_DIR" "$REPORT_DIR"

# Run health check with all features
"$SCRIPT" \
  --snapshots "$SNAPSHOT_DIR" \
  --json \
  --output-dir "$REPORT_DIR" \
  --log "$LOG_FILE" \
  --email "$EMAIL" \
  --alert-webhook "$WEBHOOK" \
  --threshold cpu=75 memory=80 disk=85
```

### Crontab Setup

```bash
# Run every 5 minutes (data collection)
*/5 * * * * /usr/local/bin/vm_monitor.sh

# Analyze trends daily (at 2 AM)
0 2 * * * /opt/vm-health-checker/vm_health_check.sh --snapshots /var/lib/vm_health/snapshots --trending 7d --log /var/log/vm_health.log

# Generate reports weekly (every Sunday)
0 0 * * 0 /opt/vm-health-checker/vm_health_check.sh --detailed-report --output-dir /var/lib/vm_health/reports --snapshots /var/lib/vm_health/snapshots
```

## Metrics Explained

| Metric | Source | Threshold | Alert Level |
|--------|--------|-----------|-------------|
| CPU Load | `/proc/uptime` | 80% per core | DEGRADED |
| Memory Usage | `/proc/meminfo` | 80% | DEGRADED / 95% CRITICAL |
| Disk Usage | `df` | 80% | DEGRADED / 95% CRITICAL |
| Swap Usage | `/proc/meminfo` | 50% | DEGRADED |
| File Descriptors | `/proc/self/fd` | N/A | INFO |
| Temperature | `/sys/class/thermal/` | N/A | INFO |

## Exit Codes

- `0` - VM is HEALTHY
- `1` - VM is DEGRADED (warnings detected)
- `2` - VM is CRITICAL (critical issues detected)
- `3` - Unknown status

## Command Reference

```bash
./vm_health_check.sh explain                    # Detailed explanation
./vm_health_check.sh --json                    # JSON output
./vm_health_check.sh --log FILE                # Log to file
./vm_health_check.sh --threshold cpu=75       # Set threshold
./vm_health_check.sh --email EMAIL            # Email alerts
./vm_health_check.sh --output-dir DIR         # Save reports
./vm_health_check.sh --alert-webhook URL      # Webhook alerts
./vm_health_check.sh --trending [7d|30d|90d]  # Trending analysis
./vm_health_check.sh --performance-compare    # Compare to avg
./vm_health_check.sh --health-history         # Show history
./vm_health_check.sh --snapshots DIR          # Enable snapshots
./vm_health_check.sh --detailed-report        # HTML report
./vm_health_check.sh --help                   # Show help
```

## Troubleshooting

### Email not sending
```bash
which mail  # Verify mail is installed
systemctl status postfix  # Check mail service
echo "Test" | mail -s "Test" your@email.com  # Test
```

### Webhook alerts failing
```bash
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"test"}' YOUR_WEBHOOK_URL
```

### Permission issues
```bash
chmod +x vm_health_check.sh
sudo chown root:root vm_health_check.sh
sudo mv vm_health_check.sh /usr/local/bin/
```

## Performance Impact

- Minimal CPU usage (< 1%)
- Memory footprint: ~5-10MB
- Disk I/O: Negligible
- Safe for production use
- Can run every 5 minutes without impact

## Contributing

Contributions are welcome! Submit issues and pull requests on GitHub.

## License

MIT License - See LICENSE file

## Support

For issues, documentation, or feature requests, visit:
https://github.com/akshigour12/vm-health-checker
