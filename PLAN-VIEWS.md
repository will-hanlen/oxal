# Adding `%plan` to the view engine

## Goal

Introduce a third `$view` variant — `%plan` — alongside `%form` and `%lens`.
A plan watches a faucet (like a lens) but produces *bindings* instead of
data: each fire of its transformer emits a set of `(stem, lens-spec)`
install/modify/delete deltas, scoped to the subtree below the plan's
stem. The set of plans declared by a mesh is static; the set of lenses
installed by those plans is data-driven.

## Decisions (locked in)

- Plan transformer returns deltas (`(set bnd-chng)`), not the full
  desired binding map. Mirrors the existing `(set chng)` lens model.
- Plan-installed lens stems must lie strictly under the plan's stem.
  Names a hierarchy; teardown is a subtree lop; placement reasoning
  stays local.
- Plans output only `lens-spec` entries — never forms, never other
  plans. (See report at top of conversation history for the
  reasoning.)

## Decisions to revisit (recommended defaults inline)

1. **"mine" for plans.** Plan transformers receive the *current binding
   map* as `mine` so they can emit deltas relative to it. Two ways to
   provide it:
   - **(a)** Walk `cod` under the plan's stem at fire-time, collecting
     every direct child whose `lord.mesh == this-plan's-mesh` and whose
     `view` is `%lens`. Single source of truth; O(children) per fire.
   - **(b)** Cache `(map stem lens-spec)` on the plan's meta and update
     on every applied bnd-chng. Faster lookups; consistency burden.
   - **Recommend (a)** to start; revisit if profiling shows it matters.

2. **Atomicity of a delta batch.** If one bnd-chng in a batch fails
   validation (e.g. emitted stem outside plan's subtree, faucet cycle in
   emitted lens), apply the valid ones or reject the whole batch?
   - **Recommend reject + suspend the plan.** Matches "all-or-nothing"
     transformer semantics and keeps debugging simple — a broken plan
     halts cleanly instead of leaving partial state.

3. **`%mod` semantics.** When `%mod` arrives for an existing binding,
   compare old vs new lens-spec. If `dep` and `sauc` unchanged, treat
   as a no-op (the lens-spec is already what it should be). Otherwise
   tear down old + install new. Avoids needless faucet-unsub/sub churn.
   - **Recommend implementing this optimization in v1**, since
     sloppy plans will frequently re-emit identical specs.

## Type changes — `lib/zozo-0.hoon`

### Extend `+$ view` (line 213)

```
+$  view
  $%  [%form form]
      [%lens lens]
      [%plan plan]   :: NEW
  ==
```

### New `+$ plan` (place after `+$ lens`, ~line 232)

```
+$  plan
  $:
    =sauc
    dep=link
    lyf=@ud
    cas=@ud
    err=(unit tang)
  ==
```

Notes:
- No `out`/`in` shape — plans don't emit data.
- `lyf`/`cas` track the plan's own life/case for replay & versioning,
  same role as on lens.
- `err` allows suspension on transformer crash, same as lens.

### Extend `+$ view-spec` and add `+$ plan-spec` (line 237)

```
+$  view-spec
  $%  [%form form-spec]
      [%lens lens-spec]
      [%plan plan-spec]   :: NEW
  ==

+$  plan-spec
  $:
    dep=link
    =sauc
  ==
```

### New `+$ bnd-chng` and `+$ plan-xfm` (place near `+$ transformer` at line 403)

```
+$  bnd-chng
  $%  [%ins =stem spec=lens-spec]
      [%del =stem]
      [%mod =stem spec=lens-spec]
  ==

+$  plan-xfm
  $-  $:  mine=(map stem lens-spec)
          snap=data
          =move
          life=@
          case=@
      ==
  (set bnd-chng)
```

`mine` carries the current binding map so authors can compute deltas.
Same `snap`/`move`/`life`/`case` shape as the lens transformer for
uniformity. `stem` keys are *relative* to the plan's stem.

### Update CLAUDE.md spec section

Add `%plan` to the "Specification" section: "A `$view` is one of
`%form` (base data), `%lens` (a pure function over a changelog
producing data), or `%plan` (a pure function over a changelog
producing lens bindings under itself)."

