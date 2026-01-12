# MemDaemon

**Automatic RAM Management Daemon for Windows 11**

MemDaemon is a PowerShell-based memory management tool designed to monitor system RAM usage and perform automated cleanup of unused memory. It works in the background like a daemon and provides both a CLI interface and automatic logging.

---

## Features

* Monitors RAM usage in real-time.
* Cleans unused memory when usage exceeds a configurable threshold.
* Provides “before and after” stats of used, free, and standby RAM.
* Logs cleanup activity to a file.
* CLI interface to manually check memory stats or trigger a cleanup.

---

## Requirements

* Windows 11
* PowerShell 5.1 or higher
* Administrator privileges for some cleanup operations

---

## File Structure

```
MemDaemon/
├── ramd.ps1              # Main CLI & service script
├── ramd-core.ps1         # Core memory cleanup functions
├── ramd-stats.ps1        # Functions to get system memory stats
├── ramd-cleaner-v2.ps1   # Cleaner module (MemReduct-style)
├── ramd.conf.json        # Optional configuration file (JSON)
└── logs/                 # Folder to store daemon logs
```

---

## Configuration

MemDaemon uses a JSON config file at `ramd.conf.json`. Example configuration:

```json
{
  "MaxMemoryUsagePercent": 75,
  "CheckIntervalSeconds": 10,
  "LogFile": "C:\\Users\\Kimat\\Desktop\\MemDaemon\\logs\\ramd-service.log",
  "ExcludeProcesses": ["explorer","powershell","svchost"],
  "MinProcessWorkingSetMB": 50
}
```

* `MaxMemoryUsagePercent` — RAM usage percentage threshold to trigger cleanup.
* `CheckIntervalSeconds` — How often (in seconds) the daemon checks memory usage.
* `LogFile` — Path to store cleanup logs.
* `ExcludeProcesses` — Processes to ignore during cleanup.
* `MinProcessWorkingSetMB` — Minimum memory a process must be using to be considered for trimming.

> If no config file exists, MemDaemon uses default values.

---

## Usage

### Run RAM Daemon in CLI

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\Kimat\Desktop\MemDaemon\ramd.ps1" status
```

Displays current memory statistics:

```
RAM Daemon Status
Total RAM : 24323.96 MB
Used RAM  : 9533.58 MB
Free RAM  : 14790.38 MB
Standby   : 14317.86 MB
Commit    : 14706.89 / 26780.34 MB
```

### Trigger Manual Cleanup

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\Kimat\Desktop\MemDaemon\ramd.ps1" clean
```

Sample output after cleanup:

```
RAM Cleanup Complete
------------------------------------
Before Cleanup:
  Total RAM  : 24323.96 MB
  Used RAM   : 7979.57 MB
  Free RAM   : 16344.39 MB
  Standby    : 14610.7 MB
  Commit     : 14396.3 / 26780.34 MB

After Cleanup:
  Used RAM   : 7997.32 MB
  Free RAM   : 16326.64 MB
  Standby    : 14600.55 MB
  Commit     : 14518.81 / 26780.34 MB
Trimmed Processes:
  chrome → 50 MB
  code   → 30 MB
```

---

## Logs

Cleanup events are logged automatically in the `logs` folder specified in `ramd.conf.json`. Each log contains:

* Timestamp of cleanup
* Memory usage before and after cleanup
* Freed RAM
* List of processes trimmed

---

## Notes

* Only PowerShell code and valid JSON should exist in the `ramd.conf.json`. Do not include PowerShell commands in the JSON file.
* Some memory cleanup operations may require administrator privileges.
* This project is a work-in-progress; future updates will improve cleaning efficiency and process selection.

