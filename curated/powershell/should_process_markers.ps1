# PowerShell 7.2+: SupportsShouldProcess, buffered pipeline validation and strict UTF-8.
# pwsh -NoProfile -File should_process_markers.ps1
# Each file is an independent operation; I/O errors may leave earlier writes.
# Caller supplies an owned directory with no concurrent writers or symlink tricks.
# The fixture creates and removes only its own verified temporary directory.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Write-LocalMarkers {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Low')]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Root,
        [Parameter(Mandatory,ValueFromPipeline)][AllowNull()][object]$InputObject
    )
    begin {
        $rootPath=[IO.Path]::GetFullPath($Root)
        if (-not [IO.Directory]::Exists($rootPath)) { throw 'Root must be an existing directory' }
        $pending=[Collections.Generic.List[object]]::new()
        $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $encoding=[Text.UTF8Encoding]::new($false,$true)
    }
    process {
        $invalid=$null -eq $InputObject
        if (-not $invalid) {
            $invalid=$null -eq $InputObject.PSObject.Properties['Name'] -or
                     $null -eq $InputObject.PSObject.Properties['Value']
        }
        if (-not $invalid) {
            $invalid=$InputObject.Name -isnot [string] -or $InputObject.Value -isnot [string]
        }
        if (-not $invalid) {
            $invalid=$InputObject.Name -cnotmatch '\A[A-Za-z][A-Za-z0-9 _-]{0,31}\z'
        }
        if (-not $invalid) {
            # Reject Windows device stems on every host, including before spaces.
            $invalid=$InputObject.Name.TrimEnd() -match '\A(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])\z'
        }
        if (-not $invalid) {
            try { $invalid=$encoding.GetByteCount($InputObject.Value) -gt 4096 }
            catch [Text.EncoderFallbackException] { $invalid=$true }
        }
        if (-not $invalid) { $invalid=-not $seen.Add($InputObject.Name) }
        if ($invalid) {
            $errorRecord=[Management.Automation.ErrorRecord]::new(
                [ArgumentException]::new('Invalid marker name, value, encoding or duplicate name'),
                'InvalidMarkerRecord',[Management.Automation.ErrorCategory]::InvalidData,$InputObject)
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
        $pending.Add([pscustomobject]@{
            Name=$InputObject.Name; Value=$InputObject.Value
            Path=[IO.Path]::Combine($rootPath,$InputObject.Name+'.txt'); Changed=$true
        })
    }
    end {
        # Validate existing targets for the whole batch before its first write.
        foreach ($item in $pending) {
            if ([IO.Directory]::Exists($item.Path)) { throw 'A marker target is a directory' }
            if ([IO.File]::Exists($item.Path)) {
                # Compare bytes, not BOM-detected text: a UTF-16 file containing
                # the same characters still needs canonical UTF-8 replacement.
                $length=([IO.FileInfo]::new($item.Path)).Length
                if ($length -le 4096) {
                    $item.Changed=[Convert]::ToHexString([IO.File]::ReadAllBytes($item.Path)) -cne
                                  [Convert]::ToHexString($encoding.GetBytes($item.Value))
                }
            }
        }
        foreach ($item in $pending) {
            $status='Unchanged'
            if ($item.Changed) {
                $status='Planned'
                if ($PSCmdlet.ShouldProcess($item.Path,'Write local marker')) {
                    [IO.File]::WriteAllText($item.Path,$item.Value,$encoding)
                    $status='Written'
                }
            }
            [pscustomobject]@{Name=$item.Name;Path=$item.Path;Status=$status}
        }
    }
}
function Check([bool]$Truth) { if (-not $Truth) { throw 'assertion failed' } }
function Reject-Marker([scriptblock]$Action) {
    $rejected=$false
    try { & $Action | Out-Null }
    catch { Check ($_.FullyQualifiedErrorId -like 'InvalidMarkerRecord*'); $rejected=$true }
    Check $rejected
}

