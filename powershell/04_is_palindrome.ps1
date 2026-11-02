# Is palindrome.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n)
    $v_original = $v_n
    $v_reversed_value = 0
    while ($v_n -gt 0) {
        $v_reversed_value = (($v_reversed_value * 10) + ($v_n % 10))
        $v_n = [long][Math]::Truncate(($v_n) / (10))
    }
    if ($v_reversed_value -eq $v_original) {
        return 1
    }
    return 0
}

if ((Invoke-Example 0) -ne 1) { throw "is_palindrome fixture 1: (0,) -> 1" }
if ((Invoke-Example 1221) -ne 1) { throw "is_palindrome fixture 2: (1221,) -> 1" }
if ((Invoke-Example 123) -ne 0) { throw "is_palindrome fixture 3: (123,) -> 0" }
if ((Invoke-Example 101) -ne 1) { throw "is_palindrome fixture 4: (101,) -> 1" }
Write-Output "is_palindrome: 4 fixtures passed"
