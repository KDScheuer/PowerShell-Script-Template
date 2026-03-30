<#
.DESCRIPTION
    Logging module for standardized logging across scripts. Provides functions to initialize logging, 
    write log entries with levels, and rotate old logs based on retention policy.
.EXAMPLE
    .\logger.ps1
    Intialize-Logging -Prefix "my-script" -RetentionDays 14 -LogLevel "INFO"
.INPUTS
    - Prefix: String prefix for log file names (e.g., "my-script" results in "my-script-yyyyMMdd-T-HHmmss.log")
    - RetentionDays: Number of days to keep log files before deletion.
    - LogLevel: Minimum log level to write to both console and log file (DEBUG, INFO, NOTICE, WARN, ERROR, FATAL)
.OUTPUTS
    - Log file written to .\logs\<prefix>-yyyyMMdd-T-HHmmss.log
    - Console and file output of log entries at or above specified LogLevel
#>

function Initialize-Logging {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Prefix,

        [Parameter(Mandatory = $true)]
        [int]$RetentionDays,

        [Parameter(Mandatory = $true)]
        [ValidateSet("DEBUG", "INFO", "NOTICE", "WARN", "ERROR", "FATAL")]
        [string]$LogLevel,

        [Parameter(Mandatory = $false)]
        [string]$ScriptPath = "Unknown",

        [Parameter(Mandatory = $false)]
        [datetime]$ScriptStartTime = (Get-Date)
    )

    $script:LogFilePath          = "$PSScriptRoot\logs"
    $script:LogFileNamePrefix    = $Prefix
    $script:LogFileRetentionDays = $RetentionDays
    $script:ConsoleLogLevel      = $LogLevel
    $script:LogFilePattern       = "$Prefix-*.log"
    $script:LogFile              = Join-Path $script:LogFilePath "$Prefix-$(Get-Date -Format 'yyyyMMdd-T-HHmmss').log"

    try {
        if (-not (Test-Path $script:LogFilePath)) {
            New-Item -ItemType Directory -Path $script:LogFilePath | Out-Null
        }
        Add-Content -Path $script:LogFile -Value $null -ErrorAction Stop
    }
    catch {
        throw "Error initializing log file '$($script:LogFile)': $_"
    }

    Write-Log "Script Start: $ScriptStartTime" -Level "INFO"
    Write-Log "Running on: $env:COMPUTERNAME as: $env:USERNAME" -Level "DEBUG"
    Write-Log "PowerShell version: $($PSVersionTable.PSVersion)" -Level "DEBUG"
    Write-Log "Script path: $ScriptPath" -Level "DEBUG"
}

function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("DEBUG", "INFO", "NOTICE", "WARN", "ERROR", "FATAL")]
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry  = "[$Timestamp] [$Level] $Message"

    $logLevels      = @("DEBUG", "INFO", "NOTICE", "WARN", "ERROR", "FATAL")
    $currentIndex   = $logLevels.IndexOf($Level)
    $thresholdIndex = $logLevels.IndexOf($script:ConsoleLogLevel)

    if ($currentIndex -ge $thresholdIndex) {
        switch ($Level) {
            "DEBUG"  { Write-Host $LogEntry -ForegroundColor DarkGray }
            "INFO"   { Write-Host $LogEntry -ForegroundColor White }
            "NOTICE" { Write-Host $LogEntry -ForegroundColor Cyan }
            "WARN"   { Write-Host $LogEntry -ForegroundColor Yellow }
            "ERROR"  { Write-Host $LogEntry -ForegroundColor DarkRed }
            "FATAL"  { Write-Host $LogEntry -ForegroundColor Red }
        }

        try {
            Add-Content -Path $script:LogFile -Value $LogEntry
        }
        catch {
            throw "Error writing to log file '$($script:LogFile)': $_"
        }
    }
}

function Remove-OldLogs {
    try {
        $cutoff  = (Get-Date).AddDays(-$script:LogFileRetentionDays)
        $oldLogs = Get-ChildItem -Path $script:LogFilePath -File -Filter $script:LogFilePattern |
                   Where-Object { $_.LastWriteTime -lt $cutoff }

        if ($oldLogs) {
            $oldLogs | Remove-Item -Force
            Write-Log "Removed $($oldLogs.Count) log file(s) older than $($script:LogFileRetentionDays) days." -Level "DEBUG"
        }
    }
    catch {
        throw "Failed to rotate log files: $_"
    }
}
