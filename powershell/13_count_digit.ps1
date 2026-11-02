# Count digit.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: n >= 0; 0 <= target <= 9; zero has one decimal digit.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n, [long]$v_target)
    if ($v_n -eq 0) {
        if ($v_target -eq 0) {
            return 1
        }
        return 0
    }
    $v_count = 0
    while ($v_n -gt 0) {
        if (($v_n % 10) -eq $v_target) {
            $v_count = ($v_count + 1)
        }
        $v_n = [long][Math]::Truncate(($v_n) / (10))
    }
    return $v_count
}

if ((Invoke-Example 0 0) -ne 1) { throw "count_digit fixture 1: (0, 0) -> 1" }
if ((Invoke-Example 0 1) -ne 0) { throw "count_digit fixture 2: (0, 1) -> 0" }
if ((Invoke-Example 1001 0) -ne 2) { throw "count_digit fixture 3: (1001, 0) -> 2" }
if ((Invoke-Example 777 7) -ne 3) { throw "count_digit fixture 4: (777, 7) -> 3" }
Write-Output "count_digit: 4 fixtures passed"
