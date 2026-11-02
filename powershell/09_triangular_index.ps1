# Triangular index.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n)
    $v_total = 0
    $v_index = 0
    while ($v_total -lt $v_n) {
        $v_index = ($v_index + 1)
        $v_total = ($v_total + $v_index)
    }
    if ($v_total -eq $v_n) {
        return $v_index
    }
    return (-1)
}

if ((Invoke-Example 0) -ne 0) { throw "triangular_index fixture 1: (0,) -> 0" }
if ((Invoke-Example 1) -ne 1) { throw "triangular_index fixture 2: (1,) -> 1" }
if ((Invoke-Example 15) -ne 5) { throw "triangular_index fixture 3: (15,) -> 5" }
if ((Invoke-Example 14) -ne -1) { throw "triangular_index fixture 4: (14,) -> -1" }
Write-Output "triangular_index: 4 fixtures passed"
