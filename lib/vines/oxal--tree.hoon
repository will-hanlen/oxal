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
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
    ==
    ;body.p5.fc.g9.pb15
      ;h1: {(pate rest-pith)}
      ;details
        ;summary: transformers
        ;div
          ;*
          %+  turn  ~(tap in ~(key by xfms.acer))
          |=  =cord
          ;div
            ;-  (trip cord)
          ==
        ==
      ==
      ;+  render-top-insert-form
      ;+  render-top-install-form
      ;+  render-top-form
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
++  render-top-insert-form
  ::
  ::  top-of-page form for inserting a single node into the data tree
  ::  at an arbitrary pith.  pax is user-facing (bare).
  ::
  ^-  manx
  ;details
    ;summary: insert node
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
            =value  "/"
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
::
++  render-top-install-form
  ::
  ::  top-of-page form for %install: fields match the poke shape
  ::  [pax=pith code=source-code dep=source-ref].  code is the @t
  ::  variant (raw hoon source); dep is split into ship and pith.
  ::
  ^-  manx
  ;details
    ;summary: install view
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
            =value  "/"
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
::
++  render-top-form
  ::
  ::  top-of-page form: accepts raw hoon for a cage, used for install and
  ::  arbitrary %do-move pokes at any pith.  preset buttons fill templates.
  ::
  ^-  manx
  ;details
    ;summary: poke
    ;div.fc.g3.p2
      ;form.br3.bd1.mono.relative(method "post")
        ;input(type "hidden", name "op", value "raw");
        ;textarea.pre.p3.fs-1.pb5.wf.focus.br3
          =id  "command"
          =name  "command"
          =spellcheck  "false"
          =rows  "10"
          =placeholder  "cage to poke %oxal, e.g.  :- %install !> ..."
          =required  ""
          ;*  ~
        ==
        ;div.absolute
          =style  "bottom: 12px; right: 12px;"
          ;button.p3.b2.hover.tc.fs1.br3.bd2.wfc.focus
            ; send
          ==
        ==
      ==
      ;div.frw.g2
        ;*
        %+  turn
          ^-  (list (pair @t @t))
          :~  :-  'install'
              '''
              :-  %install  !>
              :+  /my-app
              \0'''
              |=  [snap=data did=move life=@ud case=@ud]
              ^-  move
              ?.  =(~ did)  did
              %-  silt
              %+  turn  ~(tap do snap)
              |=  [pax=pith nod=node]
              ^-  chng
              [%ins pax nod]
              \0'''
              [~walrus-migrev-dolseg /bing/bong]
              '''
            ::
              :-  'do-move ins'
              '''
              :-  %do-move  !>
              %-  sy
              :~
                :+  %ins  /some/pith  ud+12
              ==
              '''
            ::
              :-  'do-move del'
              '''
              :-  %do-move  !>
              %-  sy
              :~
                :-  %del  /some/pith
              ==
              '''
            ::
              :-  'clear'  ''
          ==
        |=  [label=@t code=@t]
        ;button.br2.bd1.p-2.b2.hover.focus
          =type  "button"
          =onclick  "document.getElementById('command').value = `{(trip code)}`"
          ;-  (trip label)
        ==
      ==
    ==
  ==
