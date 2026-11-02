# Largest prime factor.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: n >= 1; returns 1 for the empty factorization of 1.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n)
    $v_largest = 1
    $v_divisor = 2
    while ($v_divisor -le [long][Math]::Truncate(($v_n) / ($v_divisor))) {
        while (($v_n % $v_divisor) -eq 0) {
            $v_largest = $v_divisor
            $v_n = [long][Math]::Truncate(($v_n) / ($v_divisor))
        }
        $v_divisor = ($v_divisor + 1)
    }
    if ($v_n -gt 1) {
        $v_largest = $v_n
    }
    return $v_largest
}

if ((Invoke-Example 1) -ne 1) { throw "largest_prime_factor fixture 1: (1,) -> 1" }
if ((Invoke-Example 12) -ne 3) { throw "largest_prime_factor fixture 2: (12,) -> 3" }
if ((Invoke-Example 49) -ne 7) { throw "largest_prime_factor fixture 3: (49,) -> 7" }
if ((Invoke-Example 97) -ne 97) { throw "largest_prime_factor fixture 4: (97,) -> 97" }
Write-Output "largest_prime_factor: 4 fixtures passed"
