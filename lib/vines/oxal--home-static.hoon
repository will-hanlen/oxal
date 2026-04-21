::  /ted/http-oxal--home-static  :  faking reactivity with datastar and scries
::
::  a GET request returns a statically built page
::  a POST request returns a swap for that same statically built page
::
/+  *vineio
::
!:
=>  |%
    ++  body-to-cage
      ::
      ::  build a cage from a decoded form body keyed by 'op'.
      ::
      |=  [body=(map @t @t) now=@da]
      ^-  cage
      =/  op=@t  (fall (~(get by body) 'op') 'noop')
      =/  pax=pith
        =/  =cord  (~(got by body) 'pax')
        =/  try=(unit pith)
          %-  mole  |.
          (cord-to-pith cord)
        ?^  try  u.try
        !<  pith
        (slap !>(..onan) (ream cord))
      ?:  =(op 'set-grow')
        =/  val=?  =('true' (~(got by body) 'val'))
        [%set-grow !>([pax val])]
      ?:  =(op 'set-eyre')
        =/  val=(unit auth)  (parse-auth (~(got by body) 'kind'))
        [%set-eyre !>([pax val])]
      ?:  =(op 'set-gall')
        =/  val=(unit auth)  (parse-auth (~(got by body) 'kind'))
        [%set-gall !>([pax val])]
      ?:  =(op 'bump')
        [%bump !>(pax)]
      ?:  =(op 'install')
        =/  code=source-code
          =/  raw  (fix-newlines (~(got by body) 'code'))
          =/  try=(unit source-code)
            %-  mole  |.
            !<  source-code
            (slap !>(.) (ream raw))
          ?~  try  raw
          u.try
        =/  dep=source-ref
          :-  (slav %p (~(got by body) 'dep-ship'))
          (cord-to-pith (~(got by body) 'dep-pith'))
        [%install !>([pax code dep])]
      ?:  =(op 'uninstall')
        [%uninstall !>(pax)]
      ?:  =(op 'del-leaf')
        =/  =move  (sy ~[[%del pax]])
        [%do-move !>(move)]
      ?:  =(op 'put-leaf')
        =/  src=@t  (fix-newlines (~(got by body) 'node'))
        =/  trimmed=@t  ?:(=(src '') '~' src)
        =/  parsed=(each node tang)
          %-  mule  |.
          !<  node
          %+  slap  !>(.)
          (ream (cat 3 trimmed '\0a\0a'))
        ?:  ?=(%.y -.parsed)
          =/  =move  (sy ~[[%ins pax p.parsed]])
          [%do-move !>(move)]
        %-  (slog p.parsed)
        =/  =move  (sy ~[[%ins (snoc pax %error) da+now]])
        [%do-move !>(move)]
      ~|  bad-op+op
      !!
    ::
    ++  render-error-manx
      ::
      ::  datastar fragment that morphs into the page's #error slot.
      ::
      |=  =tang
      ^-  manx
      ;div#error.fc.g2.p3.bd1.b2.br2.f-1
        ;div.bold: poke failed
        ;button.p2.br2.bd1.b3.hover.focus
          =onclick  "window.location.reload()"
          ; refresh
        ==
        ;+  (render-tang tang)
      ==
    ::
    ++  parse-auth
      ::
      ::  parse an auth-kind selection into a (unit auth); 'none' means ~.
      ::
      |=  kind=@t
      ^-  (unit auth)
      ?:  =(kind 'none')  ~
      =;  k=auth-kind
        `[k ~]
      ?:  =(kind 'white')         %white
      ?:  =(kind 'black')         %black
      ?:  =(kind 'black-moon')    %black-moon
      ?:  =(kind 'black-planet')  %black-planet
      ?:  =(kind 'black-star')    %black-star
      ?:  =(kind 'black-galaxy')  %black-galaxy
      ~|  bad-auth-kind+kind
      !!
    --
::
=;  reng
::
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
::
?:  =('POST' method.bowl)
  =/  body  formencoded-body:vio
  =/  =cage  (body-to-cage body now.bowl)
  ;<  err=(unit tang)  bind:m  (soft-poke-our:vio cage)
  ?^  err
    %-  (slog u.err)
    ;<  ~  bind:m
      %-  send-simple-payload:vio
      :-  [200 ['content-type' 'text/html']~]
      :-  ~
      %-  as-octt:mimes:html
      %-  en-xml:html
      (render-error-manx u.err)
    (pure:m !>(~))
  ?:  .=  `'true'  (get-header:http 'datastar-request' header-list.bowl)
    ;<  =acer  bind:m  (scry ,acer /gx/oxal/acer/noun)
    ;<  ~  bind:m
      %-  send-simple-payload:vio
      :-  [200 ['content-type' 'text/html']~]
      :-  ~
      %-  as-octt:mimes:html
      %-  en-xml:html
      ~(bod reng acer bowl)
    ::
    (pure:m !>(~))
  ::
  ;<  ~  bind:m
    %+  send-simple-payload:vio
      [303 ['location' (spat (welp [prefix rest]:bowl))]~]
    ~
  (pure:m !>(~))
