"""Source-bound spot-check reproducers and post-fix controls; never training data."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import uuid

ROOT = Path(__file__).resolve().parents[1]
SQL = 'sql/05_running_balances.sql'
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def now(): return datetime.now(timezone.utc).isoformat()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--phase', choices=['before', 'after'], required=True)
    parser.add_argument('--temp-root', type=Path)
    args = parser.parse_args()
    sources = sorted(p for directory in ['advanced/c','advanced/cpp','curated/c','curated/cpp']
                     for p in (ROOT/directory).glob('*') if p.suffix in ('.c','.cpp'))
    paths = [SQL, *[p.relative_to(ROOT).as_posix() for p in sources]]
    record = dict(schema_version=1, run_id=uuid.uuid4().hex, path='tools/correction_probe.py',
                  started_at=now(), platform=platform.platform(), validation_mode='control_policy',
                  invocation=[sys.executable,*sys.argv], source_hashes={p:sha(ROOT/p) for p in paths},
                  harness_hashes={'correction_probe.py':sha(Path(__file__))}, runtime_versions={'python':sys.version,'sqlite':sqlite3.sqlite_version},
                  commands=[], findings=[], phase=args.phase,
                  scope='Focused self-check/build-configuration and mutation review, not an exhaustive correctness audit or extra training volume.')
    evidence = ROOT/'research/evidence'
    for relative in paths:
        p=ROOT/relative; target=evidence/'review_sources'/(sha(p)+p.suffix)
        target.parent.mkdir(exist_ok=True)
        if not target.exists(): target.write_bytes(p.read_bytes())
    harness=evidence/'harness'/(sha(Path(__file__))+'.py')
    if not harness.exists(): harness.write_bytes(Path(__file__).read_bytes())
    def run(argv, cwd, kind, timeout=60):
        result=subprocess.run(list(map(str,argv)),cwd=cwd,capture_output=True,text=True,timeout=timeout)
        record['commands'].append(dict(argv=list(map(str,argv)),cwd=str(cwd),kind=kind,
                                       returncode=result.returncode,stdout=result.stdout,stderr=result.stderr))
        return result
    try:
        original=(ROOT/SQL).read_text(encoding='utf-8')
        needle='WHERE position = 1'
        assert original.count(needle)==1
        with sqlite3.connect(':memory:') as db:
            db.executescript(original)
            count=db.execute('SELECT COUNT(*) FROM checks').fetchone()[0]
            if args.phase=='before':
                start=original.index('WITH ranked AS')
                query=original[start:original.index(';',start)+1]
                rows=db.execute(query).fetchall()
                assert rows==[(1,'2026-01-01',8800),(1,'2026-01-03',8300),(2,'2026-01-02',3000)]
                assert count==3
            else:
                rows=db.execute('SELECT account_id,day,balance_cents FROM end_of_day_balance ORDER BY account_id,day').fetchall()
                assert rows==[(1,'2026-01-01',8800),(1,'2026-01-03',8300),(2,'2026-01-01',0),(2,'2026-01-02',3000)]
                assert count==8
        for label, replacement in [('weaken last-posting filter','WHERE position >= 1'),('remove last-posting filter','')]:
            mutant=original.replace(needle,replacement)
            data=mutant.encode('utf-8'); digest=hashlib.sha256(data).hexdigest()
            target=evidence/'mutations'/(digest+'.sql');target.parent.mkdir(exist_ok=True)
            if not target.exists(): target.write_bytes(data)
            finding=dict(path=SQL,classification='test_gap_demonstrated_by_deliberate_mutation',mutation=label,
                         original_sha256=sha(ROOT/SQL),mutant_sha256=digest,original_rows=rows)
            with sqlite3.connect(':memory:') as db:
                try: db.executescript(mutant)
                except sqlite3.IntegrityError as error:
                    assert args.phase=='after' and error.sqlite_errorname=='SQLITE_CONSTRAINT_CHECK'
                    finding.update(observed='mutation_rejected',error=error.sqlite_errorname,message=str(error))
                else:
                    assert args.phase=='before', 'broken last-posting filter survived repaired tests'
                    start=mutant.index('WITH ranked AS'); query=mutant[start:mutant.index(';',start)+1]
                    actual=db.execute(query).fetchall()
                    assert db.execute('SELECT COUNT(*) FROM checks').fetchone()[0]==3
                    assert len(actual)==4 and actual!=rows
                    finding.update(observed='all_three_checks_pass_despite_extra_output_row',mutated_rows=actual)
            record['findings'].append(finding)
        with tempfile.TemporaryDirectory(prefix='spot-correction-',dir=args.temp_root) as directory:
            temporary=Path(directory)
            for index, source in enumerate(sources):
                cpp=source.suffix=='.cpp'
                compiler=shutil.which('cl' if os.name=='nt' else ('c++' if cpp else 'cc'))
                if not compiler:raise RuntimeError('compiler unavailable: '+str(cpp))
                version=run([compiler] if os.name=='nt' else [compiler,'--version'],temporary,'version_probe')
                record['runtime_versions'][compiler]=version.stdout+version.stderr
                stem=temporary/('example-'+str(index))
                binary=stem.with_suffix('.exe') if os.name=='nt' else stem
                if os.name=='nt':
                    normal=[compiler,'/nologo','/W4','/EHsc','/std:c++20' if cpp else '/std:c17',source,'/Fe:'+str(binary),'/Fo:'+str(stem)+'.obj']
                    disabled=[*normal,'/DNDEBUG']
                else:
                    normal=[compiler,'-std=c++20' if cpp else '-std=c17','-Wall','-Wextra',source,'-o',binary]
                    disabled=[*normal,'-DNDEBUG']
                if args.phase=='after':
                    build=run(normal,temporary,'normal_build');assert build.returncode==0,source
                    execution=run([binary],temporary,'normal_execution');assert execution.returncode==0 and 'passed' in execution.stdout,source
                build=run(disabled,temporary,'assertions_disabled_build')
                finding=dict(path=source.relative_to(ROOT).as_posix(),source_sha256=sha(source),
                             side_effect_review='Inspect assert call sites separately; this probe does not prove algorithm correctness.')
                if build.returncode==0:
                    execution=run([binary],temporary,'assertions_disabled_execution',timeout=25)
                    finding.update(classification='build_configuration_false_success' if execution.returncode==0 and 'passed' in execution.stdout else 'assertion_disabled_runtime_failure',
                                   build_returncode=0,returncode=execution.returncode,stdout=execution.stdout,stderr=execution.stderr)
                    assert args.phase=='before','assertion-disabled executable unexpectedly built: '+str(source)
                else:
                    raw=build.stdout+build.stderr
                    guard=re.search(r'#ifdef NDEBUG\s*#error "([^"]+)"',source.read_text(encoding='utf-8'))
                    assert guard and guard.group(1) in raw, raw
                    finding.update(classification='assertion_disabled_build_rejected',build_returncode=build.returncode)
                record['findings'].append(finding)
        record['result']='passed'
    except Exception as error:
        record.update(result='failed',error=repr(error))
    record['finished_at']=now()
    output=evidence/'history'/(now().replace(':','-')+'-correction-'+record['run_id']+'.jsonl')
    output.write_text(json.dumps(record)+'\n',encoding='utf-8')
    print(record['result'].upper(), 'focused correction probe',args.phase,record.get('error',''))
    for finding in record['findings']:print(finding['path'],finding['classification'],finding.get('observed',finding.get('returncode',finding.get('build_returncode'))))
    print('Evidence:',output.relative_to(ROOT))
    return 0 if record['result']=='passed' else 1

if __name__=='__main__':raise SystemExit(main())
