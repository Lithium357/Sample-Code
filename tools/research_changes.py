#!/usr/bin/env python3
"""Append edit/failure/resolution links without replacing historical results."""
from datetime import datetime,timezone
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def main():
    ledger=ROOT/'research/changes.jsonl'
    existing=[json.loads(line) for line in ledger.read_text().splitlines() if line.strip()] if ledger.exists() else []
    ids={row.get('event_id') for row in existing}
    latest={row['path']:row['after_sha256'] for row in existing if 'after_sha256' in row}
    events=[]
    for path,previous in latest.items():
        current=hashlib.sha256((ROOT/path).read_bytes()).hexdigest()
        if current!=previous:
            events.append({'event_id':'edit:'+path+':'+current,'kind':'subsequent_source_edit','task_id':'research-pass-1',
                           'path':path,'before_sha256':previous,'after_sha256':current,
                           'reason':'Formatting or subsequent refinement; validation must bind to the new hash.'})
    records=[]
    for path in sorted((ROOT/'research/evidence/history').glob('*.jsonl')):
        records.extend(json.loads(line) for line in path.read_text().splitlines() if line.strip())
    records.sort(key=lambda row:row['finished_at'])
    for index,row in enumerate(records):
        if row['result']!='failed':continue
        event_id='failure:'+row['run_id']+':'+row['path']
        events.append({'event_id':event_id,'kind':'observed_validation_failure','task_id':'research-pass-1',
                       'path':row['path'],'run_id':row['run_id'],'source_hashes':row['source_hashes'],
                       'harness_hashes':row['harness_hashes'],'error':row.get('error'),
                       'original_result_preserved':True})
        after=next((r for r in records[index+1:] if r['path']==row['path'] and r['result']=='passed'),None)
        if after:
            events.append({'event_id':'resolution:'+event_id,'kind':'subsequent_successful_rerun',
                           'path':row['path'],'failed_run_id':row['run_id'],'passed_run_id':after['run_id'],
                           'failed_source_hashes':row['source_hashes'],'passed_source_hashes':after['source_hashes'],
                           'source_bundle_changed':row['source_hashes']!=after['source_hashes'],
                           'mechanism':'See research/fixes.md; successful rerun does not erase the failure.'})
    with ledger.open('a',encoding='utf-8') as stream:
        added=0
        for event in events:
            if event['event_id'] not in ids:
                event['recorded_at']=datetime.now(timezone.utc).isoformat()
                stream.write(json.dumps(event)+'\n');ids.add(event['event_id']);added+=1
    print('Appended ledger events:',added)

if __name__=='__main__':main()
