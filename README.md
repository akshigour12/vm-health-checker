# VM Health Checker

A lightweight Bash script for checking the health of a Linux virtual machine. It inspects core system resources like CPU usage, memory consumption, disk usage, and swap usage, and reports whether the VM is healthy, degraded, or in a critical state.

It also supports an `explain` mode that prints a more detailed summary of the health check and what the results mean.

## Features

- CPU load monitoring
- Memory usage check
- Disk usage check
- Swap usage check
- Root filesystem accessibility check
- Core system process validation
- Detailed `explain` output
- JSON output support
- Logging support
- Custom thresholds
- Email and webhook alerts
- HTML and snapshot-based reporting

## Quick start

```bash
chmod +x vm_health_check.sh
./vm_health_check.sh
./vm_health_check.sh explain
```

## Usage

```bash
./vm_health_check.sh
./vm_health_check.sh explain
./vm_health_check.sh --json
./vm_health_check.sh --log /var/log/vm_health.log
./vm_health_check.sh --threshold cpu=75 memory=85 disk=85 swap=40
./vm_health_check.sh --email admin@example.com
./vm_health_check.sh --help
```

## What the script checks

The script evaluates the following indicators:

- CPU load average
- Memory utilization percentage
- Disk usage on `/`
- Swap usage percentage
- Root filesystem accessibility
- Basic system process health
- Optional additional metrics such as temperature and file descriptor usage

## Explain mode

When you pass `explain` as a command-line argument, the script prints a richer explanation of the current health state and how to interpret the results.

```bash
./vm_health_check.sh explain
```

Example output:

```text
VM Health Summary
=================
[INFO] Hostname: vm-prod-01
[INFO] CPU cores: 8
[INFO] CPU load average: 1.62, 1.48, 1.31
[OK] CPU load is within expected range.
[OK] Memory usage is healthy (42.31%).
[OK] Disk usage is healthy (58.00%).
[OK] Swap usage is within acceptable limits (10%).
[OK] Root filesystem is accessible.
[OK] Core system processes are running.

Overall VM Health Status: HEALTHY
The virtual machine appears to be operating normally.
```

## Advanced usage

### JSON output

```bash
./vm_health_check.sh --json
```

This outputs a structured JSON payload that can be used by monitoring tools, dashboards, or custom scripts.

### Logging

```bash
./vm_health_check.sh --log /var/log/vm_health.log
```

### Custom thresholds

```bash
./vm_health_check.sh --threshold cpu=70 memory=80 disk=85 swap=40
```

### Email alerting

```bash
./vm_health_check.sh --email admin@example.com
```

### Webhook alerting

```bash
./vm_health_check.sh --alert-webhook https://hooks.slack.com/services/your/webhook/url
```

### Snapshot and trend analysis

```bash
./vm_health_check.sh --snapshots /var/lib/vm_health/snapshots --trending 7d
```

This allows you to collect health snapshots over time and analyze trends such as average memory usage or peak disk usage.

### HTML report generation

```bash
./vm_health_check.sh --detailed-report --output-dir /var/reports/vm-health
```

This creates a readable report for documentation or operational review.

## Exit codes

The script uses standard exit codes for automation:

- `0` = HEALTHY
- `1` = DEGRADED
- `2` = CRITICAL
- `3` = Unknown or unsupported status

## Requirements

The script is primarily intended for Linux-based systems and expects standard utilities such as:

- `bash`
- `grep`
- `awk`
- `sed`
- `df`
- `ps`
- `nproc`

For some advanced features, optional commands may be required, including:

- `mail` for email alerts
- `curl` for webhook notifications
- `systemctl` for service checks (if you extend the script)

## Example cron setup

```bash
# Run the check every 5 minutes
*/5 * * * * /path/to/vm_health_check.sh --log /var/log/vm_health.log
```

## Troubleshooting

### Permission denied

```bash
chmod +x vm_health_check.sh
```

### No output or script fails on Linux minimal systems

Make sure the system has the required utilities installed:

```bash
which bash awk grep df ps nproc
```

### Email alerts not sending

Check whether `mail` is installed and configured:

```bash
which mail
```

## License

MIT License

## Repository

https://github.com/akshigour12/vm-health-checker
