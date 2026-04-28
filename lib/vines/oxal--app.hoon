::  /ted/http-oxal--app  :  detail page for a single app
::
::    GET   /oxal/app/<name>   show one app's source, computed views, edit form
::    POST  /oxal/app/<name>   stub: ops not yet wired; redirects
::
::  a bare /oxal/app (no name) bounces to the list page at /oxal/apps.
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
?:  =('POST' method.bowl)
  =/  form=(map @t @t)  formencoded-body:vio
  =/  op=@t  (~(gut by form) 'op' '')
  ?:  =('put-data' op)
    ::
    ::  insert a node into the data tree at `view-pax` + `sub-pax`.
    ::  parses both piths and the value as a node, then pokes
    ::  oxal with %do-move (which qualifies the pith with /[our]).
    ::
    =/  view-cord=@t  (~(gut by form) 'view-pax' '')
    =/  sub-cord=@t   (~(gut by form) 'sub-pax' '')
    =/  value=@t  (~(gut by form) 'value' '')
    =/  view-pith=pith  (cord-to-pith view-cord)
    =/  sub-pith=pith
      ?:  =('' sub-cord)  ~
      (cord-to-pith sub-cord)
    =/  full-pith=pith  (welp view-pith sub-pith)
    =/  =node  (cord-to-node value)
    =/  =move  (silt ~[[%ins full-pith node]])
    ;<  ~  bind:m  (poke-our:vio %do-move !>(move))
    ;<  ~  bind:m
      %+  send-simple-payload:vio
        [303 ['location' (spat (welp [prefix rest]:bowl))]~]
      ~
    (pure:m !>(~))
  ?:  =('del-data' op)
    ::
    =/  pax-cord=@t  (~(gut by form) 'pax' '')
    =/  full-pith=pith  (cord-to-pith pax-cord)
    =/  =move  (silt ~[[%del full-pith]])
    ;<  ~  bind:m  (poke-our:vio %do-move !>(move))
    ;<  ~  bind:m
      %+  send-simple-payload:vio
        [303 ['location' (spat (welp [prefix rest]:bowl))]~]
      ~
    (pure:m !>(~))
  ?:  =('update-app' op)
    ::
    =/  name=term   `@tas`(~(gut by form) 'name' '')
    =/  source=@t   (fix-newlines (~(got by form) 'source'))
    ;<  ~  bind:m  (poke-our:vio %update-app !>([name source]))
    ;<  ~  bind:m
      %+  send-simple-payload:vio
        [303 ['location' (spat (welp [prefix rest]:bowl))]~]
      ~
    (pure:m !>(~))
  ::  unknown op: bounce back unchanged.
  ::
  ;<  ~  bind:m
    %+  send-simple-payload:vio
      [303 ['location' (spat (welp [prefix rest]:bowl))]~]
    ~
  (pure:m !>(~))
::
?~  rest.bowl
  ::
  ::  no app name in the URL — redirect to the list page.
  ::
  ;<  ~  bind:m
    %+  send-simple-payload:vio
      [303 ['location' '/oxal/apps']~]
    ~
  (pure:m !>(~))
::
;<  =acer  bind:m  (scry ,acer /gx/oxal/acer/noun)
=/  name=@ta  i.rest.bowl
=/  found=(unit app)  (find-app apps.acer name)
;<  ~  bind:m
  %-  send-simple-payload:vio
  %+  node-to-simple-payload  %manx
  (render-detail name our.bowl data.file.acer code.file.acer found)
