#requires -Version 7.3
# PowerShell 7.3+/.NET. This command TAKES ownership once begin executes.
# Parameter-binding failures happen before ownership transfers. Do not use the
# stream concurrently or dispose it yourself while the command runs.
# Each object owns fresh Bytes, with zero-based Int64 Offset. Short reads are
# emitted as short blocks; they are not EOF. Input must obey .NET Stream.Read.
# Cooperative cancellation is checked before each synchronous Read, not inside
# a blocked Read. Earlier output is observable on a later error/cancellation.
# A throwing Dispose can itself fail cleanup; no exception-suppression guarantee.
# clean-block reference: Microsoft Learn about_Functions_Advanced_Methods.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-OwnedBlocks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateNotNull()][System.IO.Stream]$Stream,
        [ValidateRange(1, 4096)][int]$BlockSize = 256,
        [System.Threading.CancellationToken]$CancellationToken = [System.Threading.CancellationToken]::None
    )
    begin {
        $owned = $Stream
        if (-not $owned.CanRead) { throw [System.ArgumentException]::new('A readable stream is required') }
        $buffer = [byte[]]::new($BlockSize)
        [long]$offset = 0
    }
    end {
        while ($true) {
            if ($CancellationToken.IsCancellationRequested) {
                $exception = [System.OperationCanceledException]::new('Block source canceled', $CancellationToken)
                $record = [System.Management.Automation.ErrorRecord]::new($exception,
                    'OwnedBlocksCanceled', [System.Management.Automation.ErrorCategory]::OperationStopped, $Stream)
                $PSCmdlet.ThrowTerminatingError($record)
            }
            $read = $owned.Read($buffer, 0, $buffer.Length)
            if ($read -eq 0) { break }
            # The producer can reuse buffer while a consumer retains/mutates Bytes.
            $bytes = $buffer
            [pscustomobject]@{ Offset = $offset; Bytes = $bytes }
            $offset += $read
        }
    }
    clean {
        if ($null -ne $owned) {
            try { $owned.Dispose() } finally { $owned = $null }
        }
    }
}

function Assert-Block([bool]$Condition, [string]$Label) {
    if (-not $Condition) { throw "failed: $Label" }
    $script:blockChecks++
}
function Assert-BlockFailure([scriptblock]$Operation, [type]$Expected, [string]$Id = '') {
    $caught = $null
    try { & $Operation | Out-Null } catch { $caught = $_ }
    Assert-Block ($null -ne $caught) 'failure required'
    if ($Id) { Assert-Block ($caught.FullyQualifiedErrorId -eq $Id) 'error identity' }
    $exception = $caught.Exception
    while ($null -ne $exception -and -not $Expected.IsInstanceOfType($exception)) {
        $exception = $exception.InnerException
    }
    Assert-Block ($null -ne $exception) 'exception type chain'
}

$script:blockChecks = 0
# Owned custom stream fixture: controlled short reads and an injected I/O error.
# It is an execution fixture, not a production replacement for real I/O.
Add-Type -TypeDefinition @'
using System;
using System.IO;
public sealed class BlockFixtureStream : MemoryStream {
    public int ReadCalls, DisposeCalls;
    public int MaxRead = int.MaxValue, FailAt = -1;
    public BlockFixtureStream(byte[] bytes) : base(bytes, false) {}
    public override int Read(byte[] bytes, int offset, int count) {
        if (ReadCalls++ == FailAt) throw new IOException("fixture read failed");
        return base.Read(bytes, offset, Math.Min(count, MaxRead));
    }
    protected override void Dispose(bool disposing) {
        if (disposing) DisposeCalls++;
        base.Dispose(disposing);
    }
}
'@

foreach ($length in @(0, 1, 2, 7, 255, 256, 257, 4095, 4096, 4097)) {
    $source = [byte[]]::new($length)
    for ($i = 0; $i -lt $length; $i++) { $source[$i] = ($i * 71 + 13) % 256 }
    foreach ($size in @(1, 2, 7, 256, 4096)) {
        foreach ($maxRead in @(1, 3, 4096)) {
            $stream = [BlockFixtureStream]::new($source)
            $stream.MaxRead = $maxRead
            $objects = @(Read-OwnedBlocks -Stream $stream -BlockSize $size)
            [long]$position = 0
            foreach ($object in $objects) {
                Assert-Block ($object.Offset -eq $position) 'offset continuity'
                Assert-Block ($object.Bytes -is [byte[]]) 'array stays inside output object'
                $expectedSize = [Math]::Min([Math]::Min($size, $maxRead), $length - $position)
                Assert-Block ($object.Bytes.Length -eq $expectedSize) 'short read retained'
                for ($j = 0; $j -lt $object.Bytes.Length; $j++) {
                    Assert-Block ($object.Bytes[$j] -eq $source[$position + $j]) 'independent byte oracle'
                }
                $position += $object.Bytes.Length
            }
            Assert-Block ($position -eq $length) 'conservation including empty input'
            Assert-Block ($stream.DisposeCalls -eq 1 -and -not $stream.CanRead) 'normal clean exactly once'
            if ($objects.Count -gt 1) {
                $before = $objects[1].Bytes[0]
                $objects[0].Bytes[0] = $objects[0].Bytes[0] -bxor 255
                Assert-Block ($objects[1].Bytes[0] -eq $before) 'output buffers do not alias'
            }
        }
    }
}