## Engine changes — `lib/zozo-3.hoon`

### Compilation cache

Mirror `xfms` for plans:

```
xfms-plan=(map @t plan-xfm)
```

Add to `acer`'s state alongside `xfms` (currently at zozo-0:371).

### `+view-from-spec` (line 82)

Add the `%plan` arm:

```
%plan
  :*  %plan
      sauc=sauc.view-spec
      dep=dep.view-spec
      lyf=0
      cas=0
      err=~
  ==
```

### `+validate-mesh-views` (line 657)

Extend the cycle check to `%plan` — the plan stem must not be at or
above its own faucet, identical to the lens rule. Add a clause
parallel to the existing one at zozo-3:679:

```
?:  ?&  ?=(%plan -.vw)
        (~(is-ancestor-or-same th full-pax) (ref-to-pith dep.vw))
    ==
  `(crip "ae: load-mesh rejected: plan at ... has self or ancestor as faucet at ...")
```

### `+place-mesh-view` (line 695)

Add a `%plan` branch after the `%form` early-return:

```
?:  ?=(%plan -.view)
  =.  dat  (~(lop do dat) full-pax)         :: plan owns its subtree
  =/  full-dep=pith    (ref-to-pith dep.view)
  =/  faucet-met=meta  (gut-meta full-dep)
  =.  cod
    %+  ~(put ox cod)  full-dep
    faucet-met(subs (~(put in subs.faucet-met) full-pax))
  =?  cor  ?=(^ sauc.view)
    (link-sub full-pax (ref-to-pith sauc.view))
  (initialize-plan-from-snap full-pax view faucet-met)
```

### `+uninstall-mesh-view` (line 723) and `+wipe-mesh-view` (line 740)

Currently gate side-effects on `?=(%lens -.view)`. Extend the gate to
`?=(?(%lens %plan) -.view)` — both need faucet-unsub and maybe-link-
unsub. Plan teardown also needs to tear down its installed sub-lenses;
since those lenses live in `cod` under the plan's stem, walking `cod`
in the subtree and faucet-unsub-ing each is required. Add a helper:

```
++  teardown-plan-subtree
  ::
  ::  walk every meta under plan-pax; for each %lens lord, faucet-unsub
  ::  and maybe-link-unsub.  data and meta nodes are removed by the
  ::  caller via lop + ~(dip ox).
  ::
  |=  plan-pax=pith
  ^+  cor
  ...
```

Call it from both `uninstall-mesh-view` and `wipe-mesh-view` before
the existing meta clear / lop. After teardown, `wipe-mesh-view`'s
existing `~(del ox cod)` + `~(lop do dat)` clean up state; for
`uninstall-mesh-view`, additionally walk `cod` in the subtree and
clear lord on each plan-installed lens.

### `+rebuild-view` (line 487)

Currently asserts `?=(%lens -.vw)`. Extend to also accept `%plan`:
on plan rebuild, fire the plan transformer fresh with empty `mine`
and the current faucet snap (i.e. teardown all current bindings,
then re-install whatever the transformer emits). Or — preferred —
fire with the current `mine` and let the transformer emit deltas
naturally.

### New: `+initialize-plan-from-snap`

Mirrors `+initialize-from-snap` (line 1160):

```
++  initialize-plan-from-snap
  |=  [full-pax=pith =view faucet-met=meta]
  ^+  cor
  ?>  ?=(%plan -.view)
  =/  met=meta  (gut-meta full-pax)
  ?.  ?=(^ lord.met)  cor
  ?:  ?=(^ err.view)  cor
  =/  snap=data  (~(dip do dat) (ref-to-pith dep.view))
  =/  mine=(map stem lens-spec)  (collect-plan-bindings full-pax)
  %:  run-plan-xfm
    full-pax  view  met  mine  snap  ~
    life.faucet-met  case.faucet-met
  ==
