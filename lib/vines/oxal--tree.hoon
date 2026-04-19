::  /ted/http-oxal--tree  :  tree rendering of a $file, scoped to rest.bowl
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
;<  =acer  bind:m  (scry ,acer /gx/oxal/acer/noun)
=/  rest-pith=pith  (pave rest.bowl)
=/  scope-pax=pith  [p+our.bowl rest-pith]
::
?:  =('POST' method.bowl)
  =/  body  formencoded-body:vio
  =/  =cage  (body-to-cage body now.bowl)
  ;<  ~  bind:m  (poke-our:vio cage)
  ;<  ~  bind:m
    %+  send-simple-payload:vio
      [303 ['location' (spat (welp [prefix rest]:bowl))]~]
    ~
  (pure:m !>(~))
::
=/  scoped-file=file  (~(dip fe file.acer) scope-pax)
::
=/  hymn=manx
  ::
  ;html
    ;head
      ;title: oxal
      ;meta(charset "utf-8");
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
      ;script(type "module", src "/hawk-init/feather/1/textarea");
      ;script(type "module", src "/hawk-init/feather/1/text-editor");
      ;style
        ;-  %-  trip
        '''
        details[open] > summary {
          filter: invert(15%);
        }
        '''
      ==
    ==
    ;body.p5.fc.g4(style "padding-bottom: 80vh;")
      ;h1: {(pate rest-pith)}
      ;div
        ;+  (render-tree scoped-file rest-pith)
      ==
    ==
  ==
::
;<  ~  bind:m
  %+  send-simple-payload:vio
    [200 ['content-type' 'text/html']~]
  :-  ~
  %-  as-octt:mimes:html
  %+  welp  "<!doctype html>"
  (en-xml:html hymn)
