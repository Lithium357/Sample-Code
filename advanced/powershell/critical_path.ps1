# Critical-path scheduling for a DAG, with earliest/latest times and float.
# pwsh -NoProfile -File critical_path.ps1
# Unlimited resources are assumed: this is precedence scheduling, not a
# resource-constrained project optimizer. Durations are nonnegative integers.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-CriticalPlan([object[]]$Tasks) {
    if ($Tasks.Count -gt 1000) { throw 'At most 1000 tasks supported' }
    $byId = [System.Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
    $children = [System.Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
    $degree = [System.Collections.Generic.Dictionary[string,int]]::new([StringComparer]::Ordinal)
    foreach ($task in $Tasks) {
        if ([string]::IsNullOrEmpty($task.Id) -or $byId.ContainsKey($task.Id)) { throw 'Empty or duplicate task id' }
        if ($task.Duration -isnot [int] -or $task.Duration -lt 0 -or $task.Duration -gt 1000000) { throw 'Invalid duration' }
        $byId.Add($task.Id, $task)
        $children.Add($task.Id, [System.Collections.Generic.List[string]]::new())
        $degree.Add($task.Id, @($task.Depends).Count)
    }
    foreach ($task in $Tasks) {
        $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($dependency in $task.Depends) {
            if (-not $byId.ContainsKey($dependency) -or -not $seen.Add($dependency)) { throw 'Missing or repeated dependency' }
            $children[$dependency].Add($task.Id)
        }
    }
    $ready = [System.Collections.Generic.SortedSet[string]]::new([StringComparer]::Ordinal)
    foreach ($task in $Tasks) { if ($degree[$task.Id] -eq 0) { $null = $ready.Add($task.Id) } }
    $order = [System.Collections.Generic.List[string]]::new()
    $earliest = [System.Collections.Generic.Dictionary[string,long]]::new([StringComparer]::Ordinal)
    $finish = [System.Collections.Generic.Dictionary[string,long]]::new([StringComparer]::Ordinal)
    [long]$project = 0
    while ($ready.Count -gt 0) {
        $id = $ready.Min; $null = $ready.Remove($id); $order.Add($id)
        [long]$start = 0
        foreach ($dependency in $byId[$id].Depends) { $start = [Math]::Max($start, $finish[$dependency]) }
        $earliest[$id] = $start
        $finish[$id] = $start + $byId[$id].Duration
        $project = [Math]::Max($project, $finish[$id])
        foreach ($child in $children[$id]) { $degree[$child]--; if ($degree[$child] -eq 0) { $null = $ready.Add($child) } }
    }
    if ($order.Count -ne $Tasks.Count) { throw 'Dependency cycle' }
    $latest = [System.Collections.Generic.Dictionary[string,long]]::new([StringComparer]::Ordinal)
    for ($i = $order.Count - 1; $i -ge 0; $i--) {
        $id = $order[$i]
        [long]$end = $project
        foreach ($child in $children[$id]) { $end = [Math]::Min($end, $latest[$child]) }
        $latest[$id] = $end - $byId[$id].Duration
    }
    $rows = @(
        foreach ($id in $order) {
            [pscustomobject]@{ Id=$id; EarliestStart=$earliest[$id]; EarliestFinish=$finish[$id]
                LatestStart=$latest[$id]; Float=$latest[$id]-$earliest[$id]
                Critical=($latest[$id] -eq $earliest[$id]) }
        }
    )
    [pscustomobject]@{ Duration=$project; Tasks=$rows }
}

function Require([bool]$Value, [string]$Message) { if (-not $Value) { throw $Message } }
function Task([string]$Id, [int]$Duration, [string[]]$Depends=@()) {
    [pscustomobject]@{ Id=$Id; Duration=$Duration; Depends=$Depends }
}
$plan = Get-CriticalPlan @((Task A 3), (Task B 2 @('A')), (Task C 5 @('A')), (Task D 1 @('B','C')))
Require ($plan.Duration -eq 9) 'Wrong project duration'
$indexed = @{}; foreach ($row in $plan.Tasks) { $indexed[$row.Id] = $row }
Require ($indexed.B.Float -eq 3 -and -not $indexed.B.Critical) 'Wrong float'
Require ($indexed.C.Critical -and $indexed.D.EarliestStart -eq 8) 'Wrong critical chain'
Require ((Get-CriticalPlan @()).Duration -eq 0) 'Empty project'

# Every small random DAG uses increasing numeric ids, enabling an independent
# direct recurrence oracle. Check both ends of every precedence constraint.
[int]$seed = 43
for ($trial = 0; $trial -lt 100; $trial++) {
    $tasks = @(); $oracle = @{}; [long]$maximum = 0
    for ($i = 0; $i -lt 10; $i++) {
        $seed = ($seed * 251 + 17) % 10007
        $duration = $seed % 7; $dependencies = @(); [long]$start = 0
        for ($j = 0; $j -lt $i; $j++) {
            $seed = ($seed * 251 + 17) % 10007
            if ($seed % 4 -eq 0) { $dependencies += "t$j"; $start = [Math]::Max($start, $oracle["t$j"]) }
        }
        $tasks += Task "t$i" $duration $dependencies
        $oracle["t$i"] = $start + $duration
        $maximum = [Math]::Max($maximum, $oracle["t$i"])
    }
    $plan = Get-CriticalPlan $tasks
    Require ($plan.Duration -eq $maximum) 'Oracle duration mismatch'
    $indexed = @{}; foreach ($row in $plan.Tasks) { $indexed[$row.Id] = $row }
    foreach ($task in $tasks) {
        $row = $indexed[$task.Id]
        Require ($row.EarliestFinish -eq $oracle[$task.Id] -and $row.Float -ge 0) 'Invalid task window'
        foreach ($dependency in $task.Depends) {
            Require ($row.EarliestStart -ge $indexed[$dependency].EarliestFinish) 'Earliest precedence broken'
            $parent = $indexed[$dependency]
            $parentDuration = $parent.EarliestFinish - $parent.EarliestStart
            Require ($row.LatestStart -ge $parent.LatestStart + $parentDuration) 'Latest precedence broken'
        }
    }
}
$rejected = $false
try { $null = Get-CriticalPlan @((Task A 1 @('B')), (Task B 1 @('A'))) } catch { $rejected = $_.Exception.Message -eq 'Dependency cycle' }
Require $rejected 'Cycle was accepted'
Write-Output 'Critical path: forward/backward windows, float, 100 DAG oracles and cycle rejection passed'
