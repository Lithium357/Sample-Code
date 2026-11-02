# Modular inverse.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: a >= 0; modulus > 1; returns -1 when no inverse exists.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_a, [long]$v_modulus)
    $v_candidate = 1
    while ($v_candidate -lt $v_modulus) {
        if ((($v_a * $v_candidate) % $v_modulus) -eq 1) {
            return $v_candidate
        }
        $v_candidate = ($v_candidate + 1)
    }
    return (-1)
}

if ((Invoke-Example 3 7) -ne 5) { throw "modular_inverse fixture 1: (3, 7) -> 5" }
if ((Invoke-Example 2 4) -ne -1) { throw "modular_inverse fixture 2: (2, 4) -> -1" }
if ((Invoke-Example 1 5) -ne 1) { throw "modular_inverse fixture 3: (1, 5) -> 1" }
if ((Invoke-Example 7 11) -ne 8) { throw "modular_inverse fixture 4: (7, 11) -> 8" }
Write-Output "modular_inverse: 4 fixtures passed"
