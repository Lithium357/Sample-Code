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
import re
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
    lua_program=os.environ.get('MORDERCA_LUA') or shutil.which('lua5.4') or 'lua'
    if language=='lua' and not shutil.which(lua_program) and not os.environ.get('MORDERCA_LUA'):
        try:import lupa.lua54
        except ImportError:raise MissingTool('No Lua 5.4 executable or lupa.lua54 native interpreter')
        code=('import hashlib,json,importlib.metadata; from pathlib import Path; from lupa import lua54; '
              'runtime=lua54.LuaRuntime(); '
              'print(json.dumps({"lupa":importlib.metadata.version("lupa"),'
              '"implementation":runtime.lua_implementation,"version":runtime.eval("_VERSION"),'
              '"module_sha256":hashlib.sha256(Path(lua54.__file__).read_bytes()).hexdigest()}))')
        version=json.loads(execute([sys.executable,'-c',code],ROOT,probe=True))
        if version['version']!='Lua 5.4':raise MissingTool('Embedded Lua 5.4 unavailable')
        CURRENT['runtime_versions'].update(python=sys.version,lua_embedded=version)
        CURRENT['runtime_embedding']='Native Lua interpreter via lupa.lua54; no standalone CLI claim'
        return
    perl_program=os.environ.get('MORDERCA_PERL') or 'perl'
    gawk_program=os.environ.get('MORDERCA_GAWK') or shutil.which('gawk') or 'awk'
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
        'perl':[[perl_program,'-v']], 'awk-gawk':[[gawk_program,'--version']],
        'lua':[[lua_program,'-v']],
    }
    for command in commands.get(language,[]):
        program = shutil.which(command[0])
        if not program: raise MissingTool('missing executable: '+command[0])
        execute([program,*command[1:]],ROOT,probe=True)
        last=CURRENT['commands'][-1]
        CURRENT['runtime_versions'][command[0]]={'probe_returncode':last['returncode'],
                                                'output':last['stdout']+last['stderr']}
        if language=='perl' and last['returncode']!=0:raise MissingTool('Perl runtime probe failed; see recorded stderr')
        if language=='lua' and (last['returncode']!=0 or not (last['stdout']+last['stderr']).startswith('Lua 5.4.')):
            raise MissingTool('Lua 5.4 required for this dialect; see runtime probe')
        if language=='awk-gawk' and (last['returncode']!=0 or not last['stdout'].startswith('GNU Awk')):
            raise MissingTool('GNU AWK runtime is unavailable; a different awk implementation is not sufficient')

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
    if case.get('adapter')=='sqlserver_container':
        if os.environ.get('MORDERCA_SQLSERVER_LOCAL')!='1':
            raise MissingTool('No opted-in owned SQL Server container; CI supplies a disposable local engine')
        container=os.environ.get('MORDERCA_SQLSERVER_CONTAINER','')
        if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]*',container):
            raise MissingTool('Explicit owned SQL Server container id/name required')
        docker=shutil.which('docker')
        if not docker:raise MissingTool('Docker CLI unavailable for the opted-in fixture')
        execute([docker,'version','--format','{{json .}}'],temporary,probe=True)
        CURRENT['runtime_versions']['docker']=CURRENT['commands'][-1]['stdout']
        image=execute([docker,'inspect','--format','{{.Image}}',container],temporary)
        CURRENT['runtime_versions']['container_image']=execute([docker,'image','inspect','--format',
            '{{json .RepoDigests}} {{.Id}} {{.Architecture}} {{.Os}}',image],temporary)
        # SQLCMDPASSWORD lives only in this disposable fixture container's env.
        # Never connect to a user server or accept a remote connection string.
        connection=[docker,'exec',container,'/opt/mssql-tools18/bin/sqlcmd','-C','-S','localhost',
                    '-U','sa','-b','-r','1','-l','5']
        execute([*connection,'-?'],temporary,probe=True)
        if CURRENT['commands'][-1]['returncode'] in (126,127):
            raise MissingTool('Bundled sqlcmd is unavailable inside the owned fixture container')
        CURRENT['runtime_versions']['sqlcmd']=CURRENT['commands'][-1]['stdout']+CURRENT['commands'][-1]['stderr']
        CURRENT['runtime_versions']['sqlserver']=execute([*connection,'-Q','SET NOCOUNT ON; SELECT @@VERSION;'],temporary)
        # Docker cp creates a root-owned file. A private directory created by
        # the normal container user lets that user remove the file, unlike a
        # root-owned file directly in sticky /tmp. No privileged exec needed.
        owned_dir='/tmp/morderca-'+uuid.uuid4().hex
        execute([docker,'exec',container,'mkdir','--',owned_dir],temporary)
        target=owned_dir+'/fixture.sql'
        primary_error=None
        try:
            execute([docker,'cp',path,container+':'+target],temporary)
            copied=execute([docker,'exec',container,'sha256sum',target],temporary).split()[0]
            if copied!=digest(path):raise AssertionError('SQL Server fixture copy differs from recorded source hash')
            CURRENT['container_source_sha256']=copied
            execute([*connection,'-i',target],temporary)
            # -r 1 directs PRINT and other messages to stderr. Retain both
            # streams in the raw command record and check completion there.
            command=CURRENT['commands'][-1]
            output=command['stdout']+'\n'+command['stderr']
            if 'T-SQL: constraints, exact errors, savepoints, migration and bound text passed' not in output:
                raise AssertionError('SQL Server fixture did not report completion')
            if case.get('negative_controls')=='constraint_migration':
                from sqlserver_controls import variants
                CURRENT['sqlserver_negative_controls']=[]
                for number, control in enumerate(variants(path.read_text(encoding='utf-8'))):
                    local=temporary/('sql-control-'+str(number)+'.sql')
                    local.write_text(control['source'],encoding='utf-8')
                    execute([docker,'cp',local,container+':'+target],temporary)
                    copied=execute([docker,'exec',container,'sha256sum',target],temporary).split()[0]
                    if copied!=digest(local):raise AssertionError('mutated SQL copy differs from control hash')
                    execute([*connection,'-i',target],temporary,probe=True)
                    record=CURRENT['commands'][-1]
                    record['kind']='negative_execution_control'
                    raw=record['stdout']+'\n'+record['stderr']
                    if (record['returncode']!=1 or 'Msg '+str(control['error'])+',' not in raw
                            or control['message'] not in raw):
                        raise AssertionError('T-SQL mutation did not fail for intended reason: '+control['name'])
                    CURRENT['sqlserver_negative_controls'].append({
                        'mutation':control['name'],'control_sha256':copied,
                        'expected_error':control['error'],'expected_message':control['message'],
                        'returncode':record['returncode'],
                        'scope':'Generated negative control, excluded from training source volume.'})
        except Exception as error:
            primary_error=error
            raise
        finally:
            cleanup_error=None
            for command in ([docker,'exec',container,'rm','-f','--',target],
                            [docker,'exec',container,'rmdir','--',owned_dir]):
                try:execute(command,temporary)
                except Exception as error:
                    CURRENT.setdefault('cleanup_errors',[]).append(repr(error))
                    if cleanup_error is None:cleanup_error=error
            # Preserve the original test failure if cleanup also fails.
            if cleanup_error is not None and primary_error is None:raise cleanup_error
        CURRENT['runtime_scope']='Native SQL Server engine in disposable Linux container, sqlcmd TLS trust only for owned localhost fixture; no SQLite translation'
        return
    if case.get('adapter')=='tcl':
        tclsh=shutil.which('tclsh')
        if tclsh:
            version_source=temporary/'tcl-version.tcl'
            version_text='puts [info patchlevel]\n'
            version_source.write_text(version_text,encoding='utf-8')
            CURRENT['generated_probe_inputs']={'tcl-version.tcl':version_text}
            CURRENT['runtime_versions']['tcl']=execute([tclsh,version_source],temporary,probe=True)
            CURRENT['tcl_checks']=execute([tclsh,path],temporary)
            assert 'passed' in CURRENT['tcl_checks']
            return
        import tkinter
        try:interpreter=tkinter.Tcl()
        except tkinter.TclError as error:raise MissingTool('Tcl runtime initialization unavailable: '+str(error))
        CURRENT['runtime_versions'].update(python=sys.version,tcl=interpreter.call('info','patchlevel'))
        CURRENT['commands'].append({'kind':'in_process','entrypoint':'tkinter.Tcl.eval',
                                    'source':case['path'],'driver_command':[sys.executable,*sys.argv],
                                    'runtime_note':'Native Tcl interpreter only; no Tk window or UI'})
        CURRENT['tcl_checks']=interpreter.eval(path.read_text(encoding='utf-8'))
        assert 'passed' in CURRENT['tcl_checks']
        return
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
    if case.get('adapter') in ('riscv_exec','riscv_uleb'):
        from isa_probe import validate_riscv_image
        programs={name:shutil.which('riscv64-linux-gnu-'+name) for name in ('as','ld','objcopy')}
        for name,program in programs.items():
            if not program:raise MissingTool('missing RISC-V GNU cross-tool: '+name+'; execution not tested on this host')
            execute([program,'--version'],ROOT,probe=True)
            CURRENT['runtime_versions']['riscv_'+name]=CURRENT['commands'][-1]['stdout']
        CURRENT['runtime_versions']['unicorn']=importlib.metadata.version('unicorn')
        obj,elf,raw=temporary/'fold.o',temporary/'fold.elf',temporary/'fold.bin'
        execute([programs['as'],'-march=rv64i','-mabi=lp64',path,'-o',obj],temporary)
        entry='decode_uleb32' if case['adapter']=='riscv_uleb' else 'ascii_fold'
        execute([programs['ld'],'-m','elf64lriscv','--no-relax','-Ttext=0x100000','-e',entry,obj,'-o',elf],temporary)
        execute([programs['objcopy'],'-O','binary','--only-section=.text',elf,raw],temporary)
        header=elf.read_bytes()
        assert header[:6]==b'\x7fELF\x02\x01' and int.from_bytes(header[18:20],'little')==243,'not little-endian ELF64 RISC-V'
        assert int.from_bytes(header[16:18],'little')==2 and int.from_bytes(header[24:32],'little')==0x100000,'unexpected ELF type/entry'
        CURRENT['produced_artifact_sha256']={p.name:digest(p) for p in (obj,elf,raw)}
        CURRENT['commands'].append({'kind':'in_process','entrypoint':'uleb_isa_probe.validate_image' if case['adapter']=='riscv_uleb' else 'isa_probe.validate_riscv_image',
                                    'linked_text':raw.name,'driver_command':[sys.executable,*sys.argv]})
        if case['adapter']=='riscv_uleb':
            from uleb_isa_probe import validate_image
            CURRENT['isa_checks']=validate_image(raw.read_bytes(),'riscv64')
        else:CURRENT['isa_checks']=validate_riscv_image(raw.read_bytes())
        return
    if case.get('adapter')=='nasm_uleb':
        nasm=shutil.which('nasm')
        if not nasm:raise MissingTool('NASM unavailable')
        execute([nasm,'-v'],ROOT,probe=True)
        CURRENT['runtime_versions']['nasm']=CURRENT['commands'][-1]['stdout']
        obj=temporary/'decode.o'
        execute([nasm,'-f','elf64',path,'-o',obj],temporary)
        CURRENT['produced_artifact_sha256']={obj.name:digest(obj)}
        if case.get('native_x86'):
            if platform.system()!='Linux' or platform.machine().lower() not in ('x86_64','amd64'):
                raise MissingTool('Native NASM fixture requires Linux x86-64; emulation is a separate invocation')
            linker=shutil.which('ld')
            if not linker:raise MissingTool('Linux ELF linker unavailable')
            execute([linker,'--version'],ROOT,probe=True)
            CURRENT['runtime_versions']['ld']=CURRENT['commands'][-1]['stdout']
            binary=temporary/'decode'
            execute([linker,obj,'-o',binary],temporary)
            execute([binary],temporary)
            CURRENT['produced_artifact_sha256'][binary.name]=digest(binary)
            CURRENT['native_self_checks']={'vectors':16,'scope':'Inline fixed literals, all output guards, status/value/count, saved registers and stack; Linux ELF _start exit status 0.'}
        else:
            from uleb_isa_probe import validate_image
            raw=temporary/'decode.bin'
            execute([nasm,'-DFLAT','-f','bin',path,'-o',raw],temporary)
            CURRENT['runtime_versions'].update(python=sys.version,unicorn=importlib.metadata.version('unicorn'))
            CURRENT['produced_artifact_sha256'][raw.name]=digest(raw)
            CURRENT['commands'].append({'kind':'in_process','entrypoint':'uleb_isa_probe.validate_image',
                'image':raw.name,'driver_command':[sys.executable,*sys.argv]})
            CURRENT['isa_checks']=validate_image(raw.read_bytes(),'x86_64')
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
    elif case.get('adapter') in ('fsharp','csharp'):
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
        if case['adapter']=='fsharp':
            execute([dotnet,'fsi','--langversion:8.0','--exec',path],temporary,extra_env=environment)
        else:
            if not any(line.startswith('10.') for line in sdks.splitlines()):
                raise MissingTool('.NET SDK 10 required for this net10.0 managed-runtime fixture')
            from xml.sax.saxutils import escape
            feed=temporary/'empty-feed';feed.mkdir()
            project=temporary/'Specimen.csproj'
            project_text=('<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup>'
                '<OutputType>Exe</OutputType><TargetFramework>net10.0</TargetFramework>'
                '<LangVersion>12.0</LangVersion><Nullable>enable</Nullable>'
                '<TreatWarningsAsErrors>true</TreatWarningsAsErrors>'
                '<NuGetAudit>false</NuGetAudit><RestoreSources>'+escape(str(feed))+'</RestoreSources>'
                '</PropertyGroup></Project>')
            project.write_text(project_text,encoding='utf-8')
            shutil.copyfile(path,temporary/'Program.cs')
            CURRENT['generated_build_inputs']={'Specimen.csproj':project_text,
                'Program.cs_sha256':digest(temporary/'Program.cs'),
                'note':'Source copied unchanged into scratch; generated project is control material, not extra training volume.'}
            # An inherited Platform=x64 changes MSBuild's default directory.
            # Choose the output explicitly rather than guessing that layout.
            build_output=temporary/'managed-output'
            execute([dotnet,'build',project,'--nologo','--output',build_output],temporary,extra_env=environment)
            execute([dotnet,build_output/'Specimen.dll'],temporary,extra_env=environment)
    elif case.get('adapter')=='python_sqlite':
        CURRENT['runtime_versions']['sqlite']=sqlite3.sqlite_version
        execute([sys.executable,path],temporary)
    elif language=='ruby' and case.get('adapter')=='ruby_strict_transcode':
        ruby=shutil.which('ruby')
        execute([ruby,'--disable=gems','-c',path],temporary)
        assert 'passed' in execute([ruby,'--disable=gems',path],temporary)
        original=path.read_text(encoding='utf-8')
        controls=[
            ('omit EOF finalization',"    pump.call(''.b, false)","    # skipped EOF" ,'missing rejection: incomplete_input'),
            ('treat chunks as complete', 'pump.call(chunk.b, true)', 'pump.call(chunk.b, false)', 'failed: independent scalar oracle'),
            ('omit output limit', 'if fragment.bytesize > limit - result.bytesize', 'if false', 'missing rejection: output_limit'),
        ]
        CURRENT['mutation_controls']=[]
        for index,(label,before,after,diagnostic) in enumerate(controls):
            assert original.count(before)==1
            text=original.replace(before,after)
            control=temporary/('transcode-control-'+str(index)+'.rb')
            control.write_text(text,encoding='utf-8')
            # Deliberate broken source is control material, never a registry case.
            store=ROOT/'research/evidence/mutations'/(digest(control)+'.rb')
            if not store.exists():store.write_bytes(control.read_bytes())
            execute([ruby,'--disable=gems',control],temporary,probe=True)
            observed=CURRENT['commands'][-1]
            observed['kind']='negative_execution_control'
            CURRENT['mutation_controls'].append({'mutation':label,'source_sha256':digest(control),
                'expected_diagnostic':diagnostic,'returncode':observed['returncode']})
            if observed['returncode']==0 or diagnostic not in observed['stderr']:
                raise AssertionError('Ruby mutation did not fail as intended: '+label)
    elif language=='perl':
        program=shutil.which(os.environ.get('MORDERCA_PERL') or 'perl')
        execute([program,'-c',path],temporary)
        assert 'passed' in execute([program,path],temporary)
        if case.get('adapter')=='perl_scoped_records':
            original=path.read_text(encoding='utf-8')
            controls=[('leak record separator', 'local $/ = \\$remaining;', '$/ = \\$remaining;', 'failed: separator restored on success'),
                      ('accept rejected tail', "if $tail eq 'reject';", 'if 0;', 'failed: expected error')]
            CURRENT['mutation_controls']=[]
            for index,(label,before,after,diagnostic) in enumerate(controls):
                assert original.count(before)==1
                control=temporary/('record-control-'+str(index)+'.pl')
                control.write_text(original.replace(before,after),encoding='utf-8')
                store=ROOT/'research/evidence/mutations'/(digest(control)+'.pl')
                if not store.exists():store.write_bytes(control.read_bytes())
                execute([program,control],temporary,probe=True)
                observed=CURRENT['commands'][-1];observed['kind']='negative_execution_control'
                CURRENT['mutation_controls'].append({'mutation':label,'source_sha256':digest(control),
                    'expected_diagnostic':diagnostic,'returncode':observed['returncode']})
                if observed['returncode']==0 or diagnostic not in observed['stderr']:
                    raise AssertionError('Perl mutation did not fail as intended: '+label)
    elif language=='lua':
        if 'runtime_embedding' in CURRENT:
            code=('import sys; from pathlib import Path; from lupa.lua54 import LuaRuntime; '
                  'LuaRuntime(encoding=None).execute(Path(sys.argv[1]).read_bytes())')
            output=execute([sys.executable,'-c',code,path],temporary)
        else:
            program=shutil.which(os.environ.get('MORDERCA_LUA') or shutil.which('lua5.4') or 'lua')
            output=execute([program,path],temporary)
        assert 'passed' in output
    elif language=='awk-gawk':
        program=shutil.which(os.environ.get('MORDERCA_GAWK') or shutil.which('gawk') or 'awk')
        assert 'passed' in execute([program,'-f',path],temporary,extra_env={'LC_ALL':'C'})
    elif language=='bash' and case.get('adapter')=='bash_waited_source':
        program=shutil.which('bash')
        assert 'passed' in execute([program,path],temporary)
        text=path.read_text(encoding='utf-8')
        needle='if wait "$producer_pid"; then producer_status=0; else producer_status=$?; fi'
        if text.count(needle)!=1:raise AssertionError('wait negative-control target is not unique')
        control=temporary/'missing-wait.sh'
        control.write_text(text.replace(needle,'producer_status=0 # deliberate missing wait'),encoding='utf-8')
        execute([program,control],temporary,probe=True)
        command=CURRENT['commands'][-1];command['kind']='negative_execution_control'
        if (command['returncode']!=1 or 'wrong producer/consumer status: expected 23 got 0' not in command['stderr']):
            raise AssertionError('Bash missing-wait control did not fail for intended producer status')
        CURRENT['process_source_control']={'mutation':'skip producer wait/status','source_sha256':digest(control),
            'expected_rejection':'wrong producer/consumer status: expected 23 got 0','returncode':command['returncode'],
            'scope':'Generated negative control, not training source volume.'}
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
        settings=json.loads(execute([shutil.which('go'),'env','-json','CGO_ENABLED','CC','GOOS','GOARCH'],temporary))
        CURRENT['runtime_versions']['go_race_configuration']=settings
        if settings['CGO_ENABLED']!='1':
            raise MissingTool('Go race detector requires CGO_ENABLED=1 and a supported C toolchain; native uninstrumented execution is a separate mode check')
        execute([shutil.which('go'),'build','-race','-o',binary,path],temporary)
        execute([binary],temporary)
    elif language=='nim' and case.get('native_nim'):
        binary=temporary/('check.exe' if os.name=='nt' else 'check')
        flags=[]
        if case.get('nim_memory_manager')=='arc':flags.append('--gc:arc')
        if os.name=='nt':
            compiler=shutil.which('cl')
            if not compiler:raise MissingTool('MSVC environment unavailable for native Nim')
            execute([compiler],ROOT,probe=True)
            CURRENT['runtime_versions']['native_c_compiler']=CURRENT['commands'][-1]['stderr']
            flags.append('--cc:vcc')
        execute([shutil.which('nim'),'c',*flags,'--hints:off','--nimcache:'+str(temporary/'nimcache'),'-o:'+str(binary),path],temporary)
        execute([binary],temporary)
        if case.get('adapter')=='nim_move_only':
            control=temporary/'copy_control.nim'
            control_text=('include '+json.dumps(path.as_posix())+'\n'
                          'var first = owned(1, Audit())\nvar second = first\n'
                          'echo first.len, second.len\n')
            control.write_text(control_text,encoding='utf-8')
            CURRENT['generated_negative_control']={'source':control_text,'sha256':digest(control),
                'scope':'Control material; implicit live-source copy must fail, not training volume.'}
            execute([shutil.which('nim'),'c',*flags,'--compileOnly','--hints:off',
                     '--nimcache:'+str(temporary/'copy-cache'),control],temporary,probe=True)
            record=CURRENT['commands'][-1]
            record['kind']='negative_compile_control'
            diagnostic=record['stdout']+record['stderr']
            if (record['returncode']!=1 or "'=copy' is not available for type <OwnedBytes>" not in diagnostic
                    or "not the last read of 'first'" not in diagnostic):
                raise AssertionError('live-source implicit copy did not fail with the intended ownership diagnostic')
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
    parser.add_argument('--native-x86',action='store_true')
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
    if args.native_x86:
        for case in cases:
            if case.get('adapter')=='nasm_uleb':case.update(native_x86=True,mode='native')
    if not cases:parser.error('no cases selected')
    run_id=uuid.uuid4().hex
    history=ROOT/'research/evidence/history'
    history.mkdir(parents=True,exist_ok=True)
    harness_store=history.parent/'harness'
    harness_store.mkdir(exist_ok=True)
    harness_paths=[Path(__file__),ROOT/'tools/sql_contracts.py',ROOT/'tools/verify.py']
    harness_paths.append(ROOT/'tools/verify_advanced.py')
    if (ROOT/'tools/isa_probe.py').exists():harness_paths.append(ROOT/'tools/isa_probe.py')
    if (ROOT/'tools/sqlserver_controls.py').exists():harness_paths.append(ROOT/'tools/sqlserver_controls.py')
    if (ROOT/'tools/uleb_isa_probe.py').exists():harness_paths.append(ROOT/'tools/uleb_isa_probe.py')
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