$stream = [BlockFixtureStream]::new([byte[]](1, 2, 3, 4))
$first = @(Read-OwnedBlocks -Stream $stream -BlockSize 1 | Select-Object -First 1)
Assert-Block ($first.Count -eq 1 -and $first[0].Bytes[0] -eq 1) 'downstream first object'
Assert-Block ($stream.ReadCalls -eq 1 -and $stream.DisposeCalls -eq 1) 'early stop clean, no read ahead'

$cts = [System.Threading.CancellationTokenSource]::new()
try {
    $cts.Cancel()
    $stream = [BlockFixtureStream]::new([byte[]](1, 2))
    Assert-BlockFailure { Read-OwnedBlocks -Stream $stream -CancellationToken $cts.Token } `
        ([System.OperationCanceledException]) 'OwnedBlocksCanceled,Read-OwnedBlocks'
    Assert-Block ($stream.ReadCalls -eq 0 -and $stream.DisposeCalls -eq 1) 'pre-cancel owns and closes without read'
} finally { $cts.Dispose() }

$cts = [System.Threading.CancellationTokenSource]::new()
try {
    $stream = [BlockFixtureStream]::new([byte[]](4, 5, 6))
    $published = [System.Collections.Generic.List[object]]::new()
    Assert-BlockFailure {
        Read-OwnedBlocks -Stream $stream -BlockSize 1 -CancellationToken $cts.Token | ForEach-Object {
            $published.Add($_)
            $cts.Cancel()
        }
    } ([System.OperationCanceledException]) 'OwnedBlocksCanceled,Read-OwnedBlocks'
    Assert-Block ($published.Count -eq 1 -and $published[0].Bytes[0] -eq 4) 'prefix survives cancellation'
    Assert-Block ($stream.ReadCalls -eq 1 -and $stream.DisposeCalls -eq 1) 'cancel before next read and clean'
} finally { $cts.Dispose() }

$stream = [BlockFixtureStream]::new([byte[]](8, 9))
$stream.FailAt = 1
$published = [System.Collections.Generic.List[object]]::new()
Assert-BlockFailure {
    Read-OwnedBlocks -Stream $stream -BlockSize 1 | ForEach-Object { $published.Add($_) }
} ([System.IO.IOException])
Assert-Block ($published.Count -eq 1 -and $published[0].Bytes[0] -eq 8) 'prefix survives read error'
Assert-Block ($stream.DisposeCalls -eq 1) 'read error cleanup'

$stream = [BlockFixtureStream]::new([byte[]](1))
Assert-BlockFailure { Read-OwnedBlocks -Stream $stream | ForEach-Object { throw 'consumer fixture failed' } } `
    ([System.Management.Automation.RuntimeException])
Assert-Block ($stream.DisposeCalls -eq 1) 'consumer error cleanup'

foreach ($size in @(0, 4097)) {
    $stream = [BlockFixtureStream]::new([byte[]](1))
    try {
        Assert-BlockFailure { Read-OwnedBlocks -Stream $stream -BlockSize $size } `
            ([System.Management.Automation.ParameterBindingException]) 'ParameterArgumentValidationError,Read-OwnedBlocks'
        Assert-Block ($stream.CanRead -and $stream.DisposeCalls -eq 0) 'binding error leaves caller ownership'
    } finally { $stream.Dispose() }
}
$writeOnly = [System.IO.Compression.DeflateStream]::new([System.IO.MemoryStream]::new(),
    [System.IO.Compression.CompressionMode]::Compress)
Assert-BlockFailure { Read-OwnedBlocks -Stream $writeOnly } ([System.ArgumentException])
Assert-Block (-not $writeOnly.CanWrite) 'unreadable acquired stream disposed'

# Actual local FileStream: literal .NET path with spaces, no provider expansion.
$directory = Join-Path ([System.IO.Path]::GetTempPath()) ('owned blocks ' + [guid]::NewGuid())
$null = [System.IO.Directory]::CreateDirectory($directory)
try {
    $path = Join-Path $directory 'data [literal].bin'
    [System.IO.File]::WriteAllBytes($path, [byte[]](0, 255, 10, 13, 0))
    $file = [System.IO.File]::OpenRead($path)
    $actual = @(Read-OwnedBlocks -Stream $file -BlockSize 2)
    Assert-Block ((($actual | ForEach-Object { $_.Bytes } | ForEach-Object { $_ }) -join ',') -eq '0,255,10,13,0') 'real raw file bytes'
    Assert-Block (-not $file.CanRead) 'real file closed'
} finally {
    if ([System.IO.File]::Exists($path)) { [System.IO.File]::Delete($path) }
    [System.IO.Directory]::Delete($directory)
}
Write-Output "owned block source: $script:blockChecks checks passed"