```

### New: `+collect-plan-bindings`

Walk `cod` under `plan-pax`, collecting direct-child entries with a
`%lens` lord whose `lord.mesh` matches the plan's mesh, returning
`(map stem lens-spec)` keyed by relative stem.

### New: `+run-plan-xfm` and `+run-plan-xfm-collect`

Parallel to `+run-xfm` and `+run-xfm-collect` (lines 643/1367) but
for plans. Resolve sauc → @t via `+resolve-plan-code` (a tiny variant
of `+resolve-code`), compile via `+get-plan-xfm`, invoke with the
plan-xfm signature, and dispatch the resulting `(set bnd-chng)` to
`+apply-bnd-chngs`. On `mule` failure, suspend the plan (write `err`
on its view) using a parallel of `+suspend-view` that handles `%plan`.

### New: `+apply-bnd-chngs`

The structural-mutation arm. Validates and applies the delta batch:

```
++  apply-bnd-chngs
  |=  [plan-pax=pith plan-mesh=term chs=(set bnd-chng)]
  ^+  cor
  =/  list=(list bnd-chng)  ~(tap in chs)
  =/  validation=(unit @t)  (validate-bnd-chngs plan-pax plan-mesh list)
  ?^  validation
    (suspend-plan plan-pax ~[leaf+(trip u.validation)])
  |-  ^+  cor
  ?~  list  cor
  =.  cor
    ?-  -.i.list
      %ins  (install-plan-lens plan-pax plan-mesh stem.i.list spec.i.list)
      %del  (uninstall-plan-lens plan-pax stem.i.list)
      %mod
        =/  full=pith  (weld plan-pax stem.i.list)
        =/  old-met=meta  (gut-meta full)
        ?~  lord.old-met
          (install-plan-lens plan-pax plan-mesh stem.i.list spec.i.list)
        =*  old-vw  view.u.lord.old-met
        ?.  ?=(%lens -.old-vw)
          (install-plan-lens plan-pax plan-mesh stem.i.list spec.i.list)
        ?:  ?&  =(dep.old-vw dep.spec.i.list)
                =(sauc.old-vw sauc.spec.i.list)
            ==
          cor                                          :: no-op fast path
        =.  cor  (uninstall-plan-lens plan-pax stem.i.list)
        (install-plan-lens plan-pax plan-mesh stem.i.list spec.i.list)
    ==
  $(list t.list)
