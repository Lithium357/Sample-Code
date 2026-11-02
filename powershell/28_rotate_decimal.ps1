# Rotate decimal.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n)
    if ($v_n -lt 10) {
        return $v_n
    }
    $v_scale = 1
    $v_remaining = $v_n
    while ($v_remaining -ge 10) {
        $v_scale = ($v_scale * 10)
        $v_remaining = [long][Math]::Truncate(($v_remaining) / (10))
    }
    return ((($v_n % 10) * $v_scale) + [long][Math]::Truncate(($v_n) / (10)))
}

if ((Invoke-Example 0) -ne 0) { throw "rotate_decimal fixture 1: (0,) -> 0" }
if ((Invoke-Example 7) -ne 7) { throw "rotate_decimal fixture 2: (7,) -> 7" }
if ((Invoke-Example 1234) -ne 4123) { throw "rotate_decimal fixture 3: (1234,) -> 4123" }
if ((Invoke-Example 120) -ne 12) { throw "rotate_decimal fixture 4: (120,) -> 12" }
Write-Output "rotate_decimal: 4 fixtures passed"
