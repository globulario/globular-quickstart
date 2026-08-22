# Governed Change Binding

A scenario run may be used as proof for a repair or feature only when its artifacts identify the exact implementation candidate **and frozen proof plan** that were tested.

Quickstart keeps the full ChangeEnvelope in `globulario/services`; the simulation stores only a binding:

```json
{
  "change": {
    "id": "chg-...",
    "envelope_ref": "...",
    "candidate_repository": "globulario/services",
    "candidate_revision": "<git sha>",
    "plan_digest": "sha256:<frozen-plan>",
    "simulation_revision": "<quickstart git sha>"
  }
}
```

The binding is copied into both `scenario-proof.json` and `learning.json`.

`plan_digest` is computed when the candidate is bound in the services-side ChangeEnvelope. It covers the exact candidate revision plus the contracts, invariants, forbidden repairs, required tests, and required scenarios that define what **PROVEN** means. A scenario result from a different plan is not interchangeable proof, even when the code revision is the same.

## Environment passed by the evolution runner

- `GLOBULAR_CHANGE_ID`
- `GLOBULAR_CHANGE_ENVELOPE_REF` (optional durable locator)
- `GLOBULAR_CANDIDATE_REPOSITORY`
- `GLOBULAR_CANDIDATE_REVISION`
- `GLOBULAR_CHANGE_PLAN_DIGEST`
- `GLOBULAR_REQUIRE_CHANGE_BINDING=1` when the run is being used as governed change proof

Normal manual/legacy scenario runs may remain unbound. Once any change-binding field is supplied, the binding must be complete. A partial binding is a proof error.

When `GLOBULAR_REQUIRE_CHANGE_BINDING=1`, the scenario executor is not started until the binding is complete. This is intentional: a cluster mutation must not occur for a certification run when the harness cannot identify which candidate and proof plan it is testing.

A green executor result cannot override an invalid binding. The proof remains ineligible.

## Authority boundary

The binding identifies provenance; it grants no authority. `learning.json` remains simulation evidence/candidate knowledge only. Behavioral Memory must validate that:

- `production_authoritative` is false;
- `promotion_required` is true;
- `may_promote` is false;
- the candidate revision is present;
- the frozen `plan_digest` is present;
- the simulation revision agrees with the quickstart proof revision.

The services-side `ai_memory/evolution` adapter enforces those properties before ingesting simulation results into Behavioral Memory.
