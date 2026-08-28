# Pattern Validation

## Patterns tested

- pattern.intent_marker_tombstone
- pattern.last_known_good
- pattern.read_repair_authority_repair

## Expected invariants

- critical_state.absence_is_not_destructive_intent
- critical_state.deletion_requires_audited_intent

## Expected code smells absent

- missing key branch calls stop or delete
- stop service on missing key without checking LKG

## Runtime evidence

- preflight.json: absent
- debug-session.json: absent

## Awareness matches

- patterns: (none matched)
- invariants: (none)
- failure modes: (none)
- forbidden fixes: (none)
- code smells: (none)

## Result

SKIPPED

## Notes

- lab-only topology: single-node quickstart (not full 3-node production cluster)
- missing evidence: preflight.json
- missing evidence: debug-session.json
