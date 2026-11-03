<?php
declare(strict_types=1);
// PHP 8.1+ streams. Run: php bom_filter.php
// Strip exactly one UTF-8 BOM at byte offset zero. This is a byte transform,
// NOT UTF-8 validation: NUL, high bytes and later BOMs are preserved. Up to
// three initial bytes may be delayed until the decision or final flush.
// Both READ and WRITE filters work on owned php://temp fixtures, without files
// or services. Expected input accounting is distinct from emitted byte count.

final class FilterAudit
{
    public int $created = 0;
    public int $closed = 0;
    public int $consumed = 0;
    public int $heldMax = 0;
}

final class InitialBomFilter extends php_user_filter
{
    private string $prefix = '';
    private bool $decided = false;
    private ?FilterAudit $audit = null;

    public function onCreate(): bool
    {
        if (!$this->params instanceof FilterAudit) {
            return false;
        }
        $this->audit = $this->params;
        ++$this->audit->created;
        return true;
    }

    public function filter($in, $out, &$consumed, bool $closing): int
    {
        $produced = false;
        while (($bucket = stream_bucket_make_writeable($in)) !== null) {
            $bytes = $bucket->data;
            $length = strlen($bytes);
            $consumed += $length;
            $this->audit->consumed += $length;
            if ($this->decided) {
                stream_bucket_append($out, $bucket);
                $produced = $produced || $length > 0;
                continue;
            }
            $take = min(3 - strlen($this->prefix), $length);
            $this->prefix .= substr($bytes, 0, $take);
            $this->audit->heldMax = max($this->audit->heldMax, strlen($this->prefix));
            if (strlen($this->prefix) < 3) {
                continue; // bucket consumed, no output brigade to pass on yet
            }
            $bytes = ($this->prefix === "\xEF\xBB\xBF" ? '' : $this->prefix)
                . substr($bytes, $take);
            $this->prefix = '';
            $this->decided = true;
            if ($bytes !== '') {
                // Use a new bucket: do not assign version-dependent/read-only
                // StreamBucket properties or its deprecated datalen property.
                stream_bucket_append($out, stream_bucket_new($this->stream, $bytes));
                $produced = true;
            }
        }
        if ($closing && !$this->decided) {
            // A proper prefix such as EF BB is data when EOF arrives early.
            if ($this->prefix !== '') {
                stream_bucket_append($out, stream_bucket_new($this->stream, $this->prefix));
                $produced = true;
            }
            $this->prefix = '';
            $this->decided = true;
        }
        return $produced ? PSFS_PASS_ON : PSFS_FEED_ME;
    }

    public function onClose(): void
    {
        if ($this->audit !== null) {
            ++$this->audit->closed;
        }
    }
}

function check(bool $ok, string $message): void
{
    if (!$ok) { throw new RuntimeException($message); }
}

set_error_handler(static function (int $severity, string $message, string $file, int $line): never {
    throw new ErrorException($message, 0, $severity, $file, $line);
});
check(stream_filter_register('morderca.initial-bom', InitialBomFilter::class), 'register filter');

/** @param list<string> $chunks */
function writeFiltered(array $chunks): string
{
    $stream = fopen('php://temp', 'w+b');
    check(is_resource($stream), 'open write fixture');
    $audit = new FilterAudit();
    try {
        $filter = stream_filter_append($stream, 'morderca.initial-bom', STREAM_FILTER_WRITE, $audit);
        check(is_resource($filter), 'attach write filter');
        $input = 0;
        foreach ($chunks as $chunk) {
            check(fwrite($stream, $chunk) === strlen($chunk), 'input bytes consumed');
            $input += strlen($chunk);
            check(fflush($stream), 'incremental flush');
        }
        check(stream_filter_remove($filter), 'remove/final-flush write filter');
        check($audit->created === 1 && $audit->closed === 1, 'one write filter lifetime');
        check($audit->consumed === $input && $audit->heldMax <= 3, 'bounded prefix/accounting');
        // Removal makes subsequent writes raw, including a fresh BOM.
        check(fwrite($stream, "\xEF\xBB\xBF!") === 4, 'write after filter removal');
        check(rewind($stream), 'rewind output');
        $result = stream_get_contents($stream);
        check(is_string($result) && str_ends_with($result, "\xEF\xBB\xBF!"), 'raw suffix preserved');
        return substr($result, 0, -4);
    } finally {
        check(fclose($stream), 'close write fixture');
    }
}

