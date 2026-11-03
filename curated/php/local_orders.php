<?php
declare(strict_types=1);
// PHP 8.1+, PDO SQLite. Local JSON-request boundary; no web server or credentials.
// php local_orders.php. Missing PDO SQLite exits 77, not a successful test.
if (!in_array('sqlite', PDO::getAvailableDrivers(), true)) {
    fwrite(STDERR, "PDO SQLite unavailable\n"); exit(77);
}
final class BadRequest extends RuntimeException {}
function validateRequest(string $method, string $contentType, string $body): array {
    if ($method !== 'POST' || strtolower(trim(explode(';', $contentType)[0])) !== 'application/json') {
        throw new BadRequest('POST application/json required');
    }
    try { $value = json_decode($body, false, 32, JSON_THROW_ON_ERROR); }
    catch (JsonException $error) { throw new BadRequest('invalid JSON', 0, $error); }
    if (!$value instanceof stdClass) throw new BadRequest('object required');
    $fields = get_object_vars($value); $keys = array_keys($fields); sort($keys);
    if ($keys !== ['id', 'notes', 'quantity', 'sku']) throw new BadRequest('unexpected fields');
    if (!is_string($value->id) || !preg_match('/^[a-z0-9-]{1,24}$/D', $value->id) ||
        !is_string($value->sku) || !preg_match('/^[A-Z]{1,12}$/D', $value->sku) ||
        !is_int($value->quantity) || $value->quantity < 1 || $value->quantity > 10 ||
        !is_string($value->notes) || strlen($value->notes) > 128) throw new BadRequest('invalid field');
    return $fields;
}
function createOrder(PDO $db, array $request): void {
    $db->beginTransaction();
    try {
        $statement = $db->prepare('INSERT INTO orders(id,notes) VALUES(:id,:notes)');
        $statement->execute([':id'=>$request['id'], ':notes'=>$request['notes']]);
        $line = $db->prepare('INSERT INTO lines(order_id,sku,quantity) VALUES(:id,:sku,:quantity)');
        $line->execute([':id'=>$request['id'], ':sku'=>$request['sku'], ':quantity'=>$request['quantity']]);
        $db->commit();
    } catch (Throwable $error) {
        if ($db->inTransaction()) $db->rollBack();
        throw $error;
    }
}
function orders(PDO $db): Generator {
    $query = $db->query('SELECT o.id,o.notes,l.sku,l.quantity FROM orders o JOIN lines l ON l.order_id=o.id ORDER BY o.id');
    try { while (($row = $query->fetch(PDO::FETCH_ASSOC)) !== false) yield $row; }
    finally { $query->closeCursor(); }
}
function check(bool $condition): void { if (!$condition) throw new RuntimeException('assertion failed'); }
$db = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
$db->exec('PRAGMA foreign_keys=ON; CREATE TABLE product(sku TEXT PRIMARY KEY);
CREATE TABLE orders(id TEXT PRIMARY KEY,notes TEXT NOT NULL);
CREATE TABLE lines(order_id TEXT PRIMARY KEY REFERENCES orders(id),sku TEXT NOT NULL REFERENCES product(sku),quantity INTEGER NOT NULL CHECK(quantity BETWEEN 1 AND 10));
INSERT INTO product VALUES(\'PEN\');');
$notes = "'); DROP TABLE orders; --";
$json = json_encode(['id'=>'order-1','sku'=>'PEN','quantity'=>2,'notes'=>$notes], JSON_THROW_ON_ERROR);
$request = validateRequest('POST', 'application/json; charset=utf-8', $json);
createOrder($db, $request);
check(iterator_to_array(orders($db), false) === [['id'=>'order-1','notes'=>$notes,'sku'=>'PEN','quantity'=>2]]);
foreach (['', '[]', '{', '{"id":"x"}', str_replace('"quantity":2', '"quantity":2.5', $json),
          str_replace('"quantity":2', '"quantity":0', $json)] as $bad) {
    $rejected = false;
    try { validateRequest('POST','application/json',$bad); } catch (BadRequest) { $rejected=true; }
    check($rejected);
}
foreach ([['GET','application/json'],['POST','text/plain']] as [$method,$type]) {
    $rejected=false; try { validateRequest($method,$type,$json); } catch (BadRequest) { $rejected=true; } check($rejected);
}
$before = iterator_to_array(orders($db), false);
foreach ([['quantity'=>11],['notes'=>str_repeat('x',129)],['extra'=>true]] as $change) {
    $rejected=false;
    try { validateRequest('POST','application/json',json_encode(array_replace($request,$change),JSON_THROW_ON_ERROR)); }
    catch (BadRequest) { $rejected=true; }
    check($rejected);
}
check(validateRequest('POST','application/json',json_encode(array_replace($request,['quantity'=>10,'notes'=>str_repeat('x',128)]),JSON_THROW_ON_ERROR))['quantity']===10);
foreach ([$request, array_replace($request,['id'=>'order-2','sku'=>'MISSING'])] as $invalid) {
    $rejected=false; try { createOrder($db,$invalid); } catch (PDOException $error) { $rejected=true; check($error->getCode()==='23000'); }
    check($rejected && !$db->inTransaction() && iterator_to_array(orders($db), false)===$before);
}
check((int)$db->query('SELECT COUNT(*) FROM orders')->fetchColumn()===1);
echo "Local orders: strict JSON, prepared literals, generator rows and transaction rollback passed\n";
