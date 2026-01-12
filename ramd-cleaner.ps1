<#
.SYNOPSIS
Advanced RAM cleanup module for MemDaemon
#>

$Global:SafeProcesses = @(
    "System", "Idle", "csrss", "wininit", "lsass",
    "explorer", "powershell", "conhost", "svchost"
)

$Global:MinTrimMB = 100

function Clear-StandbyMemory {
    try {
        
        Invoke-Expression "Clear-VMStandbyList" -ErrorAction SilentlyContinue
    } catch {
        Write-Verbose "Could not clear standby memory: $_"
    }
}

function Optimize-ProcessMemory {
    [CmdletBinding()]
    param (
        [switch]$ClearStandbyMemorySwitch
    )

    if ($ClearStandbyMemorySwitch) {
        Clear-StandbyMemory
    }

    $BeforeStats = Get-SystemMemoryStats
    $FreedProcesses = @()

    Get-Process | Where-Object {
        ($_.WorkingSet64 -gt ($Global:MinTrimMB * 1MB)) -and
        ($Global:SafeProcesses -notcontains $_.Name)
    } | ForEach-Object {
        $ProcessName = $_.Name
        $UsedBefore = [math]::Round($_.WorkingSet64 / 1MB, 2)

        Clear-ProcessMemory $_
        Start-Sleep -Milliseconds 100

        $UsedAfter = [math]::Round($_.WorkingSet64 / 1MB, 2)
        $Freed = [math]::Round($UsedBefore - $UsedAfter, 2)

        if ($Freed -gt 0) {
            $FreedProcesses += [PSCustomObject]@{
                Process = $ProcessName
                FreedMB = $Freed
            }
        }
    }

    $AfterStats = Get-SystemMemoryStats
    $TotalFreed = [math]::Round($AfterStats.FreeRAM_MB - $BeforeStats.FreeRAM_MB, 2)

    return [PSCustomObject]@{
        TotalFreedMB     = $TotalFreed
        FreeBeforeMB     = $BeforeStats.FreeRAM_MB
        FreeAfterMB      = $AfterStats.FreeRAM_MB
        UsedAfterMB      = $AfterStats.UsedRAM_MB
        ProcessesTrimmed = $FreedProcesses
    }
}
