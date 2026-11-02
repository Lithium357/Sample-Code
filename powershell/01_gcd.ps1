# Gcd.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: a,b >= 0; gcd(0,0) is defined as 0.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_a, [long]$v_b)
    while ($v_b -ne 0) {
        $v_remainder = ($v_a % $v_b)
        $v_a = $v_b
        $v_b = $v_remainder
    }
    return $v_a
}

if ((Invoke-Example 48 18) -ne 6) { throw "gcd fixture 1: (48, 18) -> 6" }
if ((Invoke-Example 0 7) -ne 7) { throw "gcd fixture 2: (0, 7) -> 7" }
if ((Invoke-Example 7 0) -ne 7) { throw "gcd fixture 3: (7, 0) -> 7" }
if ((Invoke-Example 0 0) -ne 0) { throw "gcd fixture 4: (0, 0) -> 0" }
if ((Invoke-Example 35 64) -ne 1) { throw "gcd fixture 5: (35, 64) -> 1" }
Write-Output "gcd: 5 fixtures passed"
