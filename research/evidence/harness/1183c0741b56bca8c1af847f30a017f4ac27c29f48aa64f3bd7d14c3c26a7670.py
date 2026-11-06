"""Excluded deliberate C++ regressions and compile gates, never training units."""
import os
import shutil
import hashlib

def execution_variants(original):
    construct='std::construct_at(reinterpret_cast<T*>(slot.storage), std::forward<Args>(args)...);'
    specs=[
        ('publish before construction',construct,'slot.occupied = true;\n            '+construct,'constructor rollback'),
        ('omit generation change','++slot.generation;','/* deliberately omitted */;','stale handle revived'),
        ('disable retirement','if (slot.generation == GenerationLimit)','if (false)','retirement boundary'),
        ('omit owner check','handle.owner != this || ','','foreign handle'),
        ('consume generation on failed construction',construct,
         'try { '+construct+' } catch (...) { ++slot.generation; throw; }','failed constructor preserves generation')]
    for label,before,after,reason in specs:
        assert original.count(before)==1
        yield {'name':label,'source':original.replace(before,after),'reason':reason}

def compile_variants(original):
    specs=[
        ('copy pool','\nvoid copy_gate() { Pool<Tracked, 2> one; Pool<Tracked, 2> two(one); (void)two.size(); }\n','deleted-copy'),
        ('throwing destructor','\nstruct GateThrowingDestructor { ~GateThrowingDestructor() noexcept(false) {} };\nPool<GateThrowingDestructor, 1> rejected_dtor;\n','pool elements require noexcept destruction'),
        ('zero capacity','\nPool<Tracked, 0> rejected_capacity;\n','pool capacity must be 1..64'),
        ('excess capacity','\nPool<Tracked, 65> rejected_capacity;\n','pool capacity must be 1..64'),
        ('zero generation limit','\nPool<Tracked, 1, 0> rejected_generation;\n','generation limit must be positive')]
    for label,extra,reason in specs:
        yield {'name':label,'source':original+extra,'reason':reason}

def validate_pool(path,temporary,root,current,execute):
    digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    binary=temporary/('pool.exe' if os.name=='nt' else 'pool')
    def build(source,probe=False):
        if os.name=='nt':
            argv=[shutil.which('cl'),'/nologo','/W4','/EHsc','/std:c++20',source,
                  '/Fe:'+str(binary),'/Fo:'+str(temporary/'pool.obj')]
        else:
            argv=[shutil.which('c++'),'-std=c++20','-Wall','-Wextra','-Werror',
                  '-fsanitize=address,undefined','-g',source,'-o',binary]
        return execute(argv,temporary,probe=probe)
    build(path)
    assert 'passed' in execute([binary],temporary)
    original=path.read_text(encoding='utf-8')
    current['mutation_controls']=[];current['compile_controls']=[]
    for index,control in enumerate(execution_variants(original)):
        local=temporary/('pool_exec_'+str(index)+'.cpp')
        local.write_text(control['source'],encoding='utf-8')
        saved=root/'research/evidence/mutations'/(digest(local)+'.cpp')
        if not saved.exists():saved.write_bytes(local.read_bytes())
        build(local)
        execute([binary],temporary,probe=True)
        observed=current['commands'][-1];observed['kind']='negative_execution_control'
        current['mutation_controls'].append({'mutation':control['name'],'source_sha256':digest(local),
            'expected_diagnostic':control['reason'],'returncode':observed['returncode']})
        if observed['returncode']==0 or control['reason'] not in observed['stdout']+observed['stderr']:
            raise AssertionError('C++ mutation missed intended assertion: '+control['name'])
    for index,control in enumerate(compile_variants(original)):
        local=temporary/('pool_compile_'+str(index)+'.cpp')
        local.write_text(control['source'],encoding='utf-8')
        saved=root/'research/evidence/mutations'/(digest(local)+'.cpp')
        if not saved.exists():saved.write_bytes(local.read_bytes())
        build(local,probe=True)
        observed=current['commands'][-1];observed['kind']='negative_compile_control'
        raw=observed['stdout']+observed['stderr'];reason=control['reason']
        intended=(('C2280' in raw or 'use of deleted function' in raw) if reason=='deleted-copy' else
                  reason in raw and ('C2338' in raw or 'static assertion failed' in raw))
        current['compile_controls'].append({'mutation':control['name'],'source_sha256':digest(local),
            'expected_diagnostic':reason,'returncode':observed['returncode']})
        if observed['returncode']==0 or not intended:
            raise AssertionError('C++ compile gate missed intended diagnostic: '+control['name'])
