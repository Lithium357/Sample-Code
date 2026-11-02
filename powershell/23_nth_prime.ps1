# Nth prime.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: 1 <= index <= 100; trial division is intended for small inputs.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_index)
    $v_count = 0
    $v_candidate = 1
    while ($v_count -lt $v_index) {
        $v_candidate = ($v_candidate + 1)
        $v_prime = 1
        $v_divisor = 2
        while ($v_divisor -le [long][Math]::Truncate(($v_candidate) / ($v_divisor))) {
            if (($v_candidate % $v_divisor) -eq 0) {
                $v_prime = 0
            }
            $v_divisor = ($v_divisor + 1)
        }
        $v_count = ($v_count + $v_prime)
    }
    return $v_candidate
}

if ((Invoke-Example 1) -ne 2) { throw "nth_prime fixture 1: (1,) -> 2" }
if ((Invoke-Example 2) -ne 3) { throw "nth_prime fixture 2: (2,) -> 3" }
if ((Invoke-Example 10) -ne 29) { throw "nth_prime fixture 3: (10,) -> 29" }
if ((Invoke-Example 25) -ne 97) { throw "nth_prime fixture 4: (25,) -> 97" }
Write-Output "nth_prime: 4 fixtures passed"
