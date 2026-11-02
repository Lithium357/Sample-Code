# Binomial.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n, [long]$v_k)
    if ($v_k -gt $v_n) {
        return 0
    }
    if ($v_k -gt ($v_n - $v_k)) {
        $v_k = ($v_n - $v_k)
    }
    $v_result = 1
    $v_index = 1
    while ($v_index -le $v_k) {
        $v_result = [long][Math]::Truncate((($v_result * (($v_n - $v_k) + $v_index))) / ($v_index))
        $v_index = ($v_index + 1)
    }
    return $v_result
}

if ((Invoke-Example 5 2) -ne 10) { throw "binomial fixture 1: (5, 2) -> 10" }
if ((Invoke-Example 0 0) -ne 1) { throw "binomial fixture 2: (0, 0) -> 1" }
if ((Invoke-Example 6 7) -ne 0) { throw "binomial fixture 3: (6, 7) -> 0" }
if ((Invoke-Example 10 5) -ne 252) { throw "binomial fixture 4: (10, 5) -> 252" }
Write-Output "binomial: 4 fixtures passed"
