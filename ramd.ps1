param ($Command)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

. "$ScriptDir\ramd-core.ps1"
. "$ScriptDir\ramd-stats.ps1"
. "$ScriptDir\ramd-cleaner-v2.ps1"    

switch ($Command) {

    "status" {
        $s = Get-SystemMemoryStats
        Write-Host "RAM Daemon Status"
        Write-Host "Total RAM : $($s.TotalRAM_MB) MB"
        Write-Host "Used RAM  : $($s.UsedRAM_MB) MB"
        Write-Host "Free RAM  : $($s.FreeRAM_MB) MB"
        Write-Host "Standby   : $($s.StandbyMB) MB"
        Write-Host "Commit    : $($s.Commit_MB) / $($s.CommitLimit_MB) MB"
    }
 
    "clean" {
        $result = Optimize-ProcessMemoryStats -ClearStandbyMemory

        Write-Host "RAM Cleanup Complete"
        Write-Host "------------------------------------"
        Write-Host "Before Cleanup:"
        Write-Host "  Total RAM  : $($result.Before.TotalRAM_MB) MB"
        Write-Host "  Used RAM   : $($result.Before.UsedRAM_MB) MB"
        Write-Host "  Free RAM   : $($result.Before.FreeRAM_MB) MB"
        Write-Host "  Standby    : $($result.Before.StandbyMB) MB"
        Write-Host "  Commit     : $($result.Before.Commit_MB) / $($result.Before.CommitLimit_MB) MB"

        Write-Host "`nAfter Cleanup:"
        Write-Host "  Used RAM   : $($result.After.UsedRAM_MB) MB"
        Write-Host "  Free RAM   : $($result.After.FreeRAM_MB) MB"
        Write-Host "  Standby    : $($result.After.StandbyMB) MB"
        Write-Host "  Commit     : $($result.After.Commit_MB) / $($result.After.CommitLimit_MB) MB"
        Write-Host "  Total Freed: $($result.TotalFreedMB) MB"

        if ($result.ProcessesTrimmed.Count -gt 0) {
            Write-Host "`nTrimmed Processes:"
            $result.ProcessesTrimmed | ForEach-Object {
                Write-Host "  $($_.Process) → $($_.FreedMB) MB"
            }
        }
        Write-Host "------------------------------------"
    }

    default {
        Write-Host "RAM Daemon CLI"
        Write-Host "Commands:"
        Write-Host "  ramd status   → show system memory stats"
        Write-Host "  ramd clean    → perform manual RAM cleanup"
    }
}
