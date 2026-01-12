<#
.SYNOPSIS
Advanced RAM cleanup with before/after stats (MemReduct style)
#>

function Optimize-ProcessMemoryStats {
    [CmdletBinding()]
    param (
        [switch]$ClearStandbyMemory
    )

    $Before = Get-SystemMemoryStats

    if ($ClearStandbyMemory) {
        try {
            Invoke-Expression "Clear-VMStandbyList" -ErrorAction SilentlyContinue
        } catch {}
    }

    $TrimmedProcesses = @()
    Get-Process | Where-Object {
        ($_.WorkingSet64 -gt 100MB) -and
        @("System","Idle","csrss","wininit","lsass","explorer","powershell","conhost","svchost") -notcontains $_.Name
    } | ForEach-Object {
        $Name = $_.Name
        $BeforeUsed = [math]::Round($_.WorkingSet64 / 1MB, 2)

        Clear-ProcessMemory $_
        Start-Sleep -Milliseconds 50

        $AfterUsed = [math]::Round($_.WorkingSet64 / 1MB, 2)
        $Freed = [math]::Round($BeforeUsed - $AfterUsed, 2)
        if ($Freed -gt 0) {
            $TrimmedProcesses += [PSCustomObject]@{
                Process = $Name
                FreedMB = $Freed
            }
        }
    }

    $After = Get-SystemMemoryStats
    $TotalFreed = [math]::Round($After.FreeRAM_MB - $Before.FreeRAM_MB, 2)

    [PSCustomObject]@{
        Before = $Before
        After = $After
        TotalFreedMB = $TotalFreed
        ProcessesTrimmed = $TrimmedProcesses
    }
}
