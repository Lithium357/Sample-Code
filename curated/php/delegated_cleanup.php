<?php
declare(strict_types=1);
// PHP 8.1+: yield-from forwarding, generator return values and cleanup order.
// Run: php delegated_cleanup.php. No services, files or third-party packages.
// Validation is lazy. Already delivered values cannot be rolled back. An item
// is acknowledged only when its yield resumes normally; SkipRow skips its ack.
// Breaking foreach does not dispose a still-referenced PHP generator. The
// consumer owns that reference and must release it to trigger early cleanup.
final class SkipRow extends RuntimeException {}

function checkedSource(array $rows, array &$events): Generator {
    $acknowledged=0;
    try {
        foreach ($rows as $position=>$row) {
            if (!is_array($row) || array_keys($row)!==['id','value'] ||
                !is_string($row['id']) || $row['id']==='' ||
                !is_int($row['value']) || $row['value']<0 || $row['value']>99) {
                throw new UnexpectedValueException('invalid record '.$position);
            }
            try {
                yield $row['id']=>$row['value'];
                $acknowledged++;
                $events[]='ack '.$position;
            } catch (SkipRow) {
                $events[]='skip '.$position;
            }
        }
        return $acknowledged;
    } finally {
        $events[]='source closed';
    }
}
function delegated(array $rows, array &$events): Generator {
    try {
        $count=yield from checkedSource($rows,$events);
        $events[]='return '.$count;
        return $count;
    } finally {
        $events[]='delegate closed';
    }
}
function check(bool $truth): void { if (!$truth) throw new RuntimeException('assertion failed'); }
function unavailableReturn(Generator $generator): void {
    $rejected=false;
    try { $generator->getReturn(); }
    catch (Exception $error) { check($error::class===Exception::class); $rejected=true; }
    check($rejected);
}
$rows=[['id'=>'same','value'=>0],['id'=>'same','value'=>99]];
$events=[];
$generator=delegated($rows,$events);
check($events===[]); // merely creating a generator executes no body
unset($generator);
check($events===[]); // an unstarted generator acquired nothing to clean up

$generator=delegated($rows,$events);
$generator->rewind();
check($generator->key()==='same' && $generator->current()===0);
unavailableReturn($generator);
$generator->next();
check($generator->key()==='same' && $generator->current()===99);
$generator->next();
check(!$generator->valid() && $generator->getReturn()===2);
check($events===['ack 0','ack 1','source closed','return 2','delegate closed']);
unset($generator);
check($events===['ack 0','ack 1','source closed','return 2','delegate closed']);

$events=[];$generator=delegated($rows,$events);
// Preserve values, not associative keys: duplicate stream keys are intentional.
check(iterator_to_array($generator,false)===[0,99]);
check($generator->getReturn()===2);
unset($generator);

$events=[];$generator=delegated($rows,$events);
$generator->rewind();
// throw() is forwarded through yield-from and returns the NEXT yielded value.
check($generator->throw(new SkipRow('fixture skip'))===99);
check($generator->key()==='same' && $generator->current()===99 && $events===['skip 0']);
$generator->next();
check($generator->getReturn()===1);
check($events===['skip 0','ack 1','source closed','return 1','delegate closed']);
unset($generator);

$events=[];$generator=delegated($rows,$events);
$generator->rewind();$failure=new DomainException('fixture terminal error');$caught=false;
try { $generator->throw($failure); }
catch (DomainException $actual) { check($actual===$failure);$caught=true; }
check($caught && !$generator->valid());
check($events===['source closed','delegate closed']);
unavailableReturn($generator);
unset($generator);

$events=[];$generator=delegated($rows,$events);
foreach ($generator as $value) { check($value===0); break; }
check($events===[]); // still suspended, still owned by $generator
unset($generator);
check($events===['source closed','delegate closed']);

$events=[];$generator=delegated([],$events);
check(iterator_to_array($generator,false)===[] && $generator->getReturn()===0);
check($events===['source closed','return 0','delegate closed']);
unset($generator);

foreach ([[],['id'=>'','value'=>1],['id'=>'x','value'=>-1],
          ['id'=>'x','value'=>100],['id'=>'x','value'=>'1'],
          ['value'=>1,'id'=>'x'],['id'=>'x','value'=>1,'extra'=>true]] as $bad) {
    $events=[];$generator=delegated([$rows[0],$bad],$events);$rejected=false;
    try { iterator_to_array($generator,false); }
    catch (UnexpectedValueException $error) {
        check($error->getMessage()==='invalid record 1');$rejected=true;
    }
    check($rejected && $events===['ack 0','source closed','delegate closed']);
    unset($generator);
}
echo "PHP delegation: lazy validation, duplicate keys, forwarded skip/errors, getReturn and exact cleanup order passed\n";
