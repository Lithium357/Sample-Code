# Lcm.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: a,b >= 0; zero arguments produce 0.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_a, [long]$v_b)
    if ($v_a -eq 0) {
        return 0
    }
    if ($v_b -eq 0) {
        return 0
    }
    $v_x = $v_a
    $v_y = $v_b
    while ($v_y -ne 0) {
        $v_remainder = ($v_x % $v_y)
        $v_x = $v_y
        $v_y = $v_remainder
    }
    return ([long][Math]::Truncate(($v_a) / ($v_x)) * $v_b)
}

if ((Invoke-Example 12 18) -ne 36) { throw "lcm fixture 1: (12, 18) -> 36" }
if ((Invoke-Example 0 7) -ne 0) { throw "lcm fixture 2: (0, 7) -> 0" }
if ((Invoke-Example 7 0) -ne 0) { throw "lcm fixture 3: (7, 0) -> 0" }
if ((Invoke-Example 5 7) -ne 35) { throw "lcm fixture 4: (5, 7) -> 35" }
if ((Invoke-Example 9 9) -ne 9) { throw "lcm fixture 5: (9, 9) -> 9" }
Write-Output "lcm: 5 fixtures passed"
