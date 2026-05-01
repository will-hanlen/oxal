::  /lib/vines/oxal--doctest: HTTP-triggered doctest runner
::
::    GET /oxal/doctest   loads every script in /lib/doctests, runs all
::                        of its sections against a fresh +ae engine,
::                        and pokes the oxal agent with structured per-
::                        script results — one %do-move per script,
::                        writing into /[our]/docs/<stem>/.  rendering
::                        is a separate concern (lens views).
::
::    each script becomes a subtree:
::
::      /docs/<stem>/title              [%t @]  cord
::      /docs/<stem>/pass               [%f ?]  aggregate
::      /docs/<stem>/sections/[ud+i]/kind        %prose | %unit | %full
::      /docs/<stem>/sections/[ud+i]/manx        manx+        ::  prose
::      /docs/<stem>/sections/[ud+i]/description manx+        ::  unit | full
::      /docs/<stem>/sections/[ud+i]/code        t+           ::  unit | full
::      /docs/<stem>/sections/[ud+i]/result      %pass | %fail :: unit | full
::      /docs/<stem>/sections/[ud+i]/tang        tang+        ::  unit | full
::      /docs/<stem>/sections/[ud+i]/show-file   f+           ::  full
::      /docs/<stem>/sections/[ud+i]/ops         noun+        ::  full
::      /docs/<stem>/sections/[ud+i]/file-snapshot data+      ::  full + show-file
::
/-  doctest
/+  *vineio, *zozo
/~  scripts  script:doctest  /lib/doctests
::
=<
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
=/  entries=(list [@ta script:doctest])  ~(tap by scripts)
=|  total=@ud
=|  failed=@ud
|-
::
?~  entries
  ::
  ::  every script processed; render the summary.
  ::
  ;<  ~  bind:m
    %-  send-html-payload:vio
    (summary-page total failed)
  (pure:m !>(~))
::
=/  [name=@ta script=script:doctest]  i.entries
=/  =stem  (parse-stem-name name)
=/  out  (run-script script stem our.bowl now.bowl)
=*  pass     pass.out
=*  changes  changes.out
;<  ~  bind:m
  (poke-our:vio %do-move !>(`(set chng)`changes))
%=  $
  entries  t.entries
  total    +(total)
  failed   ?:(pass failed +(failed))
==
::
::::  helpers
::
|%
::
++  parse-stem-name
  ::
  ::  decode a script filename to a pith.  hawk's convention:
  ::    a-b---c---d  ->  /a-b/c/d
  ::  i.e. triple-hyphens separate path segments.  each segment is
  ::  a single @tas, so single hyphens stay inside one segment.
  ::
  |=  txt=@ta
  ^-  pith
  %+  rash  txt
  %+  more  (jest '---')
  %+  cook
    |=  =tape
    ^-  iota
    =/  c=@tas  (crip tape)
    ?>  ((sane %tas) c)
    c
  (star ;~(less (jest '---') next))
::
++  summary-page
  ::
  |=  [total=@ud failed=@ud]
  ^-  manx
  =/  passed=@ud  (sub total failed)
  ;html
    ;head
      ;meta(charset "UTF-8");
      ;title: doctests
      ;link(rel "icon", href "data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\"/>");
    ==
    ;body.p4.mono
      ;h1: doctests
      ;p
        ;-  "{(a-co:co passed)} of {(a-co:co total)} passed"
      ==
      ;p
        ;a(href "/oxal"): browse oxal
      ==
    ==
  ==
::
++  run-script
  ::
  ::  run one script: thread an acer through every section, collect
  ::  the per-section change sets into a single set.  the aggregate
  ::  pass flag is && of every section's pass.
  ::
  |=  [=script:doctest =stem our=@p now=@da]
  ^-  [pass=? changes=(set chng)]
  =/  base=pith  (welp /docs stem)
  =|  acc=(set chng)
  =.  acc  (~(put in acc) [%ins (welp base /title) [%t title.script]])
  =|  i=@ud
  =/  pass=?  &
  =|  ax=acer
  =/  steps=(list section:doctest)  steps.script
  |-
  ?~  steps
    =.  acc  (~(put in acc) [%ins (welp base /pass) [%f pass]])
    [pass acc]
  =/  section-base=pith  (welp base ~[%sections [%ud i]])
  =^  out=[section-pass=? section-changes=(set chng)]
      ax
    (run-section i.steps section-base ax our now)
  $(steps t.steps, i +(i), pass &(pass section-pass.out), acc (~(uni in acc) section-changes.out))
::
++  run-section
  ::
  |=  [=section:doctest base=pith ax=acer our=@p now=@da]
  ^-  [[pass=? changes=(set chng)] _ax]
  ?-  -.section
    %prose
      :_  ax
      :-  &
      %-  silt
      ^-  (list chng)
      :~  [%ins (welp base /kind) %prose]
          [%ins (welp base /manx) [%manx +.section]]
      ==
    ::
    %unit
      :_  ax
      (run-unit +.section base)
    ::
    %full
      (run-full +.section base ax our now)
  ==
