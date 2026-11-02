# Discrete log.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: base,target >= 0; modulus > 1; target < modulus; brute-force exponent search.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_base, [long]$v_target, [long]$v_modulus)
    $v_value = (1 % $v_modulus)
    $v_exponent = 0
    while ($v_exponent -lt $v_modulus) {
        if ($v_value -eq $v_target) {
            return $v_exponent
        }
        $v_value = (($v_value * $v_base) % $v_modulus)
        $v_exponent = ($v_exponent + 1)
    }
    return (-1)
}

if ((Invoke-Example 2 1 7) -ne 0) { throw "discrete_log fixture 1: (2, 1, 7) -> 0" }
if ((Invoke-Example 2 4 7) -ne 2) { throw "discrete_log fixture 2: (2, 4, 7) -> 2" }
if ((Invoke-Example 2 3 7) -ne -1) { throw "discrete_log fixture 3: (2, 3, 7) -> -1" }
if ((Invoke-Example 3 5 7) -ne 5) { throw "discrete_log fixture 4: (3, 5, 7) -> 5" }
Write-Output "discrete_log: 4 fixtures passed"
