function Get-SystemMemoryStats {
    # Get OS memory info
    $os = Get-CimInstance Win32_OperatingSystem

    $totalMB = [math]::Round($os.TotalVisibleMemorySize / 1024, 2)
    $freeMB  = [math]::Round($os.FreePhysicalMemory / 1024, 2)
    $usedMB  = [math]::Round($totalMB - $freeMB, 2)

    # Get commit counters
    $commitCounter = Get-Counter '\Memory\Committed Bytes'
    $commitLimitCounter = Get-Counter '\Memory\Commit Limit'

    $commitMB = [math]::Round($commitCounter.CounterSamples.CookedValue / 1MB, 2)
    $commitLimitMB = [math]::Round($commitLimitCounter.CounterSamples.CookedValue / 1MB, 2)

    # Optional: get standby/cached memory
    $standbyMB = 0
    try {
        $standbyCounter = Get-Counter '\Memory\Standby Cache Normal Priority Bytes'
        $standbyMB = [math]::Round($standbyCounter.CounterSamples.CookedValue / 1MB, 2)
    } catch {}

    [PSCustomObject]@{
        TotalRAM_MB     = $totalMB
        UsedRAM_MB      = $usedMB
        FreeRAM_MB      = $freeMB
        Commit_MB       = $commitMB
        CommitLimit_MB  = $commitLimitMB
        StandbyMB       = $standbyMB
    }
}