::
++  run-unit
  ::
  ::  compile and evaluate a unit-test's code.  result tang is
  ::  always written (possibly empty); pass = empty tang.
  ::
  |=  [ut=unit-test:doctest base=pith]
  ^-  [pass=? changes=(set chng)]
  =/  res=(each vase tang)
    %-  mule  |.
    (slap !>(.) (ream code.ut))
  =/  =tang
    ?:  ?=(%.n -.res)  p.res
    ::  the slap result must be a tang.  if it is a vase whose type
    ::  doesn't fit, !< crashes; we fall back to the crash trace.
    ::
    =/  rus=(each tang tang)
      %-  mule  |.
      ^-  tang
      !<  tang  p.res
    ?:  ?=(%.n -.rus)  p.rus
    p.rus
  =/  pass=?  =(~ tang)
  :-  pass
  %-  silt
  ^-  (list chng)
  :~  [%ins (welp base /kind) %unit]
      [%ins (welp base /description) [%manx description.ut]]
      [%ins (welp base /code) [%t code.ut]]
      [%ins (welp base /result) ?:(pass %pass %fail)]
      [%ins (welp base /tang) [%tang tang]]
  ==
::
++  run-full
  ::
  ::  run a full-test: thread ops through a fresh +ae engine, then
  ::  evaluate the acer-test gate against the resulting acer.  any
  ::  crash inside ops or the gate becomes a fail with the crash
  ::  trace as the section's tang.  on crash, the outer acer is
  ::  preserved (ops were aborted, not committed).
  ::
  |=  [ft=full-test:doctest base=pith ax=acer our=@p now=@da]
  ^-  [[pass=? changes=(set chng)] _ax]
  =/  result=(each [acer tang] tang)
    %-  mule  |.
    =/  ax-after  (run-ops ops.ft ax our now)
    =/  vas=vase  (slap !>(.) (ream code.ft))
    =/  gut=(each acer-test:doctest tang)
      %-  mule  |.
      !<  acer-test:doctest  vas
    ?:  ?=(%.n -.gut)  [ax-after p.gut]
    [ax-after (p.gut ax-after)]
  ?:  ?=(%.n -.result)
    :_  ax
    :-  |
    %-  silt
    ^-  (list chng)
    :~  [%ins (welp base /kind) %full]
        [%ins (welp base /description) [%manx description.ft]]
        [%ins (welp base /show-file) [%f show-file.ft]]
        [%ins (welp base /code) [%t code.ft]]
        [%ins (welp base /ops) [%noun ops.ft]]
        [%ins (welp base /result) %fail]
        [%ins (welp base /tang) [%tang p.result]]
    ==
  =/  [ax-after=acer =tang]  p.result
  =/  pass=?  =(~ tang)
  =/  base-changes=(list chng)
    ^-  (list chng)
    :~  [%ins (welp base /kind) %full]
        [%ins (welp base /description) [%manx description.ft]]
        [%ins (welp base /show-file) [%f show-file.ft]]
        [%ins (welp base /code) [%t code.ft]]
        [%ins (welp base /ops) [%noun ops.ft]]
        [%ins (welp base /result) ?:(pass %pass %fail)]
        [%ins (welp base /tang) [%tang tang]]
    ==
  =?  base-changes  show-file.ft
    %+  weld  base-changes
    ^-  (list chng)
    :~  [%ins (welp base /file-snapshot) [%data data.file.ax-after]]
    ==
  :_  ax-after
  :-  pass
  (silt base-changes)
::
++  run-ops
  ::
  ::  thread a sequence of ingress ops through a fresh +ae engine.
  ::  effects (the cards list) are discarded — tests inspect acer only.
  ::  any crash inside an op propagates up to the +mule wrapper in
  ::  +run-full, where it is captured as the section's tang.
  ::
  |=  [ops=(list ingress-op:doctest) ax=acer our=@p now=@da]
  ^-  acer
  ?~  ops  ax
  =/  engine  ~(. ae ax our now | |)
  =/  new-ax=acer
    ?-  -.i.ops
      %do-move
        +:abet:(ingress-do-move:engine [`move`[*hlc changes.i.ops] |])
      ::
      %install-app
        +:abet:(ingress-install-app:engine name.i.ops source.i.ops)
      ::
      %uninstall-app
        +:abet:(ingress-uninstall-app:engine name.i.ops)
      ::
      %update-app
        +:abet:(ingress-update-app:engine name.i.ops source.i.ops)
      ::
      %bump
        +:abet:(ingress-bump:engine pax.i.ops)
      ::
      %set-grow
        +:abet:(ingress-set-grow:engine pax.i.ops val.i.ops)
      ::
      %set-eyre
        +:abet:(ingress-set-eyre:engine pax.i.ops val.i.ops)
      ::
      %set-gall
        +:abet:(ingress-set-gall:engine pax.i.ops val.i.ops)
      ::
      %hear-remote
        =/  args=[ship=ship pax=pith snap=data move=move life=life case=case]
          [ship.i.ops pax.i.ops snap.i.ops move.i.ops life.i.ops case.i.ops]
        +:abet:(ingress-hear-remote:engine args)
      ::
      %hear-remote-code
        =/  args=[ship=ship pax=pith snap=code move=meta-move life=life case=case]
          [ship.i.ops pax.i.ops snap.i.ops meta-move.i.ops life.i.ops case.i.ops]
        +:abet:(ingress-hear-remote-code:engine args)
    ==
  $(ops t.ops, ax new-ax)
::
--