::
;<  =acer  bind:m  (scry ,acer /gx/oxal/acer/noun)
;<  ~  bind:m
  %-  send-simple-payload:vio
  %+  node-to-simple-payload  %manx
  ~(hymn reng acer bowl)
::
(pure:m !>(~))
::
|_  [ax=acer bowl=http-bowl]
::
++  rest-pith  ^-  pith  (pave rest.bowl)
++  scope-pax  ^-  pith  [p+our.bowl rest-pith]
++  scoped-file  ^-  file  (~(dip fe file.ax) scope-pax)
::
++  init-beneath
  ::
  ^-  ?
  =/  c=code  code.file.ax
  ?=(^ (~(abo ox c) scope-pax |=(m=_c &(?=(^ leaf.m) ?=(^ view.u.leaf.m)))))
::
++  hymn
  ::
  ;html
    ;head
      ;title: oxal
      ;meta(charset "utf-8");
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
      ;link(rel "icon", href "data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\"/>");
      ;script(type "module", src "/hawk-init/feather/1/textarea");
      ;script(type "module", src "/hawk-init/feather/1/text-editor");
      ;script(type "module", src "/hawk-init/feather/1/datastar");
    ==
    ;body.p5.fc.g4(style "padding-bottom: 80vh;")
      ;nav.fr.g2.ac
        ;a.p-2.br2.bd1.b2.hover(href (trip (spat prefix.bowl))): /
        ;*
        =<  p
        %^  spin  rest-pith  *pith
        |=  [i=iota acc=pith]
        =.  acc  (snoc acc i)
        =/  url=tape  (trip (spat (welp prefix.bowl (pout acc))))
        :_  acc
        ;a.p-2.br2.bd1.b2.hover(href url)
          ;-  (print-node-strict i)
        ==
      ==
      ;+  bod
    ==
  ==
::
++  bod
  ::
  ;div#tree
    ;div#error;
    ;details
      ;summary: create node
      ;+  (render-create-node-form rest.bowl)
    ==
    ;details
      ;summary: create view
      ;+  (render-create-view-form rest.bowl)
    ==
    ;div.h7;
    ;+  (render-tree scoped-file rest-pith init-beneath)
  ==
