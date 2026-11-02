# Ceil div.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: numerator >= 0; denominator > 0.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_numerator, [long]$v_denominator)
    $v_quotient = [long][Math]::Truncate(($v_numerator) / ($v_denominator))
    if (($v_numerator % $v_denominator) -ne 0) {
        $v_quotient = ($v_quotient + 1)
    }
    return $v_quotient
}

if ((Invoke-Example 0 3) -ne 0) { throw "ceil_div fixture 1: (0, 3) -> 0" }
if ((Invoke-Example 10 3) -ne 4) { throw "ceil_div fixture 2: (10, 3) -> 4" }
if ((Invoke-Example 12 3) -ne 4) { throw "ceil_div fixture 3: (12, 3) -> 4" }
if ((Invoke-Example 1 9) -ne 1) { throw "ceil_div fixture 4: (1, 9) -> 1" }
Write-Output "ceil_div: 4 fixtures passed"
