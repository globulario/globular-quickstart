# Certification — globular 1.2.360 → 1.2.363

The 1.2.360 campaign found five product defects and two harness defects. This
records the fixes, and states for each **what the evidence proves** — kept
separate from what it asserts.

- Under test: `dist/globular-1.2.363-linux-amd64`
  (`scripts/build-release.sh 1.2.363 --full-regenerate`)
- Simulation: `globular-quickstart`, 5 nodes, Docker, one cold boot per
  destructive suite — `make clean && make up`, the real installer unpacking the
  real release tarball. No snapshots; nothing carried between destructive suites.
- Driver: `scripts/certify-release.sh 1.2.363`, full 81-scenario run.
- Predecessor: [CERTIFICATION-1.2.360.md](CERTIFICATION-1.2.360.md).

## 1. Results

**76 / 81 scenarios PASS, 1163 checks** (1.2.360: 75 / 81).

| Suite | 1.2.360 | 1.2.363 | |
|---|---|---|---|
| smoke | 3 / 3 | 3 / 3 | |
| functional | 10 / 10 | 10 / 10 | |
| security | 9 / 9 | 9 / 9 | |
| patterns | 5 / 5 + control | 5 / 5 + control | |
| training | 5 / 5 | 5 / 5 | |
| **soak** | **3 / 5** | **5 / 5** | defect 4 fixed |
| recovery | 7 / 7 | 7 / 7 | |
| resilience | 13 / 13 | 13 / 13 | |
| upgrade | 11 / 12 | 9 / 12, **0 failures on re-run so far** | see §4 |
| **authority** | **4 / 6** | **5 / 6** | defects 5 + 6 fixed |
| catastrophic | 5 / 5 | 5 / 5 | |

`residue-negative-control` is *supposed* to fail — it is the negative control
for the restoration law, classified `🟦 expected-fail`, and is not a defect.

## 2. The seven defects, and what proves each fix

### Defect 4 — the node agent cached its etcd client certificate for the life of the process

`GetEtcdTLS` read the service keypair once into `tls.Config.Certificates`, and
`GetEtcdClient` cached the client process-wide. A certificate replaced on disk —
by rotation, repair, or restore — never reached the running process.

Compounding it: Go only sends a client certificate whose issuer appears in the
server's `CertificateRequest.AcceptableCAs`. A wrong-CA leaf is dropped, an
**empty** certificate is sent, and under TLS 1.3 `Dial` still returns nil. The
rejection surfaces only as an operation that never completes — which is why this
presented as an etcd fault and not a credential fault.

**Cost:** one node held a bad leaf for 37 minutes across 55 reconcile cycles of
`remediation_no_progress`, while the correct certificate had been back on disk
within a minute. 591 `tls: client didn't provide a certificate` rejections,
100 % of them from that one node, to all five members.

**Fix:** the keypair is supplied per handshake via `GetClientCertificate`, as the
server side already does with `certReloader`. Load errors are no longer
discarded, and a leaf that does not chain to the cluster CA is named rather than
left to become a timeout.
→ `golang/config/etcd_client.go`

**Proven:** `soak` **3/5 → 5/5**, on 1.2.361 **and** 1.2.363 — each after a fresh
cold boot in which `security` injected and restored an expired certificate on
node-3 first. That is the original outage sequence, reproduced twice, clean both
times.

### Defect 5 — the CLI attached no membership metadata at all

`globularcli` built every gRPC connection with a raw `grpc.DialContext` carrying
transport credentials and nothing else. There were **zero** interceptors in the
package. Every other Globular client appends `cluster_id` and `cluster_uid`
through `globular_client`'s interceptor; the CLI never did.

After initialization the server requires `cluster_uid` on any request that is not
bootstrap, mTLS, JWT, loopback, or allowlisted. So:

| routing | outcome |
|---|---|
| local instance | loopback exemption → succeeds |
| `--token` supplied | JWT exemption → succeeds |
| neither | `Unauthenticated: cluster_uid required` |

Repository discovery rotates across instances, so the failure rate is the
fraction of rotations that leave the node. That is why this read as an
intermittent *repository* fault across three releases.

**Fix:** membership metadata attached at all four dial sites through one shared
helper, unary and stream, so a new dial site cannot silently omit it.
→ `golang/globularcli/cluster_metadata_interceptor.go`

**Proven:** `cluster_uid required` **3 occurrences → 0** in `authority`;
`controller-zombie-after-lease-loss` **PARTIAL → PASS**; and 42 consecutive live
repository calls across all five nodes with **0** failures against a ~13 %
baseline (~0.3 % likely by chance).

### Defect 6 — the restoration postcondition gave up before the repair finished

