::  three: common patterns (oxal-redux)
::
/+  *zozo-2
|%
++  zozo  %400
::
++  get-app
  ::
  ::  linear scan of apps for a name match.
  ::
  |=  [acer want=term]
  ^-  (unit app)
  ?~  apps  ~
  ?:  =(name.i.apps want)  `app.i.apps
  $(apps t.apps)
::
++  got-app
  ::
  |=  [=acer name=term]
  ~|  app-not-found/name
  (need (get-app acer name))
::
++  ae
  :::
  ::    acer engine
  ::
  =|  cards=(list card:agent:gall)
  |_  [ax=acer our=ship now=@da verb=? effects=?]
  +*  fil  file.ax
      dat  data.fil
      cod  code.fil
  ::
  ++  cor   .
  ++  abet  [(flop cards) ax]
  ++  emit  |=  =card:agent:gall  cor(cards [card cards])
  ++  emil  |=  cs=(list card:agent:gall)  cor(cards (welp (flop cs) cards))
  ::
  ++  ingress-tick
    ::
    ::  advance the acer's hlc against now (local cause).  returns the
    ::  new hlc and an updated cor.
    ::
    ^-  [hlc _cor]
    =/  new=hlc  (hlc-tick now-hlc.ax now)
    =.  now-hlc.ax  new
    [new cor]
  ::
  ++  ingress-merge
    ::
    ::  merge a remote hlc into the acer's hlc against now.  returns
    ::  the merged hlc and an updated cor.
    ::
    |=  rem=hlc
    ^-  [hlc _cor]
    =/  new=hlc  (hlc-merge now-hlc.ax rem now)
    =.  now-hlc.ax  new
    [new cor]
  ::
  ++  vlog
    ::
    ::  verbose-only slog: emit msg as a leaf iff verb is %.y.
    ::
    |=  msg=tape
    ^+  cor
    ?.  verb  cor
    %-  (slog leaf+msg ~)
    cor
  ::
  ++  under-our
    ::
    ::  qualify a bare user-facing pith with /[our]
    ::
    |=  pax=pith
    ^-  pith
    [p+our pax]
  ::
  ++  min-meta-depth  2
  ++  meta-allowed
    ::
    ::  is full-pax deep enough to carry meta and participate in
    ::  propagation?  the root and /[ship] are pinned at life=0 case=0.
    ::
    |=  full-pax=pith
    ^-  ?
    (gte (lent full-pax) min-meta-depth)
  ::
  ++  reject-shallow
    ::
    ::  slog a depth-rejection message and pass through cor
    ::
    |=  [op=tape full-pax=pith]
    ^+  cor
    %-  (slog leaf+"fe: rejected {op} at {(pate full-pax)}: depth < 2" ~)
    cor
  ::
  ++  gut-meta
    ::
    ::  get meta at pax, or default if missing
    ::
    |=  pax=pith
    ^-  meta
    (fall (~(get ox cod) pax) *meta)
  ::
  ++  find-app
    ::
    ::  linear scan of apps.ax for an entry with the given name.
    ::
    |=  want=term
    ^-  (unit app)
    =/  aps  apps.ax
    |-  ^-  (unit app)
    ?~  aps  ~
    ?:  =(name.i.aps want)  `app.i.aps
    $(aps t.aps)
  ::
  ++  meta-significant-change
    ::
    ::  does the transition from old to new touch any structural field?
    ::  case/logs/life alone are engine bookkeeping and don't fire
    ::  code facts.
    ::
    |=  [old=(unit meta) new=(unit meta)]
    ^-  ?
    ?~  new  ?=(^ old)
    ?~  old  %.y
    ?|  !=(grow.u.old grow.u.new)
        !=(eyre.u.old eyre.u.new)
        !=(gall.u.old gall.u.new)
        !=(lord.u.old lord.u.new)
        !=(subs.u.old subs.u.new)
        !=(view-subs.u.old view-subs.u.new)
    ==
  ::
  ++  beneath-view
    ::
    ::  is pax beneath an existing view?
    ::
    |=  [pax=pith c=code]
    ^-  ?
    ?=(^ (~(abo ox c) pax |=(m=_c &(?=(^ leaf.m) ?=(^ lord.u.leaf.m)))))
  ::
  ++  beneath-lens
    ::
    ::  is pax beneath an existing %lens view?
    ::
    |=  [pax=pith c=code]
    ^-  ?
    ?=(^ (~(abo ox c) pax |=(m=_c ?&(?=(^ leaf.m) ?=(^ lord.u.leaf.m) ?=(%lens -.view.u.lord.u.leaf.m)))))
  ::
  ++  at-or-beneath-lens
    ::
    ::  does pax itself have a %lens view, or sit beneath one?
    ::  do-move rejects writes here: %lens output is derived, not
    ::  user-editable.  %form views (and unview'd paths) hold base
    ::  data and pass through.
    ::
    |=  [pax=pith c=code]
    ^-  ?
    =/  met=meta  (fall (~(get ox c) pax) *meta)
    ?:  ?&  ?=(^ lord.met)
            ?=(%lens -.view.u.lord.met)
        ==
      %.y
    (beneath-lens pax c)
  ::
  ++  suspend-view
    ::
    ::  unsub from faucet and store error on view
    ::
    |=  [pax=pith =view met=meta =tang]
    ^+  cor
    ?>  ?=(%lens -.view)
    ?>  ?=(^ lord.met)
    =.  cor  (vlog "ae: suspend view at {(pate pax)}")
    =.  cor  (faucet-unsub pax dep.view)
    =.  cod
      %+  ~(put ox cod)  pax
      met(lord `[app=app.u.lord.met view=view(err `tang)])
    cor
  ::
  ++  get-xfm
    ::
    ::  get transformer from cache, or compile and cache it.
    ::  returns [%| tang] on parse/type failure so callers can
    ::  suspend the view instead of crashing the whole op.
    ::  failed compiles are not cached: the same cord would fail
    ::  again, so there is nothing to memoize.
    ::
    |=  src=@t
    ^-  [(each transformer tang) _cor]
    =/  cached  (~(get by xfms.ax) src)
    ?^  cached  [[%& u.cached] cor]
    =/  result=(each transformer tang)
      (mule |.(!<(transformer (slap !>(.) (ream src)))))
    ?-  -.result
      %&  =.  xfms.ax  (~(put by xfms.ax) src p.result)
          [result cor]
      %|  [result cor]
    ==
  ::
  ++  resolve-code
    ::
    ::  resolve view.sauc to the @t cord to compile.
    ::    - atom: use as-is
    ::    - link: fetch leaf from local data; on miss or
    ::      wrong shape, fall back to a crashing-gate cord so the
    ::      view suspends via run-xfm's mule on first invocation.
    ::
    |=  =view
    ^-  @t
    ?>  ?=(%lens -.view)
    ?@  sauc.view  sauc.view
    =/  link-pax=pith  (ref-to-pith sauc.view)
    =/  fallback=@t
      %-  crip
      """
      |=  *
      ~|  no-code/(pate {<link-pax>})
      !!
      """
    =/  nod=(unit node)  (~(get do dat) link-pax)
    ?~  nod  fallback
    ?.  ?=([%t @] u.nod)  fallback
    t.u.nod
  ::
  ++  reset-submetas
    ::
    ::  increment life, reset case, and clear logs for all
    ::  submetas under pax.
    ::  skip-root: don't touch the root meta (for install).
    ::
    |=  [pax=pith skip-root=?]
    ^+  cor
    =/  subs=(list (pair pith meta))
      ~(tap ox (~(dip ox cod) pax))
    =/  sr=?  skip-root
    |-  ^+  cor
    ?~  subs  cor
    =?  cor  ?!(?&(sr =(/ p.i.subs)))
      =/  full  (weld pax p.i.subs)
      =/  new-met=meta
        %=  q.i.subs
          life  ?:(grow.q.i.subs +(life.q.i.subs) life.q.i.subs)
          case  0
          logs  ~
        ==
      =.  cod  (~(put ox cod) full new-met)
      =/  snap=data  (~(dip do dat) full)
      (emit-node-effects full new-met snap [*hlc ~])
    $(subs t.subs)
  ::
  ++  faucet-unsub
    ::
    ::  remove full-pax from a faucet's subscriber set.
    ::  the faucet may live on any ship's subtree.
    ::
    |=  [full-pax=pith dep=link]
    ^+  cor
    =/  faucet-pax       (ref-to-pith dep)
    =/  faucet-met=meta  (gut-meta faucet-pax)
    =.  cod
      %+  ~(put ox cod)  faucet-pax
      faucet-met(subs (~(del in subs.faucet-met) full-pax))
    cor
  ::
  ++  link-sub
    ::
    ::  register a view at full-pax as a link-subscriber on the
    ::  meta at link-pax (the pith pointed to by [%link pith]).
    ::
    |=  [full-pax=pith link-pax=pith]
    ^+  cor
    =/  met=meta  (gut-meta link-pax)
    =.  cod
      %+  ~(put ox cod)  link-pax
      met(view-subs (~(put in view-subs.met) full-pax))
    cor
  ::
  ++  link-unsub
    ::
    ::  remove a view at full-pax from the link-subscriber set
    ::  on the meta at link-pax.
    ::
    |=  [full-pax=pith link-pax=pith]
    ^+  cor
    =/  met=meta  (gut-meta link-pax)
    =.  cod
      %+  ~(put ox cod)  link-pax
      met(view-subs (~(del in view-subs.met) full-pax))
    cor
  ::
  ++  maybe-link-unsub
    ::
    ::  if view.sauc is a link, call link-unsub; else no-op.
    ::
    |=  [full-pax=pith =view]
    ^+  cor
    ?>  ?=(%lens -.view)
    ?@  sauc.view  cor
    (link-unsub full-pax (ref-to-pith sauc.view))
  ::
  ++  ingress-do-move
    ::
    ::  user-facing move: chng piths are bare, relative to /[our].
    ::  qualify them and dispatch to apply-move-qualified.  wraps the
    ::  dispatch to capture structural code changes produced by any
    ::  transformer firings during propagate.  ticks the agent-level
    ::  hlc once and freezes that time onto the move, so all log
    ::  entries from this cause share one timestamp.
    ::
    |=  [=move allow-view-write=?]
    ^+  cor
    =^  time=hlc  cor  ingress-tick
    =.  move  move(time time)
    =.  cor  (vlog "ae: do-move ({(scow %ud ~(wyt in chng-set.move))} changes)")
    =/  cod-before  cod
    =.  cor  (apply-move-qualified (prefix-move [p+our ~] move) allow-view-write)
    (emit-code-at-ancestors cod-before)
  ::
  ++  apply-move-qualified
    ::
    ::  apply a move whose chng piths are already qualified
    ::  (start with a ship iota).  updates data, filters to
    ::  effective changes, walks up code tree.
    ::
    |=  [=move allow-view-write=?]
    ^+  cor
    =/  [d=data effective=(set chng)]
      (apply-changes move allow-view-write)
    ?:  =(~ effective)  cor
    (propagate d cod effective time.move)
  ::
  ++  rebuild-view
    ::
    ::  wipe a view's output and re-fire its transformer from the
    ::  current faucet snap.  used when the view's source code
    ::  changed (link target update) or its faucet's life bumped.
    ::  full-pax is fully qualified with [%p our].
    ::
    |=  full-pax=pith
    ^+  cor
    =/  met=meta  (gut-meta full-pax)
    ?~  lord.met  cor
    =*  vw  view.u.lord.met
    ?>  ?=(%lens -.vw)
    =.  cor  (vlog "ae: rebuild-view at {(pate full-pax)}")
    =.  dat  (~(lop do dat) full-pax)
    =/  faucet-met=meta  (gut-meta (ref-to-pith dep.vw))
    (initialize-from-snap full-pax vw faucet-met)
  ::
  ++  reinstall-links
    ::
    ::  for each effective change, rebuild every view-sub on the meta
    ::  at the change's pith from the current faucet snap.  re-resolves
    ::  link sources, so a code change at the link target propagates
    ::  into a fresh transformer.
    ::
    |=  effective=(set chng)
    ^+  cor
    =/  chs=(list chng)  ~(tap in effective)
    |-  ^+  cor
    ?~  chs  cor
    =/  m=meta  (gut-meta (pith-of-chng i.chs))
    =/  vs=(list pith)  ~(tap in view-subs.m)
    =.  cor
      |-  ^+  cor
      ?~  vs  cor
      =.  cor  (rebuild-view i.vs)
      $(vs t.vs)
    $(chs t.chs)
  ::
  ++  reinstall-subs
    ::
    ::  rebuild every view in pax's subs set from the current faucet
    ::  snap.  used on remote life-bump to force local subscribers
    ::  to rebuild from the fresh snap.
    ::
    |=  pax=pith
    ^+  cor
    =/  m=meta  (gut-meta pax)
    =/  subs-list=(list pith)  ~(tap in subs.m)
    |-  ^+  cor
    ?~  subs-list  cor
    =.  cor  (rebuild-view i.subs-list)
    $(subs-list t.subs-list)
  ::
  ++  apply-changes
    ::
    ::  apply each change to data, filtering to effective ones.
    ::  skip changes at or beneath a %lens view unless allow-view-write:
    ::  do-move only writes to base data (under forms or unview'd).
    ::
    |=  [=move allow-view-write=?]
    ^-  [data (set chng)]
    =/  d=data  dat
    =/  c=code  cod
    =/  is-at-or-beneath-lens=$-([pith code] ?)  at-or-beneath-lens
    =/  effective=(set chng)  ~
    =/  changes=(list chng)  ~(tap in chng-set.move)
    |-
    ?~  changes  [d effective]
    =/  p=pith  (pith-of-chng i.changes)
    ?:  ?&(!allow-view-write (is-at-or-beneath-lens p c))
      ~|  "fe: rejected write at or beneath lens at {(pate p)}"
      !!
    ?-  -.i.changes
      %ins
        ?:  =(`node.i.changes (~(get do d) pith.i.changes))
          $(changes t.changes)
        %=  $
          changes    t.changes
          d          (~(put do d) pith.i.changes node.i.changes)
          effective  (~(put in effective) i.changes)
        ==
      ::
      %del
        ?.  (~(has do d) pith.i.changes)
          $(changes t.changes)
        %=  $
          changes    t.changes
          d          (~(del do d) pith.i.changes)
          effective  (~(put in effective) i.changes)
        ==
    ==
  ::
  ++  propagate
    ::
    ::  merge-walk.  process ancestor piths longest-first from a shared
    ::  queue; each pith bumps its case at most once.  firing a
    ::  subscriber's transformer produces a move whose ancestors and
    ::  relative chngs are merged back into the same queue/rels,
    ::  so downstream updates share the walk instead of triggering
    ::  nested propagates.  at the end, re-install %link-subscribed
    ::  views whose link target was in any effective change.
    ::
    ::  time is the cause's hlc, frozen at ingress.  every log entry
    ::  appended during this walk -- including transformer-produced
    ::  ones -- carries this same time.
    ::
    |=  [d=data c=code effective=(set chng) time=hlc]
    ^+  cor
    ::  commit data/code up front so transformer-produced changes
    ::  see the current state.
    ::
    =.  cor  cor(data.file.ax d, code.file.ax c)
    =/  rels=(map pith (set chng))  (build-rels effective)
    =/  queue=(list pith)  (sort-piths-desc ~(key by rels))
    =|  processed=(set pith)
    =/  combined=(set chng)  effective
    (propagate-loop queue rels processed combined time)
  ::
  ++  propagate-loop
    ::
    ::  one iteration of the merge-walk.
    ::
    |=  $:  queue=(list pith)
            rels=(map pith (set chng))
            processed=(set pith)
            combined=(set chng)
            time=hlc
        ==
    ^+  cor
    ?~  queue
      (reinstall-links combined)
    =/  anc=pith  i.queue
    =/  rest=(list pith)  t.queue
    ?:  (~(has in processed) anc)
      $(queue rest)
    =.  processed  (~(put in processed) anc)
    =/  rel=(set chng)  (fall (~(get by rels) anc) ~)
    ?~  rel
      $(queue rest)
    =/  met=meta  (gut-meta anc)
    =/  rel-move=move  [time rel]
    =/  new-met=meta
      %=  met
        case  +(case.met)
        logs  (snoc logs.met rel-move)
      ==
    ::  bump case and append this walk's [time rel] to logs
    ::
    =.  cor
      %-  vlog
      "ae: propagate at {(pate anc)} life={(scow %ud life.new-met)} case={(scow %ud case.new-met)}"
    =.  cod  (~(put ox cod) anc new-met)
    =/  snap=data  (~(dip do dat) anc)
    ::  fan this bump out to gall/grow/eyre channels
    ::
    =.  cor  (emit-node-effects anc new-met snap rel-move)
    ::  fire subscribers of this ancestor, collecting their outputs
    ::
    =^  xfm-out=move  cor
      (fire-subs-collect new-met snap rel life.new-met case.new-met time)
    ?:  =(~ chng-set.xfm-out)
      $(queue rest)
    ::  apply transformer output to data; filter to effective chngs
    ::
    =^  xfm-effective=(set chng)  cor  (apply-extra-changes xfm-out)
    ?:  =(~ xfm-effective)
      $(queue rest)
    =.  combined  (~(uni in combined) xfm-effective)
    =/  added-rels=(map pith (set chng))  (build-rels xfm-effective)
    =.  rels   (merge-rels rels added-rels)
    =/  new-queue=(list pith)
      (merge-queue rest ~(key by added-rels) processed)
    $(queue new-queue)
  ::
  ++  run-xfm
    ::
    ::  apply one transformer invocation to a subscriber view.
    ::  on success: update view lyf/cas, apply prefixed output.
    ::  on failure: unsub from faucet and suspend view.
    ::
    ::  sub is a fully-qualified pith (starts with a ship iota);
    ::  the transformer output is prefixed with sub and applied
    ::  via apply-move-qualified to avoid double-prefixing.  the
    ::  input move and re-applied output both carry now-hlc.ax,
    ::  the cause's frozen time (already ticked at ingress).
    ::
    |=  [sub=pith =view met=meta snap=data mov=(set chng) lyf=@ud cas=@ud]
    ^+  cor
    ?>  ?=(%lens -.view)
    ?>  ?=(^ lord.met)
    =.  cor  (vlog "ae: run-xfm at {(pate sub)}")
    =^  xfm-res=(each transformer tang)  cor  (get-xfm (resolve-code view))
    ?:  ?=(%| -.xfm-res)
      (suspend-view sub view met p.xfm-res)
    =/  xfm=transformer  p.xfm-res
    =/  mine=data  (~(dip do dat) sub)
    =/  time=hlc  now-hlc.ax
    =/  in-move=move  [time mov]
    =/  result=(each move tang)
      (mule |.((xfm [mine snap in-move lyf cas])))
    ?-  -.result
      %&
        =.  cod
          %+  ~(put ox cod)  sub
          met(lord `[app=app.u.lord.met view=view(lyf lyf, cas cas)])
        =/  prefixed=move  (prefix-move sub p.result)
        (apply-move-qualified [prefixed(time time) %.y])
      ::
      %|
        (suspend-view sub view met p.result)
    ==
  ::
  ++  migrate-form-view
    ::
    ::  splat a form view's pre-computed migration output into the
    ::  cleared subtree at its stem.  place-app-view has already lopped
    ::  the subtree, so rep replaces a clean target.
    ::
    |=  [stem=pith new=data]
    ^+  cor
    =/  full-pax  (under-our stem)
    =.  dat  (~(rep do dat) full-pax new)
    cor
  ::
  ++  place-app-view
    ::
    ::  install one view from app `name` at stem.  for %lens, wires
    ::  faucet subs, optional link subs, and runs initialize-from-snap.
    ::  for %form, just writes the meta (no faucet, no transformer).
    ::  pre-validated by ingress-install-app, so the meta-allowed and
    ::  beneath-view checks here are defensive.
    ::
    |=  [name=term stem=pith =view]
    ^+  cor
    =/  full-pax  (under-our stem)
    =/  old=(unit meta)  (~(get ox cod) full-pax)
    =/  met=meta
      %*  .  *meta
        life       ?~  old  0
                   ?:  grow.u.old  +(life.u.old)
                   life.u.old
        lord       `[app=name view=view]
        subs       ?~(old ~ subs.u.old)
        view-subs  ?~(old ~ view-subs.u.old)
        grow       ?~(old %.n grow.u.old)
        eyre       ?~(old ~ eyre.u.old)
        gall       ?~(old ~ gall.u.old)
      ==
    =.  cod  (~(put ox cod) full-pax met)
    =.  dat  (~(lop do dat) full-pax)
    ?:  ?=(%form -.view)  cor
    =/  full-dep=pith    (ref-to-pith dep.view)
    =/  faucet-met=meta  (gut-meta full-dep)
    =.  cod
      %+  ~(put ox cod)  full-dep
      faucet-met(subs (~(put in subs.faucet-met) full-pax))
    =?  cor  ?=(^ sauc.view)
      (link-sub full-pax (ref-to-pith sauc.view))
    (initialize-from-snap full-pax view faucet-met)
  ::
  ++  ingress-install-app
    ::
    ::  compile app source, run it with empty data, place all returned
    ::  views, and append the app entry to acer.apps.  on compile or
    ::  run failure, store the entry with views=~ and error=`tang —
    ::  no tree changes.  rejects if `name` already exists, or if any
    ::  returned stem fails pre-validation (depth or beneath-view).
    ::
    |=  [name=term source=@t]
    ^+  cor
    =.  cor  (vlog "ae: install-app {<name>}")
    ?:  ?=(^ (find-app name))
      %-  (slog leaf+"ae: rejected install-app: {<name>} already exists" ~)
      cor
    =/  cod-before  cod
    =/  comp=(each app-gate tang)
      (mule |.(!<(app-gate (slap !>(.) (ream source)))))
    ?:  ?=(%| -.comp)
      =/  =app  *app
      =.  source.app  source
      =.  error.app  `p.comp
      =.  apps.ax  (snoc apps.ax [name app])
      cor
    =/  =app-gate  p.comp
    =/  globals=data  (~(dip do dat) ~[p+our [%n ~] %globals])
    =/  locals=data   (~(dip do dat) ~[p+our [%n ~] %app name])
    =/  run=(each (map stem view) tang)
      (mule |.((app-gate [our name globals locals])))
    ?:  ?=(%| -.run)
      =/  =app  *app
      =.  source.app    source
      =.  app-gate.app  app-gate
      =.  error.app     `p.run
      =.  apps.ax  (snoc apps.ax [name app])
      cor
    =/  vws=(map stem view)  p.run
    ::
    ::  inject the system-owned locals view at /[our]/~/app/[name].
    ::  bare stem; under-our qualifies it during placement.  reject
    ::  if the app-gate already declared a view at this exact stem.
    ::
    =/  locals-stem=stem  ~[[%n ~] %app name]
    ?:  (~(has by vws) locals-stem)
      =/  =app  *app
      =.  source.app    source
      =.  app-gate.app  app-gate
      =.  error.app     `~[leaf+"app may not declare view at locals stem"]
      =.  apps.ax       (snoc apps.ax [name app])
      cor
    =.  vws  (~(put by vws) locals-stem [%form ~ ~])
    =/  pairs=(list [stem view])  ~(tap by vws)
    =/  validation=(unit @t)
      |-  ^-  (unit @t)
      ?~  pairs  ~
      =/  full-pax  (under-our -.i.pairs)
      =/  vw=view   +.i.pairs
      ?.  (meta-allowed full-pax)
        `(crip "ae: install-app rejected: stem too shallow at {(pate full-pax)}")
      ?:  (beneath-view full-pax cod)
        `(crip "ae: install-app rejected: stem at or beneath existing view at {(pate full-pax)}")
      ?:  ?&  ?=(%lens -.vw)
              (~(is-ancestor-or-same th full-pax) (ref-to-pith dep.vw))
          ==
        `(crip "ae: install-app rejected: lens at {(pate full-pax)} has self or ancestor as faucet at {(pate (ref-to-pith dep.vw))}")
      $(pairs t.pairs)
    ?^  validation
      %-  (slog leaf+(trip u.validation) ~)
      cor
    ::
    ::  pre-capture: snapshot data at every form-view stem (v1 state).
    ::  must run before any place-app-view, because place-app-view lops
    ::  the subtree, and a shallow form's lop would erase data a deeper
    ::  form still needs to migrate from.
    ::
    =/  form-snaps=(map stem data)
      =/  ps=(list [s=stem v=view])  ~(tap by vws)
      =|  acc=(map stem data)
      |-  ^-  (map stem data)
      ?~  ps  acc
      ?.  ?=(%form -.v.i.ps)
        $(ps t.ps)
      =/  full-pax  (under-our s.i.ps)
      $(ps t.ps, acc (~(put by acc) s.i.ps (~(dip do dat) full-pax)))
    ::
    ::  pre-flight migrators: run every form view's migrator on its
    ::  snapshot, trapped via mule.  if any crashes, abort the install:
    ::  store entry with error, no dat or cod mutation.
    ::
    =/  migrated=(each (map stem data) tang)
      =/  ps=(list [s=stem v=view])  ~(tap by vws)
      =|  acc=(map stem data)
      |-  ^-  (each (map stem data) tang)
      ?~  ps  [%& acc]
      ?.  ?=(%form -.v.i.ps)
        $(ps t.ps)
      ?~  migrator.v.i.ps
        $(ps t.ps)
      =/  pre=data  (~(got by form-snaps) s.i.ps)
      =/  res=(each data tang)
        (mule |.((u.migrator.v.i.ps pre)))
      ?-  -.res
        %|  [%| p.res]
        %&  $(ps t.ps, acc (~(put by acc) s.i.ps p.res))
      ==
    ?:  ?=(%| -.migrated)
      =/  =app  *app
      =.  source.app    source
      =.  app-gate.app  app-gate
      =.  error.app     `p.migrated
      =.  apps.ax       (snoc apps.ax [name app])
      cor
    ::
    ::  phase A: place all views (existing behavior — meta + lop, lens
    ::  wires faucet and runs initialize-from-snap).
    ::
    =.  cor
      =/  pairs=(list [stem view])  ~(tap by vws)
      |-  ^+  cor
      ?~  pairs  cor
      =.  cor  (place-app-view name -.i.pairs +.i.pairs)
      $(pairs t.pairs)
    ::
    ::  phase B: splat migrator outputs into the cleared subtrees,
    ::  shallowest-first.  rep replaces a whole subtree, so a deeper
    ::  stem's splat must land last to win where stems nest.
    ::
    =.  cor
      =/  splats=(list [stem data])  ~(tap by p.migrated)
      =.  splats
        %+  sort  splats
        |=  [a=[s=stem *] b=[s=stem *]]
        (lth (lent s.a) (lent s.b))
      |-  ^+  cor
      ?~  splats  cor
      =.  cor  (migrate-form-view -.i.splats +.i.splats)
      $(splats t.splats)
    =/  =app  *app
    =.  source.app    source
    =.  app-gate.app  app-gate
    =.  views.app     vws
    =.  apps.ax  (snoc apps.ax [name app])
    (emit-code-at-ancestors cod-before)
  ::
  ++  uninstall-app-view
    ::
    ::  remove a single app view: faucet/link unsub for %lens, then
    ::  clear lord on meta.  preserves data.  stem is bare; qualified
    ::  with /[our] before lookup.
    ::
    |=  [stem=pith =view]
    ^+  cor
    =/  full-pax  (under-our stem)
    =/  met=meta  (gut-meta full-pax)
    =?  cor  ?=(%lens -.view)
      =.  cor  (faucet-unsub full-pax dep.view)
      (maybe-link-unsub full-pax view)
    =.  cod  (~(put ox cod) full-pax met(lord ~))
    cor
  ::
  ++  ingress-uninstall-app
    ::
    ::  remove every view placed by app `name` (faucet/link unsub,
    ::  clear lord) and drop the entry from apps.ax.  preserves data.
    ::  no-op (with slog) if name not found.
    ::
    |=  name=term
    ^+  cor
    =.  cor  (vlog "ae: uninstall-app {<name>}")
    =/  found=(unit app)  (find-app name)
    ?~  found
      %-  (slog leaf+"ae: rejected uninstall-app: {<name>} not found" ~)
      cor
    =/  cod-before  cod
    =.  cor
      =/  pairs=(list [stem view])  ~(tap by views.u.found)
      |-  ^+  cor
      ?~  pairs  cor
      =.  cor  (uninstall-app-view -.i.pairs +.i.pairs)
      $(pairs t.pairs)
    =.  apps.ax
      %+  skip  apps.ax
      |=  [n=term *]
      =(n name)
    (emit-code-at-ancestors cod-before)
  ::
  ++  ingress-reinstall-app
    ::
    ::  re-install app `name` from its stored source: remove all of
    ::  its current views, then rerun install-app with the same source.
    ::  no-op (with slog) if name not found.
    ::
    |=  name=term
    ^+  cor
    =.  cor  (vlog "ae: reinstall-app {<name>}")
    =/  found=(unit app)  (find-app name)
    ?~  found
      %-  (slog leaf+"ae: rejected reinstall-app: {<name>} not found" ~)
      cor
    =/  src=@t  source.u.found
    =.  cor  (ingress-uninstall-app name)
    (ingress-install-app name src)
  ::
  ++  ingress-update-app
    ::
    ::  replace app `name`'s source: uninstall its current views, then
    ::  install fresh from the new source.  installs from scratch if
    ::  no app by that name exists.
    ::
    |=  [name=term source=@t]
    ^+  cor
    =.  cor  (vlog "ae: update-app {<name>}")
    =/  found=(unit app)  (find-app name)
    =?  cor  ?=(^ found)  (ingress-uninstall-app name)
    (ingress-install-app name source)
  ::
  ++  ingress-set-grow
    ::
    ::  set grow flag on meta at pax, creating meta if missing.
    ::  pax is user-facing (qualified with /[our]).
    ::
    |=  [pax=pith val=?]
    ^+  cor
    ?>  effects
    =/  full-pax  (under-our pax)
    =.  cor  (vlog "ae: set-grow at {(pate full-pax)} = {?:(val "y" "n")}")
    ?.  (meta-allowed full-pax)  (reject-shallow "set-grow" full-pax)
    =/  cod-before  cod
    =/  met=meta  (gut-meta full-pax)
    =.  cod  (~(put ox cod) full-pax met(grow val))
    (emit-code-at-ancestors cod-before)
  ::
  ++  ingress-set-eyre
    ::
    ::  set eyre auth on meta at pax, creating meta if missing.
    ::  pax is user-facing (qualified with /[our]).
    ::  if the new state is cache-safe, push current node to the
    ::  eyre cache; if we left a cache-safe state, evict.
    ::
    |=  [pax=pith val=(unit auth)]
    ^+  cor
    ?>  effects
    =/  full-pax  (under-our pax)
    =.  cor  (vlog "ae: set-eyre at {(pate full-pax)}")
    ?.  (meta-allowed full-pax)  (reject-shallow "set-eyre" full-pax)
    =/  cod-before  cod
    =/  met=meta  (gut-meta full-pax)
    =/  new-met=meta  met(eyre val)
    =.  cod  (~(put ox cod) full-pax new-met)
    =.  cor
      ?:  (eyre-cached new-met)
        (eyre-push full-pax new-met (~(get do dat) full-pax))
      ?:  (eyre-cached met)
        (eyre-evict full-pax)
      cor
    (emit-code-at-ancestors cod-before)
  ::
  ++  ingress-set-gall
    ::
    ::  set gall auth on meta at pax, creating meta if missing.
    ::  pax is user-facing (qualified with /[our]).
    ::  on flip-off, kick existing /sub/, /code/, and /both/ subscribers
    ::  (their subscription is no longer valid).  on flip-on, nothing
    ::  to push: subscribers will arrive via on-watch and get initial
    ::  state there.
    ::
    |=  [pax=pith val=(unit auth)]
    ^+  cor
    ?>  effects
    =/  full-pax  (under-our pax)
    =.  cor  (vlog "ae: set-gall at {(pate full-pax)}")
    ?.  (meta-allowed full-pax)  (reject-shallow "set-gall" full-pax)
    =/  cod-before  cod
    =/  met=meta  (gut-meta full-pax)
    =.  cod  (~(put ox cod) full-pax met(gall val))
    =.  cor  (emit-code-at-ancestors cod-before)
    ?.  &(?=(^ gall.met) ?=(~ val))  cor
    =/  bp=path  (bare-path full-pax)
    %-  emit
    [%give %kick ~[[%sub bp] [%code bp] [%both bp]] ~]
  ::
  ++  initialize-from-snap
    ::
    ::  run the transformer once with the faucet's current snap and
    ::  an empty move, signaling "reconstruct state from snap".
    ::  full-pax is qualified.
    ::
    |=  [full-pax=pith =view faucet-met=meta]
    ^+  cor
    ?>  ?=(%lens -.view)
    =/  met=meta  (gut-meta full-pax)
    ?.  ?=(^ lord.met)  cor
    =*  vw  view.u.lord.met
    ?>  ?=(%lens -.vw)
    ?:  ?=(^ err.vw)  cor
    =/  snap=data  (~(dip do dat) (ref-to-pith dep.view))
    %:  run-xfm
      full-pax  view  met  snap  ~
      life.faucet-met  case.faucet-met
    ==
  ::
  ++  ingress-hear-remote
    ::
    ::  apply an incoming fact about ship's faucet at pax.
    ::  life bump => replace subtree with snap and reset submetas;
    ::  otherwise apply the incremental move.  subscriber views
    ::  living under /[our]/... are fired via the normal propagate
    ::  path inside apply-move-qualified.
    ::
    |=  [=ship pax=pith snap=data =move =life =case]
    ^+  cor
    =/  full-pax  `pith`[p+ship pax]
    =.  cor  (vlog "ae: hear-remote from {<ship>} at {(pate full-pax)}")
    ?.  (meta-allowed full-pax)  (reject-shallow "hear-remote" full-pax)
    ::  merge the originator's hlc into our agent clock and re-stamp
    ::  the move with the merged hlc.  any local downstream fan-out
    ::  uses this merged time, so the receiver's logs record "when i
    ::  learned this", not the originator's clock alone.
    ::
    =^  time=hlc  cor  (ingress-merge time.move)
    =.  move  move(time time)
    =/  cod-before  cod
    =/  met=meta  (gut-meta full-pax)
    =?  cor  |((gth life life.met) =(~ chng-set.move))
      =.  dat  (~(rep do dat) full-pax snap)
      =.  cod
        %+  ~(put ox cod)  full-pax
        met(life life, case case, logs ~)
      =.  cor  (reset-submetas full-pax %.y)
      =/  new-met=meta  (gut-meta full-pax)
      =/  snp=data  (~(dip do dat) full-pax)
      =.  cor  (emit-node-effects full-pax new-met snp [*hlc ~])
      (reinstall-subs full-pax)
    =.  cor  (apply-move-qualified (prefix-move [p+ship ~] move) %.y)
    (emit-code-at-ancestors cod-before)
  ::
  ++  ingress-hear-remote-code
    ::
    ::  apply an incoming %oxal-code fact about ship's faucet at pax.
    ::  life bump or empty meta-move => overwrite our mirrored code
    ::  subtree at full-pax with snap; otherwise apply the incremental
    ::  meta-move by welding full-pax onto each relative pith.  local
    ::  /code/ and /both/ subscribers are notified by the trailing
    ::  emit-code-at-ancestors call.
    ::
    |=  [=ship pax=pith snap=code =meta-move =life =case]
    ^+  cor
    =/  full-pax  `pith`[p+ship pax]
    =.  cor  (vlog "ae: hear-remote-code from {<ship>} at {(pate full-pax)}")
    ?.  (meta-allowed full-pax)  (reject-shallow "hear-remote-code" full-pax)
    =/  cod-before  cod
    =/  met=meta  (gut-meta full-pax)
    ?:  |((gth life life.met) =(~ meta-move))
      =.  cod  (~(rep ox cod) full-pax snap)
      (emit-code-at-ancestors cod-before)
    =.  cod
      =/  chs=(list meta-chng)  ~(tap in meta-move)
      |-  ^+  cod
      ?~  chs  cod
      =.  cod
        ?-  -.i.chs
          %ins  (~(put ox cod) (weld full-pax pith.i.chs) meta.i.chs)
          %del  (~(del ox cod) (weld full-pax pith.i.chs))
        ==
      $(chs t.chs)
    (emit-code-at-ancestors cod-before)
  ::
  ++  ingress-bump
    ::
    ::  wipe data subtree, increment lifes, reset cases and logs.
    ::  only valid within a %form view; rejected otherwise.
    ::  pax is user-facing (qualified with /[our]).
    ::
    |=  pax=pith
    ^+  cor
    =/  full-pax  (under-our pax)
    =.  cor  (vlog "ae: bump at {(pate full-pax)}")
    ?.  (meta-allowed full-pax)  (reject-shallow "bump" full-pax)
    ::  the closest enclosing view (including self) must be a %form
    ::
    ~|  %bump-must-be-within-form-view
    =/  ancs=(list (pair pith _cod))
      %+  ~(anc ox cod)  full-pax
      |=(m=_cod ?&(?=(^ leaf.m) ?=(^ lord.u.leaf.m)))
    ?<  ?=(~ ancs)
    ?>  ?=(^ leaf.q.i.ancs)
    ?>  ?=(^ lord.u.leaf.q.i.ancs)
    ?>  ?=(%form -.view.u.lord.u.leaf.q.i.ancs)
    ::
    =/  cod-before  cod
    =.  dat  (~(lop do dat) full-pax)
    =.  cor  (reset-submetas full-pax %.n)
    (emit-code-at-ancestors cod-before)
  ::
  ++  build-rels
    ::
    ::  map each ancestor pith of each chng (the chng pith itself,
    ::  every prefix, and the root ~) to the set of chngs relativized
    ::  to that ancestor.
    ::
    |=  chs=(set chng)
    ^-  (map pith (set chng))
    =/  cl=(list chng)  ~(tap in chs)
    =|  out=(map pith (set chng))
    |-  ^+  out
    ?~  cl  out
    =/  ch=chng  i.cl
    =/  p=pith  (pith-of-chng ch)
    =/  depths=(list @ud)
      ?:  (lth (lent p) min-meta-depth)  ~
      (gulf min-meta-depth (lent p))
    =.  out
      |-  ^+  out
      ?~  depths  out
      =/  d=@ud  i.depths
      =/  anc=pith  (scag d p)
      =/  rp=pith   (slag d p)
      =/  rel-chng=chng
        ?-  -.ch
          %ins  ch(pith rp)
          %del  ch(pith rp)
        ==
      =/  have=(set chng)  (fall (~(get by out) anc) ~)
      =.  out  (~(put by out) anc (~(put in have) rel-chng))
      $(depths t.depths)
    $(cl t.cl)
  ::
  ++  sort-piths-desc
    ::
    ::  list of piths from a set, sorted by length descending.
    ::
    |=  ps=(set pith)
    ^-  (list pith)
    %+  sort  ~(tap in ps)
    |=  [a=pith b=pith]
    (gth (lent a) (lent b))
  ::
  ++  merge-rels
    ::
    ::  merge b into a, unioning chng sets at shared piths.
    ::
    |=  [a=(map pith (set chng)) b=(map pith (set chng))]
    ^-  (map pith (set chng))
    =/  kvs=(list (pair pith (set chng)))  ~(tap by b)
    |-  ^+  a
    ?~  kvs  a
    =/  have  (fall (~(get by a) p.i.kvs) ~)
    =.  a  (~(put by a) p.i.kvs (~(uni in have) q.i.kvs))
    $(kvs t.kvs)
  ::
  ++  merge-queue
    ::
    ::  add new piths to queue, skipping any that are already
    ::  processed or already in the queue; re-sort longest-first.
    ::
    |=  [q=(list pith) adds=(set pith) processed=(set pith)]
    ^-  (list pith)
    =/  have=(set pith)  (~(gas in *(set pith)) q)
    =/  new=(list pith)
      %+  skim  ~(tap in adds)
      |=  p=pith
      ?&  !(~(has in processed) p)
          !(~(has in have) p)
      ==
    %+  sort  (weld q new)
    |=  [a=pith b=pith]
    (gth (lent a) (lent b))
  ::
  ++  fire-subs-collect
    ::
    ::  fire every subscriber of met's subs, collecting their
    ::  transformer outputs into one combined move.  suspended and
    ::  absent views are skipped.  time is the cause's hlc; the
    ::  combined output carries it.
    ::
    |=  [met=meta snap=data mov=(set chng) lyf=@ud cas=@ud time=hlc]
    ^-  [move _cor]
    =/  sub-list=(list pith)  ~(tap in subs.met)
    =/  out=move  [time ~]
    |-  ^+  [out cor]
    ?~  sub-list  [out cor]
    =/  sub=pith  i.sub-list
    =/  sub-met=meta  (gut-meta sub)
    ?~  lord.sub-met  $(sub-list t.sub-list)
    =*  vw  view.u.lord.sub-met
    ?>  ?=(%lens -.vw)
    ?:  ?=(^ err.vw)  $(sub-list t.sub-list)
    =^  maybe-out=(unit move)  cor
      (run-xfm-collect sub vw sub-met snap mov lyf cas time)
    =?  out  ?=(^ maybe-out)
      out(chng-set (~(uni in chng-set.out) chng-set.u.maybe-out))
    $(sub-list t.sub-list)
  ::
  ++  run-xfm-collect
    ::
    ::  run a subscriber's transformer.  on success, update the view
    ::  meta and return the prefixed output move.  on crash, suspend
    ::  the view and return ~.  the input move carries the cause's
    ::  time so transformers can read it; the output is re-stamped
    ::  with the same time -- transformers don't get to invent
    ::  timestamps (otherwise replay diverges).
    ::
    |=  [sub=pith =view met=meta snap=data mov=(set chng) lyf=@ud cas=@ud time=hlc]
    ^-  [(unit move) _cor]
    ?>  ?=(%lens -.view)
    ?>  ?=(^ lord.met)
    =.  cor  (vlog "ae: fire xfm at {(pate sub)}")
    =^  xfm-res=(each transformer tang)  cor  (get-xfm (resolve-code view))
    ?:  ?=(%| -.xfm-res)
      [~ (suspend-view sub view met p.xfm-res)]
    =/  xfm=transformer  p.xfm-res
    =/  mine=data  (~(dip do dat) sub)
    =/  in-move=move  [time mov]
    =/  result=(each move tang)
      (mule |.((xfm [mine snap in-move lyf cas])))
    ?-  -.result
      %&
        =.  cod
          %+  ~(put ox cod)  sub
          met(lord `[app=app.u.lord.met view=view(lyf lyf, cas cas)])
        =/  prefixed=move  (prefix-move sub p.result)
        [`prefixed(time time) cor]
      ::
      %|
        [~ (suspend-view sub view met p.result)]
    ==
  ::
  ++  apply-extra-changes
    ::
    ::  apply a transformer output move to data, returning the set
    ::  of effective (non-no-op) chngs.  beneath-view filtering is
    ::  skipped: output is already prefixed with the view's own pith.
    ::
    |=  mv=move
    ^-  [(set chng) _cor]
    =/  d=data  dat
    =|  effective=(set chng)
    =/  changes=(list chng)  ~(tap in chng-set.mv)
    |-
    ?~  changes
      =.  cor  cor(data.file.ax d)
      [effective cor]
    ?-  -.i.changes
      %ins
        ?:  =(`node.i.changes (~(get do d) pith.i.changes))
          $(changes t.changes)
        %=  $
          changes    t.changes
          d          (~(put do d) pith.i.changes node.i.changes)
          effective  (~(put in effective) i.changes)
        ==
      ::
      %del
        ?.  (~(has do d) pith.i.changes)
          $(changes t.changes)
        %=  $
          changes    t.changes
          d          (~(del do d) pith.i.changes)
          effective  (~(put in effective) i.changes)
        ==
    ==
  ::
  ++  initial-watch-response
    ::
    ::  current [snap life case] at a fully-qualified pax, for on-watch.
    ::
    |=  full-pax=pith
    ^-  [snap=data life=@ud case=@ud]
    =/  met=meta  (gut-meta full-pax)
    =/  snap=data  (~(dip do dat) full-pax)
    [snap life.met case.met]
  ::
  ::
  ::  effect emission
  ::
  ::  three independent channels, each gated on one meta property:
  ::    gall.met ≠ ~            => /sub/<pax> facts
  ::    grow.met                => /logs/ history facts
  ::    eyre.met ∈ {^%white ^%black}, no exceptions
  ::                            => %set-response (node-summary node)
  ::
  ::  all emission paths strip the leading ship iota of full-pax,
  ::  so subscribers and urls are ship-less.
  ::
  ++  bare-pax
    ::
    ::  drop the leading ship iota from a fully-qualified pax.
    ::
    |=  full-pax=pith
    ^-  pith
    ?>  ?=(^ full-pax)
    t.full-pax
  ::
  ++  bare-path
    ::
    ::  path rendering of full-pax minus its leading ship iota.
    ::
    |=  full-pax=pith
    ^-  path
    (pout (bare-pax full-pax))
  ::
  ++  eyre-cached
    ::
    ::  cache-safe auth? only [%white ~] and [%black ~] (no exceptions).
    ::
    |=  met=meta
    ^-  ?
    ?~  eyre.met  %.n
    ?.  ?=(~ exceptions.u.eyre.met)  %.n
    ?=(?(%white %black) kind.u.eyre.met)
  ::
  ++  eyre-url
    ::
    ::  cache url, e.g. /-/foo/22/pith.
    ::
    |=  full-pax=pith
    ^-  @t
    (rap 3 ~['/-' (spat (bare-path full-pax))])
  ::
  ++  eyre-set
    ::
    ::  low-level: send %set-response to eyre.
    ::
    |=  [url=@t entry=(unit cache-entry:eyre)]
    ^+  cor
    %-  emit
    [%pass /set-response %arvo %e %set-response url entry]
  ::
  ++  gall-channel
    ::
    ::  /sub/ and /both/ subscription effects.  always emits %oxal-snap.
    ::  an empty move signals a full-replace; otherwise incremental.
    ::  no-op if gall.met is ~.
    ::
    |=  [full-pax=pith met=meta snap=data =move]
    ^+  cor
    ?~  gall.met  cor
    =/  bp=path  (bare-path full-pax)
    =/  paths=(list path)  ~[[%sub bp] [%both bp]]
    %-  emit
    [%give %fact paths %oxal-snap !>([snap move life.met case.met])]
  ::
  ++  code-channel
    ::
    ::  /code/ and /both/ subscription effects.  emits %oxal-code.
    ::  an empty meta-move signals a full-replace; otherwise incremental.
    ::  no-op if gall.met is ~.
    ::
    |=  [full-pax=pith met=meta snap=code =meta-move]
    ^+  cor
    ?~  gall.met  cor
    =/  bp=path  (bare-path full-pax)
    =/  paths=(list path)  ~[[%code bp] [%both bp]]
    %-  emit
    [%give %fact paths %oxal-code !>([snap meta-move life.met case.met])]
  ::
  ++  grow-channel
    ::
    ::  /logs/ history effects.  no-op if grow.met is false.
    ::
    |=  [full-pax=pith met=meta snap=data =move]
    ^+  cor
    ?.  grow.met  cor
    =/  bp=path  (bare-path full-pax)
    =/  logs-path=path  [(scot %ud nuke.ax) %logs (scot %ud life.met) (scot %ud case.met) bp]
    %-  emit
    [%give %fact ~[logs-path] %oxal-snap !>([snap move life.met case.met])]
  ::
  ++  eyre-push
    ::
    ::  cache (node-summary node) as plain-text response at full-pax's url.
    ::  no-op if eyre.met is not cache-safe; evict if no leaf at full-pax.
    ::  auth in the entry is true iff %white (only self); %black is public.
    ::
    |=  [full-pax=pith met=meta nod=(unit node)]
    ^+  cor
    ?~  eyre.met  cor
    ?.  ?=(~ exceptions.u.eyre.met)  cor
    ?.  ?=(?(%white %black) kind.u.eyre.met)  cor
    =/  url=@t  (eyre-url full-pax)
    ?~  nod  (eyre-set url ~)
    =/  body=@t  (crip (node-summary u.nod))
    =/  entry=cache-entry:eyre
      :*  auth=?=(%white kind.u.eyre.met)
          :-  %payload
          (node-to-simple-payload u.nod)
      ==
    (eyre-set url `entry)
  ::
  ++  eyre-evict
    ::
    ::  unconditionally evict full-pax's cached response.
    ::
    |=  full-pax=pith
    ^+  cor
    (eyre-set (eyre-url full-pax) ~)
  ::
  ++  emit-node-effects
    ::
    ::  fan a bump out to the three channels.
    ::  an empty move signals a full-replace on the gall channel.
    ::
    |=  [full-pax=pith met=meta snap=data =move]
    ^+  cor
    ?.  effects  cor
    =.  cor  (gall-channel full-pax met snap move)
    =.  cor  (grow-channel full-pax met snap move)
    (eyre-push full-pax met (~(get do dat) full-pax))
  ::
  ++  initial-watch-response-code
    ::
    ::  current [snap life case] of code subtree at full-pax, for
    ::  on-watch of /code/ and /both/.
    ::
    |=  full-pax=pith
    ^-  [snap=code life=@ud case=@ud]
    =/  met=meta  (gut-meta full-pax)
    =/  snap=code  (~(dip ox cod) full-pax)
    [snap life.met case.met]
  ::
  ++  emit-code-at-ancestors
    ::
    ::  diff cod-before against current cod, filter by
    ::  meta-significant-change, and fan each surviving change out to
    ::  every gall-authorized ancestor (of length >= min-meta-depth),
    ::  relativizing the change pith to each ancestor.
    ::
    |=  cod-before=code
    ^+  cor
    ?.  effects  cor
    =/  before-list=(list [pith meta])  ~(tap ox cod-before)
    =/  after-list=(list [pith meta])   ~(tap ox cod)
    =/  before-map=(map pith meta)  (malt before-list)
    =/  after-map=(map pith meta)   (malt after-list)
    =/  all-piths=(set pith)
      %-  ~(uni in (silt (turn before-list head)))
      (silt (turn after-list head))
    =/  chngs=(list [pith meta-chng])
      %+  murn  ~(tap in all-piths)
      |=  p=pith
      ^-  (unit [pith meta-chng])
      =/  old=(unit meta)  (~(get by before-map) p)
      =/  new=(unit meta)  (~(get by after-map) p)
      ?.  (meta-significant-change old new)  ~
      ?~  new  `[p [%del p]]
      `[p [%ins p u.new]]
    ?~  chngs  cor
    =|  rels=(map pith meta-move)
    =.  rels
      =/  cs=(list [pith meta-chng])  chngs
      |-  ^+  rels
      ?~  cs  rels
      =/  pax=pith       -.i.cs
      =/  mc=meta-chng   +.i.cs
      =/  len=@ud        (lent pax)
      =/  depths=(list @ud)
        ?:  (lth len min-meta-depth)  ~
        (gulf min-meta-depth len)
      =.  rels
        |-  ^+  rels
        ?~  depths  rels
        =/  d=@ud       i.depths
        =/  anc=pith    (scag d pax)
        =/  anc-met=meta  (gut-meta anc)
        ?~  gall.anc-met
          $(depths t.depths)
        =/  rp=pith   (slag d pax)
        =/  rel=meta-chng
          ?-  -.mc
            %ins  mc(pith rp)
            %del  mc(pith rp)
          ==
        =/  have=meta-move  (fall (~(get by rels) anc) ~)
        =.  rels  (~(put by rels) anc (~(put in have) rel))
        $(depths t.depths)
      $(cs t.cs)
    =/  rel-list=(list [pith meta-move])  ~(tap by rels)
    |-  ^+  cor
    ?~  rel-list  cor
    =/  anc=pith       -.i.rel-list
    =/  mm=meta-move   +.i.rel-list
    =/  anc-met=meta   (gut-meta anc)
    =/  anc-snap=code  (~(dip ox cod) anc)
    =.  cor  (code-channel anc anc-met anc-snap mm)
    $(rel-list t.rel-list)
  --
--
