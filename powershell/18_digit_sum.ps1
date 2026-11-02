# Digit sum.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n)
    $v_total = 0
    while ($v_n -gt 0) {
        $v_total = ($v_total + ($v_n % 10))
        $v_n = [long][Math]::Truncate(($v_n) / (10))
    }
    return $v_total
}

if ((Invoke-Example 0) -ne 0) { throw "digit_sum fixture 1: (0,) -> 0" }
if ((Invoke-Example 12345) -ne 15) { throw "digit_sum fixture 2: (12345,) -> 15" }
if ((Invoke-Example 909) -ne 18) { throw "digit_sum fixture 3: (909,) -> 18" }
if ((Invoke-Example 1000) -ne 1) { throw "digit_sum fixture 4: (1000,) -> 1" }
Write-Output "digit_sum: 4 fixtures passed"