`_verify_postconditions` polled for a hardcoded 120 s. The controller's etcd
auto-rejoin cycle is minutes: victim etcd deactivated 22:36:37, MemberAdd
22:41:01, wipe executed 22:44:24 — the dispatch cooldown alone is 3 minutes. The
gate declared failure while a working repair was still in flight, and the
unrestored residue then made the *next* scenario fail for having a degraded
baseline.

**Fix:** per-scenario window, and `restoration_timeout_seconds` is refused
without a `restoration_reason` — an unexplained longer window is how a
repair-latency regression gets absorbed instead of reported.
→ `tests/harness/bin/globular-scenario`

**Proven:** `node-clone-identity-collision` **FAIL → PASS** (it had failed
identically on 1.2.359 and 1.2.360).

### Defect 7 — the CA-gateway re-issue dropped every IP SAN

`reissueLeafViaCAGateway` passed only `spec.GetAlternateDomains()` to the signing
path. The local issuance path in the same file gathers `gatherIPs()` plus the
ingress VIP; the gateway path passed **no IP SANs at all**. The controller dials
node agents by IP and etcd peers verify each other by IP, so the repaired
certificate was unusable for exactly the traffic that matters.

This is the missing link in defect 4: it is what made the certificate unusable in
the first place. The caching bug then made it permanent.

**Fix:** the IPs travel through the same alternates list — `normalizeAltDomains`
already routes an IP-shaped alternate into the SAN config's `IP.N` block.
→ `golang/node_agent/node_agent_server/certificate.go`

**Proven:** `node_ip_san_ok` **false → true** on node-3
(`has_node_ip: true, node_ip: 10.10.0.13`); `security` **8/9 → 9/9**, on 1.2.362
and again on 1.2.363.

### T1 (harness) — the cert oracle asserted the wrong property

`cert-expiry-detection` asserted only that the repaired certificate was
un-expired and CA-signed. Both were true of a certificate the node agent had
**already logged as unusable** (`missing IP SAN: 10.10.0.13`), so the scenario
reported **PASS 12/12** while the damage propagated into a later suite disguised
as an etcd problem.

**Fix:** `pki.cert_info` reports `node_ip_san_ok`; the scenario asserts it.
→ `tests/harness/lib/probes.sh`, `tests/scenarios/security/cert-expiry-detection.yaml`

**Proven:** it caught defect 7 on its first run — turning a log line nobody could
act on into a reproducible failure. Verified able to **fire**, not merely to
pass: it returns false against a DNS-only certificate and true against the live
node certs.

### Fix 3 (from 1.2.360) — the refusal now names the cause it observed

Carried forward and worth recording, because it paid for itself three times:
`services desired set` used to report its own RPC failures as "no published
version — publish it, then retry". It has since surfaced three *distinct* real
causes: the `cluster_uid` gap (defect 5), a transport failure, and ScyllaDB
quorum loss (§3). Each would otherwise have been read as a publishing defect.

## 3. The one remaining red row, and why it is not a product defect

`authority/rejoin-after-missed-generations` — **PARTIAL**.

    Error: cannot verify the kind of dns (repository unreachable: rpc error:
    code = Unavailable desc = artifact ledger unavailable: scylla list manifests:
    Cannot achieve consistency level for cl QUORUM. Requires 1, alive 0)

The scenario **deliberately destroys ScyllaDB quorum**. The repository therefore
cannot verify a package kind, and `services desired set` fails closed per
`desired.keyed_by_kind_and_name`. That is the designed behaviour, working.

The open question is a scenario-expectation one for the owner: should a scenario
that intentionally removes storage quorum expect desired-state writes to
succeed? Answering it is a decision, not a fix, so nothing here has been changed
to make the row green.

## 4. The three upgrade rows, and why they are contention

The first `upgrade` run scored 9/12. All three non-passes were downstream of the
workflow circuit breaker opening (`15 failures in 5m`), which blocked reconcile;
the failing steps were MinIO/objectstore convergence, a subsystem none of these
fixes touch.

Two measurements settle it:

- The breaker opened **more** on the certified 1.2.360 run (13 events) than here
  (6) — and that run still scored 11/12. The condition is pre-existing and
  timing-sensitive.
- Re-run on a quiet host (load 5.6 vs 18+), same binary:
  `deploy-publish-then-converge` **FAIL → PASS**, and the suite reached
  **9 PASS / 0 non-pass** before this document was written. The decisive row is
  that one scenario flipping on an unchanged binary; the re-run's own final
  tally is in `.runlogs/1.2.363-upgrade.log` and supersedes this line if it
  differs.

Contention, not regression. Recorded rather than silently re-run: the first
result stands in the evidence, with the second beside it.

## 5. Corrections made during this work

Listed because they cost more than the defects did, and a certification that
hides its wrong turns is worth less than one that shows them.

