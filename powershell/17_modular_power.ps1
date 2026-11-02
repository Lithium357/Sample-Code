# Modular power.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: base,exponent >= 0; modulus > 0; intermediate products must fit signed 32-bit.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_base, [long]$v_exponent, [long]$v_modulus)
    $v_result = (1 % $v_modulus)
    $v_base = ($v_base % $v_modulus)
    while ($v_exponent -gt 0) {
        if (($v_exponent % 2) -eq 1) {
            $v_result = (($v_result * $v_base) % $v_modulus)
        }
        $v_exponent = [long][Math]::Truncate(($v_exponent) / (2))
        $v_base = (($v_base * $v_base) % $v_modulus)
    }
    return $v_result
}

if ((Invoke-Example 2 10 1000) -ne 24) { throw "modular_power fixture 1: (2, 10, 1000) -> 24" }
if ((Invoke-Example 7 0 1) -ne 0) { throw "modular_power fixture 2: (7, 0, 1) -> 0" }
if ((Invoke-Example 3 4 7) -ne 4) { throw "modular_power fixture 3: (3, 4, 7) -> 4" }
if ((Invoke-Example 5 3 13) -ne 8) { throw "modular_power fixture 4: (5, 3, 13) -> 8" }
Write-Output "modular_power: 4 fixtures passed"
