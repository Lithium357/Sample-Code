# Is happy.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: n >= 0; a cap of 100 digit-square iterations detects failure for these bounded inputs.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n)
    $v_steps = 0
    while ($v_steps -lt 100) {
        if ($v_n -eq 1) {
            return 1
        }
        $v_total = 0
        while ($v_n -gt 0) {
            $v_digit = ($v_n % 10)
            $v_total = ($v_total + ($v_digit * $v_digit))
            $v_n = [long][Math]::Truncate(($v_n) / (10))
        }
        $v_n = $v_total
        $v_steps = ($v_steps + 1)
    }
    return 0
}

if ((Invoke-Example 1) -ne 1) { throw "is_happy fixture 1: (1,) -> 1" }
if ((Invoke-Example 19) -ne 1) { throw "is_happy fixture 2: (19,) -> 1" }
if ((Invoke-Example 2) -ne 0) { throw "is_happy fixture 3: (2,) -> 0" }
if ((Invoke-Example 0) -ne 0) { throw "is_happy fixture 4: (0,) -> 0" }
Write-Output "is_happy: 4 fixtures passed"
