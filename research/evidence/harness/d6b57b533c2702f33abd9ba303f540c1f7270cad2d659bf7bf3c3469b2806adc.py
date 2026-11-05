"""Focused SQL display-output mutations; control material only."""
from datetime import datetime,timezone
import hashlib,json,platform,sqlite3,sys,uuid
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'outputs/Sample-Code'
phase=sys.argv[1]
assert phase in ('before','after')
specs=[
 ('sql/10_ranking_with_ties.sql','WHERE dense_rank <= 2 ORDER','WHERE dense_rank <= 3 ORDER',
  'SELECT division, contestant, points FROM standings','top_division_scores',4,
  [('blue','Eden',80),('blue','Fin',80),('blue','Gale',70),('red','Ari',100),('red','Blair',90),('red','Casey',90)],
  [('blue','Eden',80),('blue','Fin',80),('blue','Gale',70),('red','Ari',100),('red','Blair',90),('red','Casey',90)]),
 ('sql/12_effective_dated_prices.sql','a.valid_from < b.valid_from','a.valid_from <= b.valid_from',
  'SELECT a.product_id, a.valid_from, b.valid_from FROM price','price_overlap_audit',4,[],[(3,0,100)]),
 ('sql/20_conditional_pivot.sql','rating >= 4','rating >= 5',
  'SELECT question, COUNT(*) AS responses','question_summary',3,
  [('quality',2,4.5,2),('speed',2,3.0,1),('support',2,4.0,1)],
  [('quality',2,4.5,2),('speed',2,3.0,1),('support',2,4.0,1)])]
def now():return datetime.now(timezone.utc).isoformat()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
record=dict(schema_version=1,run_id=uuid.uuid4().hex,path='tools/sql_output_probe',started_at=now(),
 platform=platform.platform(),validation_mode='control_policy',invocation=[sys.executable,*sys.argv],
 source_hashes={s[0]:sha(ROOT/s[0]) for s in specs},harness_hashes={'sql_output_probe.py':sha(Path(__file__))},
 runtime_versions={'python':sys.version,'sqlite':sqlite3.sqlite_version},commands=[],findings=[],phase=phase)
h=ROOT/'research/evidence/harness'/(sha(Path(__file__))+'.py')
if not h.exists():h.write_bytes(Path(__file__).read_bytes())
try:
 for path,old,new,prefix,view,count,before,after in specs:
  p=ROOT/path;source=p.read_text(encoding='utf-8');assert source.count(old)==1
  saved=ROOT/'research/evidence/review_sources'/(sha(p)+'.sql')
  if not saved.exists():saved.write_bytes(p.read_bytes())
  query=source[source.index(prefix):source.index(';',source.index(prefix))+1] if phase=='before' else 'SELECT * FROM '+view
  with sqlite3.connect(':memory:') as db:
   db.executescript(source);rows=sorted(db.execute(query).fetchall());assert rows==sorted(before if phase=='before' else after)
  mutant=source.replace(old,new);data=mutant.encode('utf-8');digest=hashlib.sha256(data).hexdigest()
  saved=ROOT/'research/evidence/mutations'/(digest+'.sql');saved.parent.mkdir(exist_ok=True)
  if not saved.exists():saved.write_bytes(data)
  finding={'path':path,'classification':'test_gap_demonstrated_by_deliberate_mutation','mutation':old+' -> '+new,'mutant_sha256':digest,'baseline_rows':rows}
  with sqlite3.connect(':memory:') as db:
   try:db.executescript(mutant)
   except sqlite3.IntegrityError as error:
    assert phase=='after' and error.sqlite_errorname=='SQLITE_CONSTRAINT_CHECK'
    finding.update(observed='mutation_rejected',error=error.sqlite_errorname)
   else:
    assert phase=='before','mutant survived corrected checks'
    start=mutant.index(prefix);q=mutant[start:mutant.index(';',start)+1];changed=sorted(db.execute(q).fetchall())
    assert changed!=rows and db.execute('SELECT COUNT(*) FROM checks').fetchone()[0]==count
    finding.update(observed='printed_result_changed_but_checks_pass',mutated_rows=changed,unchanged_checks=count)
  record['findings'].append(finding)
 record['result']='passed'
except Exception as error:record.update(result='failed',error=repr(error))
record['finished_at']=now()
out=ROOT/'research/evidence/history'/(now().replace(':','-')+'-sql-output-'+record['run_id']+'.jsonl')
out.write_text(json.dumps(record)+'\n',encoding='utf-8')
print(record['result'].upper(),record.get('error',''),record['findings']);print(out.relative_to(ROOT))
raise SystemExit(record['result']!='passed')
