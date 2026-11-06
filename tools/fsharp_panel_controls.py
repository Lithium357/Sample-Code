"""Excluded control material, not working-code training units."""
import hashlib

def validate_controls(source,temporary,root,current,execute,dotnet,environment):
    original=source.read_text(encoding='utf-8')
    specs=[
        ('discard right errors','Invalid(a @ b)','Invalid a','all field errors in order'),
        ('reverse error order','Invalid(a @ b)','Invalid(b @ a)','all field errors in order'),
        ('use ambient culture','CultureInfo.InvariantCulture','CultureInfo.CurrentCulture','culture independent'),
        ('use longer side for coat','amount > min width height / 2M','amount > max width height / 2M','dependent geometry'),
        ('relax fractional grammar','{1,3}','{0,4}','independent grammar and scaled oracle')]
    current['mutation_controls']=[]
    def invoke(path):
        execute([dotnet,'fsi','--langversion:8.0','--exec',path],temporary,probe=True,extra_env=environment)
        return current['commands'][-1]
    def save(path):
        digest=hashlib.sha256(path.read_bytes()).hexdigest()
        target=root/'research/evidence/mutations'/(digest+'.fsx')
        if not target.exists():target.write_bytes(path.read_bytes())
        return digest
    for index,(name,before,after,reason) in enumerate(specs):
        assert original.count(before)==1
        control=temporary/('panel_control_'+str(index)+'.fsx')
        control.write_text(original.replace(before,after),encoding='utf-8')
        digest=save(control)
        observed=invoke(control);observed['kind']='negative_execution_control'
        current['mutation_controls'].append({'mutation':name,'source_sha256':digest,
            'expected_diagnostic':'failed: '+reason,'returncode':observed['returncode']})
        if observed['returncode']==0 or 'failed: '+reason not in observed['stdout']+observed['stderr']:
            raise AssertionError('F# mutation missed intended assertion: '+name)
    control=temporary/'panel_units_gate.fsx'
    control.write_text(original+'\nlet units_gate : decimal<mm> = 1M<mm^2>\n',encoding='utf-8')
    digest=save(control)
    observed=invoke(control);observed['kind']='negative_type_control'
    current['units_control']={'source_sha256':digest,'returncode':observed['returncode'],
        'expected_error':'FS0001','scope':'FSI must reject a length/area assignment; excluded ill-typed control, no standalone compile-only claim.'}
    raw=observed['stdout']+observed['stderr']
    if observed['returncode']==0 or 'FS0001' not in raw or 'mm' not in raw:
        raise AssertionError('F# units gate did not reject incompatible measures')
