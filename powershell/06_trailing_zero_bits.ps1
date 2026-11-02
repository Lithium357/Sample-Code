# Trailing zero bits.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: n >= 0; zero returns -1 because it has no finite trailing-zero count.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n)
    if ($v_n -eq 0) {
        return (-1)
    }
    $v_count = 0
    while (($v_n % 2) -eq 0) {
        $v_count = ($v_count + 1)
        $v_n = [long][Math]::Truncate(($v_n) / (2))
    }
    return $v_count
}

if ((Invoke-Example 0) -ne -1) { throw "trailing_zero_bits fixture 1: (0,) -> -1" }
if ((Invoke-Example 1) -ne 0) { throw "trailing_zero_bits fixture 2: (1,) -> 0" }
if ((Invoke-Example 40) -ne 3) { throw "trailing_zero_bits fixture 3: (40,) -> 3" }
if ((Invoke-Example 64) -ne 6) { throw "trailing_zero_bits fixture 4: (64,) -> 6" }
Write-Output "trailing_zero_bits: 4 fixtures passed"
