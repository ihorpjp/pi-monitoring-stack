# 🖥️ System Health Monitor

A Bash script that checks the health of your Linux system and alerts you when something needs attention.

---

## What It Checks

| Section | What it monitors |
|---------|-----------------|
| **System Info** | OS, kernel version, uptime, current user |
| **CPU** | Usage %, core count, load average (1m / 5m / 15m) |
| **Memory** | RAM used %, MB used / total / free, swap usage |
| **Disk** | Each mounted filesystem — used %, free space |
| **Network** | Active interfaces, internet connectivity, DNS |
| **Processes** | Top 5 by CPU usage |
| **Open Ports** | All listening ports and their processes |
| **Security** | Failed SSH login attempts in last 24h + top attacker IPs |

---

## Quick Start

```bash
# Basic run
bash check_system.sh

# Save output to log file (~/lab/logs/system_YYYY-MM-DD.log)
bash check_system.sh --log

# Only show warnings and alerts (hide OK lines)
bash check_system.sh --quiet

# Both flags together
bash check_system.sh --log --quiet
```

---

## Example Output

```
╔══════════════════════════════════════════╗
║         System Health Monitor            ║
║         by Ihor Bezruchko                ║
╚══════════════════════════════════════════╝
  Time: 2025-02-27 14:32:01
  Host: ihor-laptop

━━━  SYSTEM INFO  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [INFO]     OS:      Ubuntu 22.04.3 LTS
  [INFO]     Kernel:  5.15.0-91-generic
  [INFO]     Uptime:  up 2 hours, 14 minutes
  [INFO]     User:    ihor

━━━  CPU  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [OK]       CPU Usage: 12%
  [INFO]     Cores:   4 logical CPU(s)
  [INFO]     Load:    0.45 0.31 0.28 (1m 5m 15m)

━━━  MEMORY  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [WARNING]  RAM Usage: 78% (threshold: 75%)
  [INFO]     RAM:     3124MB used / 3987MB total / 612MB free

━━━  DISK  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [OK]       Disk /: 45% used
             Used: 22G  |  Free: 27G

━━━  SECURITY — FAILED LOGINS (last 24h)  ━━━━━━━
  [CRITICAL] Failed login attempts: 47
  Top IPs:
    192.168.1.105 → 23 attempts
    10.0.0.44     → 14 attempts
```

---

## Alert Levels

```
[OK]        Value is within normal range — green
[WARNING]   Value is approaching the limit — yellow
[CRITICAL]  Value exceeded the critical threshold — red
```

---

## Thresholds

You can change the alert thresholds at the top of the script:

```bash
CPU_WARN=70     # % CPU — warning level
CPU_CRIT=90     # % CPU — critical level
MEM_WARN=75     # % RAM — warning level
MEM_CRIT=90     # % RAM — critical level
DISK_WARN=80    # % disk — warning level
DISK_CRIT=95    # % disk — critical level
```

---

## Automate with Cron

Run the check automatically every 30 minutes and save to log:

```bash
# Open crontab
crontab -e

# Add this line:
*/30 * * * * bash ~/lab/scripts/linux/check_system.sh --log --quiet
```

This will silently monitor your system and only log warnings and alerts.

---

## New vs setup_lab.sh

| Feature | setup_lab.sh | check_system.sh |
|---------|-------------|-----------------|
| Arguments (`--log`, `--quiet`) | ✗ | ✓ |
| Thresholds with alert levels | ✗ | ✓ |
| Multiple sections | ✗ | ✓ |
| Log file output | ✗ | ✓ |
| Security checks | ✗ | ✓ |
| Cron-ready | ✗ | ✓ |

---

## Project Roadmap

- [x] CPU, memory, disk monitoring
- [x] Network and DNS checks
- [x] Failed login detection with top IPs
- [x] `--log` flag for file output
- [x] `--quiet` flag for cron usage
- [x] Color-coded alert levels
- [ ] `--json` flag — output as JSON for parsing
- [ ] Email alert when critical threshold is hit
- [ ] Telegram bot notification
- [ ] HTML report generation

---

## Author

**Ihor Bezruchko**
Junior IT Support | Cybersecurity Enthusiast | Luxembourg

- LinkedIn: [linkedin.com/in/ihorbezruchko](https://linkedin.com/in/ihorbezruchko)
- GitHub: [github.com/ihorbezruchko](https://github.com/ihorbezruchko)

---

## License

MIT — free to use, modify, and share.
