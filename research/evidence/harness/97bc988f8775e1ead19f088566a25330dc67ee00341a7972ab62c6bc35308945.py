#!/usr/bin/env python3
"""Append-only, source-bound validation. No automatic installation or services.

python tools/research_validate.py --suite repairs
python tools/research_validate.py --suite curated
python tools/research_validate.py --path sql/14_nonoverlapping_bookings.sql
Missing tools are recorded per unit as not_tested; --require-tools fails the run.
History JSONL files are never overwritten; each invocation gets a fresh run id.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path
import platform
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import uuid
import verify as legacy
from sql_contracts import check_contracts, mutations
from sql_contracts import OBSERVATIONS

ROOT = Path(__file__).resolve().parents[1]
CURRENT = None

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def now():
    return datetime.now(timezone.utc).isoformat()

def execute(argv, cwd, timeout=90, probe=False):
    command = [str(value) for value in argv]
    record = {'argv':command,'cwd':str(cwd),'started_at':now(),'kind':'version_probe' if probe else 'test_command'}
    try:
        result = subprocess.run(command,cwd=cwd,text=True,capture_output=True,timeout=timeout)
        record.update(returncode=result.returncode,stdout=result.stdout,stderr=result.stderr)
    except Exception as error:
        record.update(returncode=None,error=repr(error))
        if CURRENT is not None: CURRENT['commands'].append(record)
        raise
    if CURRENT is not None: CURRENT['commands'].append(record)
    if result.returncode and not probe:
        if result.returncode == 77:
            raise MissingTool(result.stdout + result.stderr)
        raise RuntimeError(f'command exited {result.returncode}: {result.stdout}\n{result.stderr}')
    return result.stdout.strip()

class MissingTool(Exception): pass

def probe(language):
    commands = {
        'ruby':[['ruby','--version']], 'go':[['go','version']],
        'rust':[['rustc','--version','--verbose']], 'php':[['php','--version']],
        'bash':[['bash','--version']], 'cmd':[[os.environ.get('COMSPEC','cmd.exe'),'/d','/c','ver']],
        'powershell':[['pwsh','-NoProfile','-Command','$PSVersionTable | ConvertTo-Json -Compress']],
        'nim':[['nim','--version'],['node','--version']],
        'c':[['cl']] if os.name=='nt' else [['cc','--version']],
    }
    for command in commands.get(language,[]):
        program = shutil.which(command[0])
        if not program: raise MissingTool('missing executable: '+command[0])
        execute([program,*command[1:]],ROOT,probe=True)
        last=CURRENT['commands'][-1]
        CURRENT['runtime_versions'][command[0]]={'probe_returncode':last['returncode'],
                                                'output':last['stdout']+last['stderr']}

def repair_cases():
    basic = json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))
    cases = [{'path':entry['path'],'language':'sql','mode':'native_sqlite'} for entry in basic if entry['language']=='sql']
    cases += [{'path':p.relative_to(ROOT).as_posix(),'language':'sql','mode':'native_sqlite'} for p in sorted((ROOT/'advanced/sql').glob('*.sql'))]
    cases += [
        {'path':'advanced/ruby/exact_cover.rb','language':'ruby','mode':'native'},
        {'path':'advanced/go/dag_scheduler.go','language':'go','mode':'native'},
        {'path':'advanced/c/incremental_frames.c','language':'c','mode':'native'},
    ]
    return cases

def validate(case, temporary):
    path = ROOT/case['path']
    language = case['language']
    if case.get('mode') == 'not_tested': raise MissingTool(case['reason'])
    if language == 'sql':
        CURRENT['runtime_versions'].update(python=sys.version,sqlite=sqlite3.sqlite_version)
        CURRENT['commands'].append({'kind':'in_process','entrypoint':'sqlite3.Connection.executescript',
                                    'source':case['path'],'driver_command':[sys.executable,*sys.argv]})
        source = path.read_text(encoding='utf-8')
        with sqlite3.connect(':memory:') as connection:
            connection.executescript(source)
            count = connection.execute('SELECT COUNT(*) FROM checks').fetchone()[0]
            OBSERVATIONS.clear()
            rejected,positive = check_contracts(connection,path.name)
            assert count>0
            assert connection.execute('PRAGMA integrity_check').fetchone()==('ok',)
            assert connection.execute('PRAGMA foreign_key_check').fetchall()==[]
        CURRENT['sql_rejections']=list(OBSERVATIONS)
        CURRENT['sql_checks'] = {'positive_assertions':count,'expected_rejections':rejected,
                                 'additional_behavior_checks':positive,'mutations':mutations(source,path.name)}
        return
    if case.get('adapter') == 'isa':
        from isa_probe import validate_isa
        CURRENT['runtime_versions'].update(python=sys.version,keystone=importlib.metadata.version('keystone-engine'),unicorn=importlib.metadata.version('unicorn'))
        CURRENT['commands'].append({'kind':'in_process','entrypoint':'isa_probe.validate_isa',
                                    'source':case['path'],'driver_command':[sys.executable,*sys.argv]})
        CURRENT['isa_checks'] = validate_isa(path,case['isa'])
        return
    if case.get('adapter') == 'postgres':
        raise MissingTool('PostgreSQL requires ephemeral local initdb/pg_ctl/psql; see runtime instructions')
    probe(language)
    legacy.run = execute
    if language == 'c':
        binary=temporary/('check.exe' if os.name=='nt' else 'check')
        if os.name=='nt':
            execute([shutil.which('cl'),'/nologo','/W4','/std:c17','/TC',path,'/Fe:'+str(binary),'/Fo:'+str(temporary/'check.obj')],temporary)
        else:
            execute([shutil.which('cc'),'-std=c17','-Wall','-Wextra','-Werror','-fsanitize=address,undefined','-g',path,'-o',binary],temporary)
        execute([binary],temporary)
    elif case.get('commands'):
        values={'root':str(ROOT),'temp':str(temporary),'source':str(path),'python':sys.executable}
        for name in ('php','go','rustc','ruby','bash','pwsh','nim','node'):
            values[name]=shutil.which(name) or name
        for command in case['commands']:
            execute([argument.format(**values) for argument in command],temporary)
    else:
        output=legacy.verify_file({'language':language,'path':case['path'],'fixtures':1},temporary)
        if language!='assembly' and not output: raise AssertionError('missing self-check success output')

def main():
    global CURRENT
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--suite',choices=['repairs','curated','all'],default='all')
    parser.add_argument('--path',action='append')
    parser.add_argument('--require-tools',action='store_true')
    args=parser.parse_args()
    cases=repair_cases() if args.suite in ('repairs','all') else []
    registry=ROOT/'research/cases.json'
    if registry.exists() and args.suite in ('curated','all'): cases+=json.loads(registry.read_text())
    if args.path:
        available={case['path']:case for case in repair_cases()+(json.loads(registry.read_text()) if registry.exists() else [])}
        unknown=set(args.path)-set(available)
        if unknown: parser.error('unknown paths: '+str(unknown))
        cases=[available[path] for path in args.path]
    run_id=uuid.uuid4().hex
    history=ROOT/'research/evidence/history'
    history.mkdir(parents=True,exist_ok=True)
    harness_store=history.parent/'harness'
    harness_store.mkdir(exist_ok=True)
    harness_paths=[Path(__file__),ROOT/'tools/sql_contracts.py',ROOT/'tools/verify.py']
    for harness in harness_paths:
        saved=harness_store/(digest(harness)+'.py')
        if not saved.exists(): saved.write_bytes(harness.read_bytes())
    failures=untested=0
    output=history/(now().replace(':','-')+'-'+run_id+'.jsonl')
    with output.open('x',encoding='utf-8') as log:
        for case in cases:
            paths=[case['path'],*case.get('support',[])]
            CURRENT={'schema_version':1,'run_id':run_id,'path':case['path'],'started_at':now(),
                'platform':platform.platform(),'invocation':[sys.executable,*sys.argv],
                'validation_mode':case.get('mode','native'),'source_hashes':{p:digest(ROOT/p) for p in paths},
                'harness_hashes':{p.name:digest(p) for p in harness_paths},
                'runtime_versions':{},'commands':[]}
            with tempfile.TemporaryDirectory(prefix='morderca-check-') as directory:
                try:
                    validate(case,Path(directory))
                    CURRENT['result']='passed'
                except (MissingTool,ImportError) as error:
                    CURRENT.update(result='not_tested',requested_mode=CURRENT['validation_mode'],validation_mode='not_tested',reason=str(error));untested+=1
                except Exception as error:
                    CURRENT.update(result='failed',error=repr(error));failures+=1
                    snapshots=history.parent/'failed_sources'
                    snapshots.mkdir(exist_ok=True)
                    for relative,sha in CURRENT['source_hashes'].items():
                        saved=snapshots/(sha+Path(relative).suffix)
                        if not saved.exists(): saved.write_bytes((ROOT/relative).read_bytes())
            CURRENT['finished_at']=now()
            log.write(json.dumps(CURRENT,ensure_ascii=False)+'\n');log.flush()
            print(CURRENT['result'].upper(),case['path'],CURRENT.get('error',CURRENT.get('reason','')),flush=True)
    print('Evidence:',output.relative_to(ROOT),'failed:',failures,'not tested:',untested,flush=True)
    return int(failures>0 or (args.require_tools and untested>0))

if __name__=='__main__':sys.exit(main())
