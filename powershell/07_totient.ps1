# Totient.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: n >= 1.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n)
    $v_result = $v_n
    $v_prime = 2
    $v_remaining = $v_n
    while ($v_prime -le [long][Math]::Truncate(($v_remaining) / ($v_prime))) {
        if (($v_remaining % $v_prime) -eq 0) {
            while (($v_remaining % $v_prime) -eq 0) {
                $v_remaining = [long][Math]::Truncate(($v_remaining) / ($v_prime))
            }
            $v_result = ($v_result - [long][Math]::Truncate(($v_result) / ($v_prime)))
        }
        $v_prime = ($v_prime + 1)
    }
    if ($v_remaining -gt 1) {
        $v_result = ($v_result - [long][Math]::Truncate(($v_result) / ($v_remaining)))
    }
    return $v_result
}

if ((Invoke-Example 1) -ne 1) { throw "totient fixture 1: (1,) -> 1" }
if ((Invoke-Example 9) -ne 6) { throw "totient fixture 2: (9,) -> 6" }
if ((Invoke-Example 12) -ne 4) { throw "totient fixture 3: (12,) -> 4" }
if ((Invoke-Example 97) -ne 96) { throw "totient fixture 4: (97,) -> 96" }
Write-Output "totient: 4 fixtures passed"