(pure:m !>(~))
::
|%
++  render-tree
  ::
  ::  recursive tree render; .rest-pith is the scope (bare, user-facing),
  ::  each rendered node accumulates its relative pith off .rest-pith.
  ::
  |=  [root=file rest-pith=pith]
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
  ;div.fc
    ;+  %^  add-class-if  &(=(0 case.meta) !has-view)  "o2"
    ;details.bdb1
      ;+  (render-summary sug nude data.f meta)
      ;div.bdt1.fc.bbv.o6.pl5
        ;+  (render-section (render-view bare-pax meta))
        ;+  (render-section (render-meta-forms bare-pax meta))
        ;+  (render-section (render-leaf-form bare-pax nude))
        ;+  (render-section (render-create-node-form bare-pax))
        ;+  (render-section (render-create-view-form bare-pax))
        ;+  (render-section (render-subs subs.meta))
        ;+  (render-section (render-logs logs.meta))
      ==
    ==
    ;div.ml5.bdl1.fc
      ;*
      %+  turn  ~(kid-list fe f)
      |=  [=iota =file]
      ^$(f file, rel (snoc rel iota), sug `iota)
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
  ^-  [marl marl]
  =/  pax-t=@t  (crip (pate pax))
  =/  sum=marl
    ;=
      ;span.bold: meta
      ;span.grow;
      ;+  ?.  grow.meta  ;/  ""
          ;span.fs-2: grow
      ;+  ?~  eyre.meta  ;/  ""
          ;span.fs-2: eyre={(trip kind.u.eyre.meta)}
      ;+  ?~  gall.meta  ;/  ""
          ;span.fs-2: gall={(trip kind.u.gall.meta)}
    ==
  =/  bod=marl
    ;=
      ::  grow
      ::
      ;form.fr.g2.ac(method "post")
        ;input(type "hidden", name "op", value "set-grow");
        ;input(type "hidden", name "pax", value (trip pax-t));
        ;input(type "hidden", name "val", value ?:(grow.meta "false" "true"));
        ;span: {?:(grow.meta "grow: on" "grow: off")}
        ;button.p-2.br2.bd1.b2.hover: toggle
      ==
      ::  eyre
      ::
      ;form.fr.g2.ac(method "post")
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
      ;form.fr.g2.ac(method "post")
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
      ;form.fr.g2.ac(method "post")
        ;input(type "hidden", name "op", value "bump");
        ;input(type "hidden", name "pax", value (trip pax-t));
        ;button.p-2.br2.bd1.b2.hover: bump life
      ==
    ==
  [sum bod]
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
++  render-leaf-form
  ::
  ::  per-node textarea for leaf.data: renders the current node via
  ::  print-strict.  submit sets the leaf by ins; clear sends a del.
  ::
  |=  [pax=pith nude=(unit node)]
  ^-  [marl marl]
  =/  pax-t=@t  (crip (pate pax))
  =/  strict-t=tape
    ?~  nude  ""
    (fall (print-strict u.nude) "")
  =/  summary-t=tape
    ?:  (gth (lent strict-t) 60)
      (weld (scag 60 strict-t) "...")
    strict-t
  =/  sum=marl
    ;=
      ;span.bold: data
      ;span.grow;
      ;+  ?~  nude  ;/  ""
          ;span.fs-2.mono
            ;-  summary-t
          ==
    ==
  =/  bod=marl
    ;=
      ;form.fc.g2(method "post")
        ;input(type "hidden", name "op", value "put-leaf");
        ;input(type "hidden", name "pax", value (trip pax-t));
        ;textarea.p3.pre.mono.br2.bd1.fs-2
          =name  "node"
          =rows  "6"
          =placeholder  "hoon for a node, e.g.  ud+12"
          ;-  strict-t
        ==
        ;div.fr.g2
          ;button.p-2.br2.bd1.b2.hover: save
        ==
      ==
      ;+  ?~  nude  ;/  ""
          ;form.fr.g2(method "post")
            ;input(type "hidden", name "op", value "del-leaf");
            ;input(type "hidden", name "pax", value (trip pax-t));
            ;button.p-2.br2.bd1.b2.hover: clear leaf
          ==
    ==
  [sum bod]
::
++  render-create-node-form
  ::
  ::  per-node form for inserting a leaf somewhere in this subtree.
  ::  pax is the current node's bare pith; the pith input is
  ::  prefilled to pax+"/" so the user fills the remainder.
  ::
  |=  pax=pith
  ^-  [marl marl]
  =/  prefill=tape
    ?~  pax  "/"
    (weld (pate pax) "/")
  =/  sum=marl
    ;=
      ;span.bold: create node below
      ;span.grow;
    ==
  =/  bod=marl
    ;=
      ;div.fc.g3.p2
        ;form.fc.g2(method "post")
          ;input(type "hidden", name "op", value "put-leaf");
          ;label.fr.g2.ac
            ;span: pith
            ;input.p-2.br2.bd1.mono.grow
              =type  "text"
              =name  "pax"
              =placeholder  "/some/pith"
              =required  ""
              =spellcheck  "false"
              =value  prefill
              ;*  ~
            ==
          ==
          ;label.fc.g2
            ;span: node
            ;textarea.p3.pre.mono.br2.bd1.fs-2
              =name  "node"
              =rows  "6"
              =placeholder  "hoon for a node, e.g.  ud+12"
              =required  ""
              ;*  ~
            ==
          ==
          ;div.fr.g2
            ;button.p-2.br2.bd1.b2.hover: insert
          ==
        ==
      ==
    ==
  [sum bod]
::
++  render-create-view-form
  ::
  ::  per-node form for installing a view somewhere in this subtree.
  ::  pax is the current node's bare pith; the pax input is prefilled
  ::  to pax+"/" so the user fills the remainder.
  ::
  |=  pax=pith
  ^-  [marl marl]
  =/  prefill=tape
    ?~  pax  "/"
    (weld (pate pax) "/")
  =/  sum=marl
    ;=
      ;span.bold: create view below
      ;span.grow;
    ==
  =/  bod=marl
    ;=
      ;div.fc.g3.p2
        ;form.fc.g2(method "post")
          ;input(type "hidden", name "op", value "install");
          ;label.fr.g2.ac
            ;span: pax
            ;input.p-2.br2.bd1.mono.grow
              =type  "text"
              =name  "pax"
              =placeholder  "/my-app"
              =required  ""
              =spellcheck  "false"
              =value  prefill
              ;*  ~
            ==
          ==
          ;label.fc.g2
            ;span: code
            ;textarea.p3.pre.mono.br2.bd1.fs-2
              =name  "code"
              =rows  "10"
              =placeholder  "|=  [snap=data did=move life=@ud case=@ud]  ^-  move  ..."
              =required  ""
              =spellcheck  "false"
              ;*  ~
            ==
          ==
          ;label.fr.g2.ac
            ;span: dep ship
            ;input.p-2.br2.bd1.mono.grow
              =type  "text"
              =name  "dep-ship"
              =placeholder  "~zod"
              =required  ""
              =spellcheck  "false"
              ;*  ~
            ==
          ==
          ;label.fr.g2.ac
            ;span: dep pith
            ;input.p-2.br2.bd1.mono.grow
              =type  "text"
              =name  "dep-pith"
              =placeholder  "/some/pith"
              =required  ""
              =spellcheck  "false"
              =value  "/"
              ;*  ~
            ==
          ==
          ;div.fr.g2
            ;button.p-2.br2.bd1.b2.hover: install
          ==
        ==
      ==
    ==
  [sum bod]
::
++  body-to-cage
  ::
  ::  build a cage from a decoded form body keyed by 'op'.
  ::
  |=  [body=(map @t @t) now=@da]
  ^-  cage
  =/  op=@t  (fall (~(get by body) 'op') 'noop')
  ?:  =(op 'set-grow')
    =/  pax=pith  (cord-to-pith (~(got by body) 'pax'))
    =/  val=?  =('true' (~(got by body) 'val'))
    [%set-grow !>([pax val])]
  ?:  =(op 'set-eyre')
    =/  pax=pith  (cord-to-pith (~(got by body) 'pax'))
    =/  val=(unit auth)  (parse-auth (~(got by body) 'kind'))
    [%set-eyre !>([pax val])]
  ?:  =(op 'set-gall')
    =/  pax=pith  (cord-to-pith (~(got by body) 'pax'))
    =/  val=(unit auth)  (parse-auth (~(got by body) 'kind'))
    [%set-gall !>([pax val])]
  ?:  =(op 'bump')
    =/  pax=pith  (cord-to-pith (~(got by body) 'pax'))
    [%bump !>(pax)]
  ?:  =(op 'install')
    =/  pax=pith  (cord-to-pith (~(got by body) 'pax'))
    =/  code=source-code  (fix-newlines (~(got by body) 'code'))
    =/  dep=source-ref
      :-  (slav %p (~(got by body) 'dep-ship'))
      (cord-to-pith (~(got by body) 'dep-pith'))
    [%install !>([pax code dep])]
  ?:  =(op 'uninstall')
    =/  pax=pith  (cord-to-pith (~(got by body) 'pax'))
    [%uninstall !>(pax)]
  ?:  =(op 'del-leaf')
    =/  pax=pith  (cord-to-pith (~(got by body) 'pax'))
    =/  =move  (sy ~[[%del pax]])
    [%do-move !>(move)]
  ?:  =(op 'put-leaf')
    =/  pax=pith  (cord-to-pith (~(got by body) 'pax'))
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
::
++  render-subs
  ::
  |=  =(set pith)
  ^-  [marl marl]
  =/  n  ~(wyt in set)
  =/  sum=marl
    ;=
      ;span.bold: subs
      ;+  ?:  =(0 n)  ;/  ""
          ;span.fs-2: {<n>}
    ==
  =/  bod=marl
    ;=
      ;div.p2.fc.g2
        ;*
        =;  =marl  ?^  marl  marl
          ;=
            ;div.fs-2: none
          ==
        %+  turn  ~(tap in set)
        |=  =pith
        ;div.mono.f5: {(pate pith)}
      ==
    ==
  [sum bod]
::
++  render-logs
  ::
  |=  =(list move)
  ^-  [marl marl]
  =/  n  (lent list)
  =/  sum=marl
    ;=
      ;span.bold: logs
      ;+  ?:  =(0 n)  ;/  ""
          ;span.fs-2: {<n>}
    ==
  =/  bod=marl
    =;  =marl  ?^  marl  marl
      ;=
        ;div.fs-2: none
      ==
    ;=
      ;div.fc.g5
        ;*
        %+  turn  list
        |=  =move
        ;div
          ;*
          %+  turn   ~(tap in move)
          |=  =chng
          ;div
            ;-
            ?-  -.chng
              %ins  "%ins {(pate pith.chng)} {(print-aura node.chng)}"
              %del  "%del {(pate pith.chng)}"
            ==
          ==
        ==
      ==  
    ==
  [sum bod]
::
++  render-view
  ::
  ::  per-node view controls: install / edit (re-install) / uninstall.
  ::  when a view exists, fields are prefilled from its source; a
  ::  linked (%link) view prefills empty since the textarea expects
  ::  raw hoon.
  ::
  |=  [pax=pith =meta]
  ^-  [marl marl]
  =/  pax-t=@t    (crip (pate pax))
  =/  has-view    ?=(^ view.meta)
  =/  code-t=tape
    ?~  view.meta  ""
    ?@  code.u.view.meta
      (trip code.u.view.meta)
    ""
  =/  dep-ship-t=tape
    ?~  view.meta  ""
    (scow %p ship.dep.u.view.meta)
  =/  dep-pith-t=tape
    ?~  view.meta  "/"
    (pate pith.dep.u.view.meta)
  =/  btn-label=tape  ?:(has-view "save view" "install view")
  =/  sum=marl
    ;=
      ;span.bold: view
      ;span.grow;
      ;+  ?~  view.meta  ;/  ""
          ;span.fr.g2.ac.fs-2
            ;span.mono
              ;-  (scow %p ship.dep.u.view.meta)
            ==
            ;span.mono
              ;-  (pate pith.dep.u.view.meta)
            ==
            ;span: L{<lyf.u.view.meta>}
            ;span: C{<cas.u.view.meta>}
          ==
    ==
  =/  bod=marl
    ;=
      ;+  ?~  view.meta  ;/  ""  (render-error u.view.meta)
      ;form.fc.g2(method "post")
        ;input(type "hidden", name "op", value "install");
        ;input(type "hidden", name "pax", value (trip pax-t));
        ;label.fc.g2
          ;span: code
          ;feather-text-editor.p3.mono.br2.bd1.fs-1
            =name  "code"
            =placeholder  "|=  [snap=data did=move life=@ud case=@ud]  ^-  move  ..."
            =required  ""
            =auto-indent  ""
            ;-  code-t
          ==
        ==
        ;label.fr.g2.ac
          ;span: dep ship
          ;input.p-2.br2.bd1.mono.grow
            =type  "text"
            =name  "dep-ship"
            =placeholder  "~zod"
            =required  ""
            =spellcheck  "false"
            =value  dep-ship-t
            ;*  ~
          ==
        ==
        ;label.fr.g2.ac
          ;span: dep pith
          ;input.p-2.br2.bd1.mono.grow
            =type  "text"
            =name  "dep-pith"
            =placeholder  "/some/pith"
            =required  ""
            =spellcheck  "false"
            =value  dep-pith-t
            ;*  ~
          ==
        ==
        ;div.fr.g2
          ;button.p-2.br2.bd1.b2.hover
            ;-  btn-label
          ==
        ==
      ==
      ;+  ?.  has-view  ;/  ""
          ;form.fr.g2(method "post")
            ;input(type "hidden", name "op", value "uninstall");
            ;input(type "hidden", name "pax", value (trip pax-t));
            ;button.p-2.br2.bd1.b2.hover: uninstall view
          ==
    ==
  [sum bod]
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
  |=  [sug=(unit iota) nude=(unit node) dat=data =meta]
  ^-  manx
  =/  has-node  ?=(^ nude)
  =/  has-kids  ?=(^ kids.dat)
  =/  has-view  ?=(^ view.meta)
  ;summary.p3.b1.fr.g3.hover
    ;+  %+  add-class
        ?.  has-view
          ?.  |(has-kids has-node)  "o5"
          ""
        =/  source  (need view.meta)
        ?^  err.source  "f-1"
        "f-3"
    ;span
      ;+
        ?~  sug  ;/  "/"
        ?@  u.sug  ;span.bold: {(trip u.sug)}
        ;span
          ;span.fs-1.f4
            ;-  (print-aura u.sug)
            ;-  ":"
          ==
          ;span.bold
            ;-  (print-node u.sug)
          ==
        ==
    ==
    ;+  ?~  subs.meta  ;/  ""
        ;span.f-3: •
    ;+
      ?.  has-node  ;/  ""
      ;span.f4
        ;*
        =/  =node  (need nude)
        ?@  node
          ;=
            ;-  (welp "%" (trip node))
          ==
        ;=
          ;span.fs-2.f3: {(print-aura node)}:
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
      ;-  <life.meta>
      ;-  "/"
      ;-  <case.meta>
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
