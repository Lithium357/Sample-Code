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

def execute(argv, cwd, timeout=90, probe=False, extra_env=None):
    command = [str(value) for value in argv]
    record = {'argv':command,'cwd':str(cwd),'started_at':now(),'kind':'version_probe' if probe else 'test_command'}
    if extra_env:record['environment_overrides']=extra_env
    try:
        result = subprocess.run(command,cwd=cwd,text=True,capture_output=True,timeout=timeout,
                                env={**os.environ,**extra_env} if extra_env else None)
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
        'cpp':[['cl']] if os.name=='nt' else [['c++','--version']],
        'assembly':[['nasm','-v'],['ld','--version']],
        'python':[[sys.executable,'--version']], 'javascript':[['node','--version']],
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

def legacy_cases():
    basic=json.loads((ROOT/'manifest.json').read_text())
    advanced=json.loads((ROOT/'advanced/manifest.json').read_text())['files']
    return [{'path':entry['path'],'language':entry['language'],
             'mode':'native_sqlite' if entry['language']=='sql' else 'native',
             'expected_fixture_count':entry.get('fixtures'),
             'scope':'Existing embedded checks; passing does not establish exhaustive feature coverage or origin audit.'}
            for entry in basic+advanced]

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
            if case.get('expected_fixture_count') is not None:assert count==case['expected_fixture_count']
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
    if case.get('adapter') == 'riscv_syntax':
        compiler=shutil.which('clang')
        if not compiler:raise MissingTool('Clang RISC-V cross-assembler unavailable; execution also not tested')
        execute([compiler,'--version'],ROOT,probe=True)
        CURRENT['runtime_versions']['clang']=CURRENT['commands'][-1]['stdout']
        obj=temporary/'fold.o'
        execute([compiler,'--target=riscv64-unknown-linux-gnu','-march=rv64i','-mabi=lp64','-c',path,'-o',obj],temporary)
        CURRENT['produced_object_sha256']=digest(obj)
        CURRENT['limitations']='Syntax/object generation only; no linking, emulation or native execution'
        return
    if case.get('adapter') == 'postgres':
        if os.environ.get('MORDERCA_POSTGRES_LOCAL')!='1':
            raise MissingTool('No opted-in disposable local PostgreSQL fixture; set MORDERCA_POSTGRES_LOCAL=1 only for an owned localhost fixture')
        program=shutil.which('psql')
        if not program:raise MissingTool('psql missing')
        execute([program,'--version'],ROOT,probe=True)
        CURRENT['runtime_versions']['psql']=CURRENT['commands'][-1]['stdout']
        connection=[program,'-X','-v','ON_ERROR_STOP=1','-h','127.0.0.1','-p','5432','-U','postgres','-d','fixture']
        CURRENT['runtime_versions']['postgresql_server']=execute([*connection,'-At','-c','SELECT version()'],temporary)
        execute([*connection,'-f',path],temporary)
        return
    if case.get('adapter') == 'nasm' and platform.system()!='Linux':
        # Flat executable test image plus ELF64 object generation; no Linux
        # kernel execution is claimed on Windows. Keep the exact tool commands.
        from verify_advanced import emulate_assembly
        nasm=shutil.which('nasm')
        if not nasm:raise MissingTool('NASM missing')
        execute([nasm,'-v'],ROOT,probe=True)
        CURRENT['runtime_versions'].update(nasm=CURRENT['commands'][-1]['stdout'],
                                          unicorn=importlib.metadata.version('unicorn'))
        CURRENT['validation_mode']='emulation'
        CURRENT['limitations']='Unicorn flat image plus NASM ELF64 assembly; no ELF loader or Linux kernel execution'
        legacy.run=execute
        emulate_assembly(path,temporary)
        return
    if language=='assembly' and platform.system()!='Linux':raise MissingTool('Native Linux x86-64 execution unavailable on this host')
    probe(language)
    legacy.run = execute
    if case.get('adapter') == 'php_pdo':
        php=shutil.which('php')
        query='echo class_exists("PDO") ? json_encode(PDO::getAvailableDrivers()) : "null";'
        drivers=json.loads(execute([php,'-r',query],temporary))
        flags=[]
        if not drivers or 'sqlite' not in drivers:
            extension=Path(php).parent/'ext'/'php_pdo_sqlite.dll'
            if os.name=='nt' and extension.exists(): flags=['-d','extension_dir='+str(extension.parent),'-d','extension=pdo_sqlite']
            else: raise MissingTool('PDO SQLite driver unavailable')
        CURRENT['runtime_versions']['pdo_sqlite']=execute([php,*flags,'-r','echo (new PDO("sqlite::memory:"))->getAttribute(PDO::ATTR_CLIENT_VERSION);'],temporary)
        execute([php,*flags,path],temporary)
    elif case.get('adapter')=='fsharp':
        dotnet=shutil.which('dotnet')
        if not dotnet:raise MissingTool('.NET SDK/F# Interactive unavailable')
        environment={'DOTNET_CLI_HOME':str(temporary/'dotnet-home'),
                     'DOTNET_SKIP_FIRST_TIME_EXPERIENCE':'1','DOTNET_NOLOGO':'1',
                     'DOTNET_CLI_TELEMETRY_OPTOUT':'1','NUGET_PACKAGES':str(temporary/'nuget')}
        execute([dotnet,'--info'],temporary,probe=True,extra_env=environment)
        CURRENT['runtime_versions']['dotnet']=CURRENT['commands'][-1]['stdout']+CURRENT['commands'][-1]['stderr']
        sdks=execute([dotnet,'--list-sdks'],temporary,extra_env=environment)
        CURRENT['runtime_versions']['dotnet_sdks']=sdks
        if not sdks:raise MissingTool('.NET host exists but no SDK/F# Interactive is installed')
        execute([dotnet,'fsi','--langversion:8.0','--exec',path],temporary,extra_env=environment)
    elif language in ('c','cpp'):
        binary=temporary/('check.exe' if os.name=='nt' else 'check')
        if os.name=='nt':
            flags=['/nologo','/W4','/EHsc','/std:c++20'] if language=='cpp' else ['/nologo','/W4','/std:c17','/TC']
            execute([shutil.which('cl'),*flags,path,'/Fe:'+str(binary),'/Fo:'+str(temporary/'check.obj')],temporary)
        else:
            execute([shutil.which('c++' if language=='cpp' else 'cc'),'-std=c++20' if language=='cpp' else '-std=c17','-Wall','-Wextra','-Werror','-fsanitize=address,undefined','-g',path,'-o',binary],temporary)
        execute([binary],temporary)
    elif language=='go' and case.get('go_race'):
        binary=temporary/('check.exe' if os.name=='nt' else 'check')
        CURRENT['instrumentation']='Go race detector'
        execute([shutil.which('go'),'build','-race','-o',binary,path],temporary)
        execute([binary],temporary)
    elif language=='nim' and case.get('native_nim'):
        binary=temporary/('check.exe' if os.name=='nt' else 'check')
        flags=[]
        if os.name=='nt':
            compiler=shutil.which('cl')
            if not compiler:raise MissingTool('MSVC environment unavailable for native Nim')
            execute([compiler],ROOT,probe=True)
            CURRENT['runtime_versions']['native_c_compiler']=CURRENT['commands'][-1]['stderr']
            flags=['--cc:vcc']
        execute([shutil.which('nim'),'c',*flags,'--hints:off','--nimcache:'+str(temporary/'nimcache'),'-o:'+str(binary),path],temporary)
        execute([binary],temporary)
    elif case.get('commands'):
        values={'root':str(ROOT),'temp':str(temporary),'source':str(path),'python':sys.executable,
                'exe':str(temporary/('specimen.exe' if os.name=='nt' else 'specimen'))}
        for name in ('php','go','rustc','ruby','bash','pwsh','nim','node'):
            values[name]=shutil.which(name) or name
        for command in case['commands']:
            execute([argument.format(**values) for argument in command],temporary)
    else:
        if language=='nim': legacy.NIM_BACKEND='js' if case.get('mode')=='transpiled_js' else 'c'
        output=legacy.verify_file({'language':language,'path':case['path'],'fixtures':1},temporary)
        if language!='assembly' and not output: raise AssertionError('missing self-check success output')

