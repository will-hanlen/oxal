::  /ted/http-oxal--gall--sky  :  render sky.bowl filtered by rest.bowl
::
/+  *vineio, *zozo
::
=<
::
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
=/  entries=(list [=path =fans:gall])
  %+  sort
    %+  murn  ~(tap by sky.bowl)
    |=  [pax=path =fans:gall]
    ^-  (unit [path fans:gall])
    ?.  =((scag (lent rest.bowl) pax) rest.bowl)  ~
    `[pax fans]
  |=  [a=[p=path *] b=[p=path *]]
  (aor (spat p.a) (spat p.b))
::
=/  filter-label=tape
  ?~  rest.bowl  "all"
  (spud rest.bowl)
::
=/  hymn=manx
  ::
  ;feather.p5.fc.g5.pb15(title "oxal sky")
    ;h1: sky
    ;div.fr.g3.f4.o6
      ;span
        ;-  "{(scow %ud (lent entries))} binding"
        ;-  ?:(=(1 (lent entries)) "" "s")
      ==
      ;span: under
      ;span.mono.bold: {filter-label}
    ==
    ;div.fc.g3
      ;*
      =;  =marl  ?^  marl  marl
        ;=
          ;div.p3.bd1.br2.o6
            ;-  ?~  rest.bowl  "no bindings"
                "no bindings under {(spud rest.bowl)}"
          ==
        ==
      %+  turn  entries
      |=  [=path =fans:gall]
      (render-binding path fans)
    ==
  ==
::
;<  ~  bind:m
  %-  send-simple-payload:vio
  %+  node-to-simple-payload  %manx
  hymn
(pure:m !>(~))
::
|%
++  render-binding
  ::
  |=  [=path =fans:gall]
  ^-  manx
  =/  revs=(list [rev=@ud dat=(pair @da (each page @uvI))])
    (tap:((on @ud (pair @da (each page @uvI))) lte) fans)
  ;details.br2.bd1
    ;summary.p2.b2.fr.g3
      ;span.bold.mono: {(spud path)}
      ;span.grow;
      ;span.o6
        ;-  "#"
        ;-  (scow %ud (lent revs))
      ==
    ==
    ;table.p2.f4
      ;thead
        ;tr
          ;th.tl.pr3: rev
          ;th.tl.pr3: time
          ;th.tl.pr3: kind
          ;th.tl: summary
        ==
      ==
      ;tbody
        ;*
        %+  turn  revs
        |=  [rev=@ud dat=(pair @da (each page @uvI))]
        (render-rev-row rev dat)
      ==
    ==
  ==
::
++  render-rev-row
  ::
  |=  [rev=@ud dat=(pair @da (each page @uvI))]
  ^-  manx
  ;tr
    ;td.pr3.mono: {(scow %ud rev)}
    ;td.pr3.mono.o6: {(scow %da p.dat)}
    ;td.pr3.mono
      ;+  (render-kind q.dat)
    ==
    ;td.mono.o6
      ;-
        ?:  ?=(%.n -.q.dat)  ""
        (render-summary p.q.dat)
    ==
  ==
::
++  render-kind
  ::
  |=  kind=(each page @uvI)
  ^-  manx
  ?-  -.kind
    %.y
      ;span.bold: {(weld "%" (trip p.p.kind))}
    ::
    %.n
      ;span
        ;span.f-1.bold.mr2: TOMB
        ;span.o6: {(scow %uv p.kind)}
      ==
  ==
::
++  render-summary
  ::
  |=  =page
  ^-  tape
  =/  res=(each tape tang)
    %-  mule  |.
    ?+  p.page  ""
      ::
      %oxal-life
        =/  lyf=@ud  ;;(@ud q.page)
        "life={(scow %ud lyf)}"
      ::
      %oxal-data
        =/  dat=data  ;;(data q.page)
        =/  n=@ud  ~(wyt do dat)
        =/  leaf-str=tape
          ?~  leaf.dat  ""
          (weld " leaf=" (print-aura u.leaf.dat))
        "nodes={(scow %ud n)}{leaf-str}"
      ::
      %oxal-move
        =/  mov=move  ;;(move q.page)
        =/  n=@ud  ~(wyt in mov)
        "chng={(scow %ud n)}"
    ==
  ?-  -.res
    %.y  p.res
    %.n  ""
  ==
--
