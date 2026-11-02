# Greedy coin count.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: amount >= 0; minimum number of US 1,5,10,25 coins.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_amount)
    $v_count = [long][Math]::Truncate(($v_amount) / (25))
    $v_amount = ($v_amount % 25)
    $v_count = ($v_count + [long][Math]::Truncate(($v_amount) / (10)))
    $v_amount = ($v_amount % 10)
    $v_count = ($v_count + [long][Math]::Truncate(($v_amount) / (5)))
    $v_amount = ($v_amount % 5)
    return ($v_count + $v_amount)
}

if ((Invoke-Example 0) -ne 0) { throw "greedy_coin_count fixture 1: (0,) -> 0" }
if ((Invoke-Example 30) -ne 2) { throw "greedy_coin_count fixture 2: (30,) -> 2" }
if ((Invoke-Example 41) -ne 4) { throw "greedy_coin_count fixture 3: (41,) -> 4" }
if ((Invoke-Example 99) -ne 9) { throw "greedy_coin_count fixture 4: (99,) -> 9" }
Write-Output "greedy_coin_count: 4 fixtures passed"
