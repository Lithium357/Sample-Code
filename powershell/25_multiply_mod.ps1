# Multiply mod.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: a,b >= 0; 0 < modulus <= 1000000; repeated doubling avoids a*b overflow.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_a, [long]$v_b, [long]$v_modulus)
    $v_result = 0
    $v_a = ($v_a % $v_modulus)
    while ($v_b -gt 0) {
        if (($v_b % 2) -eq 1) {
            $v_result = (($v_result + $v_a) % $v_modulus)
        }
        $v_a = (($v_a * 2) % $v_modulus)
        $v_b = [long][Math]::Truncate(($v_b) / (2))
    }
    return $v_result
}

if ((Invoke-Example 12 13 7) -ne 2) { throw "multiply_mod fixture 1: (12, 13, 7) -> 2" }
if ((Invoke-Example 0 9 3) -ne 0) { throw "multiply_mod fixture 2: (0, 9, 3) -> 0" }
if ((Invoke-Example 123 456 97) -ne 22) { throw "multiply_mod fixture 3: (123, 456, 97) -> 22" }
if ((Invoke-Example 5 9 1) -ne 0) { throw "multiply_mod fixture 4: (5, 9, 1) -> 0" }
Write-Output "multiply_mod: 4 fixtures passed"
