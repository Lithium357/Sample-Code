# Residual-network minimum-cost flow with Bellman-Ford augmenting paths.
# pwsh -NoProfile -File min_cost_flow.ps1
# Integral capacities/costs; small graphs only. Reachable negative cycles are
# rejected rather than silently returning a nonoptimal answer.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

class FlowEdge {
    [int]$To
    [int]$Reverse
    [long]$Capacity
    [long]$Cost
    FlowEdge([int]$to, [int]$reverse, [long]$capacity, [long]$cost) {
        $this.To = $to; $this.Reverse = $reverse
        $this.Capacity = $capacity; $this.Cost = $cost
    }
}

function New-Network([int]$Count) {
    if ($Count -lt 2) { throw 'At least two vertices required' }
    $graph = [System.Collections.Generic.List[FlowEdge][]]::new($Count)
    for ($i = 0; $i -lt $Count; $i++) {
        $graph[$i] = [System.Collections.Generic.List[FlowEdge]]::new()
    }
    # Unary comma prevents PowerShell from enumerating the array as output.
    return ,$graph
}

function Add-Arc($Graph, [int]$From, [int]$To, [long]$Capacity, [long]$Cost) {
    if ($From -lt 0 -or $To -lt 0 -or $From -ge $Graph.Length -or $To -ge $Graph.Length) { throw 'Invalid vertex' }
    if ($From -eq $To -or $Capacity -lt 0 -or [Math]::Abs($Cost) -gt 1000000 -or $Capacity -gt 1000000) { throw 'Invalid arc' }
    $forward = [FlowEdge]::new($To, $Graph[$To].Count, $Capacity, $Cost)
    $reverse = [FlowEdge]::new($From, $Graph[$From].Count, 0, -$Cost)
    $Graph[$From].Add($forward)
    $Graph[$To].Add($reverse)
}

function Send-Flow($Graph, [int]$Source, [int]$Sink, [long]$Demand) {
    $count = $Graph.Length
    if ($Source -eq $Sink -or $Source -lt 0 -or $Sink -lt 0 -or $Source -ge $count -or $Sink -ge $count -or $Demand -lt 0) { throw 'Invalid flow request' }
    [long]$flow = 0; [long]$cost = 0
    [long]$infinity = 1000000000000000
    while ($flow -lt $Demand) {
        $distance = [long[]]::new($count)
        $previousVertex = [int[]]::new($count)
        $previousEdge = [int[]]::new($count)
        for ($i = 0; $i -lt $count; $i++) { $distance[$i] = $infinity; $previousVertex[$i] = -1 }
        $distance[$Source] = 0
        for ($pass = 0; $pass -lt $count; $pass++) {
            $changed = $false
            for ($u = 0; $u -lt $count; $u++) {
                if ($distance[$u] -eq $infinity) { continue }
                for ($j = 0; $j -lt $Graph[$u].Count; $j++) {
                    $edge = $Graph[$u][$j]
                    if ($edge.Capacity -gt 0 -and $distance[$edge.To] -gt $distance[$u] + $edge.Cost) {
                        $distance[$edge.To] = $distance[$u] + $edge.Cost
                        $previousVertex[$edge.To] = $u; $previousEdge[$edge.To] = $j
                        $changed = $true
                    }
                }
            }
            if (-not $changed) { break }
            if ($pass -eq $count - 1) { throw 'Reachable negative-cost cycle' }
        }
        if ($distance[$Sink] -eq $infinity) { break }
        [long]$amount = $Demand - $flow
        for ($v = $Sink; $v -ne $Source; $v = $previousVertex[$v]) {
            if ($previousVertex[$v] -lt 0) { throw 'Broken predecessor chain' }
            $edge = $Graph[$previousVertex[$v]][$previousEdge[$v]]
            $amount = [Math]::Min($amount, $edge.Capacity)
        }
        for ($v = $Sink; $v -ne $Source; $v = $previousVertex[$v]) {
            $u = $previousVertex[$v]
            $edge = $Graph[$u][$previousEdge[$v]]
            $edge.Capacity -= $amount
            $Graph[$v][$edge.Reverse].Capacity += $amount
        }
        $flow += $amount; $cost += $amount * $distance[$Sink]
    }
    [pscustomobject]@{ Flow = $flow; Cost = $cost; Satisfied = ($flow -eq $Demand) }
}

function Assert-True([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }

# Assignment network: greedy first assignment costs 1, but its locally cheap
# choice must later be undone through a reverse arc to avoid a cost-100 edge.
$g = New-Network 6
Add-Arc $g 0 1 1 0; Add-Arc $g 0 2 1 0
Add-Arc $g 1 3 1 1; Add-Arc $g 1 4 1 2
Add-Arc $g 2 3 1 2; Add-Arc $g 2 4 1 100
Add-Arc $g 3 5 1 0; Add-Arc $g 4 5 1 0
$answer = Send-Flow $g 0 5 2
Assert-True ($answer.Satisfied -and $answer.Cost -eq 4) 'Residual rerouting failed'

$g = New-Network 3
Add-Arc $g 0 1 2 -3; Add-Arc $g 1 2 2 5
$answer = Send-Flow $g 0 2 3
Assert-True ($answer.Flow -eq 2 -and $answer.Cost -eq 4 -and -not $answer.Satisfied) 'Partial flow failed'
$zero = Send-Flow $g 0 2 0
Assert-True ($zero.Flow -eq 0 -and $zero.Cost -eq 0) 'Zero demand failed'

# Exhaustively compare all 2x2 assignment costs in a bounded family.
for ($a = 0; $a -lt 4; $a++) {
    for ($b = 0; $b -lt 4; $b++) {
        for ($c = 0; $c -lt 4; $c++) {
            for ($d = 0; $d -lt 4; $d++) {
                $g = New-Network 6
                Add-Arc $g 0 1 1 0; Add-Arc $g 0 2 1 0
                Add-Arc $g 1 3 1 $a; Add-Arc $g 1 4 1 $b
                Add-Arc $g 2 3 1 $c; Add-Arc $g 2 4 1 $d
                Add-Arc $g 3 5 1 0; Add-Arc $g 4 5 1 0
                $answer = Send-Flow $g 0 5 2
                Assert-True ($answer.Flow -eq 2 -and $answer.Cost -eq [Math]::Min($a + $d, $b + $c)) 'Assignment oracle mismatch'
            }
        }
    }
}
$g = New-Network 4
Add-Arc $g 0 1 1 0; Add-Arc $g 1 2 1 -2; Add-Arc $g 2 1 1 0; Add-Arc $g 2 3 1 0
$rejected = $false
try { $null = Send-Flow $g 0 3 1 } catch { $rejected = $_.Exception.Message -like '*negative-cost cycle*' }
Assert-True $rejected 'Negative-cycle detection failed'
Write-Output 'Min-cost flow: reverse arcs, partial flow, 256 oracle assignments and negative cycles passed'