function readFiltered(string $input, int $chunkSize): string
{
    $stream = fopen('php://temp', 'w+b');
    check(is_resource($stream), 'open read fixture');
    $audit = new FilterAudit();
    try {
        check(fwrite($stream, $input) === strlen($input), 'write source bytes');
        check(rewind($stream), 'rewind source');
        check(stream_set_chunk_size($stream, $chunkSize) > 0, 'set read chunk size');
        $filter = stream_filter_append($stream, 'morderca.initial-bom', STREAM_FILTER_READ, $audit);
        check(is_resource($filter), 'attach read filter');
        $result = stream_get_contents($stream);
        check(is_string($result), 'read filtered bytes');
        check(stream_filter_remove($filter), 'remove read filter');
        check($audit->created === 1 && $audit->closed === 1, 'one read filter lifetime');
        check($audit->consumed === strlen($input) && $audit->heldMax <= 3, 'read accounting');
        return $result;
    } finally {
        check(fclose($stream), 'close read fixture');
    }
}

$bom = "\xEF\xBB\xBF";
$cases = [
    ['', ''], ['a', 'a'], ['ab', 'ab'], ['abc', 'abc'],
    ["\xEF", "\xEF"], ["\xEF\xBB", "\xEF\xBB"], [$bom, ''],
    [$bom . 'X', 'X'], ["\xEF\xBBX", "\xEF\xBBX"],
    ["\xEFX\xBF", "\xEFX\xBF"], ["\0\xFF\xEF", "\0\xFF\xEF"],
    [$bom . $bom . 'Z', $bom . 'Z'], ['text' . $bom, 'text' . $bom],
];
$partitions = 0;
foreach ($cases as [$input, $expected]) {
    for ($first = 0; $first <= strlen($input); ++$first) {
        for ($second = $first; $second <= strlen($input); ++$second) {
            $chunks = [substr($input, 0, $first), substr($input, $first, $second - $first), substr($input, $second)];
            check(writeFiltered($chunks) === $expected, 'fixed expected bytes across write partitions');
            ++$partitions;
        }
    }
    foreach ([1, 2, 3, 7] as $chunkSize) {
        check(readFiltered($input, $chunkSize) === $expected, 'fixed expected bytes across read chunks');
    }
}
$allBytes = implode('', array_map(chr(...), range(0, 255)));
foreach ([1, 2, 17, 64] as $chunkSize) {
    check(readFiltered($allBytes, $chunkSize) === $allBytes, 'all non-BOM bytes unchanged');
    check(readFiltered($bom . $allBytes, $chunkSize) === $allBytes, 'BOM before arbitrary binary data');
}

// Two streams interleave their partial headers; state must be per filter.
$a = fopen('php://temp', 'w+b');
$b = fopen('php://temp', 'w+b');
check(is_resource($a) && is_resource($b), 'interleaved streams');
$auditA = new FilterAudit(); $auditB = new FilterAudit();
try {
    $fa = stream_filter_append($a, 'morderca.initial-bom', STREAM_FILTER_WRITE, $auditA);
    $fb = stream_filter_append($b, 'morderca.initial-bom', STREAM_FILTER_WRITE, $auditB);
    check(fwrite($a, "\xEF") === 1 && fwrite($b, 'Q') === 1, 'partial independent prefixes');
    check(fwrite($a, "\xBB\xBFok") === 4 && fwrite($b, 'RS') === 2, 'complete independent prefixes');
    check(stream_filter_remove($fa) && stream_filter_remove($fb), 'remove both filters');
    rewind($a); rewind($b);
    check(stream_get_contents($a) === 'ok' && stream_get_contents($b) === 'QRS', 'independent states');
    check($auditA->consumed === 5 && $auditB->consumed === 3, 'independent counters');
} finally {
    fclose($a); fclose($b);
}
check($auditA->closed === 1 && $auditB->closed === 1, 'no repeated close after removal');

$invalid = fopen('php://temp', 'w+b');
check(is_resource($invalid), 'invalid-parameter fixture');
$rejected = false;
try {
    stream_filter_append($invalid, 'morderca.initial-bom', STREAM_FILTER_WRITE, new stdClass());
} catch (ErrorException $error) {
    $rejected = $error->getSeverity() === E_WARNING && str_contains($error->getMessage(), 'filter');
} finally { fclose($invalid); }
check($rejected, 'bad filter parameters rejected through warning-to-exception boundary');
restore_error_handler();
echo "BOM stream filter: $partitions write partitions, read chunks, binary data and lifetimes passed\n";
