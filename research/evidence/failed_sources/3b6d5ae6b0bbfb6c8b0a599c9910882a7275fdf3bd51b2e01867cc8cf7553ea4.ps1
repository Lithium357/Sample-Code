# PowerShell 7+, .NET. pwsh -NoProfile -File provider_bytes.ps1
# Resolve a literal PowerShell path through session-state providers before
# passing it to .NET. Relative paths follow the PowerShell location/PSDrive,
# which need not match the process working directory used by .NET APIs.
# This is bounded file reading, not a security sandbox or an atomic snapshot.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-LiteralBytes {
    [CmdletBinding()]
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$LiteralPath,
        [ValidateRange(0, 1048576)][int]$MaxBytes = 4096
    )
    $provider = $null
    $drive = $null
    $nativePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
        $LiteralPath, [ref]$provider, [ref]$drive)
    if ($provider.Name -ne 'FileSystem') {
        throw [System.NotSupportedException]::new('A FileSystem path is required')
    }
    # Read at most one sentinel byte beyond the limit. A file that grows while
    # being read cannot force an unbounded ReadAllBytes allocation here.
    $buffer = [byte[]]::new($MaxBytes + 1)
    $stream = [System.IO.File]::Open($nativePath, [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    try {
        $used = 0
        while ($used -lt $buffer.Length) {
            $n = $stream.Read($buffer, $used, $buffer.Length - $used)
            if ($n -eq 0) { break }
            $used += $n
        }
        if ($used -gt $MaxBytes) {
            throw [System.IO.InvalidDataException]::new('Byte limit exceeded')
        }
        $result = [byte[]]::new($used)
        [System.Array]::Copy($buffer, $result, $used)
        # Preserve the array as ONE output object, including zero/one elements.
        # Normal PowerShell pipeline output would enumerate the bytes.
        return ,$result
    }
    finally { $stream.Dispose() }
}

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "Assertion failed: $Message" }
}

function Assert-Failure([scriptblock]$Action, [type]$Expected) {
    $caught = $null
    try { & $Action | Out-Null } catch { $caught = $_ }
    Assert-True ($null -ne $caught) 'operation must fail'
    # PowerShell may wrap a .NET invocation. Walk the actual inner chain rather
    # than accepting an arbitrary exception or matching translated messages.
    $exception = $caught.Exception
    while ($null -ne $exception -and -not $Expected.IsInstanceOfType($exception)) {
        $exception = $exception.InnerException
    }
    Assert-True ($null -ne $exception) "expected $($Expected.FullName), got $($caught.Exception.GetType().FullName)"
}

