# Is leap year.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: year >= 1; proleptic Gregorian calendar.
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_year)
    if (($v_year % 400) -eq 0) {
        return 1
    }
    if (($v_year % 100) -eq 0) {
        return 0
    }
    if (($v_year % 4) -eq 0) {
        return 1
    }
    return 0
}

if ((Invoke-Example 1900) -ne 0) { throw "is_leap_year fixture 1: (1900,) -> 0" }
if ((Invoke-Example 2000) -ne 1) { throw "is_leap_year fixture 2: (2000,) -> 1" }
if ((Invoke-Example 2024) -ne 1) { throw "is_leap_year fixture 3: (2024,) -> 1" }
if ((Invoke-Example 2023) -ne 0) { throw "is_leap_year fixture 4: (2023,) -> 0" }
Write-Output "is_leap_year: 4 fixtures passed"
