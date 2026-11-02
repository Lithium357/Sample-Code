# Lattice paths.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_width, [long]$v_height)
    $v_steps = ($v_width + $v_height)
    $v_result = 1
    $v_index = 1
    while ($v_index -le $v_width) {
        $v_result = [long][Math]::Truncate((($v_result * (($v_steps - $v_width) + $v_index))) / ($v_index))
        $v_index = ($v_index + 1)
    }
    return $v_result
}

if ((Invoke-Example 0 0) -ne 1) { throw "lattice_paths fixture 1: (0, 0) -> 1" }
if ((Invoke-Example 2 2) -ne 6) { throw "lattice_paths fixture 2: (2, 2) -> 6" }
if ((Invoke-Example 3 2) -ne 10) { throw "lattice_paths fixture 3: (3, 2) -> 10" }
if ((Invoke-Example 4 4) -ne 70) { throw "lattice_paths fixture 4: (4, 4) -> 70" }
Write-Output "lattice_paths: 4 fixtures passed"