$beforeLocation = Get-Location
$processCwd = [System.Environment]::CurrentDirectory
$root = Join-Path ([System.IO.Path]::GetTempPath()) ('literal-provider-' + [guid]::NewGuid().ToString('N'))
$driveName = 'Fixture' + [guid]::NewGuid().ToString('N')
$createdDrive = $false
[void][System.IO.Directory]::CreateDirectory($root)
try {
    $literal = Join-Path $root 'entry[12].bin'
    [System.IO.File]::WriteAllBytes($literal, [byte[]](0, 255, 65))
    [System.IO.File]::WriteAllBytes((Join-Path $root 'entry1.bin'), [byte[]](11))
    [System.IO.File]::WriteAllBytes((Join-Path $root 'entry2.bin'), [byte[]](22))
    [System.IO.File]::WriteAllBytes((Join-Path $root 'empty.bin'), [byte[]]::new(0))
    [void][System.IO.Directory]::CreateDirectory((Join-Path $root 'sub dir'))
    New-PSDrive -Name $driveName -PSProvider FileSystem -Root $root | Out-Null
    $createdDrive = $true
    Set-Location -LiteralPath ($driveName + ':\')
    Assert-True ([System.Environment]::CurrentDirectory -eq $processCwd) 'Set-Location leaves process cwd alone'

    $data = Read-LiteralBytes -LiteralPath 'entry[12].bin' -MaxBytes 3
    Assert-True ($data -is [byte[]]) 'binary array type'
    Assert-True (($data -join ',') -eq '0,255,65') 'literal bracket file'
    $wild = @(Get-ChildItem -Path 'entry[12].bin')
    Assert-True ($wild.Count -eq 2) 'wildcard path matches two other files'
    Assert-True (($wild.Name | Sort-Object) -join ',' -eq 'entry1.bin,entry2.bin') 'wildcard names'
    $qualified = Read-LiteralBytes -LiteralPath ('FileSystem::' + $literal) -MaxBytes 3
    Assert-True (($qualified -join ',') -eq '0,255,65') 'provider-qualified native path'
    $viaDrive = Read-LiteralBytes -LiteralPath ($driveName + ':\entry[12].bin')
    Assert-True (($viaDrive -join ',') -eq '0,255,65') 'drive-qualified path'
    $one = @(Read-LiteralBytes -LiteralPath 'entry1.bin' -MaxBytes 1)
    Assert-True ($one.Count -eq 1 -and $one[0] -is [byte[]] -and $one[0].Length -eq 1) 'singleton output remains one byte array'
    $empty = @(Read-LiteralBytes -LiteralPath 'empty.bin' -MaxBytes 0)
    Assert-True ($empty.Count -eq 1 -and $empty[0] -is [byte[]] -and $empty[0].Length -eq 0) 'empty output remains one byte array'

    Assert-Failure { Read-LiteralBytes -LiteralPath 'entry[12].bin' -MaxBytes 2 } ([System.IO.InvalidDataException])
    Assert-Failure { Read-LiteralBytes -LiteralPath 'entry1.bin' -MaxBytes 0 } ([System.IO.InvalidDataException])
    Assert-Failure { Read-LiteralBytes -LiteralPath 'missing.bin' } ([System.IO.FileNotFoundException])
    Assert-Failure { Read-LiteralBytes -LiteralPath 'Env:PATH' } ([System.NotSupportedException])
    Assert-Failure { Read-LiteralBytes -LiteralPath '' } ([System.Management.Automation.ParameterBindingValidationException])
    Assert-Failure { Read-LiteralBytes -LiteralPath 'empty.bin' -MaxBytes -1 } ([System.Management.Automation.ParameterBindingValidationException])
    Assert-Failure { Read-LiteralBytes -LiteralPath 'empty.bin' -MaxBytes 1048577 } ([System.Management.Automation.ParameterBindingValidationException])
    for ($i = 0; $i -lt 20; $i++) {
        Assert-Failure { Read-LiteralBytes -LiteralPath 'entry[12].bin' -MaxBytes 1 } ([System.IO.InvalidDataException])
        $exclusive = [System.IO.File]::Open($literal, [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $exclusive.Dispose()
    }
    Assert-True (([System.IO.File]::ReadAllBytes($literal) -join ',') -eq '0,255,65') 'failure preserved file bytes'
    Assert-True (@(Get-ChildItem -LiteralPath $root -File).Count -eq 4) 'no unexpected files'
}
finally {
    Set-Location -LiteralPath $beforeLocation.Path
    if ($createdDrive) { Remove-PSDrive -Name $driveName }
    # Remove exact owned fixtures and the empty owned directory, nonrecursively.
    foreach ($name in @('entry[12].bin', 'entry1.bin', 'entry2.bin', 'empty.bin')) {
        $fixture = Join-Path $root $name
        if ([System.IO.File]::Exists($fixture)) { [System.IO.File]::Delete($fixture) }
    }
    $subdir = Join-Path $root 'sub dir'
    if ([System.IO.Directory]::Exists($subdir)) { [System.IO.Directory]::Delete($subdir) }
    [System.IO.Directory]::Delete($root)
}
Assert-True (-not (Test-Path -LiteralPath $root)) 'owned fixture cleanup'
Write-Output 'provider bytes: literal paths, providers, byte shape, bounds and cleanup passed'
