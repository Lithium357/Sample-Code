# Digital root.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n)
    while ($v_n -ge 10) {
        $v_total = 0
        while ($v_n -gt 0) {
            $v_total = ($v_total + ($v_n % 10))
            $v_n = [long][Math]::Truncate(($v_n) / (10))
        }
        $v_n = $v_total
    }
    return $v_n
}

if ((Invoke-Example 0) -ne 0) { throw "digital_root fixture 1: (0,) -> 0" }
if ((Invoke-Example 999) -ne 9) { throw "digital_root fixture 2: (999,) -> 9" }
if ((Invoke-Example 12345) -ne 6) { throw "digital_root fixture 3: (12345,) -> 6" }
if ((Invoke-Example 8) -ne 8) { throw "digital_root fixture 4: (8,) -> 8" }
Write-Output "digital_root: 4 fixtures passed"
