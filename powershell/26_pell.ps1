# Pell.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n)
    $v_previous = 0
    $v_current = 1
    $v_index = 0
    while ($v_index -lt $v_n) {
        $v_following = ((2 * $v_current) + $v_previous)
        $v_previous = $v_current
        $v_current = $v_following
        $v_index = ($v_index + 1)
    }
    return $v_previous
}

if ((Invoke-Example 0) -ne 0) { throw "pell fixture 1: (0,) -> 0" }
if ((Invoke-Example 1) -ne 1) { throw "pell fixture 2: (1,) -> 1" }
if ((Invoke-Example 5) -ne 29) { throw "pell fixture 3: (5,) -> 29" }
if ((Invoke-Example 10) -ne 2378) { throw "pell fixture 4: (10,) -> 2378" }
Write-Output "pell: 4 fixtures passed"
