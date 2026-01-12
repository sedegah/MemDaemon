$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

. "$ScriptDir\ramd-core.ps1"
. "$ScriptDir\ramd-stats.ps1"

$Config = Get-Content "$ScriptDir\ramd.conf.json" | ConvertFrom-Json

$LogDir = Split-Path "$ScriptDir\$($Config.LogFile)"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

while ($true) {

    $before = Get-SystemMemoryStats
    $usage = [int](Get-Counter '\Memory\% Committed Bytes In Use').CounterSamples.CookedValue

    if ($usage -ge $Config.MaxMemoryUsagePercent) {

        Get-Process |
        Where-Object {
            $_.WorkingSet64 -gt 50MB -and
            $Config.ExcludeProcesses -notcontains $_.Name
        } |
        ForEach-Object { Trim-ProcessMemory $_ }

        Start-Sleep 2  # allow memory to settle

        $after = Get-SystemMemoryStats
        $freed = [math]::Round($after.FreeRAM_MB - $before.FreeRAM_MB, 2)

        $log = @"
[$(Get-Date)]
Trigger: ${usage}%
Freed RAM: ${freed} MB
Free Before: $($before.FreeRAM_MB) MB
Free After : $($after.FreeRAM_MB) MB
Used RAM  : $($after.UsedRAM_MB) MB
Commit    : $($after.Commit_MB) / $($after.CommitLimit_MB) MB
--------------------------------------
"@

        # Write to log file in the correct relative path
        Add-Content "$ScriptDir\$($Config.LogFile)" $log
    }

    Start-Sleep $Config.CheckIntervalSeconds
}
