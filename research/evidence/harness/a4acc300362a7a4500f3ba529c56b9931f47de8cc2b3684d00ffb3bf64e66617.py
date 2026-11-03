#!/usr/bin/env python3
"""Exercise review hash gates in a scratch repository; control material only.

Uses real matching baseline execution records. A comment-only Go revision is
actually compiled/run before testing stale-review rejection; no pass is invented.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import tempfile
import uuid

ROOT=Path(__file__).resolve().parents[1]
PATHS=['go/01_gcd.go','rust/01_gcd.rs','ruby/01_gcd.rb']
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def now():return datetime.now(timezone.utc).isoformat()

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--temp-root',type=Path)
    parser.add_argument('--require-tools',action='store_true')
    args=parser.parse_args()
    controls=['tools/review_policy_probe.py','tools/research_inventory.py',
              'research/reviews.jsonl','research/reviews/pass-5-gcd.md',*PATHS]
    record=dict(schema_version=1,run_id=uuid.uuid4().hex,path='tools/review_policy_probe.py',
                started_at=now(),platform=platform.platform(),validation_mode='control_policy',
                invocation=[sys.executable,*sys.argv],source_hashes={p:sha(ROOT/p) for p in controls},
                harness_hashes={p:sha(ROOT/p) for p in controls[:2]},runtime_versions={'python':sys.version},commands=[],
                qualification='Control-policy checks, not training examples or additional execution-validated source volume.')
    def run(argv,cwd,environment=None):
        result=subprocess.run(list(map(str,argv)),cwd=cwd,text=True,capture_output=True,timeout=120,
                              env={**os.environ,**(environment or {})})
        record['commands'].append(dict(argv=list(map(str,argv)),cwd=str(cwd),returncode=result.returncode,
                                       stdout=result.stdout,stderr=result.stderr,environment_overrides=environment or {}))
        if result.returncode:raise RuntimeError('control subprocess failed: '+repr(argv))
        return result.stdout
    try:
        import tiktoken
        record['runtime_versions']['tiktoken']=tiktoken.__version__
        go=shutil.which('go')
        if not go:raise ImportError('Go unavailable for genuinely executed comment-only control revision')
        record['runtime_versions']['go']=run([go,'version'],ROOT).strip()
        base=(args.temp_root or Path(tempfile.gettempdir())).resolve()
        base.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='review-policy-',dir=base) as directory:
            scratch=Path(directory).resolve()
            assert scratch.parent==base
            def copy(relative):
                destination=scratch/relative;destination.parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(ROOT/relative,destination)
            for p in PATHS:copy(p)
            for name in ('research_inventory.py','research_validate.py','verify.py','verify_advanced.py','sql_contracts.py','isa_probe.py'):copy('tools/'+name)
            document='research/reviews/pass-5-gcd.md';copy(document)
            manifest=[x for x in json.loads((ROOT/'manifest.json').read_text()) if x['path'] in PATHS]
            (scratch/'manifest.json').write_text(json.dumps(manifest),encoding='utf-8')
            (scratch/'advanced').mkdir();(scratch/'advanced/manifest.json').write_text('{"files":[]}',encoding='utf-8')
            (scratch/'research/cases.json').write_text('[]',encoding='utf-8')
            reviews=[json.loads(l) for l in (ROOT/'research/reviews.jsonl').read_text().splitlines() if l.strip()]
            reviews=[x for x in reviews if x['path'] in PATHS and x['source_sha256']==sha(ROOT/x['path'])]
            latest={x['path']:x for x in reviews}
            assert set(latest)==set(PATHS),'baseline current reviews missing'
            original_reviews=list(latest.values())
            review_file=scratch/'research/reviews.jsonl'
            def write_reviews(values):review_file.write_text(''.join(json.dumps(x)+'\n' for x in values),encoding='utf-8')
            write_reviews(original_reviews)
            baseline={}
            for history in (ROOT/'research/evidence/history').glob('*.jsonl'):
                for line in history.read_text().splitlines():
                    row=json.loads(line)
                    if row['path'] in PATHS and row['result']=='passed' and row['source_hashes'].get(row['path'])==sha(ROOT/row['path']):baseline[row['path']]=row
            assert set(baseline)==set(PATHS),'baseline genuine execution evidence missing'
            history=scratch/'research/evidence/history';history.mkdir(parents=True)
            (history/'copied-real-baseline.jsonl').write_text(''.join(json.dumps(x)+'\n' for x in baseline.values()),encoding='utf-8')
            runtime_temp=scratch/'runtime-temp';runtime_temp.mkdir()
            env={'TEMP':str(runtime_temp),'TMP':str(runtime_temp)}
            observations=[]
            def inventory(label,expected):
                run([sys.executable,scratch/'tools/research_inventory.py'],scratch,env)
                rows=[json.loads(l) for l in (scratch/'research/lineage.jsonl').read_text().splitlines()]
                actual={x['path'] for x in rows if x['training_eligibility']=='candidate_after_source_bound_checks'}
                assert actual==set(expected),(label,actual,expected)
                observations.append({'case':label,'candidate_paths':sorted(actual)})
                return {x['path']:x for x in rows}
            inventory('current source, current document, real passes',PATHS)
            doc=scratch/document; original_doc=doc.read_bytes()
            doc.write_bytes(original_doc+b'\ncontrol-only document revision\n')
            inventory('stale document rejects all three',[])
            doc.write_bytes(original_doc)
            source=scratch/PATHS[0]; original_source=source.read_bytes()
            source.write_bytes(original_source+b'\n// control-only comment revision\n')
            run([sys.executable,scratch/'tools/research_validate.py','--path',PATHS[0],'--require-tools'],scratch,env)
            after=inventory('new source passes execution but lacks new review',PATHS[1:])
            assert after[PATHS[0]]['execution_validated']
            nested=[json.loads(l) for p in history.glob('*.jsonl') for l in p.read_text().splitlines()]
            record['genuine_control_revision_execution']=next(x for x in nested if x['source_hashes'].get(PATHS[0])==sha(source) and x['result']=='passed')
            source.write_bytes(original_source)
            wrong=[dict(x) for x in original_reviews]
            next(x for x in wrong if x['path']==PATHS[0])['task_family']='wrong.family'
            write_reviews(wrong);inventory('family mismatch rejects only its file',PATHS[1:])
            revoked={**latest[PATHS[0]],'review_id':'control-revocation','outcome':'hold_for_more_review'}
            write_reviews([*original_reviews,revoked]);inventory('later revocation wins',PATHS[1:])
            record['policy_checks']=observations
        record['result']='passed'
    except ImportError as error:record.update(result='not_tested',reason=str(error))
    except Exception as error:record.update(result='failed',error=repr(error))
    record['finished_at']=now()
    history=ROOT/'research/evidence/history';history.mkdir(parents=True,exist_ok=True)
    snapshots=history.parent/'harness';snapshots.mkdir(exist_ok=True)
    for p in controls[:2]:
        target=snapshots/(sha(ROOT/p)+'.py')
        if not target.exists():target.write_bytes((ROOT/p).read_bytes())
    target=history/(now().replace(':','-')+'-policy-'+record['run_id']+'.jsonl')
    with target.open('x',encoding='utf-8') as stream:stream.write(json.dumps(record)+'\n')
    print(record['result'].upper(),'review-policy controls',record.get('error',record.get('reason','')))
    print('Evidence:',target.relative_to(ROOT))
    return int(record['result']=='failed' or (args.require_tools and record['result']=='not_tested'))
if __name__=='__main__':sys.exit(main())