$fixtureParent=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$fixtureLeaf='marker-fixture-'+[guid]::NewGuid().ToString('N')
$fixtureRoot=[IO.Path]::Combine($fixtureParent,$fixtureLeaf)
$null=[IO.Directory]::CreateDirectory($fixtureRoot)
try {
    $records=@([pscustomobject]@{Name='space name';Value='hé'},[pscustomobject]@{Name='empty';Value=''})
    $planned=@($records | Write-LocalMarkers -Root $fixtureRoot -WhatIf)
    Check ($planned.Count -eq 2 -and @($planned | Where-Object Status -ne 'Planned').Count -eq 0)
    Check ([IO.Directory]::GetFiles($fixtureRoot).Length -eq 0)
    $written=@($records | Write-LocalMarkers -Root $fixtureRoot -Confirm:$false)
    Check (@($written | Where-Object Status -eq 'Written').Count -eq 2)
    Check ([Convert]::ToHexString([IO.File]::ReadAllBytes($written[0].Path)) -ceq '68C3A9')
    Check ([IO.File]::ReadAllBytes($written[1].Path).Length -eq 0)
    $again=@($records | Write-LocalMarkers -Root $fixtureRoot -Confirm:$false)
    Check (@($again | Where-Object Status -eq 'Unchanged').Count -eq 2)
    [IO.File]::WriteAllText($written[0].Path,'hé',[Text.Encoding]::Unicode)
    $noncanonical=[Convert]::ToHexString([IO.File]::ReadAllBytes($written[0].Path))
    $canonicalPlan=@($records[0] | Write-LocalMarkers -Root $fixtureRoot -WhatIf)
    Check ($canonicalPlan[0].Status -eq 'Planned')
    Check ([Convert]::ToHexString([IO.File]::ReadAllBytes($written[0].Path)) -ceq $noncanonical)
    $normalized=@($records[0] | Write-LocalMarkers -Root $fixtureRoot -Confirm:$false)
    Check ($normalized[0].Status -eq 'Written')
    Check ([Convert]::ToHexString([IO.File]::ReadAllBytes($written[0].Path)) -ceq '68C3A9')
    $changed=[pscustomobject]@{Name='space name';Value='changed'}
    $null=$changed | Write-LocalMarkers -Root $fixtureRoot -WhatIf
    Check ([Convert]::ToHexString([IO.File]::ReadAllBytes($written[0].Path)) -ceq '68C3A9')
    $prefix=[pscustomobject]@{Name='not published';Value='prefix'}
    foreach ($bad in @(
        [pscustomobject]@{Name='../escape';Value='bad'},
        [pscustomobject]@{Name='NUL';Value='bad'},
        [pscustomobject]@{Name='com1 ';Value='bad'},
        [pscustomobject]@{Name=('a'*33);Value='bad'},
        [pscustomobject]@{Name='bad';Value=@(1,2)},
        [pscustomobject]@{Name='bad';Value=('x'*4097)},
        [pscustomobject]@{Name='bad';Value=('雪'*1366)},
        [pscustomobject]@{Name='bad';Value=([string][char]0xd800)},
        [pscustomobject]@{Value='missing name'}
    )) {
        Reject-Marker { @($prefix,$bad) | Write-LocalMarkers -Root $fixtureRoot -Confirm:$false }
        Check (-not [IO.File]::Exists([IO.Path]::Combine($fixtureRoot,'not published.txt')))
    }
    Reject-Marker {
        @([pscustomobject]@{Name='Case';Value='a'},[pscustomobject]@{Name='case';Value='b'}) |
            Write-LocalMarkers -Root $fixtureRoot -Confirm:$false
    }
    Reject-Marker { $null | Write-LocalMarkers -Root $fixtureRoot -Confirm:$false }
    Check ([IO.Directory]::GetFiles($fixtureRoot).Length -eq 2)
    $boundary=[pscustomobject]@{Name=('b'*32);Value=('x'*4096)}
    $null=$boundary | Write-LocalMarkers -Root $fixtureRoot -Confirm:$false
    Check ([IO.File]::ReadAllBytes([IO.Path]::Combine($fixtureRoot,('b'*32)+'.txt')).Length -eq 4096)
    $blocked=[IO.Path]::Combine($fixtureRoot,'blocked.txt')
    $null=[IO.Directory]::CreateDirectory($blocked)
    $blockedError=$false
    try {
        @($prefix,[pscustomobject]@{Name='blocked';Value='bad'}) |
            Write-LocalMarkers -Root $fixtureRoot -Confirm:$false | Out-Null
    } catch { Check ($_.Exception.Message -eq 'A marker target is a directory'); $blockedError=$true }
    Check $blockedError
    Check (-not [IO.File]::Exists([IO.Path]::Combine($fixtureRoot,'not published.txt')))
} finally {
    $resolved=[IO.Path]::GetFullPath($fixtureRoot)
    if (-not $resolved.StartsWith($fixtureParent,[StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($resolved) -cne $fixtureLeaf) { throw 'fixture cleanup path mismatch' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
Write-Output 'PowerShell markers: WhatIf, pipeline buffering, exact UTF-8, idempotence, validation boundaries and owned cleanup passed'
