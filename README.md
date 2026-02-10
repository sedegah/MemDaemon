# MemDaemon

**Automatic RAM Management Daemon for Windows 11**

MemDaemon is a PowerShell-based memory management tool designed to monitor system RAM usage and perform automated cleanup of unused memory. It runs in the background like a daemon and writes activity logs for observability.

---

## Features

* Monitors RAM usage in real-time.
* Cleans process working sets when memory usage exceeds a configurable threshold.
* Provides before/after memory stats (used, free, standby, and commit).
* Logs cleanup activity to a configurable log file.
* Supports configurable exclusions and minimum process memory size.

---

## Requirements

* Windows 11
* PowerShell 5.1 or higher
* Administrator privileges for some cleanup operations

---

## File Structure

```text
MemDaemon/
├── ramd-core.ps1         # Core process memory trim functions
├── ramd-stats.ps1        # Functions to retrieve system memory stats
├── ramd-cleaner.ps1      # Manual cleanup function with before/after output
├── ramd-service.ps1      # Background daemon loop
├── ramd.conf.json        # Configuration file (valid JSON)
└── logs/                 # Created automatically for daemon logs
```

---

## Configuration

MemDaemon reads settings from `ramd.conf.json`.

```json
{
  "MaxMemoryUsagePercent": 75,
  "CheckIntervalSeconds": 10,
  "LogFile": "logs/ramd-service.log",
  "ExcludeProcesses": ["System", "Idle", "csrss", "wininit", "lsass", "explorer", "powershell", "conhost", "svchost"],
  "MinProcessWorkingSetMB": 50
}
```

* `MaxMemoryUsagePercent` — threshold to trigger cleanup.
* `CheckIntervalSeconds` — daemon check interval in seconds.
* `LogFile` — relative or absolute path for service logs.
* `ExcludeProcesses` — process names ignored during cleanup.
* `MinProcessWorkingSetMB` — minimum process working set to be eligible for trimming.

If the config file is missing or invalid, the service falls back to built-in defaults.

---

## Usage

### Start Daemon Loop

```powershell
powershell -ExecutionPolicy Bypass -File "C:\path\to\MemDaemon\ramd-service.ps1"
```

The daemon checks memory usage every `CheckIntervalSeconds` and trims eligible processes when usage crosses `MaxMemoryUsagePercent`.

### Run Manual Cleanup

```powershell
powershell -ExecutionPolicy Bypass -Command ". 'C:\path\to\MemDaemon\ramd-core.ps1'; . 'C:\path\to\MemDaemon\ramd-stats.ps1'; . 'C:\path\to\MemDaemon\ramd-cleaner.ps1'; Optimize-ProcessMemoryStats"
```

---

## Logs

Cleanup events are appended to the configured `LogFile` and include:

* Timestamp
* Trigger memory usage
* Free memory before/after
* Commit usage snapshot
* Any daemon loop errors

---

## Notes

* Keep `ramd.conf.json` valid JSON only.
* Some memory cleanup operations may require administrator privileges.
* Process trimming behavior can vary depending on process protections and Windows policies.
