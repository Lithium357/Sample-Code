# Is armstrong.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n)
    $v_digits = 1
    $v_remaining = $v_n
    while ($v_remaining -ge 10) {
        $v_digits = ($v_digits + 1)
        $v_remaining = [long][Math]::Truncate(($v_remaining) / (10))
    }
    $v_total = 0
    $v_remaining = $v_n
    while ($v_remaining -gt 0) {
        $v_digit = ($v_remaining % 10)
        $v_product = 1
        $v_exponent = 0
        while ($v_exponent -lt $v_digits) {
            $v_product = ($v_product * $v_digit)
            $v_exponent = ($v_exponent + 1)
        }
        $v_total = ($v_total + $v_product)
        $v_remaining = [long][Math]::Truncate(($v_remaining) / (10))
    }
    if ($v_total -eq $v_n) {
        return 1
    }
    return 0
}

if ((Invoke-Example 0) -ne 1) { throw "is_armstrong fixture 1: (0,) -> 1" }
if ((Invoke-Example 153) -ne 1) { throw "is_armstrong fixture 2: (153,) -> 1" }
if ((Invoke-Example 9474) -ne 1) { throw "is_armstrong fixture 3: (9474,) -> 1" }
if ((Invoke-Example 154) -ne 0) { throw "is_armstrong fixture 4: (154,) -> 0" }
Write-Output "is_armstrong: 4 fixtures passed"