::
++  render-tree
  ::
  ::  recursive tree render; .rest-pith is the scope (bare, user-facing),
  ::  each rendered node accumulates its relative pith off .rest-pith.
  ::
  |=  [root=file rest-pith=pith beneath=?]
  ^-  manx
  =|  rel=pith
  =|  sug=(unit iota)
  =/  f  root
  |-
  ^-  manx
  =/  bare-pax  (welp rest-pith rel)
  =/  meta  (fall leaf.code.f *meta)
  =/  nude  leaf.data.f
  =/  has-node  ?=(^ nude)
  =/  has-view  ?=(^ view.meta)
  =/  has-view-below  ?=(^ (~(views-below fe f) /))
  =/  has-kids  ?=(^ kids.data.f)
  =/  at-or-below  |(beneath has-view)
  =/  nid  (uid bare-pax)
  =/  sections=(list [tape tape manx])
    %-  zing
    ^-  (list (list [tape tape manx]))
    :~
      :::
      ?:  &(beneath !has-view)  ~
      ~[(render-view bare-pax meta)]
      ::
      ~[(render-node-form at-or-below bare-pax nude)]
      ::
      ~[(render-meta-forms bare-pax meta)]
      ::
      ~[(render-subs subs.meta)]
      ::
      ~[(render-logs logs.meta)]
    ==
  ;div.fc
    =id  "tree{nid}"
    ;+  %^  add-class-if  at-or-below  "f-3"
    ;div
      =id  "treeleaf{nid}"
      =data-signals  "\{'_details{nid}': false}"
      ;+
        %+  add-attribute  ['data-on:click' "$_details{nid} = !$_details{nid}"]
        %+  add-attribute  ['data-class:active' "$_details{nid}"]
        (render-summary rel sug nude data.f code.f at-or-below)
      ;+  %^  add-class-if  !|(has-kids has-node has-view has-view-below)  "hidden"
      ;div.fc.b2.ml4.bd1.mb3.mt1
        =style  hid
        =data-show  "$_details{nid}"
        =data-signals  "\{'_sec{nid}': '{-:(head sections)}'}"
        ;div.fr.bbh.bdb1
          ;*
          %+  turn  sections
          |=  [name=tape info=tape *]
          ;button.p-2.b3.hover.fr.g2
            =data-on_click  "$_sec{nid} = '{name}'"
            =data-class_toggled  "$_sec{nid} == '{name}'"
            ;span: {name}
            ;span.o6: {info}
          ==
          ;div.grow;
          ;+  ?~  eyre.meta  ;/  ""
              ;a.p-2.b2.hover.f-4
                =href  (pate :(welp #/['-'] rest.bowl rel))
                =target  "_blank"
                ; open
              ==
        ==
        ;*
        %+  turn  sections
        |=  [name=tape tape contents=manx]
        ;div
          =style  "hid"
          =data-show  "$_sec{nid} == '{name}'"
          ;+  contents
        ==
      ==
    ==
    ;div.ml2.pl3.fc.bdl1
      =id  "treekids{nid}"
      ;*
      %+  turn  ~(kid-list fe f)
      |=  [=iota =file]
      ^$(f file, rel (snoc rel iota), sug `iota, beneath at-or-below)
    ==
  ==
::
++  render-section
  ::
  ::  wrap a section's [summary-contents body-contents] pair in the
  ::  standard <details>/<summary> frame.
  ::
  |=  [sum=marl bod=marl]
  ^-  manx
  ;details
    ;summary.fr.g2.ac.p2.b1.hover
      ;*  sum
    ==
    ;div.p3.pl5.bdt1
      ;*  bod
    ==
  ==
::
++  render-meta-forms
  ::
  ::  per-node controls over meta: grow, eyre, gall, bump.
  ::  install / uninstall of the view live in render-view.
  ::
  |=  [pax=pith =meta]
  ^-  [tape tape manx]
  =/  pax-t=@t  (crip (pate pax))
  =/  sum=tape  ""
  =/  bod=manx
    ;div.p3
      ;span: {(pate pax)}
      ::  open via eyre
      ::
      ;+  ?~  eyre.meta  ;/  ""
          ;a.p-2.br2.bd1.b2.hover
            =href    (weld "/-" (pate pax))
            =target  "_blank"
            =rel     "noopener"
            ; open
          ==
      ::  grow
      ::
      ;form.fr.g2.ac(data-on_submit post)
        ;input(type "hidden", name "op", value "set-grow");
        ;input(type "hidden", name "pax", value (trip pax-t));
        ;input(type "hidden", name "val", value ?:(grow.meta "false" "true"));
        ;span: {?:(grow.meta "grow: on" "grow: off")}
        ;button.p-2.br2.bd1.b2.hover: toggle
      ==
      ::  eyre
      ::
      ;form.fr.g2.ac(data-on_submit post)
        ;input(type "hidden", name "op", value "set-eyre");
        ;input(type "hidden", name "pax", value (trip pax-t));
        ;label.fr.g2.ac
          ;span: eyre
          ;+  (auth-select "kind" eyre.meta)
        ==
        ;button.p-2.br2.bd1.b2.hover: set
      ==
      ::  gall
      ::
      ;form.fr.g2.ac(data-on_submit post)
        ;input(type "hidden", name "op", value "set-gall");
        ;input(type "hidden", name "pax", value (trip pax-t));
        ;label.fr.g2.ac
          ;span: gall
          ;+  (auth-select "kind" gall.meta)
        ==
        ;button.p-2.br2.bd1.b2.hover: set
      ==
      ::  bump
      ::
      ;form.fr.g2.ac(data-on_submit post)
        ;input(type "hidden", name "op", value "bump");
        ;input(type "hidden", name "pax", value (trip pax-t));
        ;button.p-2.br2.bd1.b2.hover: bump life
      ==
    ==
  ["meta" sum bod]
::
++  auth-select
  ::
  ::  <select> element for a (unit auth) meta field
  ::
  |=  [name=tape cur=(unit auth)]
  ^-  manx
  =/  cur-kind=@t
    ?~  cur  'none'
    kind.u.cur
  =/  opts=(list [@t tape])
    :~  ['none' "none"]
        ['white' "white"]
        ['black' "black"]
        ['black-moon' "black-moon"]
        ['black-planet' "black-planet"]
        ['black-star' "black-star"]
        ['black-galaxy' "black-galaxy"]
    ==
  ;select.br2.bd1.p-2
    =name  name
    ;*
    %+  turn  opts
    |=  [k=@t label=tape]
    %^  add-attribute-if  =(k cur-kind)  selected+""
    ;option  =value  (trip k)  ;-  label  ==
  ==
::
++  render-node-form
  ::
  ::  per-node textarea for leaf.data: renders the current node via
  ::  print-strict.  submit sets the leaf by ins; clear sends a del.
  ::
  |=  [locked=? pax=pith nude=(unit node)]
  ^-  [tape tape manx]
  =/  nid  (uid pax)
  =/  pax-t=@t  (crip (pate pax))
  =/  strict-t=tape
    ?~  nude  ""
    (fall (print-strict u.nude) "")
  =/  sum=tape  ""
  =/  bod=manx
    ?:  locked
      ;div.mono.fs-1.pre.fc.g2.p3
        ;div.fs-2.o5: data locked because within $view
        ;+
        ?~  nude     ;span: none
        ?+  u.nude   ;span: no rendering
          aota       ;div: {(print-aura u.nude)}: {(print-node u.nude)}
          [%pith *]  ;div: {(pate u.nude)}
          [%tang *]
            ;div.pre.mono
              ;-  (print-tang tang.u.nude)
            ==
        ==
      ==
    ;div
      ;div.fc.relative
        ;form.fc(data-on_submit post)
          =id  "nodeform{nid}"
          =data-indicator  "_loadnode{nid}"
          ;input(type "hidden", name "op", value "put-leaf");
          ;input(type "hidden", name "pax", value (trip pax-t));
          ;feather-textarea.mono.focus.p3.fs-2
            =name  "node"
            =required  ""
            =rows  "6"
            =placeholder  "hoon for a node, e.g.  ud+12"
            =spellcheck  "false"
            ;-  strict-t
          ==
        ==
        ;div.absolute.right0.bottom0.pr4.pb4.z1.fr.g3
          ;button.p-2.br2.bd1.b3.hover.focus
            =data-class_pulse  "$_loadnode{nid}"
            =type  "submit"
            =form  "nodeform{nid}"
            ; save
          ==
          ;+  ?~  nude  ;/  ""
              ;form.fr(data-on_submit post)
                ;input(type "hidden", name "op", value "del-leaf");
                ;input(type "hidden", name "pax", value (trip pax-t));
                ;button.p-2.br2.bd1.b3.hover.focus: clear leaf
              ==
        ==
      ==
    ==
  ["node" sum bod]
::
++  render-create-node-form
  ::
  ::  per-node form for inserting a leaf somewhere in this subtree.
  ::  pax is the current node's bare pith; the pith input is
  ::  prefilled to pax+"/" so the user fills the remainder.
  ::
  |=  pax=pith
  ^-  manx
  ;form.fc.g2(data-on_submit post)
    ;input(type "hidden", name "op", value "put-leaf");
    ;label.fr.g2.ac
      ;span: pith
      ;input.p-2.br2.bd1.mono.grow.focus
        =type  "text"
        =name  "pax"
        =placeholder  "/some/pith"
        =required  ""
        =spellcheck  "false"
        ;*  ~
      ==
    ==
    ;label.fc.g2
      ;span: node
      ;feather-textarea.p3.mono.br2.bd1.fs-2.focus
        =name  "node"
        =rows  "6"
        =placeholder  "hoon for a node, e.g.  ud+12"
        =required  ""
        =spellcheck  "false"
        ;*  ~
      ==
    ==
    ;div.fr.g2
      ;button.p-2.br2.bd1.b2.hover.focus: insert
    ==
  ==
::
++  render-create-view-form
  ::
  ::  per-node form for installing a view somewhere in this subtree.
  ::  pax is the current node's bare pith; the pax input is prefilled
  ::  to pax+"/" so the user fills the remainder.
  ::
  |=  pax=pith
  ^-  manx
  ;div.fc.g3.p2
    ;form.fc.g2(data-on_submit post)
      ;input(type "hidden", name "op", value "install");
      ;label.fr.g2.ac
        ;span: pax
        ;input.p-2.br2.bd1.mono.grow.focus
          =type  "text"
          =name  "pax"
          =placeholder  "/my-app"
          =required  ""
          =spellcheck  "false"
          =value   ?~(pax "/" (weld (pate pax) "/"))
          ;*  ~
        ==
      ==
      ;label.fc.g2
        ;span: code
        ;feather-textarea.p3.mono.br2.bd1.fs-2.focus
          =name  "code"
          =rows  "10"
          =placeholder  "^-  transformer"
          =required  ""
          =spellcheck  "false"
          =value  "[%link {(scow %p our.bowl)} /path-to-code]"
          ;-  "[%link {(scow %p our.bowl)} /path-to-code]"
        ==
      ==
      ;label.fr.g2.ac
        ;span: dep ship
        ;input.p-2.br2.bd1.mono.grow.focus
          =type  "text"
          =name  "dep-ship"
          =placeholder  "~zod"
          =value  (scow %p our.bowl)
          =required  ""
          =spellcheck  "false"
          ;*  ~
        ==
      ==
      ;label.fr.g2.ac
        ;span: dep pith
        ;input.p-2.br2.bd1.mono.grow.focus
          =type  "text"
          =name  "dep-pith"
          =placeholder  "/some/pith"
          =required  ""
          =spellcheck  "false"
          =value  (pate rest.bowl)
          ;*  ~
        ==
      ==
      ;div.fr.g2
        ;button.p-2.br2.bd1.b2.hover.focus: install
      ==
    ==
  ==
::
++  render-subs
  ::
  |=  =(set pith)
  ^-  [tape tape manx]
  =/  n  ~(wyt in set)
  =/  bod=manx
    ;div.p3
      ;*
      =;  =marl  ?^  marl  marl
        ;=
          ;div: none
        ==
      %+  turn  ~(tap in set)
      |=  =pith
      ;div.mono.f5.fs-1: {(pate pith)}
    ==
  ["subscribers" ?:(=(~ set) "" <~(wyt in set)>) bod]
::
++  render-logs
  ::
  |=  =(list move)
  ^-  [tape tape manx]
  =/  bod=manx
    ;div.fc.bbv.p3.bc9
      ;*
      =;  =marl  ?^  marl  marl
        ;=
          ;div.fs-2: none
        ==
      %-  flop
      =<  p
      %^  spin  list  1
      |=  [=move a=@]
      :_  +(a)
      ;div.fr.g4.as.p1
        ;div.f5.w7: {<a>}
        ;div
          ;*
          %+  turn   ~(tap in move)
          |=  =chng
          ;div
            ;-
            ?-  -.chng
              %ins  "%ins {(pate pith.chng)}  - {"%"}{(print-aura node.chng)}"
              %del  "%del {(pate pith.chng)}"
            ==
          ==
        ==
      ==
    ==
  ["logs" <(lent list)> bod]
::
++  render-view
  ::
  ::  per-node view controls: install / edit (re-install) / uninstall.
  ::  when a view exists, fields are prefilled from its source; a
  ::  linked (%link) view prefills empty since the textarea expects
  ::  raw hoon.
  ::
  |=  [pax=pith =meta]
  ^-  [tape tape manx]
  =/  pax-t=@t    (crip (pate pax))
  =/  has-view    ?=(^ view.meta)
  =/  nid=tape  (uid pax)
  =/  code-t=tape
    ?~  view.meta  ""
    ?@  code.u.view.meta
      (trip code.u.view.meta)
    =,  source-ref.code.u.view.meta
    "[%link {<ship>} {"#"}{(pate pith)}]"
  =/  dep-ship-t=tape
    ?~  view.meta  ""
    (scow %p ship.dep.u.view.meta)
  =/  dep-pith-t=tape
    ?~  view.meta  "/"
    (pate pith.dep.u.view.meta)
  =/  btn-label=tape  ?:(has-view "save view" "install view")
  =/  sum=tape  ""
  =/  bod=manx
    ;div.fc.bbv
      ;+  ?~  view.meta  ;/  ""  (render-error u.view.meta)
      ;form.fc.bbv.fs-2
        =data-on_submit  post
        =id  "#vf{nid}"
        ;input(type "hidden", name "op", value "install");
        ;input(type "hidden", name "pax", value (trip pax-t));
        ;div.fr.bbh
          ;label.fc
            =style   "min-width: 100px"
            ;input.p-2.mono.grow
              =type  "text"
              =name  "dep-ship"
              =placeholder  "~zod"
              =required  ""
              =spellcheck  "false"
              =value  dep-ship-t
              ;*  ~
            ==
          ==
          ;label.fc.grow
            ;input.p-2.mono.grow
              =type  "text"
              =name  "dep-pith"
              =placeholder  "/some/pith"
              =required  ""
              =spellcheck  "false"
              =value  dep-pith-t
              ;*  ~
            ==
          ==
        ==
        ;feather-textarea.p3.mono.fs-2
          =name  "code"
          =placeholder  "^-  transformer"
          =required  ""
          =auto-indent  ""
          =spellcheck  "false"
          =rows  "5"
          ;-  code-t
        ==
      ==
      ;div.fr.bbh
        ;button.p3.b3.hover.focus.fs0.grow
          =type  "submit"
          =form  "#vf{nid}"
          ;-  btn-label
        ==
        ;+  ?.  has-view  ;/  ""
            ;form.fr.g2(data-on_submit post)
              ;input(type "hidden", name "op", value "uninstall");
              ;input(type "hidden", name "pax", value (trip pax-t));
              ;button.p-2.b3.hover.focus: uninstall view
            ==
      ==
    ==
  ["view" sum bod]
::
++  post
  ::
  "@post('{(spud (welp prefix.bowl rest.bowl))}', \{contentType: 'form'})"
::
++  render-error
  ::
  |=  =source
  ^-  manx
  ;div.fc.g2.f3
    ;+  ?~  err.source  ;/  ""
        (render-tang err.source)
  ==
::
++  render-summary
  ::
  |=  [where=pith sug=(unit iota) nude=(unit node) dat=data cod=code at-or-below-view=?]
  ^-  manx
  =/  meta  (fall leaf.cod *meta)
  =/  has-node  ?=(^ nude)
  =/  has-kids  ?=(^ kids.dat)
  =/  has-view  ?=(^ view.meta)
  =/  has-view-below  ?=(^ (~(views-below fe [dat cod]) /))
  %^  add-class-if  !|(has-kids has-node has-view has-view-below)  "hidden"
  ;button.p-1.b1.fr.g3.hover.wf
    ;+  %+  add-class
        ?.  has-view
          ?.  |(has-kids has-node)  "o5"
          ""
        =/  source  (need view.meta)
        ?^  err.source  "f-1"
        "f-3"
    ;span
      ;+
        %^  add-class-if  has-view  "bold"
        %^  add-class-if  &(!has-view at-or-below-view)  "o7"
        ?~  sug  ;span: /
        ?@  u.sug  ;span: {(trip u.sug)}
        ;span
          ;span.fs-1.o7
            ;-  (print-aura u.sug)
            ;-  ":"
          ==
          ;span
            ;-  (print-node u.sug)
          ==
        ==
    ==
    ;+  ?:  =(~ subs.meta)  ;/  ""
        ;span.f-3.bold: [{<~(wyt in subs.meta)>}]
    ;+  ?:  =(~ view-subs.meta)  ;/  ""
        ;span.f-4.bold: [{<~(wyt in view-subs.meta)>}]
    ;+
      ?.  has-node  ;/  ""
      ;span.o7
        ;*
        =/  =node  (need nude)
        ?@  node
          ;=
            ;-  (welp "%" (trip node))
          ==
        ;=
          ;span.fs-2: {(print-aura node)}:
          ;-  (print-node (need nude))
        ==
      ==
    ;span.grow;
    ;+  ?.  grow.meta  ;/  ""
        ;span: grow
    ;+  ?~  gall.meta  ;/  ""
        ;span
          ;-  "gall="
          ;-  (print-auth u.gall.meta)
        ==
    ;+  ?~  eyre.meta  ;/  ""
        ;span
          ;-  "eyre="
          ;-  (print-auth u.eyre.meta)
        ==
    ;span.o6.mono
      ;-  <case.meta>
      ;-  ":"
      ;-  <life.meta>
    == 
  ==
::
++  print-auth
  ::
  |=  =auth
  ^-  tape
  ;:  welp
    (trip -.auth)
    ":"
    <~(wyt in exceptions.auth)>
  ==
--