| # | Claim | Reality |
|---|---|---|
| 1 | "node-3's etcd was active throughout" | It crash-looped through six PIDs. The stabilisation is what made the diagnosis work — 95 of 104 probe failures came *after* it. |
| 2 | "the probe fabricates endpoint errors it never measured" | Overreach. The peers were contacted. Stated as proven before checking their logs. |
| 3 | "cert-less TLS rejections are cluster-wide, so not an explanation" | A miscount of *all* rejections. Counting only cert-less ones: 100 % from node-3. It was the explanation. |
| 4 | "the cert repair gives up" | Withdrawn. It retries every heartbeat; the silence was a correctly-idle loop after a valid cert was restored. |
| 5 | "Fix 2 was never exercised" | Wrong. Scoped to one bundle and generalised to the suite. |
| 6 | "a pruned etcd member has no path back" | False. `MemberAdd succeeded` is in the journal. Same mis-scoped grep. |
| 7 | "defect 5 is an architectural circularity needing an authorization decision" | False. The CLI could read the keypair and reach etcd all along; it had no interceptor. A two-minute `etcdctl get` would have disproved it. |

Six of seven share one mechanism: **concluding from absent evidence** — a zero
count from a search never proven able to fire, or an assumption never tested
against the live system. This codebase already names that shape
(`awareness.scanner_zero_findings_conflates_clean_with_dead`), and it took the
graph surfacing it before the pattern stopped.

The awareness entries filed on premises 6 and 7 are marked **WITHDRAWN in place**
rather than deleted, so the correction is visible to the next reader.

## 6. Regression tests added

| package | cases | proves |
|---|---|---|
| `config/etcd_client_cert_source_test.go` | 7 | a restored certificate reaches the running process; unchanged mtime served from cache; present-but-unusable is an error, not a silent downgrade; absent keypair still works during Day-0; a wrong-CA leaf is named; end-to-end handshake recovery against a `client-cert-auth: true` server |
| `node_agent/.../infra_health_probe_etcd_test.go` | 5 | reaching no member reports UNKNOWN, not FAILED; a genuine local fault still reports FAILED; a peer's answer is never proof about the local member; the local attempt cannot consume the whole probe budget |
| `security/san_ip_coverage_test.go` | 2 | IP alternates become IP SANs; **negative control** — the exact call the gateway used to make produces none |
| `globular_client/cluster_uid_diagnosis_test.go` | 6 | a refusal names its cause; **controls** — never invents a diagnosis, never reshapes an unrelated error |
| `globularcli/cluster_metadata_interceptor_test.go` | 4 | metadata on unary and stream; **controls** — a caller's own `cluster_id` is never clobbered, Day-0 absence stays non-fatal |

Every suite was verified to **fail against the pre-fix behaviour** — for defect 4
by temporarily reinstating the caching path and watching three of seven fail.
They are regression tests, not restatements of what the code already did.

## 7. Re-checking every claim without re-running anything

```bash
# The proof table and its scope.
cat tests/PROOF.md

# Defect 4 — soak, before and after. Anchor on '^  → ' to count SCENARIO
# verdicts: an unanchored grep also matches the suite-level line.
grep -c '^  → PASS' .runlogs/1.2.360-soak.log               # 3
grep -cE '^  → (FAIL|PARTIAL)' .runlogs/1.2.360-soak.log    # 2
grep -c '^  → PASS' .runlogs/1.2.363-soak.log               # 5
grep -cE '^  → (FAIL|PARTIAL)' .runlogs/1.2.363-soak.log    # 0

# Defect 5 — the refusal is gone:
grep -c "cluster_uid required" .runlogs/1.2.363-authority.log   # 0
grep -A2 "── controller-zombie-after-lease-loss ──" .runlogs/1.2.363-authority.log

# Defect 6 — the clone scenario:
grep -A2 "── node-clone-identity-collision ──" .runlogs/1.2.363-authority.log

# Defect 7 — the SAN assertion, on the live node cert:
python3 -c "import json;d=json.load(open('tests/reports/20260904T055754-security/cert-expiry-detection/evidence.json'));print([i['result'] for i in d['items'] if i['id']=='cert_chain_valid'])"

# §3 — the remaining red row names ScyllaDB, not the publisher:
grep -o "artifact ledger unavailable[^\"]*" \
  tests/reports/20260904T102554-authority/rejoin-after-missed-generations/evidence.json | head -1

# §4 — the circuit breaker predates these fixes:
grep -rhc "circuit breaker open" tests/reports/20260903T201125-upgrade/*/evidence/journal/*/cluster-controller.log
```

## 8. What is NOT claimed

- The `authority` PARTIAL is **not fixed**. It is understood, and the fix is a
  decision about scenario expectations that belongs to the owner.
- The `upgrade` re-run is evidence of contention, not proof that no regression
  exists anywhere in that suite. Both results are in the evidence.
- Nothing here says the system is defect-free. It says these seven defects are
  fixed, each with evidence a later reader can re-check, and that no scenario was
  skipped, quarantined, retried until green, or re-baselined to get there.
