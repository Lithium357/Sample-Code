#!/usr/bin/env python3
"""Source lineage and cl100k_base volume with source-bound evidence eligibility.
Historical aggregate reports do not count as current reproducible validation.
"""
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import tiktoken

ROOT=Path(__file__).resolve().parents[1]
ENC=tiktoken.get_encoding('cl100k_base')

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def count(path):return len(ENC.encode(path.read_text(encoding='utf-8'),disallowed_special=()))

def refresh():
    path=ROOT/'manifest.json'
    basic=json.loads(path.read_text())
    for entry in basic:
        source=ROOT/entry['path']
        entry.update(tokens=count(source),bytes=source.stat().st_size,sha256=sha(source))
    path.write_text(json.dumps(basic,indent=2)+'\n',encoding='utf-8')
    path=ROOT/'advanced/manifest.json'
    advanced=json.loads(path.read_text())
    totals=Counter()
    for entry in advanced['files']:
        source=ROOT/entry['path']
        entry.update(tokens=count(source),bytes=source.stat().st_size,sha256=sha(source))
        totals[entry['language']]+=entry['tokens']
    advanced.update(tokens=sum(totals.values()),tokens_by_language=dict(totals))
    path.write_text(json.dumps(advanced,indent=2)+'\n',encoding='utf-8')
    return basic,advanced['files']

def main():
    basic,advanced=refresh()
    registry=ROOT/'research/cases.json'
    cases=json.loads(registry.read_text()) if registry.exists() else []
    curated={}
    for case in cases:
        for path in [case['path'],*case.get('support',[])]:
            curated[path]={'path':path,'language':case['language'],'task_family':case['task_family'],
                           'role':case.get('support_roles',{}).get(path,case.get('role','source') if path==case['path'] else 'support_source'),
                           'primary_unit':case['path']}
    rows=[]
    for entry in basic:
        stem=re.sub(r'^(sample_)?\d+_','',Path(entry['path']).stem)
        rows.append({**entry,'task_family':('sqlite.scenario.' if entry['language']=='sql' else 'parallel.integer.')+stem,
                     'task_id':'conversation-round-1','origin':'synthetic_parallel','role':'source_with_inline_fixtures',
                     'generation_model_version':None,'origin_audit':'legacy_not_exhaustively_audited'})
    for entry in advanced:
        language=entry['language']
        round_id='conversation-round-2'
        if language in ('c','cpp') or Path(entry['path']).stem in ('overlap_memmove','radix_sort_i32','crc32_ieee','suffix_index','earley_recognizer','two_sat','weighted_semaphore','wal_recovery','observed_remove_set'):
            round_id='conversation-round-3'
        rows.append({**entry,'task_family':'advanced.'+Path(entry['path']).stem,
                     'task_id':round_id,'origin':'synthetic_individually_authored','role':'source_with_inline_fixtures',
                     'generation_model_version':None,'origin_audit':'legacy_not_exhaustively_audited'})
    for entry in curated.values():
        path=ROOT/entry['path']
        rows.append({**entry,'sha256':sha(path),'bytes':path.stat().st_size,'tokens':count(path),
                     'task_id':'research-pass-1','origin':'synthetic_individually_authored',
                     'generation_model_version':None,'origin_audit':'no_benchmark_source_intentionally_used'})
    evidence=[]
    for path in sorted((ROOT/'research/evidence/history').glob('*.jsonl')):
        for line in path.read_text(encoding='utf-8').splitlines():
            if line.strip():evidence.append(json.loads(line))
    current_hashes={row['path']:row['sha256'] for row in rows}
    evidence.sort(key=lambda record:record['finished_at'])
    eligible={}
    for record in evidence:
        bundle=record['source_hashes']
        if all(current_hashes.get(path)==digest for path,digest in bundle.items()):
            key=(record['path'],record['validation_mode'])
            eligible[key]=record
    passed_paths=set()
    for record in eligible.values():
        if record['result']=='passed' and record['validation_mode'] in ('native','native_sqlite','native_postgresql','transpiled_js','emulation'):
            passed_paths.update(record['source_hashes'])
    for row in rows:
        row['provenance_ref']='research/provenance/session.json'
        row['prompt_ref']='research/provenance/research-request.txt' if row['task_id']=='research-pass-1' else 'research/provenance/session.json#prompts'
        row['edits_ref']='research/changes.jsonl'
        row['current_source_bound_pass']=row['path'] in passed_paths
        row['execution_validated']=row['current_source_bound_pass']
        row['training_eligibility']=('candidate_after_source_bound_checks' if row['origin_audit']=='no_benchmark_source_intentionally_used' and row['current_source_bound_pass']
                                     else 'hold_for_validation' if row['origin_audit']=='no_benchmark_source_intentionally_used' else 'legacy_origin_and_coverage_review_required')
        row['validation_records']=[{'run_id':r['run_id'],'result':r['result'],'mode':r['validation_mode']}
                                   for (path,_),r in eligible.items() if path==row.get('primary_unit',row['path'])]
    output=ROOT/'research/lineage.jsonl'
    output.write_text(''.join(json.dumps(row,ensure_ascii=False)+'\n' for row in rows),encoding='utf-8')
    by_language={}
    for language in sorted({row['language'] for row in rows}):
        subset=[row for row in rows if row['language']==language]
        by_language[language]={'files':len(subset),'generated_tokens':sum(row['tokens'] for row in subset),
                               'current_source_bound_pass_tokens':sum(row['tokens'] for row in subset if row['current_source_bound_pass'])}
    role_totals=Counter()
    for row in rows:role_totals[row['role']]+=row['tokens']
    report={'tokenizer':'cl100k_base','morderca_tokenizer_used':False,'counting':'sum of individually tokenized source/support files; normalized text newlines',
            'tokenizer_implementation':'tiktoken','tokenizer_implementation_version':tiktoken.__version__,
            'whole_file_role_tokens':dict(role_totals),
            'role_notice':'File roles, not lexical code-only counts; source files may contain inline comments/self-checks.',
            'inline_components':None,'component_reason':'comments and inline fixtures not lexically separated; BPE segment counts are not additive',
            'files':len(rows),'generated_tokens':sum(row['tokens'] for row in rows),
            'current_source_bound_pass_files':sum(row['current_source_bound_pass'] for row in rows),
            'current_source_bound_pass_tokens':sum(row['tokens'] for row in rows if row['current_source_bound_pass']),
            'execution_validated_files':sum(row['execution_validated'] for row in rows),
            'execution_validated_tokens':sum(row['tokens'] for row in rows if row['execution_validated']),
            'execution_scope':'Native, transpiled JS or emulated checks only; syntax-only success is excluded.',
            'by_language':by_language,
            'qualification':'Evidence applies to source hashes/modes recorded. Legacy aggregate passes are retained but not counted here; passing is not a model-performance result.'}
    (ROOT/'research/volume.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({key:value for key,value in report.items() if key!='by_language'},indent=2))

if __name__=='__main__':main()
