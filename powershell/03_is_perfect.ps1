# Is perfect.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n)
    $v_total = 0
    $v_divisor = 1
    while ($v_divisor -lt $v_n) {
        if (($v_n % $v_divisor) -eq 0) {
            $v_total = ($v_total + $v_divisor)
        }
        $v_divisor = ($v_divisor + 1)
    }
    if ($v_total -eq $v_n) {
        if ($v_n -gt 0) {
            return 1
        }
    }
    return 0
}

if ((Invoke-Example 0) -ne 0) { throw "is_perfect fixture 1: (0,) -> 0" }
if ((Invoke-Example 1) -ne 0) { throw "is_perfect fixture 2: (1,) -> 0" }
if ((Invoke-Example 6) -ne 1) { throw "is_perfect fixture 3: (6,) -> 1" }
if ((Invoke-Example 28) -ne 1) { throw "is_perfect fixture 4: (28,) -> 1" }
if ((Invoke-Example 12) -ne 0) { throw "is_perfect fixture 5: (12,) -> 0" }
Write-Output "is_perfect: 5 fixtures passed"
