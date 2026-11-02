# Lucas.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n)
    $v_previous = 2
    $v_current = 1
    $v_index = 0
    while ($v_index -lt $v_n) {
        $v_following = ($v_previous + $v_current)
        $v_previous = $v_current
        $v_current = $v_following
        $v_index = ($v_index + 1)
    }
    return $v_previous
}

if ((Invoke-Example 0) -ne 2) { throw "lucas fixture 1: (0,) -> 2" }
if ((Invoke-Example 1) -ne 1) { throw "lucas fixture 2: (1,) -> 1" }
if ((Invoke-Example 5) -ne 11) { throw "lucas fixture 3: (5,) -> 11" }
if ((Invoke-Example 10) -ne 123) { throw "lucas fixture 4: (10,) -> 123" }
Write-Output "lucas: 4 fixtures passed"
