$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

. "$ScriptDir\ramd-core.ps1"
. "$ScriptDir\ramd-stats.ps1"

$defaultConfig = [PSCustomObject]@{
    MaxMemoryUsagePercent = 75
    CheckIntervalSeconds  = 10
    LogFile               = 'logs/ramd-service.log'
    ExcludeProcesses      = @('System', 'Idle', 'csrss', 'wininit', 'lsass', 'explorer', 'powershell', 'conhost', 'svchost')
    MinProcessWorkingSetMB = 50
}

function Get-RamdConfig {
    param([string]$ConfigPath)

    if (-not (Test-Path $ConfigPath)) {
        Write-Warning "Config not found at '$ConfigPath'. Using default configuration."
        return $defaultConfig
    }

    try {
        $rawConfig = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Warning "Config at '$ConfigPath' is invalid JSON. Using default configuration."
        return $defaultConfig
    }

    [PSCustomObject]@{
        MaxMemoryUsagePercent = if ($rawConfig.MaxMemoryUsagePercent) { [int]$rawConfig.MaxMemoryUsagePercent } else { $defaultConfig.MaxMemoryUsagePercent }
        CheckIntervalSeconds  = if ($rawConfig.CheckIntervalSeconds) { [int]$rawConfig.CheckIntervalSeconds } else { $defaultConfig.CheckIntervalSeconds }
        LogFile               = if ($rawConfig.LogFile) { [string]$rawConfig.LogFile } else { $defaultConfig.LogFile }
        ExcludeProcesses      = if ($rawConfig.ExcludeProcesses) { @($rawConfig.ExcludeProcesses) } else { $defaultConfig.ExcludeProcesses }
        MinProcessWorkingSetMB = if ($rawConfig.MinProcessWorkingSetMB) { [int]$rawConfig.MinProcessWorkingSetMB } else { $defaultConfig.MinProcessWorkingSetMB }
    }
}

function Resolve-RamdLogPath {
    param(
        [string]$BasePath,
        [string]$ConfiguredLogPath
    )

    if ([System.IO.Path]::IsPathRooted($ConfiguredLogPath)) {
        return $ConfiguredLogPath
    }

    return Join-Path $BasePath $ConfiguredLogPath
}

$configPath = Join-Path $ScriptDir 'ramd.conf.json'
$Config = Get-RamdConfig -ConfigPath $configPath
$logPath = Resolve-RamdLogPath -BasePath $ScriptDir -ConfiguredLogPath $Config.LogFile
$logDir = Split-Path -Path $logPath -Parent

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

while ($true) {
    try {
        $before = Get-SystemMemoryStats
        $usage = [int](Get-Counter '\Memory\% Committed Bytes In Use').CounterSamples.CookedValue

        if ($usage -ge $Config.MaxMemoryUsagePercent) {
            Get-Process |
                Where-Object {
                    $_.WorkingSet64 -gt ($Config.MinProcessWorkingSetMB * 1MB) -and
                    $Config.ExcludeProcesses -notcontains $_.Name
                } |
                ForEach-Object { Clear-ProcessMemory $_ }

            Start-Sleep -Seconds 2

            $after = Get-SystemMemoryStats
            $freed = [math]::Round($after.FreeRAM_MB - $before.FreeRAM_MB, 2)

            $log = @"
[$(Get-Date -Format 's')]
Trigger Usage: ${usage}%
Freed RAM: ${freed} MB
Free Before: $($before.FreeRAM_MB) MB
Free After : $($after.FreeRAM_MB) MB
Used RAM  : $($after.UsedRAM_MB) MB
Commit    : $($after.Commit_MB) / $($after.CommitLimit_MB) MB
--------------------------------------
"@

            Add-Content -Path $logPath -Value $log
        }
    }
    catch {
        Add-Content -Path $logPath -Value "[$(Get-Date -Format 's')] ERROR: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds $Config.CheckIntervalSeconds
}
