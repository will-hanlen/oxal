# %oxal

## Specification

%oxal is a networked other than tests
reactive database.

There is a single tree of data.

An overlay tree stores metadata and defines cached transformations on other parts of the tree.

Each transformation is called a $view.
A $view is a pure function over the changelog of another location.

Like spreadsheets, $views chain together to create increasingly complex
transformations.


## Structure

- app/oxal.hoon - main agent
- lib/zozo.hoon - all zozo
- lib/zozo-0.hoon - types, tree engine, data engine, pith engine, parsers, printers
- lib/zozo-1.hoon - web utilities
- lib/zozo-2.hoon — file engine (`+fe`)
- lib/zozo-3.hoon — acer engine (`+ae`)


## Development Setup

Test piers run as tmux windows in a shared session. The wrapper
scripts read the local setup from `.env` in the repo root — copy
`.env.example` to `.env` to bootstrap. The relevant vars:

- `OXAL_TMUX_SESSION` — shared tmux session name.
- `OXAL_SHIPS` — space-separated list of ship aliases. Each alias
  is also the tmux window name, so `${OXAL_TMUX_SESSION}:${ship}`
  is the dojo target.
- `OXAL_<ship>_PIER` — pier path (relative to repo root) for each
  listed ship. Used by `--sync` runs to rsync the source tree in.
- `OXAL_TIMEOUT` — default dojo command timeout in seconds.

Helper scripts. All but `.dojo.sh` fan their command out to every
ship in `OXAL_SHIPS` *in parallel*, buffer per-ship output, and
print labeled blocks (`=== ship: <name> ===`) in declared order.
Exit is non-zero if any ship's run failed.

- `sh .commit.sh` — rsync the source tree into each ship's desk and
  `|commit %oxal`. Run after editing any file in the repo.
- `sh .run.sh "<dojo-command>"` — run an arbitrary dojo command on
  every ship without syncing (e.g. `sh .run.sh "|hi ~zod"`).
- `sh .doctest.sh` — `.commit.sh` plus `+oxal!doctest-run` to run the
  doctest suite on every ship and print each tang.
- `sh .dojo-fan.sh <cmd> [--sync]` — the fan-out primitive that the
  three wrappers above are built on; reach for it only when you need
  a different command + sync combination than they offer.
- `sh .dojo.sh <session:window> <timeout> <cmd> [--sync=<pier>]` —
  the single-ship primitive `.dojo-fan.sh` shells out to; reach for
  it only when targeting one specific ship outside the `.env` set
  (different ship, custom timeout, etc.).

## Typed dojo testing via `-build-file`

When testing with `.run.sh`, prefer real types over `*` returns. `*`
prints as raw cells of atoms (`[110 0]`, `1.635.017.060`); a real type
prints as `[%n ~]`, `%data`, with face names — and unlocks the lib's
arms.

### Pattern

```
=zo -build-file /=oxal=/lib/zozo/hoon
=/  d  .^(data:zo %gx /(scot %p our)/oxal/(scot %da now)/data/(scot %p our)/~/doctest/sample/noun)
~(tah do:zo d)
=zo
```

- **`=face -build-file /=desk=/path/to/file/hoon`** — builds a file
  and binds it to `face`. Every arm and type is now `arm:face`.
- **Type goes in `.^`**, not `;;`. `.^(data:zo %gx ...)` returns typed
  directly.
- **Always unpin** at the end: `=zo`. Pins persist across `.run.sh`
  calls (long-lived dojo session) and pollute future runs.

### Multi-line in one call

`.run.sh` sends embedded newlines as separate dojo statements; pins
are visible to later lines in the same call. Stack everything in one
call:

```
sh .run.sh '=zo -build-file /=oxal=/lib/zozo/hoon
=dt -build-file /=oxal=/lib/doctest/hoon
(report-to-data:dt *report:dt)
=zo
=dt'
```

### Gotchas

- `/+ foo` / `/- foo` don't work in dojo — no Ford context. Always
  `-build-file`.
- Use `=>  face  expr` to flatten arms into subject (drops the
  `:face` suffix).
- Scrying *inside* a `[%data ...]` leaf returns the empty oxal
  `[~ ~]` — the inner data is the leaf, not a child. Scry the
  wrapping pith and unwrap via `data.u.leaf.d`.
- Path segments slay: `~` → `[%n ~]`, `~zod` → `[%p ~zod]`, `42` →
  `[%ud 42]`. Build scry paths to match.

## Piths and paths

`pith = (list iota)` and `iota = node`. A pith is a list of typed
nodes; a hoon `path` is a list of `@ta` knots. They share the
`/foo/bar` literal syntax for all-term segments — both produce
`[%foo %bar ~]` — but diverge once segments are non-term.

**Use `#/foo/bar` to write a pith literal.** The `#` prefix triggers
slay-decoding of each segment, so atoms with auras land as typed
nodes; plain `/` keeps them as `@ta` knots.

```
> /foo/22/~zod
[%foo ~.22 ~.~zod ~]
> [#/foo/22/~zod]
[%foo [%ud 22] [%p ~zod] ~]
```

In the dojo `#/...` is not a valid standalone expression — wrap it:
`[#/foo/bar]`. (Plain `/foo/bar` *is* a standalone expression.)

Auras decoded by slay on `#/`: `42` → `[%ud 42]`, `~zod` → `[%p
~zod]`, `~2026.4.30` → `[%da ...]`, `0xdead.beef` → `[%ux ...]`, `~`
→ `[%n ~]`.

For nested piths, use `[pith+...]` (wide-form cell), not `[%pith
...]` (which the path parser won't read):

```
> [#/apps/[pith+[#/foo/users]]/view]
[%apps [%pith %foo %users ~] %view ~]
```

Don't use `~[...]` for piths in source — it's a tuple, not a typed
list, and fails `!< pith`.

### Serializers (lib/zozo-0)

Two pairs of round-trip serializers; pick by audience:

- **url-safe / terse — `+nate` / `+sily`, `+pate` / `+stib`.**
  `+pate` emits path-style segments (`/foo/22/~zod`); `+stib` is its
  inverse. `+nate` emits a single node (`%foo`, `ud+42`, `p+~zod`);
  `+sily` is its inverse. Use these for URLs, file paths, and
  anywhere the output round-trips through a tape.

- **hoon source — `+nare` / `+pare`.** Emit the form a programmer
  would write. `+pare` wraps in `[#/...]`, so `(slap !>(.) (ream
  (crip (pare p))))` recovers the pith. Use these when generating
  hoon source for `+ream` to evaluate.

Lossy summary: `+node-summary` produces a one-line, max-80-char
human-readable tape. Not round-trippable.

## Style

- 2-space indent
- arm descriptions go below the arm name
  ```
  ++  some-arm
    ::
    ::  comment describing what the arm does
    ::
    %the-body-of-the-arm
    ::
  ```
