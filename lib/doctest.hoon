::  /lib/doctest: pure runner and oxal-data conversion for doctests
::
::    +run-script        : evaluate one $script, return a $report
::    +parse-stem-name   : decode a filename like a-b---c to a pith
::    +report-to-changes : project a $report under a base pith into a
::                         (set chng) ready for %do-move
::    +report-to-data    : project a $report into a single $data tree,
::                         suitable as the body of a [%data ...] node
::
::    the runner has no dependence on the oxal agent or its data
::    tree.  callers that want results in oxal call +report-to-changes
::    and poke %do-move.
::
/-  *doctest
/+  *zozo
|%
::
++  parse-stem-name
  ::
  ::  decode a script filename to a pith.  triple-hyphens separate
  ::  path segments: a-b---c-d  ->  /a-b/c-d.  each segment becomes a
  ::  single @tas, so single hyphens stay inside one segment.
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
++  run-script
  ::
  ::  run every section in input order, threading an isolated +ae
  ::  acer through %full sections.  the aggregate pass flag is && of
  ::  every section's pass.
  ::
  |=  [=script our=@p now=@da]
  ^-  report
  =|  acc=(list section-result)
  =/  pass=?  &
  =|  ax=acer
  =/  steps=(list section)  steps.script
  |-
  ?~  steps
    [title.script pass (flop acc)]
  =^  out=section-result  ax  (run-section i.steps ax our now)
  =/  sect-pass=?
    ?-  -.out
      %prose  &
      %unit   pass.unit-result.out
      %full   pass.full-result.out
    ==
  $(steps t.steps, pass &(pass sect-pass), acc [out acc])
::
++  run-section
  ::
  |=  [=section ax=acer our=@p now=@da]
  ^-  [section-result _ax]
  ?-  -.section
    %prose  [section ax]
    %unit   [unit+(run-unit unit-test.section) ax]
    %full   (run-full full-test.section ax our now)
  ==
::
++  run-unit
  ::
  ::  compile and evaluate a unit-test's code.  result tang is
  ::  always present (possibly empty); pass = empty tang.
  ::
  |=  ut=unit-test
  ^-  unit-result
  =/  res=(each vase tang)
    %-  mule  |.
    (slap !>(.) (ream code.ut))
  =/  =tang
    ?:  ?=(%.n -.res)  p.res
    =/  rus=(each tang tang)
      %-  mule  |.
      !<  tang  p.res
    ?:  ?=(%.n -.rus)  p.rus
    p.rus
  =/  pass=?  =(~ tang)
  [description.ut code.ut pass tang]
::
++  run-full
  ::
  ::  thread ops through a fresh +ae engine, then evaluate the
  ::  acer-test gate against the resulting acer.  any crash inside
  ::  ops or the gate becomes a fail with the crash trace as tang.
  ::  on crash, the outer acer is preserved (ops were aborted).
  ::
  |=  [ft=full-test ax=acer our=@p now=@da]
  ^-  [section-result _ax]
  =/  result=(each [acer tang] tang)
    %-  mule  |.
    =/  ax-after  (run-ops ops.ft ax our now)
    =/  vas=vase  (slap !>(.) (ream code.ft))
    =/  gut=(each acer-test tang)
      %-  mule  |.
      !<  acer-test  vas
    ?:  ?=(%.n -.gut)  [ax-after p.gut]
    [ax-after (p.gut ax-after)]
  ?:  ?=(%.n -.result)
    :_  ax
    :-  %full
    :*  description.ft  show-file.ft  ops.ft  code.ft  |
        p.result  ~
    ==
  =/  [ax-after=acer =tang]  p.result
  =/  pass=?  =(~ tang)
  =/  snap=(unit data)  ?:(show-file.ft `data.file.ax-after ~)
  :_  ax-after
  :-  %full
  :*  description.ft  show-file.ft  ops.ft  code.ft  pass
      tang  snap
  ==
::
++  run-ops
  ::
  ::  thread a sequence of ingress ops through a fresh +ae engine.
  ::  effects are discarded — tests inspect acer only.  any crash
  ::  inside an op propagates up to the +mule wrapper in run-full,
  ::  where it is captured as the section's tang.
  ::
  |=  [ops=(list ingress-op) ax=acer our=@p now=@da]
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
++  report-to-changes
  ::
  ::  project a report into a (set chng), with all piths under base.
  ::
  ::    base/title              [%t cord]
  ::    base/pass               [%f ?]
  ::    base/sections/[ud+i]/<fields>...
  ::
  ::  callers prefix to taste; the doctest vine uses base=/docs/<stem>.
  ::
  |=  [base=pith =report]
  ^-  (set chng)
  =|  acc=(set chng)
  =.  acc  (~(put in acc) [%ins (welp base /title) [%t title.report]])
  =.  acc  (~(put in acc) [%ins (welp base /pass) [%f pass.report]])
  =|  i=@ud
  =/  sects=(list section-result)  sections.report
  |-
  ?~  sects  acc
  =/  section-base=pith  (welp base ~[%sections [%ud i]])
  =.  acc  (~(uni in acc) (section-result-to-changes section-base i.sects))
  $(sects t.sects, i +(i), acc acc)
::
++  section-result-to-changes
  ::
  |=  [base=pith =section-result]
  ^-  (set chng)
  ?-  -.section-result
    %prose
      %-  silt
      ^-  (list chng)
      :~  [%ins (welp base /kind) %prose]
          [%ins (welp base /manx) [%manx +.section-result]]
      ==
    ::
    %unit
      =*  ur  unit-result.section-result
      %-  silt
      ^-  (list chng)
      :~  [%ins (welp base /kind) %unit]
          [%ins (welp base /description) [%manx description.ur]]
          [%ins (welp base /code) [%t code.ur]]
          [%ins (welp base /result) ?:(pass.ur %pass %fail)]
          [%ins (welp base /tang) [%tang tang.ur]]
      ==
    ::
    %full
      =*  fr  full-result.section-result
      =/  base-changes=(list chng)
        :~  [%ins (welp base /kind) %full]
            [%ins (welp base /description) [%manx description.fr]]
            [%ins (welp base /show-file) [%f show-file.fr]]
            [%ins (welp base /code) [%t code.fr]]
            [%ins (welp base /ops) [%noun ops.fr]]
            [%ins (welp base /result) ?:(pass.fr %pass %fail)]
            [%ins (welp base /tang) [%tang tang.fr]]
        ==
      =?  base-changes  ?=(^ file-snapshot.fr)
        %+  weld  base-changes
        ^-  (list chng)
        :~  [%ins (welp base /file-snapshot) [%data u.file-snapshot.fr]]
        ==
      (silt base-changes)
  ==
::
++  report-to-data
  ::
  ::  project a report into a single $data tree, sharing layout with
  ::  +report-to-changes.  the output is a value (not a chng set), so
  ::  callers can wrap it as a [%data ...] node and poke %do-move.
  ::
  |=  =report
  ^-  data
  =|  d=data
  =/  cl=(list chng)  ~(tap in (report-to-changes ~ report))
  |-
  ?~  cl  d
  ?>  ?=(%ins -.i.cl)
  $(cl t.cl, d (~(put do d) pith.i.cl node.i.cl))
--
