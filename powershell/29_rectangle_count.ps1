# Rectangle count.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_width, [long]$v_height)
    $v_horizontal = [long][Math]::Truncate((($v_width * ($v_width + 1))) / (2))
    $v_vertical = [long][Math]::Truncate((($v_height * ($v_height + 1))) / (2))
    return ($v_horizontal * $v_vertical)
}

if ((Invoke-Example 0 4) -ne 0) { throw "rectangle_count fixture 1: (0, 4) -> 0" }
if ((Invoke-Example 1 1) -ne 1) { throw "rectangle_count fixture 2: (1, 1) -> 1" }
if ((Invoke-Example 2 3) -ne 18) { throw "rectangle_count fixture 3: (2, 3) -> 18" }
if ((Invoke-Example 4 4) -ne 100) { throw "rectangle_count fixture 4: (4, 4) -> 100" }
Write-Output "rectangle_count: 4 fixtures passed"
