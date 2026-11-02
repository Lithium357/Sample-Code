# Myers shortest insert/delete edit script with complete path reconstruction.
# pwsh -NoProfile -File myers_diff.ps1
# Ordinal string tokens; no substitution primitive. O((N+M)D) search time,
# O(D^2) stored frontier trace. Inputs are capped to keep this demo bounded.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-MyersDiff([string[]]$Before, [string[]]$After) {
    $n = $Before.Count; $m = $After.Count
    if ($n + $m -gt 400) { throw 'Demo limit: 400 combined tokens' }
    $frontier = [System.Collections.Generic.Dictionary[int,int]]::new()
    $frontier[1] = 0
    $trace = [System.Collections.Generic.List[object]]::new()
    $distance = -1
    :search for ($d = 0; $d -le $n + $m; $d++) {
        $saved = [System.Collections.Generic.Dictionary[int,int]]::new($frontier)
        $trace.Add($saved)
        for ($k = -$d; $k -le $d; $k += 2) {
            if ($k -eq -$d -or ($k -ne $d -and $frontier[$k - 1] -lt $frontier[$k + 1])) {
                $x = $frontier[$k + 1]
            } else { $x = $frontier[$k - 1] + 1 }
            $y = $x - $k
            while ($x -lt $n -and $y -lt $m -and [string]::Equals($Before[$x], $After[$y], [StringComparison]::Ordinal)) {
                $x++; $y++
            }
            $frontier[$k] = $x
            if ($x -eq $n -and $y -eq $m) { $distance = $d; break search }
        }
    }
    if ($distance -lt 0) { throw 'No edit path found' }
    $edits = [System.Collections.Generic.List[object]]::new()
    $x = $n; $y = $m
    for ($d = $distance; $d -ge 0; $d--) {
        $old = $trace[$d]; $k = $x - $y
        if ($k -eq -$d -or ($k -ne $d -and $old[$k - 1] -lt $old[$k + 1])) { $previousK = $k + 1 }
        else { $previousK = $k - 1 }
        $previousX = $old[$previousK]; $previousY = $previousX - $previousK
        while ($x -gt $previousX -and $y -gt $previousY) {
            $x--; $y--; $edits.Add([pscustomobject]@{ Kind='Keep'; Value=$Before[$x] })
        }
        if ($d -gt 0) {
            if ($x -eq $previousX) { $y--; $edits.Add([pscustomobject]@{ Kind='Insert'; Value=$After[$y] }) }
            else { $x--; $edits.Add([pscustomobject]@{ Kind='Delete'; Value=$Before[$x] }) }
        }
    }
    $edits.Reverse()
    [pscustomobject]@{ Distance=$distance; Edits=$edits.ToArray() }
}

function Get-OracleDistance([string[]]$A, [string[]]$B) {
    # Independent quadratic DP, with substitution represented by delete+insert.
    $previous = [int[]]::new($B.Count + 1)
    for ($j=0; $j -le $B.Count; $j++) { $previous[$j] = $j }
    for ($i=1; $i -le $A.Count; $i++) {
        $current = [int[]]::new($B.Count + 1); $current[0] = $i
        for ($j=1; $j -le $B.Count; $j++) {
            if ([string]::Equals($A[$i-1],$B[$j-1],[StringComparison]::Ordinal)) { $current[$j]=$previous[$j-1] }
            else { $current[$j]=1+[Math]::Min($previous[$j],$current[$j-1]) }
        }
        $previous=$current
    }
    return $previous[$B.Count]
}
function Check-Diff([string[]]$A, [string[]]$B) {
    $answer = Get-MyersDiff $A $B
    if ($answer.Distance -ne (Get-OracleDistance $A $B)) { throw 'Nonminimal edit script' }
    $output = [System.Collections.Generic.List[string]]::new()
    $position=0; $changes=0
    foreach ($edit in $answer.Edits) {
        if ($edit.Kind -eq 'Keep' -or $edit.Kind -eq 'Delete') {
            if ($position -ge $A.Count -or -not [string]::Equals($A[$position],$edit.Value,[StringComparison]::Ordinal)) { throw 'Script consumes wrong token' }
            $position++
        }
        if ($edit.Kind -ne 'Delete') { $output.Add($edit.Value) }
        if ($edit.Kind -ne 'Keep') { $changes++ }
    }
    if ($position -ne $A.Count -or $changes -ne $answer.Distance -or $output.Count -ne $B.Count) { throw 'Incomplete edit script' }
    for ($i=0; $i -lt $B.Count; $i++) {
        if (-not [string]::Equals($output[$i],$B[$i],[StringComparison]::Ordinal)) { throw 'Script does not reconstruct target' }
    }
}
Check-Diff @() @()
Check-Diff @('a') @()
Check-Diff @() @('b')
Check-Diff @('A') @('a')
Check-Diff @('A','B','C','A','B','B','A') @('C','B','A','B','A','C')
[int]$seed=83
for ($trial=0; $trial -lt 400; $trial++) {
    $a=@(); $b=@()
    for ($i=0; $i -lt ($trial % 17); $i++) { $seed=($seed*251+17)%10007; $a += [string]($seed%4) }
    for ($i=0; $i -lt (($trial*7)%19); $i++) { $seed=($seed*251+17)%10007; $b += [string]($seed%4) }
    Check-Diff $a $b
}
Write-Output 'Myers diff: minimality, exact reconstruction, case sensitivity and 400 DP comparisons passed'
