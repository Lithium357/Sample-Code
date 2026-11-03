<?php
declare(strict_types=1);
// PHP 8.1+: lazy CSV records with explicit schema, numeric validation and cleanup.
// CSV lexical quoting follows fgetcsv, not a claim of strict RFC rejection.
function csvRows(string $path): Generator {
    $handle=fopen($path,'rb');
    if ($handle===false) throw new RuntimeException('open failed');
    try {
        $header=fgetcsv($handle,0,',','"','');
        if ($header!==['sku','units']) throw new UnexpectedValueException('header');
        $record=1;
        while (($row=fgetcsv($handle,0,',','"',''))!==false) {
            $record++;
            if ($row===[null]) continue;
            if (count($row)!==2 || $row[0]==='' || !preg_match('/^(0|[1-9][0-9]{0,3})$/D',$row[1])) {
                throw new UnexpectedValueException('record '.$record);
            }
            yield ['sku'=>$row[0],'units'=>(int)$row[1]];
        }
    } finally { fclose($handle); }
}
function check(bool $value): void {if(!$value)throw new RuntimeException('assertion failed');}
$file=tempnam(sys_get_temp_dir(),'csv fixture ');
if($file===false)throw new RuntimeException('temp file failed');
try {
    file_put_contents($file,"sku,units\r\n\"pen, blue\",2\r\n\"line\nbreak\",0\r\n\r\n");
    check(iterator_to_array(csvRows($file),false)===[['sku'=>'pen, blue','units'=>2],['sku'=>"line\nbreak",'units'=>0]]);
    file_put_contents($file,"sku,units\n");check(iterator_to_array(csvRows($file),false)===[]);
    foreach(["","units,sku\n","sku,units\nx,-1\n","sku,units\nx,01\n","sku,units\nx,10000\n","sku,units\nx,2,extra\n"] as $bad){
        file_put_contents($file,$bad);$rejected=false;
        try{iterator_to_array(csvRows($file),false);}catch(UnexpectedValueException){$rejected=true;}
        check($rejected);
    }
    file_put_contents($file,"sku,units\nfirst,1\nsecond,bad\n");
    $stream=csvRows($file);$stream->rewind();check($stream->current()===['sku'=>'first','units'=>1]);
    unset($stream); // finally closes the file even when enumeration stops early.
    check(unlink($file));check(!file_exists($file));
}finally{if(file_exists($file))unlink($file);}
echo "CSV stream: quoted newlines, lazy rows, exact schema, numeric failures and early-close cleanup passed\n";