::
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
    ;details.br2.bd1.scroll-none
      ;+  (render-summary sug nude data.f meta)
      ;div.p2.bdt1.fc.g3
        ;+  (render-view bare-pax meta)
        ;+  (render-bound meta)
        ;+  (render-meta-forms bare-pax meta)
        ;+  (render-leaf-form bare-pax nude)
        ;+  (render-subs subs.meta)
        ;+  (render-logs logs.meta)
      ==
    ==
    ;div.pl4.fc.pt2
      ;*
      %+  turn  ~(kid-list fe f)
      |=  [=iota =file]
      ^$(f file, rel (snoc rel iota), sug `iota)
    ==
  ==
::
++  render-meta-forms
  ::
  ::  per-node controls over meta: grow, eyre, gall, bump, uninstall.
  ::
  |=  [pax=pith =meta]
  ^-  manx
  =/  pax-t=@t  (crip (pate pax))
  ;details
    ;summary: meta
    ;div.p2.fc.g3
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
      ::  uninstall (only when a view is installed)
      ::
      ;+  ?~  view.meta  ;/  ""
          ;form.fr.g2.ac(method "post")
            ;input(type "hidden", name "op", value "uninstall");
            ;input(type "hidden", name "pax", value (trip pax-t));
            ;button.p-2.br2.bd1.b2.hover: uninstall view
          ==
    ==
  ==
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
  ^-  manx
  =/  pax-t=@t  (crip (pate pax))
  =/  strict-t=tape
    ?~  nude  ""
    (fall (print-strict u.nude) "")
  ;details
    ;summary: data
    ;div.p2.fc.g3
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
  ==
::
++  body-to-cage
  ::
  ::  build a cage from a decoded form body keyed by 'op'.
  ::
  |=  [body=(map @t @t) now=@da]
  ^-  cage
  =/  op=@t  (fall (~(get by body) 'op') 'noop')
  ?:  =(op 'raw')
    =/  command=@t
      (fix-newlines (cat 3 (~(got by body) 'command') '\0a\0a'))
    =;  =(each cage tang)
      ?:  ?=(%.y -.each)  p.each
      %-  (slog p.each)
      =/  =move  (sy ~[[%ins /error da+now]])
      [%do-move !>(move)]
    %-  mule  |.
    !<  cage
    %+  slap  !>(.)
    (ream command)
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
  ^-  manx
  ;div
    ;strong: subs
    ;div
      ;*
      =;  =marl  ?^  marl  marl
        ;=
          ;div: none
        ==
      %+  turn  ~(tap in set)
      |=  =pith
      ;div: {(pate pith)}
    ==
  ==
++  render-logs
  ::
  |=  =(list move)
  ;details
    ;summary: logs
    ;div
      ;*
      =;  =marl  ?^  marl  marl
        ;=
          ;div: none
        ==
      %+  turn  list
      |=  =move
      ;div.f5
        ;*
        %+  turn   ~(tap in move)
        |=  =chng
        ;div: {<chng>}
      ==
    ==
  ==
++  render-bound
  ::
  |=  =meta
  ^-  manx
  ;div.frw.g2.f5
    ;strong.f0: bound
    ;div: grow {<grow.meta>}
    ;div: eyre {<eyre.meta>}
    ;div: gall {<gall.meta>}
  ==
++  render-view
  ::
  |=  [pax=pith =meta]
  ^-  manx
  ;details
    ;summary
      ; view
      ;+  ?~  view.meta  ;/  ""
          ;span
            ;span.bold.px2
              ;-  (scow %p ship.dep.u.view.meta)
            ==
            ;span.bold.px2
              ;-  (pate pith.dep.u.view.meta)
            ==
            ;span.f4.p2
              ;-  <lyf.u.view.meta>
            ==
            ;span.px2
              ;-  <cas.u.view.meta>
            ==
          ==
    ==
    ;div.p3.fc.g3
      ;+  ?~  view.meta  ;/  ""  (render-error u.view.meta)
      ;div.fc.g2
        ;textarea.p3.pre.mono.br2.bd1.fs-2
          =rows  "8"
          =readonly  ""
          =placeholder  ?^(view.meta "there was a view here" "no view yere")
          ;-  ?~  view.meta  ""
              ?@  code.u.view.meta
                (trip code.u.view.meta)
              %+  weld  "> "
              (pate (ref-to-pith source-ref.code.u.view.meta))
        ==
      ==
    ==
  ==
++  render-error
  ::
  |=  =source
  ^-  manx
  ;div.fc.g2.f3
    ;+  ?~  err.source  ;/  ""
        (render-tang err.source)
  ==
++  render-summary
  ::
  |=  [sug=(unit iota) nude=(unit node) dat=data =meta]
  ^-  manx
  =/  has-node  ?=(^ nude)
  =/  has-kids  ?=(^ kids.dat)
  =/  has-view  ?=(^ view.meta)
  ;summary.p2.b2.fr.g3
    ;+  %+  add-class
        ?.  has-view
          ?.  |(has-kids has-node)  "o5"
          ""
        =/  source  (need view.meta)
        ?^  err.source  "f-1"
        "f-3"
    ;span.bold
      ;-
        ?~  sug  "/"
        %+  welp  "/"
        (print-node u.sug)
    ==
    ;+
      ?.  has-node  ;/  ""
      ;span
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
    ;span.o6
      ;-  "L"
      ;-  <life.meta>
    ==
    ;span.o6
      ;-  "C"
      ;-  <case.meta>
    ==
    ;span.o6
      ;-  "#S"
      ;-  <~(wyt in subs.meta)>
    ==
  ==
++  print-auth
  |=  =auth
  ^-  tape
  ;:  welp
    (trip -.auth)
    ":"
    <~(wyt in exceptions.auth)>
  ==
--
