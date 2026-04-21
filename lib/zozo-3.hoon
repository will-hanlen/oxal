::  three: common patterns (oxal-redux)
::
/+  *zozo-2
|%
++  zozo  %400
::
+$  bump
  ::
  ::  a node-state bump that drives effect emission.
  ::    %case: case on this pith incremented; move is the change relative to it.
  ::    %life: life on this pith incremented; state reset.
  ::
  $%  [%case =move]
      [%life ~]
  ==
::
++  ae
  :::
  ::    acer engine
  ::
  =|  cards=(list card:agent:gall)
  |_  [ax=acer our=ship verb=? effects=?]
  +*  fil  file.ax
      dat  data.fil
      cod  code.fil
  ::
  ++  cor   .
  ++  abet  [(flop cards) ax]
  ++  emit  |=  =card:agent:gall  cor(cards [card cards])
  ++  emil  |=  cs=(list card:agent:gall)  cor(cards (welp (flop cs) cards))
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
  ++  beneath-view
    ::
    ::  is pax beneath an existing view?
    ::
    |=  [pax=pith c=code]
    ^-  ?
    ?=(^ (~(abo ox c) pax |=(m=_c &(?=(^ leaf.m) ?=(^ view.u.leaf.m)))))
  ::
  ++  at-or-beneath-view
    ::
    ::  does pax itself have a view, or is pax beneath an existing view?
    ::
    |=  [pax=pith c=code]
    ^-  ?
    =/  met=meta  (fall (~(get ox c) pax) *meta)
    ?:  ?=(^ view.met)  %.y
    (beneath-view pax c)
  ::
  ++  suspend-view
    ::
    ::  unsub from faucet and store error on view
    ::
    |=  [pax=pith =source met=meta =tang]
    ^+  cor
    =.  cor  (vlog "ae: suspend view at {(pate pax)}")
    =.  cor  (faucet-unsub pax dep.source)
    =.  cod  (~(put ox cod) pax met(view `source(err tang)))
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
    ::  resolve source.code to the @t cord to compile.
    ::    - atom: use as-is
    ::    - [%link pith]: fetch leaf from local data; on miss or
    ::      wrong shape, fall back to a crashing-gate cord so the
    ::      view suspends via run-xfm's mule on first invocation.
    ::
    |=  =source
    ^-  @t
    ?@  code.source  code.source
    =/  link-pax=pith  (ref-to-pith source-ref.code.source)
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
      (emit-node-effects full new-met snap [%life ~])
    $(subs t.subs)
  ::
  ++  faucet-unsub
    ::
    ::  remove full-pax from a faucet's subscriber set.
    ::  the faucet may live on any ship's subtree.
    ::
    |=  [full-pax=pith dep=source-ref]
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
    ::  if source.code is a [%link source-ref], call link-unsub; else no-op.
    ::
    |=  [full-pax=pith =source]
    ^+  cor
    ?@  code.source  cor
    (link-unsub full-pax (ref-to-pith source-ref.code.source))
  ::
  ++  ingress-do-move
    ::
    ::  user-facing move: chng piths are bare, relative to /[our].
    ::  qualify them and dispatch to apply-move-qualified.
    ::
    |=  [=move allow-view-write=?]
    ^+  cor
    =.  cor  (vlog "ae: do-move ({(scow %ud ~(wyt in move))} changes)")
    (apply-move-qualified (prefix-move [p+our ~] move) allow-view-write)
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
    (propagate d cod effective)
  ::
  ++  reinstall-links
    ::
    ::  for each effective change, look up view-subs on the meta
    ::  at the change's pith; re-install every view in that set
    ::  using its currently stored source.  a re-install re-resolves
    ::  the link and either rebuilds cleanly or suspends with
    ::  %no-pith via the fallback gate.
    ::
    |=  effective=(set chng)
    ^+  cor
    =/  chs=(list chng)  ~(tap in effective)
    |-  ^+  cor
    ?~  chs  cor
    =/  p=pith  (pith-of-chng i.chs)
    =/  met=meta  (gut-meta p)
    =/  vs=(set pith)  view-subs.met
    ?~  vs  $(chs t.chs)
    =/  views=(list pith)  ~(tap in `(set pith)`vs)
    =.  cor
      |-  ^+  cor
      ?~  views  cor
      =/  vmet=meta  (gut-meta i.views)
      ?~  view.vmet  $(views t.views)
      ::  view paxes in view-subs are fully qualified with [%p our];
      ::  install re-qualifies internally, so strip the head iota.
      ::
      =/  bare-pax=pith  ?>(?=(^ i.views) t.i.views)
      =.  cor  (ingress-install bare-pax code.u.view.vmet dep.u.view.vmet)
      $(views t.views)
    $(chs t.chs)
  ::
  ++  reinstall-subs
    ::
    ::  re-install every view in pax's subs set using its currently
    ::  stored source.  used on reinstall / life-bump to force local
    ::  subscribers to rebuild from the fresh snap with an empty move.
    ::
    |=  pax=pith
    ^+  cor
    =/  met=meta  (gut-meta pax)
    =/  subs-list=(list pith)  ~(tap in subs.met)
    |-  ^+  cor
    ?~  subs-list  cor
    =/  smet=meta  (gut-meta i.subs-list)
    ?~  view.smet  $(subs-list t.subs-list)
    ::  sub paxes are fully qualified with [%p our]; strip head iota
    ::  since ingress-install re-qualifies internally.
    ::
    =/  bare-pax=pith  ?>(?=(^ i.subs-list) t.i.subs-list)
    =.  cor  (ingress-install bare-pax code.u.view.smet dep.u.view.smet)
    $(subs-list t.subs-list)
  ::
  ++  apply-changes
    ::
    ::  apply each change to data, filtering to effective ones.
    ::  skip changes at or beneath a view unless allow-view-write.
    ::
    |=  [=move allow-view-write=?]
    ^-  [data (set chng)]
    =/  d=data  dat
    =/  c=code  cod
    =/  is-at-or-beneath-view=$-([pith code] ?)  at-or-beneath-view
    =/  effective=(set chng)  ~
    =/  changes=(list chng)  ~(tap in move)
    |-
    ?~  changes  [d effective]
    =/  p=pith  (pith-of-chng i.changes)
    ?:  ?&(!allow-view-write (is-at-or-beneath-view p c))
      ~|  "fe: rejected write at or beneath view at {(pate p)}"
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
    |=  [d=data c=code effective=(set chng)]
    ^+  cor
    ::  commit data/code up front so transformer-produced changes
    ::  see the current state.
    ::
    =.  cor  cor(data.file.ax d, code.file.ax c)
    =/  rels=(map pith (set chng))  (build-rels effective)
    =/  queue=(list pith)  (sort-piths-desc ~(key by rels))
    =|  processed=(set pith)
    =/  combined=(set chng)  effective
    (propagate-loop queue rels processed combined)
  ::
  ++  propagate-loop
    ::
    ::  one iteration of the merge-walk.
    ::
    |=  $:  queue=(list pith)
            rels=(map pith (set chng))
            processed=(set pith)
            combined=(set chng)
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
    =/  new-met=meta
      %=  met
        case  +(case.met)
        logs  (snoc logs.met [rel])
      ==
    ::  bump case and append this walk's rel to logs
    ::
    =.  cor
      %-  vlog
      "ae: propagate at {(pate anc)} life={(scow %ud life.new-met)} case={(scow %ud case.new-met)}"
    =.  cod  (~(put ox cod) anc new-met)
    =/  snap=data  (~(dip do dat) anc)
    ::  fan this bump out to gall/grow/eyre channels
    ::
    =.  cor  (emit-node-effects anc new-met snap [%case rel])
    ::  fire subscribers of this ancestor, collecting their outputs
    ::
    =^  xfm-out=move  cor
      (fire-subs-collect new-met snap rel life.new-met case.new-met)
    ?:  =(~ xfm-out)
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
    ::  via apply-move-qualified to avoid double-prefixing.
    ::
    |=  [sub=pith =source met=meta snap=data mov=(set chng) lyf=@ud cas=@ud]
    ^+  cor
    =.  cor  (vlog "ae: run-xfm at {(pate sub)}")
    =^  xfm-res=(each transformer tang)  cor  (get-xfm (resolve-code source))
    ?:  ?=(%| -.xfm-res)
      (suspend-view sub source met p.xfm-res)
    =/  xfm=transformer  p.xfm-res
    =/  mine=data  (~(dip do dat) sub)
    =/  result=(each move tang)
      (mule |.((xfm [mine snap mov lyf cas])))
    ?-  -.result
      %&
        =.  cod
          (~(put ox cod) sub met(view `source(lyf lyf, cas cas)))
        (apply-move-qualified [(prefix-move sub p.result) %.y])
      ::
      %|
        (suspend-view sub source met p.result)
    ==
  ::
  ++  ingress-install
    ::
    ::  install a view: store source in code tree, wipe data subtree.
    ::  pax is user-facing (bare, relative to /[our]); qualify it.
    ::  caller supplies only code and dep; lyf/cas/err default to
    ::  initial values (run-xfm overwrites lyf/cas on first fire).
    ::
    |=  [pax=pith code=source-code dep=source-ref]
    ^+  cor
    =/  =source  [code dep lyf=0 cas=0 err=~]
    =/  full-pax  (under-our pax)
    =/  full-dep  (ref-to-pith dep.source)
    =.  cor  (vlog "ae: install at {(pate full-pax)}")
    ?.  (meta-allowed full-pax)  (reject-shallow "install" full-pax)
    ::  reject install beneath an existing view
    ::
    ?:  (beneath-view full-pax cod)
      %-  (slog leaf+"fe: rejected install at or beneath view at {(pate full-pax)}" ~)
      cor
    ::  reject install whose faucet is the view itself or an ancestor
    ::  of it: the view's output would flow back into its own input.
    ::
    ?:  (~(is-ancestor-or-same th full-pax) full-dep)
      %-  %+  slog  leaf+"fe: rejected install at {(pate full-pax)}: faucet {(pate full-dep)} is self or ancestor"
          ~
      cor
    =/  old  (~(get ox cod) full-pax)
    ::  if re-installing, run uninstall cleanup first
    ::
    =?  cor  &(?=(^ old) ?=(^ view.u.old))
      =.  cor  (faucet-unsub full-pax dep.u.view.u.old)
      (maybe-link-unsub full-pax u.view.u.old)
    =/  met=meta
      %*  .  *meta
        life       ?~  old  0
                   ?:  grow.u.old  +(life.u.old)
                   life.u.old
        view       `source
        subs       ?~(old ~ subs.u.old)
        view-subs  ?~(old ~ view-subs.u.old)
        grow       ?~(old %.n grow.u.old)
        eyre       ?~(old ~ eyre.u.old)
        gall       ?~(old ~ gall.u.old)
      ==
    =.  cod  (~(put ox cod) full-pax met)
    =.  dat  (~(lop do dat) full-pax)
    ::  on reinstall, fire life-bump effects on the root.  life on
    ::  root may or may not have bumped depending on grow.
    ::
    =?  cor  ?=(^ old)
      =/  snap=data  (~(dip do dat) full-pax)
      (emit-node-effects full-pax met snap [%life ~])
    ::  on grow children, increment life; reset case for all submetas
    ::
    =.  cor  (reset-submetas full-pax %.y)
    ::  populate faucet subs with this view's path
    ::
    =/  faucet-met=meta  (gut-meta full-dep)
    =.  cod
      %+  ~(put ox cod)  full-dep
      faucet-met(subs (~(put in subs.faucet-met) full-pax))
    ::  populate link subs if source uses %link
    ::
    =?  cor  ?=([%link *] code.source)
      (link-sub full-pax (ref-to-pith source-ref.code.source))
    =.  cor  (initialize-from-snap full-pax source faucet-met)
    ::  on reinstall, force local subs to rebuild from fresh snap
    ::  (empty move); new installs have no prior subs to notify.
    ::
    ?~  old  cor
    (reinstall-subs full-pax)
  ::
  ++  ingress-set-grow
    ::
    ::  set grow flag on meta at pax, creating meta if missing.
    ::  pax is user-facing (qualified with /[our]).
    ::  on false->true flip, publish current /life/ and /snap/ state.
    ::
    |=  [pax=pith val=?]
    ^+  cor
    ?>  effects
    =/  full-pax  (under-our pax)
    =.  cor  (vlog "ae: set-grow at {(pate full-pax)} = {?:(val "y" "n")}")
    ?.  (meta-allowed full-pax)  (reject-shallow "set-grow" full-pax)
    =/  met=meta  (gut-meta full-pax)
    =/  new-met=meta  met(grow val)
    =.  cod  (~(put ox cod) full-pax new-met)
    ?.  &(val !grow.met)  cor
    =/  snap=data  (~(dip do dat) full-pax)
    (grow-flip-on full-pax new-met snap)
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
    =/  met=meta  (gut-meta full-pax)
    =/  new-met=meta  met(eyre val)
    =.  cod  (~(put ox cod) full-pax new-met)
    ?:  (eyre-cached new-met)
      (eyre-push full-pax new-met (~(get do dat) full-pax))
    ?:  (eyre-cached met)
      (eyre-evict full-pax)
    cor
  ::
  ++  ingress-set-gall
    ::
    ::  set gall auth on meta at pax, creating meta if missing.
    ::  pax is user-facing (qualified with /[our]).
    ::  on flip-off, kick existing /sub/ subscribers (their subscription
    ::  is no longer valid).  on flip-on, nothing to push: subscribers
    ::  will arrive via on-watch and get initial state there.
    ::
    |=  [pax=pith val=(unit auth)]
    ^+  cor
    ?>  effects
    =/  full-pax  (under-our pax)
    =.  cor  (vlog "ae: set-gall at {(pate full-pax)}")
    ?.  (meta-allowed full-pax)  (reject-shallow "set-gall" full-pax)
    =/  met=meta  (gut-meta full-pax)
    =.  cod  (~(put ox cod) full-pax met(gall val))
    ?.  &(?=(^ gall.met) ?=(~ val))  cor
    %-  emit
    [%give %kick ~[[%sub (bare-path full-pax)]] ~]
  ::
  ++  ingress-uninstall
    ::
    ::  remove a view: clear view from meta, preserve data.
    ::  pax is user-facing (qualified with /[our]).
    ::
    |=  pax=pith
    ^+  cor
    =/  full-pax  (under-our pax)
    =.  cor  (vlog "ae: uninstall at {(pate full-pax)}")
    ?.  (meta-allowed full-pax)  (reject-shallow "uninstall" full-pax)
    =/  met=meta  (gut-meta full-pax)
    ::  remove from faucet subs if this was a view
    ::
    =?  cor  ?=(^ view.met)
      =.  cor  (faucet-unsub full-pax dep.u.view.met)
      (maybe-link-unsub full-pax u.view.met)
    =.  cod  (~(put ox cod) full-pax met(view ~))
    cor
  ::
  ++  initialize-from-snap
    ::
    ::  run the transformer once with the faucet's current snap and
    ::  an empty move, signaling "reconstruct state from snap".
    ::  full-pax is qualified.
    ::
    |=  [full-pax=pith =source faucet-met=meta]
    ^+  cor
    =/  met=meta  (gut-meta full-pax)
    ?.  ?=(^ view.met)  cor
    ?:  ?=(^ err.u.view.met)  cor
    =/  snap=data  (~(dip do dat) (ref-to-pith dep.source))
    %:  run-xfm
      full-pax  source  met  snap  ~
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
    =/  met=meta  (gut-meta full-pax)
    =?  cor  |((gth life life.met) =(~ move))
      =.  dat  (~(rep do dat) full-pax snap)
      =.  cod
        %+  ~(put ox cod)  full-pax
        met(life life, case case, logs ~)
      =.  cor  (reset-submetas full-pax %.y)
      =/  new-met=meta  (gut-meta full-pax)
      =/  snp=data  (~(dip do dat) full-pax)
      =.  cor  (emit-node-effects full-pax new-met snp [%life ~])
      (reinstall-subs full-pax)
    (apply-move-qualified (prefix-move [p+ship ~] move) %.y)
  ::
  ++  ingress-bump
    ::
    ::  wipe data subtree, increment lifes, reset cases and logs.
    ::  crashes if any views exist at or below pax.
    ::  pax is user-facing (qualified with /[our]).
    ::
    |=  pax=pith
    ^+  cor
    =/  full-pax  (under-our pax)
    =.  cor  (vlog "ae: bump at {(pate full-pax)}")
    ?.  (meta-allowed full-pax)  (reject-shallow "bump" full-pax)
    ::  check no ancestor of full-pax has a view
    ::
    ~|  %cannot-bump-an-installed-view
    ?<  ?=(^ (~(anc ox cod) full-pax |=(m=_cod ?&(?=(^ leaf.m) ?=(^ view.u.leaf.m)))))
    ::  check no node at or below full-pax has a view
    ::
    =/  subs=(list (pair pith meta))
      ~(tap ox (~(dip ox cod) full-pax))
    |-  ^+  cor
    ?~  subs
      =.  dat  (~(lop do dat) full-pax)
      (reset-submetas full-pax %.n)
    ?<  ?=(^ view.q.i.subs)
    $(subs t.subs)
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
    ::  absent views are skipped.
    ::
    |=  [met=meta snap=data mov=(set chng) lyf=@ud cas=@ud]
    ^-  [move _cor]
    =/  sub-list=(list pith)  ~(tap in subs.met)
    =|  out=move
    |-  ^+  [out cor]
    ?~  sub-list  [out cor]
    =/  sub=pith  i.sub-list
    =/  sub-met=meta  (gut-meta sub)
    ?~  view.sub-met  $(sub-list t.sub-list)
    =/  =source  u.view.sub-met
    ?:  ?=(^ err.source)  $(sub-list t.sub-list)
    =^  maybe-out=(unit move)  cor
      (run-xfm-collect sub source sub-met snap mov lyf cas)
    =?  out  ?=(^ maybe-out)  (~(uni in out) u.maybe-out)
    $(sub-list t.sub-list)
  ::
  ++  run-xfm-collect
    ::
    ::  run a subscriber's transformer.  on success, update the view
    ::  meta and return the prefixed output move.  on crash, suspend
    ::  the view and return ~.
    ::
    |=  [sub=pith =source met=meta snap=data mov=(set chng) lyf=@ud cas=@ud]
    ^-  [(unit move) _cor]
    =.  cor  (vlog "ae: fire xfm at {(pate sub)}")
    =^  xfm-res=(each transformer tang)  cor  (get-xfm (resolve-code source))
    ?:  ?=(%| -.xfm-res)
      [~ (suspend-view sub source met p.xfm-res)]
    =/  xfm=transformer  p.xfm-res
    =/  mine=data  (~(dip do dat) sub)
    =/  result=(each move tang)
      (mule |.((xfm [mine snap mov lyf cas])))
    ?-  -.result
      %&
        =.  cod
          (~(put ox cod) sub met(view `source(lyf lyf, cas cas)))
        [`(prefix-move sub p.result) cor]
      ::
      %|
        [~ (suspend-view sub source met p.result)]
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
    =/  changes=(list chng)  ~(tap in mv)
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
  ::    gall.met ≠ ~            => /sub/<pax> facts and kicks
  ::    grow.met                => /life/, /snap/, /logs/ history facts
  ::    eyre.met ∈ {^%white ^%black}, no exceptions
  ::                            => %set-response (print-node node)
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
    ::  /sub/ subscription effects.  case: %fact.  life: %kick.
    ::  no-op if gall.met is ~.
    ::
    |=  [full-pax=pith met=meta =bump]
    ^+  cor
    ?~  gall.met  cor
    =/  sub-path=path  [%sub (bare-path full-pax)]
    ?-    bump
        [%life ~]
      %-  emit
      [%give %kick ~[sub-path] ~]
    ::
        [%case *]
      %-  emit
      [%give %fact ~[sub-path] %oxal-move !>([move.bump life.met case.met])]
    ==
  ::
  ++  grow-channel
    ::
    ::  /life/, /snap/, /logs/ history effects.  no-op if grow.met is false.
    ::
    |=  [full-pax=pith met=meta snap=data =bump]
    ^+  cor
    ?.  grow.met  cor
    =/  bp=path  (bare-path full-pax)
    ?-    bump
        [%case *]
      =/  snap-path=path  [(scot %ud nuke.ax) %snap (scot %ud life.met) (scot %ud case.met) bp]
      =/  logs-path=path  [(scot %ud nuke.ax) %logs (scot %ud life.met) (scot %ud case.met) bp]
      =.  cor
        %-  emit
        [%give %fact ~[snap-path] %oxal-data !>(snap)]
      %-  emit
      [%give %fact ~[logs-path] %oxal-move !>([move.bump life.met case.met])]
    ::
        [%life ~]
      =/  life-path=path  [(scot %ud nuke.ax) %life bp]
      =/  snap-path=path  [(scot %ud nuke.ax) %snap (scot %ud life.met) '0' bp]
      =.  cor
        %-  emit
        [%give %fact ~[life-path] %oxal-life !>(life.met)]
      %-  emit
      [%give %fact ~[snap-path] %oxal-data !>(snap)]
    ==
  ::
  ++  grow-flip-on
    ::
    ::  grow.met just flipped %.n -> %.y; neither life nor case bumped.
    ::  publish current state on /life/ and /snap/<life>/<case>/ so
    ::  fresh history subscribers have a coherent starting point.
    ::
    |=  [full-pax=pith met=meta snap=data]
    ^+  cor
    =/  bp=path  (bare-path full-pax)
    =/  life-path=path  [(scot %ud nuke.ax) %life bp]
    =/  snap-path=path  [(scot %ud nuke.ax) %snap (scot %ud life.met) (scot %ud case.met) bp]
    =.  cor
      %-  emit
      [%give %fact ~[life-path] %oxal-life !>(life.met)]
    %-  emit
    [%give %fact ~[snap-path] %oxal-data !>(snap)]
  ::
  ++  eyre-push
    ::
    ::  cache (print-node node) as plain-text response at full-pax's url.
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
    =/  body=@t  (crip (print-node u.nod))
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
    ::
    |=  [full-pax=pith met=meta snap=data =bump]
    ^+  cor
    ?.  effects  cor
    =.  cor  (gall-channel full-pax met bump)
    =.  cor  (grow-channel full-pax met snap bump)
    (eyre-push full-pax met (~(get do dat) full-pax))
  --
--