```

### New: `+validate-bnd-chngs`

Per-batch pre-flight, returns `~` if all valid or the first error msg:

- emitted stem is non-empty (a sub-pith, not the plan's own stem)
- emitted stem ∪ plan-pax meets `meta-allowed`
- emitted stem ∪ plan-pax does not collide with an existing view
  (other than the lens this plan previously installed at the same
  stem, for `%mod`)
- `%ins` / `%mod` lens-spec passes the existing faucet-cycle check:
  emitted stem ∪ plan-pax must not be at-or-above
  `(ref-to-pith dep.spec)`

### New: `+install-plan-lens` / `+uninstall-plan-lens`

Thin wrappers around the existing meta-write + faucet-sub +
maybe-link-sub + initialize-from-snap pipeline used by
`+place-mesh-view` for lenses (zozo-3:706–721), but tagged so that
teardown knows the lens belongs to the plan rather than directly to
the mesh's `++load` output.

Open question: does the lens's `lord.mesh` point to the plan's
mesh name, or to a synthetic id derived from the plan's stem? The
former matches today's structure; the latter would let
`+collect-plan-bindings` discriminate cleanly. **Recommend: keep
`lord.mesh` = mesh name; discriminate by location (under plan-pax
in `cod`).** No new field on `meta`.

### New: `+suspend-plan`

Parallel of `+suspend-view` (line 319) for plans. Faucet-unsub, write
`err` on the plan's view, leave installed sub-lenses *in place* for
now — tearing them down on plan suspension might surprise users when
they fix the plan and the sub-lenses come back fresh. Document this
choice; revisit.

### Propagation — `+propagate` / `+propagate-loop` / `+run-xfm-collect`

The propagation pipeline (zozo-3:561+) walks subscribers of changed
faucets and fires their transformers. Today every subscriber is a
`%lens`; the dispatch in `+run-xfm-collect` (line 1367) needs to
branch on view type and call `+run-plan-xfm-collect` for `%plan`
subscribers. The faucet `subs` set on `meta` is already shape-
agnostic, so no schema change there.

### `+reinstall-subs` and `+reinstall-links` (lines 505/526)

Both currently call `+rebuild-view`, which assumes `%lens`. With
the `+rebuild-view` extension above, plans get rebuilt the same way
when their faucet's life bumps or their link target changes.

## Validation matrix (summary)

| Check | %form | %lens | %plan |
|-------|-------|-------|-------|
| meta-allowed (depth) | ✓ | ✓ | ✓ |
| under-mesh (territory) | ✓ | ✓ | ✓ |
| no existing view at/below | ✓ | ✓ | ✓ |
| stem not at/above own faucet | n/a | ✓ | ✓ NEW |
| emitted-lens stem under self | n/a | n/a | ✓ NEW |
| emitted-lens stem not collide | n/a | n/a | ✓ NEW |
| emitted-lens cycle check | n/a | n/a | ✓ NEW |

## Phasing

**Phase 1 — types only.**
Add `%plan` to `view`, `view-spec`, plus `plan`, `plan-spec`,
`bnd-chng`, `plan-xfm`. No engine code yet. Rebuild and confirm the
existing meshes still compile (forms + lenses unaffected).

**Phase 2 — install/teardown.**
Implement `+place-mesh-view`'s plan branch, `+uninstall-mesh-view`
extension, `+wipe-mesh-view` extension, `+teardown-plan-subtree`,
`+validate-mesh-views` plan cycle check. Plans install but never
fire — write a doctest mesh that loads with a plan declared and
verify install/uninstall round-trips cleanly.

**Phase 3 — fire once.**
Implement `+initialize-plan-from-snap`, `+collect-plan-bindings`,
`+run-plan-xfm`, `+resolve-plan-code`, `+get-plan-xfm`,
`+apply-bnd-chngs`, `+validate-bnd-chngs`, `+install-plan-lens`,
`+uninstall-plan-lens`. Plan fires once on install with empty `mine`
and produces lens bindings. Doctest: a plan over a small static
faucet emits the expected lens set.

**Phase 4 — propagate.**
Wire `%plan` subscribers into `+run-xfm-collect`'s dispatch. Plans
re-fire on faucet changes, emit deltas, the engine applies them.
Doctest: a plan over a mutable faucet — adding a faucet entry
installs a new lens, removing one tears it down.

**Phase 5 — failure modes.**
`+suspend-plan`, plan-rebuild on link target update, link-sub for
plan code. Doctest: plan with a broken transformer suspends with
err set; fixing the transformer recovers it.

**Phase 6 — `%mod` no-op fast path.**
Implement the `dep`+`sauc`-equality check inside `+apply-bnd-chngs`
to avoid churn when a plan re-emits identical specs.

## Tests (added to `lib/doctest-mesh.txt`)

- **Static plan, single binding.** Plan over a single-leaf faucet
  emits one lens; lens fires; data appears at expected stem.
- **Plan over a list faucet.** Faucet is a `(map @ data)`; plan emits
  one lens per key. Add a key → new lens appears + data flows. Remove
  a key → lens torn down + data subtree cleared.
- **Plan idempotence.** Plan re-emits an identical batch; with the
  `%mod` fast path, no faucet-sub churn (assert via subs set).
- **Cycle rejection.** Plan whose declared faucet is at or above its
  own stem → load fails.
- **Emitted-lens cycle rejection.** Plan emits a lens whose faucet is
  at or above its own (under-plan) stem → batch suspends the plan.
- **Plan-emitted lens collides with mesh-declared view.** Plan tries
  to install at a stem already occupied by a mesh-declared lens or
  form → batch suspends the plan.
- **Plan suspension preserves children.** Suspend a plan with err;
  installed sub-lenses keep firing. Fix the plan; on next faucet
  change, deltas reconcile cleanly.
- **Mesh teardown reaches plan-installed lenses.** `++drop` →
  `+wipe-mesh-view` faucet-unsubs every plan-installed lens.

## Out of scope for this round

- Plans emitting plans (recursion). Strictly additive later.
- Plans emitting forms. Decided no — see report at top of conversation.
- Cross-plan stem ownership reconciliation. Plans own subtrees only;
  two plans can't write the same stem because of the existing
  beneath-view check.
- Optimization (b) above (caching `mine` on plan's meta).
