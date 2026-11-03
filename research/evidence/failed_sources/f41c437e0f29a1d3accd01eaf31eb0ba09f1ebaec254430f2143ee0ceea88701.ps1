# PowerShell 7: objects/pipelines, strict records, parameter errors, JSON and CSV.
# pwsh -NoProfile -File object_pipeline.ps1; owned local temp directory only.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Convert-Reading {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, Mandatory)][AllowNull()][object]$InputObject,
        [ValidateRange(1,100)][int]$Scale=1
    )
    process {
        $invalid=$null -eq $InputObject
        if (-not $invalid) {
            $names=(@($InputObject.PSObject.Properties.Name | Sort-Object) -join ',')
            $invalid=$names -cne 'Amount,Name'
        }
        if (-not $invalid) {
            $invalid=$InputObject.Name -isnot [string] -or [string]::IsNullOrEmpty($InputObject.Name) -or
                ([string]$InputObject.Amount) -notmatch '^[0-9]{1,4}$'
        }
        if (-not $invalid) { $invalid=[int]$InputObject.Amount -gt 1000 }
        if ($invalid) {
            $record=[System.Management.Automation.ErrorRecord]::new(
                [ArgumentException]::new('Expected Name and Amount (0..1000)'),
                'InvalidReading',[System.Management.Automation.ErrorCategory]::InvalidData,$InputObject)
            $PSCmdlet.ThrowTerminatingError($record)
        }
        [pscustomobject]@{Name=$InputObject.Name;Amount=([int]$InputObject.Amount)*$Scale}
    }
}
function Require([bool]$Value) { if (-not $Value) { throw 'assertion failed' } }
function Expect-Error([scriptblock]$Action,[string]$Prefix) {
    $rejected=$false
    try { $null=& $Action } catch {
        if ($_.FullyQualifiedErrorId -notlike "$Prefix*") { throw }
        $rejected=$true
    }
    Require $rejected
}
$inputRows=ConvertFrom-Json '[{"Name":"pen","Amount":2},{"Name":"ink","Amount":0}]'
$rows=@($inputRows | Convert-Reading -Scale 5)
Require ($rows.Count -eq 2 -and $rows[0].Amount -eq 10 -and $rows[1].Amount -eq 0)
Require ($inputRows[0].Amount -eq 2) # Transformation did not mutate its input.
Require (@(@() | Convert-Reading).Count -eq 0)
Expect-Error { [pscustomobject]@{Name='x';Amount=-1} | Convert-Reading } 'InvalidReading'
Expect-Error { [pscustomobject]@{Name='x';Amount=1;Extra=2} | Convert-Reading } 'InvalidReading'
Expect-Error { $inputRows | Convert-Reading -Scale 0 } 'ParameterArgumentValidationError'
$directory=Join-Path ([IO.Path]::GetTempPath()) ('morderca-objects-'+[guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -LiteralPath $directory
try {
    $csv=Join-Path $directory 'round trip.csv'
    $rows | Export-Csv -LiteralPath $csv -NoTypeInformation
    $roundTrip=@(Import-Csv -LiteralPath $csv | Convert-Reading)
    Require (($roundTrip | ConvertTo-Json -Compress) -ceq ($rows | ConvertTo-Json -Compress))
    $jsonRejected=$false
    try { $null=ConvertFrom-Json '{bad' -ErrorAction Stop } catch {
        if ($_.FullyQualifiedErrorId -notlike '*Json*') { throw };$jsonRejected=$true
    }
    Require $jsonRejected
} finally { Remove-Item -LiteralPath $directory -Recurse -Force }
Write-Output 'Object pipeline: typed transformation, parameter/record errors, JSON and CSV round trip passed'
