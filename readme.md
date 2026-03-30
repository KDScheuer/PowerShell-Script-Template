# PowerShell Script Bootstrap

A minimal, grab-and-go starting point for PowerShell scripts. Clone it, copy the template, and start writing logic — structured logging, log rotation, and startup diagnostics are already wired up.

---

## What's Included

| File | Purpose |
|------|---------|
| `template.ps1` | Starting point for any new script |
| `logger.ps1` | Logging module — dot-sourced by the template |

---

## Quick Start

```powershell
git clone https://github.com/KDScheuer/PowerShellScriptBootStrap.git
```

1. Copy `template.ps1` and rename it for your script
2. Update the comment-based help block at the top (`.SYNOPSIS`, `.DESCRIPTION`, etc.)
3. Set your log prefix, retention period, and minimum log level in `Initialize-Logging`
4. Write your logic inside the `try` block

---

## Logger

### Initialization

```powershell
. "$PSScriptRoot\logger.ps1"
Initialize-Logging -Prefix "my-script" -RetentionDays 7 -LogLevel "INFO" -ScriptPath $PSScriptRoot -ScriptStartTime $ScriptStartTime
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `Prefix` | Yes | Log file name prefix — e.g. `"my-script"` produces `my-script-20260329-T-083045.log` |
| `RetentionDays` | Yes | Number of days before old log files are deleted |
| `LogLevel` | Yes | Minimum level to write — entries below this are suppressed from both console and file |
| `ScriptPath` | No | Path logged at startup for diagnostics (pass `$PSScriptRoot`) |
| `ScriptStartTime` | No | Start time logged at startup (pass `$ScriptStartTime`) |

On initialization, the logger automatically writes:
- Script start time
- Hostname and executing user
- PowerShell version
- Script path

### Writing Logs

```powershell
Write-Log "Connecting to database." -Level "INFO"
Write-Log "Query returned $($results.Count) rows." -Level "DEBUG"
Write-Log "Config file not found, using defaults." -Level "WARN"
Write-Log "Failed to connect: $_" -Level "ERROR"
```

### Log Levels

Levels are ordered — setting `LogLevel "WARN"` suppresses `DEBUG`, `INFO`, and `NOTICE` from both console output and the log file.

| Level | Console Color | Use For |
|-------|--------------|---------|
| `DEBUG` | Dark Gray | Verbose diagnostics |
| `INFO` | White | General progress |
| `NOTICE` | Cyan | Notable milestones |
| `WARN` | Yellow | Non-fatal issues |
| `ERROR` | Dark Red | Recoverable errors |
| `FATAL` | Red | Unrecoverable failures |

### Log Output

```
[2026-03-29 08:30:45] [INFO] Script Start: 03/29/2026 08:30:45
[2026-03-29 08:30:45] [DEBUG] Running on: WORKSTATION01 as: jdoe
[2026-03-29 08:30:45] [DEBUG] PowerShell version: 5.1.19041.5247
[2026-03-29 08:30:45] [DEBUG] Script path: C:\Scripts\my-script
[2026-03-29 08:30:46] [INFO] Connecting to database.
[2026-03-29 08:30:46] [WARN] Config file not found, using defaults.
[2026-03-29 08:30:47] [INFO] Script finished. Duration: 2.13 seconds.
```

Log files are written to `.\logs\` relative to the script location and are automatically cleaned up based on `RetentionDays`.

---

## Exit Codes

`$ExitCode` is initialized to `0` and passed to `exit` at the end of `finally`, so Task Scheduler and other callers always receive an explicit code.

Set it in your `catch` block or anywhere in the `try` block where a failure condition is detected:

```powershell
catch {
    Write-Log "Error: $_" -Level "FATAL"
    $ExitCode = 1
}
```

Use distinct non-zero values if you need to differentiate failure types in the calling system.

---

## Structure

```
PowerShellScriptBootStrap/
├── logger.ps1       # Logging module
├── template.ps1     # Script template
└── logs/            # Created automatically at runtime (gitignored)
```
