# Integer log.
# PowerShell 7; pwsh -NoProfile -File FILE.ps1
# Contract: n >= 1; base >= 2; returns floor(log_base(n)).
# Run this file independently; failures exit nonzero.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Example {
    param([long]$v_n, [long]$v_base)
    $v_exponent = 0
    while ($v_n -ge $v_base) {
        $v_n = [long][Math]::Truncate(($v_n) / ($v_base))
        $v_exponent = ($v_exponent + 1)
    }
    return $v_exponent
}

if ((Invoke-Example 1 2) -ne 0) { throw "integer_log fixture 1: (1, 2) -> 0" }
if ((Invoke-Example 8 2) -ne 3) { throw "integer_log fixture 2: (8, 2) -> 3" }
if ((Invoke-Example 99 10) -ne 1) { throw "integer_log fixture 3: (99, 10) -> 1" }
if ((Invoke-Example 100 10) -ne 2) { throw "integer_log fixture 4: (100, 10) -> 2" }
Write-Output "integer_log: 4 fixtures passed"
