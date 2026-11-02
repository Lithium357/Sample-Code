# Next power of two.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n)
    $v_result = 1
    while ($v_result -lt $v_n) {
        $v_result = ($v_result * 2)
    }
    return $v_result
}

if ((Invoke-Example 0) -ne 1) { throw "next_power_of_two fixture 1: (0,) -> 1" }
if ((Invoke-Example 1) -ne 1) { throw "next_power_of_two fixture 2: (1,) -> 1" }
if ((Invoke-Example 9) -ne 16) { throw "next_power_of_two fixture 3: (9,) -> 16" }
if ((Invoke-Example 64) -ne 64) { throw "next_power_of_two fixture 4: (64,) -> 64" }
Write-Output "next_power_of_two: 4 fixtures passed"
