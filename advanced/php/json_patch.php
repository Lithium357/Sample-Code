<?php
declare(strict_types=1);
// Transactional JSON Patch subset with JSON Pointer escaping and array insertion.
// php json_patch.php
// Supports add/remove/replace/test/copy/move. Root add/replace are supported;
// removing the entire document is explicitly rejected. PHP native JSON number
// precision applies. Inputs must originate from JSON, not arbitrary PHP objects.
final class PatchError extends RuntimeException {}
function cloneJson(mixed $value): mixed {
    return json_decode(json_encode($value, JSON_THROW_ON_ERROR | JSON_PRESERVE_ZERO_FRACTION), false, 512, JSON_THROW_ON_ERROR);
}
function pointer(string $path): array {
    if ($path === '') return [];
    if ($path[0] !== '/') throw new PatchError('pointer must start with slash');
    $tokens = explode('/', substr($path, 1));
    foreach ($tokens as &$token) {
        if (preg_match('/~(?![01])/', $token)) throw new PatchError('invalid pointer escape');
        $token = str_replace(['~1', '~0'], ['/', '~'], $token);
    }
    return $tokens;
}
function arrayIndex(string $token, int $size, bool $inserting): int {
    if ($token === '-' && $inserting) return $size;
    if (!preg_match('/^(0|[1-9][0-9]*)$/D', $token) || strlen($token) > strlen((string)$size)) {
        throw new PatchError('noncanonical array index');
    }
    $index = (int)$token;
    if ($index > $size || (!$inserting && $index === $size)) throw new PatchError('array index outside range');
    return $index;
}
function readPath(mixed $document, array $tokens): mixed {
    foreach ($tokens as $token) {
        if ($document instanceof stdClass && property_exists($document, $token)) $document = $document->{$token};
        elseif (is_array($document)) $document = $document[arrayIndex($token, count($document), false)];
        else throw new PatchError('path does not exist');
    }
    return $document;
}
function &parentAt(mixed &$document, array $tokens): mixed {
    $current =& $document;
    foreach ($tokens as $token) {
        if ($current instanceof stdClass && property_exists($current, $token)) $current =& $current->{$token};
        elseif (is_array($current)) { $index = arrayIndex($token, count($current), false); $current =& $current[$index]; }
        else throw new PatchError('missing parent');
    }
    return $current;
}
function modify(mixed &$document, array $tokens, string $operation, mixed $value = null): void {
    if ($tokens === []) {
        if ($operation === 'remove') throw new PatchError('root removal is unsupported');
        $document = cloneJson($value); return;
    }
    $last = array_pop($tokens);
    $parent =& parentAt($document, $tokens);
    if ($parent instanceof stdClass) {
        if ($operation !== 'add' && !property_exists($parent, $last)) throw new PatchError('missing member');
        if ($operation === 'remove') unset($parent->{$last});
        else $parent->{$last} = cloneJson($value);
    } elseif (is_array($parent)) {
        $index = arrayIndex($last, count($parent), $operation === 'add');
        if ($operation === 'add') array_splice($parent, $index, 0, [cloneJson($value)]);
        elseif ($operation === 'remove') array_splice($parent, $index, 1);
        else $parent[$index] = cloneJson($value);
    } else throw new PatchError('parent is scalar');
}
function jsonEqual(mixed $a, mixed $b): bool {
    if ((is_int($a) || is_float($a)) && (is_int($b) || is_float($b))) return $a == $b;
    if (gettype($a) !== gettype($b)) return false;
    if ($a instanceof stdClass) {
        $a = get_object_vars($a); $b = get_object_vars($b); ksort($a); ksort($b);
        if (array_keys($a) !== array_keys($b)) return false;
        foreach ($a as $key => $value) if (!jsonEqual($value, $b[$key])) return false;
        return true;
    }
    if (is_array($a)) {
        if (count($a) !== count($b)) return false;
        foreach ($a as $index => $value) if (!jsonEqual($value, $b[$index])) return false;
        return true;
    }
    return $a === $b;
}
function patch(mixed $original, array $operations): mixed {
    $document = cloneJson($original); // Failure never changes the caller's object.
    foreach ($operations as $operation) {
        if (!is_array($operation) || !isset($operation['op'], $operation['path']) ||
            !is_string($operation['op']) || !is_string($operation['path'])) throw new PatchError('invalid operation');
        $path = pointer($operation['path']); $kind = $operation['op'];
        if (in_array($kind, ['add', 'replace', 'test'], true)) {
            if (!array_key_exists('value', $operation)) throw new PatchError('value required');
            if ($kind === 'test') {
                if (!jsonEqual(readPath($document, $path), $operation['value'])) throw new PatchError('test failed');
            } else modify($document, $path, $kind, $operation['value']);
        } elseif ($kind === 'remove') modify($document, $path, 'remove');
        elseif ($kind === 'copy' || $kind === 'move') {
            if (!isset($operation['from']) || !is_string($operation['from'])) throw new PatchError('from required');
            $from = pointer($operation['from']);
            $value = cloneJson(readPath($document, $from));
            if ($kind === 'move') {
                if ($from === $path) continue;
                if (count($path) > count($from) && array_slice($path, 0, count($from)) === $from) {
                    throw new PatchError('cannot move ancestor into descendant');
                }
                modify($document, $from, 'remove');
            }
            // Array destination indices are evaluated after source removal.
            modify($document, $path, 'add', $value);
        } else throw new PatchError('unknown operation');
    }
    return $document;
}
function check(bool $value): void { if (!$value) throw new RuntimeException('self-check failed'); }
$original = json_decode('{"items":["a","b","c"],"a/b":{"~":null},"obj":{"x":1}}', false, 512, JSON_THROW_ON_ERROR);
$result = patch($original, [
    ['op'=>'test','path'=>'/a~1b/~0','value'=>null],
    ['op'=>'move','from'=>'/items/0','path'=>'/items/2'],
    ['op'=>'copy','from'=>'/obj','path'=>'/copy'],
    ['op'=>'replace','path'=>'/obj/x','value'=>2],
    ['op'=>'add','path'=>'/items/-','value'=>'d'],
]);
check($result->items === ['b','c','a','d'] && $result->copy->x === 1 && $result->obj->x === 2);
check($original->items === ['a','b','c'] && $original->obj->x === 1);
foreach ([
    [['op'=>'remove','path'=>'/missing']],
    [['op'=>'add','path'=>'/items/01','value'=>1]],
    [['op'=>'replace','path'=>'/items/-','value'=>1]],
    [['op'=>'move','from'=>'/obj','path'=>'/obj/child']],
    [['op'=>'test','path'=>'/obj/x','value'=>true]],
    [['op'=>'add','path'=>'/~2','value'=>1]],
    [['op'=>'replace','path'=>'/obj/x','value'=>9],['op'=>'remove','path'=>'/missing']],
] as $operations) {
    $rejected = false; try { patch($original, $operations); } catch (PatchError) { $rejected = true; }
    check($rejected && $original->obj->x === 1);
}
check(jsonEqual(json_decode('{"a":1,"b":2}'),json_decode('{"b":2,"a":1.0}')));
check(patch($original,[['op'=>'replace','path'=>'','value'=>[1,2]]]) === [1,2]);
echo "JSON Patch: escaped pointers, array moves, deep copies, tests and atomic rejection passed\n";
