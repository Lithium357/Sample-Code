"""Audit real failure/pass links; control material, excluded from training."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import platform
import sys
import uuid

ROOT = Path(__file__).resolve().parents[1] / 'outputs/Sample-Code'
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def now(): return datetime.now(timezone.utc).isoformat()
ledger_path = ROOT / 'research/changes.jsonl'
ledger = [json.loads(line) for line in ledger_path.read_text(encoding='utf-8').splitlines()]
raw = []
for path in (ROOT / 'research/evidence/history').glob('*.jsonl'):
    raw.extend(json.loads(line) for line in path.read_text(encoding='utf-8').splitlines())
by_run = {(row['run_id'], row['path']): row for row in raw}
record = dict(schema_version=1, run_id=uuid.uuid4().hex, path='tools/research_changes.py',
              started_at=now(), platform=platform.platform(), validation_mode='control_policy',
              invocation=[sys.executable, *sys.argv], source_hashes={'tools/research_changes.py':sha(ROOT/'tools/research_changes.py')},
              harness_hashes={'audit_resolution_scope.py':sha(Path(__file__))},
              ledger_input_sha256=sha(ledger_path), runtime_versions={'python':sys.version}, commands=[],
              scope='Actual ledger/input audit, not additional sample execution or code volume.')
store = ROOT / 'research/evidence/harness'
for source, suffix in [(Path(__file__), '.py'), (ledger_path, '.ledger')]:
    target = store / (sha(source) + suffix)
    if not target.exists(): target.write_bytes(source.read_bytes())
try:
    linked = [row for row in ledger if row.get('kind') == 'subsequent_successful_rerun']
    corrections = {row.get('corrects_event_id') for row in ledger if row.get('kind') == 'metadata_correction'}
    matching = mismatched = 0
    for link in linked:
        failed = by_run[(link['failed_run_id'], link['path'])]
        passed = by_run[(link['passed_run_id'], link['path'])]
        assert failed['result'] == 'failed' and passed['result'] == 'passed'
        assert failed['source_hashes'] == link['failed_source_hashes']
        assert passed['source_hashes'] == link['passed_source_hashes']
        differences = [key for key in ['platform', 'validation_mode', 'instrumentation']
                       if failed.get(key) != passed.get(key)]
        if differences:
            assert link['event_id'] in corrections, 'uncorrected cross-scope link: ' + link['event_id']
            mismatched += 1
        else:
            matching += 1
    path = 'curated/go/conditional_snapshot.go'
    race_failure = by_run[('a4e3ed8171714b409e3ab3700d5e3336', path)]
    ordinary_pass = by_run[('6f7145255f91499cbb955c589c80b3b0', path)]
    assert race_failure.get('instrumentation') == 'Go race detector'
    assert ordinary_pass.get('instrumentation') is None
    assert race_failure['platform'] == ordinary_pass['platform']
    assert race_failure['validation_mode'] == ordinary_pass['validation_mode'] == 'native'
    assert not any(link['failed_run_id'] == race_failure['run_id'] for link in linked), 'unavailable local race setup falsely resolved'
    # A real matching-scope later success should still be linked.
    assert any(link['failed_run_id'] == '1d6fd14590db44c1a540dc45ae0c5fe7'
               and link['passed_run_id'] == 'b7370dbebe8249f2b42cd926aa1df2d0' for link in linked)
    record.update(result='passed', checks={'scope_matched_links':matching,
                  'historical_mismatches_with_corrections':mismatched,
                  'local_race_failure_not_resolved_by_ordinary_native':True,
                  'matching_NASM_emulation_success_linked':True})
except Exception as error:
    record.update(result='failed', error=repr(error))
record['finished_at'] = now()
output = ROOT / 'research/evidence/history' / (now().replace(':','-') + '-scope-' + record['run_id'] + '.jsonl')
output.write_text(json.dumps(record) + '\n', encoding='utf-8')
print(record['result'].upper(), record.get('checks', record.get('error')))
print('Evidence:', output.relative_to(ROOT))
raise SystemExit(0 if record['result'] == 'passed' else 1)
