"""Excluded Nim body regressions; copy owned fixtures, never alter working source."""
import hashlib
import shutil

def validate_controls(case,path,temporary,root,current,execute,nim,flags):
    module=root/case['support'][0]
    original=module.read_text(encoding='utf-8')
    driver=path.read_text(encoding='utf-8')
    binary=temporary/('scoped-release.exe' if __import__('os').name=='nt' else 'scoped-release')
    execute([nim,'c',*flags,'-d:release','--assertions:off','--hints:off',
             '--nimcache:'+str(temporary/'release-cache'),'-o:'+str(binary),path],temporary)
    assert 'checks passed' in execute([binary],temporary)
    specs=[
        ('omit real close','close(reader.file)','discard reader.file','native file closed'),
        ('ignore poison','if reader.poisoned:','if false:','oversize poisons without retry'),
        ('discard carriage return',"    if value == '\\n': return some(line)",
         "    if value == '\\r': continue\n    if value == '\\n': return some(line)",'independent LF prefix oracle'),
        ('allow one extra byte','if line.len == reader.limit:','if line.len > reader.limit:','independent LF prefix oracle'),
        ('omit cached EOF','if reader.ended: return none(string)','# omitted EOF cache','cached EOF performs no read'),
        ('omit I/O poison','    except IOError:\n      reader.poisoned = true\n      raise',
         '    except IOError:\n      raise','I/O error identity and poison')]
    current['mutation_controls']=[]
    for index,(name,before,after,reason) in enumerate(specs):
        assert original.count(before)==1,(name,before)
        directory=temporary/('scoped-control-'+str(index));directory.mkdir()
        mutant=directory/module.name;main=directory/path.name
        mutant.write_text(original.replace(before,after),encoding='utf-8')
        main.write_text(driver,encoding='utf-8')
        digest=hashlib.sha256(mutant.read_bytes()).hexdigest()
        stored=root/'research/evidence/mutations'/(digest+'.nim')
        if not stored.exists():stored.write_bytes(mutant.read_bytes())
        target=temporary/('scoped-control.exe' if __import__('os').name=='nt' else 'scoped-control')
        # Reuse unchanged stdlib objects, but compile the actual changed module.
        execute([nim,'c',*flags,'--hints:off','--nimcache:'+str(temporary/'nimcache'),'-o:'+str(target),main],temporary)
        execute([target],temporary,probe=True)
        observed=current['commands'][-1];observed['kind']='negative_execution_control'
        current['mutation_controls'].append({'mutation':name,'source_sha256':digest,
            'fixture_sha256':hashlib.sha256(main.read_bytes()).hexdigest(),
            'expected_diagnostic':'failed: '+reason,'returncode':observed['returncode']})
        if observed['returncode']==0 or 'failed: '+reason not in observed['stdout']+observed['stderr']:
            raise AssertionError('Nim mutation missed intended assertion: '+name)