def main():
    global CURRENT
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--suite',choices=['repairs','curated','legacy','all'],default='all')
    parser.add_argument('--path',action='append')
    parser.add_argument('--only-language',action='append')
    parser.add_argument('--skip-language',action='append',default=[])
    parser.add_argument('--go-race',action='store_true')
    parser.add_argument('--native-nim',action='store_true')
    parser.add_argument('--require-tools',action='store_true')
    args=parser.parse_args()
    cases=legacy_cases() if args.suite in ('legacy','all') else repair_cases() if args.suite=='repairs' else []
    registry=ROOT/'research/cases.json'
    if registry.exists() and args.suite in ('curated','all'): cases+=json.loads(registry.read_text())
    if args.path:
        available={case['path']:case for case in legacy_cases()+(json.loads(registry.read_text()) if registry.exists() else [])}
        unknown=set(args.path)-set(available)
        if unknown: parser.error('unknown paths: '+str(unknown))
        cases=[available[path] for path in args.path]
    cases=[case for case in cases if case['language'] not in args.skip_language and (not args.only_language or case['language'] in args.only_language)]
    if args.go_race:
        for case in cases:
            if case['language']=='go':case['go_race']=True
    if args.native_nim:
        for case in cases:
            if case['language']=='nim':case.update(native_nim=True,mode='native')
    if not cases:parser.error('no cases selected')
    run_id=uuid.uuid4().hex
    history=ROOT/'research/evidence/history'
    history.mkdir(parents=True,exist_ok=True)
    harness_store=history.parent/'harness'
    harness_store.mkdir(exist_ok=True)
    harness_paths=[Path(__file__),ROOT/'tools/sql_contracts.py',ROOT/'tools/verify.py']
    harness_paths.append(ROOT/'tools/verify_advanced.py')
    if (ROOT/'tools/isa_probe.py').exists():harness_paths.append(ROOT/'tools/isa_probe.py')
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
