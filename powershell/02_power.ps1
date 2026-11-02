# Power.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: base,exponent >= 0; all intermediate products must fit signed 32-bit; 0^0 = 1.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_base, [long]$v_exponent)
    $v_result = 1
    while ($v_exponent -gt 0) {
        if (($v_exponent % 2) -eq 1) {
            $v_result = ($v_result * $v_base)
        }
        $v_exponent = [long][Math]::Truncate(($v_exponent) / (2))
        if ($v_exponent -gt 0) {
            $v_base = ($v_base * $v_base)
        }
    }
    return $v_result
}

if ((Invoke-Example 0 0) -ne 1) { throw "power fixture 1: (0, 0) -> 1" }
if ((Invoke-Example 2 10) -ne 1024) { throw "power fixture 2: (2, 10) -> 1024" }
if ((Invoke-Example 3 5) -ne 243) { throw "power fixture 3: (3, 5) -> 243" }
if ((Invoke-Example 7 1) -ne 7) { throw "power fixture 4: (7, 1) -> 7" }
Write-Output "power: 4 fixtures passed"