(pure:m !>(~))
::
|%
++  find-app
  ::
  ::  linear scan of apps for a name match.
  ::
  |=  [aps=(list [name=term =app]) want=@ta]
  ^-  (unit app)
  ?~  aps  ~
  ?:  =(name.i.aps want)  `app.i.aps
  $(aps t.aps)
::
++  render-detail
  ::
  ::  detail page: nav crumb, then either the app body or a notice.
  ::
  |=  [name=@ta our=ship dat=data cod=code found=(unit app)]
  ^-  manx
  ;html
    ;head
      ;meta(charset "UTF-8");
      ;meta
        =name  "viewport"
        =content  "width=device-width, ".
                  "initial-scale=1, ".
                  "maximum-scale=1, ".
                  "user-scalable=no, ".
                  "viewport-fit=cover"
        ;*  ~
      ==
      ;title: oxal app
      ;link(rel "icon", href "data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\"/>");
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
      ;script(type "module", src "/hawk-init/feather/1/textarea");
      ;script(type "module", src "/hawk-init/feather/1/datastar");
    ==
    ;body.p5.fc.g5.pb15
      ;nav.fr.g2.ac
        ;a.p-2.br2.bd1.b2.hover
          =href  "/oxal/apps"
          ; apps
        ==
        ;span.o5: /
        ;span.bold.mono: {(trip name)}
      ==
      ;+  ?~  found
          ;div.p5.bd1.br2.o6
            ;span: no app named
            ;span.bold.mono: {(trip name)}
          ==
        (render-detail-body name our dat cod u.found)
    ==
  ==
::
++  render-detail-body
  ::
  ::  body of the detail page: source, %forms, %lenses.
  ::
  |=  [name=@ta our=ship dat=data cod=code =app]
  ^-  manx
  ;div.fc.g5
    ;+  ?~  error.app  ;/  ""
        ;section.fc.g2
          ;h2.f-1: error
          ;div.p3.bd1.br2.b3.mono.fs-2.f-1
            ;+  (render-tang u.error.app)
          ==
        ==
    ;section.fc.g2
      ;details(open "")
        ;summary.bold: source
        ;form.fc.g2.mt2(method "post")
          ;input(type "hidden", name "op", value "update-app");
          ;input(type "hidden", name "name", value (trip name));
          ;feather-textarea.p3.mono.br2.bd1.fs-2
            =name  "source"
            =rows  "12"
            =required  ""
            =spellcheck  "false"
            ;-  (trip source.app)
          ==
          ;div.fr.g2.ac
            ;button.p-2.br2.bd1.b2.hover: save
          ==
        ==
      ==
    ==
    ;+  (render-form-views name our dat cod views.app)
    ;+  (render-lens-views our dat cod views.app)
  ==
::
++  render-form-views
  ::
  ::  one section listing every %form view in the app, each with a
  ::  small put-data form (sub-path + value) that pokes %do-move.
  ::
  |=  [name=@ta our=ship dat=data cod=code vws=(map stem view)]
  ^-  manx
  =/  forms=(list [stem view])
    %+  skim  ~(tap by vws)
    |=  [=stem =view]
    ?=(%form -.view)
  ;section.fc.g2
    ;h2: %forms
    ;div.fc.g3
      ;*
      =;  =marl  ?^  marl  marl
        ;=
          ;div.o6.fs-2: no %form views in this app
        ==
      %+  turn  forms
      |=  [=stem =view]
      (render-form-row name our dat cod stem)
    ==
  ==
::
++  render-form-row
  ::
  ::  one row per %form view: shows the view's pith, the data tree
  ::  rooted at it, then a form for inserting a new node at a
  ::  sub-path.
  ::
  |=  [name=@ta our=ship dat=data cod=code =stem]
  ^-  manx
  =/  pax=tape  (pate stem)
  =/  full-pith=pith  (welp `pith`[p+our ~] stem)
  =/  sub-data=data   (~(dip do dat) full-pith)
  =/  count=@ud       ~(wyt do sub-data)
  =/  live=(unit meta)  (~(get ox cod) full-pith)
  ;div.fc.g2.p3.bd1.br2.b2
    ;div.fr.g2.ac
      ;span.mono.bold: {pax}
      ;span.o6.fs-2: %form
      ;span.o6.fs-2: ({(scow %ud count)})
    ==
    ;+  ?~  live  ;/  ""
        (render-lens-subs u.live)
    ;+  (render-data-tree full-pith & sub-data)
    ;form.fr.g2.ac(method "post")
      ;input(type "hidden", name "op", value "put-data");
      ;input(type "hidden", name "view-pax", value pax);
      ;input.p-2.br2.bd1.mono.fs-2.grow
        =type  "text"
        =name  "sub-pax"
        =placeholder  "/sub/path"
        =spellcheck  "false"
        ;*  ~
      ==
      ;input.p-2.br2.bd1.mono.fs-2.grow
        =type  "text"
        =name  "value"
        =placeholder  "value (e.g. 42, 'hi', %tas)"
        =spellcheck  "false"
        =required  ""
        ;*  ~
      ==
      ;button.p-2.br2.bd1.b2.hover: insert
    ==
  ==
::
++  render-lens-views
  ::
  ::  one section listing every %lens view in the app, each showing
  ::  the lens's pith, all its metadata, and the data it currently
  ::  holds at that pith.
  ::
  |=  [our=ship dat=data cod=code vws=(map stem view)]
  ^-  manx
  =/  lenses=(list [stem view])
    %+  skim  ~(tap by vws)
    |=  [=stem =view]
    ?=(%lens -.view)
  ;section.fc.g2
    ;h2: %lenses
    ;div.fc.g3
      ;*
      =;  =marl  ?^  marl  marl
        ;=
          ;div.o6.fs-2: no %lens views in this app
        ==
      %+  turn  lenses
      |=  [=stem vw=view]
      (render-lens-row our dat cod stem vw)
    ==
  ==
::
++  render-lens-row
  ::
  ::  one row per %lens view: shows pith, metadata (sauc, dep, lyf,
  ::  cas, err, plus runtime life/case from the meta tree), and the
  ::  data entries currently stored under it.  read-only: lens output
  ::  is derived, not user-editable.
  ::
  |=  [our=ship dat=data cod=code =stem vw=view]
  ^-  manx
  ?>  ?=(%lens -.vw)
  =/  pax=tape  (pate stem)
  =/  full-pith=pith  (welp `pith`[p+our ~] stem)
  =/  sub-data=data  (~(dip do dat) full-pith)
  =/  count=@ud       ~(wyt do sub-data)
  =/  live=(unit meta)  (~(get ox cod) full-pith)
  =/  live-view=view
    ?:  ?&(?=(^ live) ?=(^ lord.u.live))
      view.u.lord.u.live
    vw
  ?>  ?=(%lens -.live-view)
  =/  dep-pax=tape  (pate (ref-to-pith dep.live-view))
  ;div.fc.g2.p3.bd1.br2.b2
    ;div.fr.g2.ac
      ;span.mono.bold: {pax}
      ;span.o6.fs-2: %lens
      ;span.o6.fs-2: ({(scow %ud count)})
    ==
    ;div.fc.g1.fs-2
      ;div.fr.g2
        ;span.o6: dep
        ;span.mono: {dep-pax}
      ==
      ;div.fr.g2
        ;span.o6: lyf
        ;span.mono: {(scow %ud lyf.live-view)}
        ;span.o6: cas
        ;span.mono: {(scow %ud cas.live-view)}
      ==
      ;+  ?~  live  ;/  ""
          ;div.fr.g2
            ;span.o6: life
            ;span.mono: {(scow %ud life.u.live)}
            ;span.o6: case
            ;span.mono: {(scow %ud case.u.live)}
          ==
      ;+  ?@  sauc.live-view
            ;details
              ;summary.o6: sauc (code)
              ;pre.pre.mono.scroll-x.p2.b3.br2: {(trip sauc.live-view)}
            ==
          ;div.fr.g2
            ;span.o6: sauc
            ;span.mono: {(pate (ref-to-pith sauc.live-view))}
          ==
      ;+  ?~  err.live-view  ;/  ""
          ;div.fc.g1
            ;span.o6: err
            ;+  (render-tang u.err.live-view)
          ==
      ;+  ?~  live  ;/  ""
          (render-lens-subs u.live)
    ==
    ;+  (render-data-tree full-pith | sub-data)
  ==
::
++  render-data-tree
  ::
  ::  recursive tree render of a $data subtree rooted at abs-pax.
  ::  each node shows its segment, the full leaf node (if any), and
  ::  a collapsible list of children.  uses datastar for the
  ::  expand/collapse toggle.  if .editable is set, each leaf gets
  ::  a small del-data form keyed on its absolute pith.
  ::
  |=  [abs-pax=pith editable=? root=data]
  ^-  manx
  =|  rel=pith
  =|  sug=(unit iota)
  =/  d  root
  |-
  ^-  manx
  =/  full-pith=pith   (welp abs-pax rel)
  =/  full-pith-t=@t   (crip (pate full-pith))
  =/  nude=(unit node)  leaf.d
  =/  has-leaf=?       ?=(^ nude)
  =/  kid-pairs=(list [iota _root])  (tap:modi kids.d)
  =/  has-kids=?       ?=(^ kid-pairs)
  =/  nid=tape         (uid full-pith)
  ;div.fc.bdl1.b2.pl2
    =data-signals  "\{'_open{nid}': true}"
    ;div.fr.g2.ac.p-2.b1.hover
      =data-on_click   "$_open{nid} = !$_open{nid}"
      =data-class_active  "$_open{nid}"
      ;span.mono.bold
        ;-
        ?~  sug  "/"
        (print-node-strict u.sug)
      ==
      ;+  ?.  has-leaf  ;/  ""
          ;span.o6.fs-2.mono: {(print-aura (need nude))}
      ;span.grow;
      ;+  ?.  has-kids  ;/  ""
          ;span.o6.fs-2: ({(scow %ud (lent kid-pairs))})
    ==
    ;div.fc.g1
      =data-show  "$_open{nid}"
      ;+  ?.  has-leaf  ;/  ""
          ;div.fr.g2.ac.p2.bd1.br2.b3
            ;div.mono.fs-2.pre.scroll-x.grow
              ;-  (print-node (need nude))
            ==
            ;+  ?.  editable  ;/  ""
                ;form(method "post")
                  ;input(type "hidden", name "op", value "del-data");
                  ;input(type "hidden", name "pax", value (trip full-pith-t));
                  ;button.p-2.br2.bd1.b3.hover.f-1: del
                ==
          ==
      ;+  ?.  has-kids  ;/  ""
          ;div.fc.g1.pl3
            ;*
            %+  turn  kid-pairs
            |=  [=iota next=_root]
            ^$(d next, rel (snoc rel iota), sug `iota)
          ==
    ==
  ==
::
++  render-lens-subs
  ::
  ::  one details element listing this lens's two subscriber sets:
  ::  subs (faucet listeners) and view-subs (code-link listeners).
  ::
  |=  =meta
  ^-  manx
  =/  faucet=(list pith)  ~(tap in subs.meta)
  =/  link=(list pith)    ~(tap in view-subs.meta)
  ;details
    ;summary.o6
      ;span: subs
      ;span.ml1: ({(scow %ud (lent faucet))})
      ;span.ml2: view-subs
      ;span.ml1: ({(scow %ud (lent link))})
    ==
    ;div.fc.g2.mt2
      ;div.fc.g1
        ;span.o6.fs-2: subs (faucet)
        ;+  ?~  faucet  ;span.o6.fs-2: ~
            ;div.fc.g1
              ;*
              %+  turn  faucet
              |=  p=pith
              ;span.mono.fs-2: {(pate p)}
            ==
      ==
      ;div.fc.g1
        ;span.o6.fs-2: view-subs (code links)
        ;+  ?~  link  ;span.o6.fs-2: ~
            ;div.fc.g1
              ;*
              %+  turn  link
              |=  p=pith
              ;span.mono.fs-2: {(pate p)}
            ==
      ==
    ==
  ==
--
