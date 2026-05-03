::  /ted/http-oxal--app  :  detail page for a single app
::
::    GET   /oxal/app/<name>   show one app's source, computed views, data tree
::    POST  /oxal/app/<name>   datastar @post ops:
::                               %update-app, %put-data, %del-data
::                             returns SSE element-patches when the request
::                             carries datastar-request: true; falls back to
::                             a 303 redirect for plain form submits.
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
=/  is-ds=?
  =((get-header:http 'datastar-request' header-list.bowl) `'true')
::
?:  =('POST' method.bowl)
  =/  form=(map @t @t)  formencoded-body:vio
  =/  op=@t  (~(gut by form) 'op' '')
  ::
  ::  apply the requested op (best-effort; unknown op is a no-op).
  ::
  ;<  ~  bind:m
    ?:  =('put-data' op)
      =/  view-cord=@t  (~(gut by form) 'view-pax' '')
      =/  sub-cord=@t   (~(gut by form) 'sub-pax' '')
      =/  seg-cord=@t   (~(gut by form) 'seg' '')
      =/  value=@t      (~(gut by form) 'value' '')
      =/  view-pith=pith  (cord-to-pith view-cord)
      =/  sub-pith=pith
        ?:  =('' sub-cord)  ~
        (cord-to-pith sub-cord)
      =/  seg-pith=pith
        ?:  =('' seg-cord)  ~
        (cord-to-pith seg-cord)
      =/  full-pith=pith  :(welp view-pith sub-pith seg-pith)
      =/  =node  (cord-to-node value)
      =/  =move  (silt ~[[%ins full-pith node]])
      (poke-our:vio %do-move !>(move))
    ?:  =('del-data' op)
      =/  pax-cord=@t  (~(gut by form) 'pax' '')
      =/  full-pith=pith  (cord-to-pith pax-cord)
      =/  =move  (silt ~[[%del full-pith]])
      (poke-our:vio %do-move !>(move))
    ?:  =('update-app' op)
      =/  name=term   `@tas`(~(gut by form) 'name' '')
      =/  source=@t   (fix-newlines (~(got by form) 'source'))
      (poke-our:vio %update-app !>([name source]))
    (sleep ~s0)
  ::
  ?.  is-ds
    ::  no-js / non-datastar fallback: bounce back to ourselves.
    ::
    ;<  ~  bind:m
      %+  send-simple-payload:vio
        [303 ['location' (spat (welp [prefix rest]:bowl))]~]
      ~
    (pure:m !>(~))
  ::
  ::  datastar response: re-fetch state, patch the detail body in place.
  ::
  ;<  =acer  bind:m  (scry ,acer /gx/oxal/acer/noun)
  =/  name=@ta  ?~(rest.bowl '' i.rest.bowl)
  =/  found=(unit app)  (find-app apps.acer name)
  =/  this-url=tape  (trip (spat (welp [prefix rest]:bowl)))
  =/  body-manx=manx
    (render-body this-url name our.bowl data.file.acer code.file.acer found)
  ;<  ~  bind:m
    %+  send-head:vio  200
    :~  ['content-type' 'text/event-stream']
        ['cache-control' 'no-cache']
        ['connection' 'keep-alive']
    ==
  ;<  ~  bind:m
    %-  send-data:vio
    %-  some
    %-  as-octs:mimes:html
    %+  datastar-response-body  ~
    ~[["outer" `"#detail-body" body-manx]]
  ;<  ~  bind:m  send-kick:vio
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
=/  this-url=tape  (trip (spat (welp [prefix rest]:bowl)))
;<  ~  bind:m
  %-  send-simple-payload:vio
  %+  node-to-simple-payload  %manx
  (render-detail this-url name our.bowl data.file.acer code.file.acer found)
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
::  datastar attribute helpers.  these wrap +add-attribute so the
::  attribute names that contain `:` (e.g. `data-on:click`) round-trip
::  through manx without manx-syntax issues.
::
++  ds-on
  ::
  ::  attach a `data-on:<event>` handler.  `event` may include
  ::  modifiers, e.g. "submit__prevent", "click__stop".
  ::
  |=  [event=tape expr=tape =manx]
  ^+  manx
  %+  add-attribute  [(crip (weld "data-on:" event)) expr]
  manx
::
++  ds-signals
  ::
  ::  attach a `data-signals` declaration.
  ::
  |=  [expr=tape =manx]
  ^+  manx
  (add-attribute ['data-signals' expr] manx)
::
++  ds-show
  ::
  ::  attach a `data-show` toggle.
  ::
  |=  [expr=tape =manx]
  ^+  manx
  (add-attribute ['data-show' expr] manx)
::
++  ds-class
  ::
  ::  attach a `data-class:<name>` toggle.
  ::
  |=  [class=tape expr=tape =manx]
  ^+  manx
  %+  add-attribute  [(crip (weld "data-class:" class)) expr]
  manx
::
++  ds-form-post
  ::
  ::  intercept this form's submit and post it through datastar
  ::  so the server can stream back element-patches.
  ::
  |=  [url=tape =manx]
  ^+  manx
  %^  ds-on  "submit"
    "@post('{url}', \{contentType: 'form'})"
  manx
::
++  render-detail
  ::
  ::  detail page: nav crumb, then either the app body or a notice.
  ::
  |=  [this-url=tape name=@ta our=ship dat=data cod=code found=(unit app)]
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
      ;+  (render-body this-url name our dat cod found)
    ==
  ==
::
++  render-body
  ::
  ::  the detail-body root.  always carries id="detail-body" so SSE
  ::  responses can replace this subtree wholesale.
  ::
  |=  [this-url=tape name=@ta our=ship dat=data cod=code found=(unit app)]
  ^-  manx
  ?~  found
    ;div#detail-body.p5.bd1.br2.o6
      ;span: no app named
      ;span.bold.mono: {(trip name)}
    ==
  (render-detail-body this-url name our dat cod u.found)
::
++  render-detail-body
  ::
  ::  body of the detail page: error, source, %forms, %lenses.
  ::
  |=  [this-url=tape name=@ta our=ship dat=data cod=code =app]
  ^-  manx
  ;div#detail-body.fc.g5
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
        ;+
        %+  ds-form-post  this-url
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
    ;+  (render-namespace-views this-url name our dat cod)
    ;+  (render-form-views this-url our dat cod views.app)
    ;+  (render-lens-views this-url our dat cod views.app)
  ==
::
++  render-namespace-views
  ::
  ::  one section showing the locals subtree (/~/<name>) — the $data
  ::  tree that feeds into the app-gate when an app is installed or
  ::  reinstalled.  rendered the same way as %form views: pith, data
  ::  tree, put-data form.
  ::
  |=  [this-url=tape name=@ta our=ship dat=data cod=code]
  ^-  manx
  =/  locals-stem=pith   ~[[%n ~] (cord-to-iota name)]
  ;section.fc.g2
    ;h2: namespace
    ;div.fc.g3
      ;+  (render-namespace-row this-url "%locals" our dat cod locals-stem)
    ==
  ==
::
++  render-namespace-row
  ::
  ::  one row per namespace subtree: shows the bare pith, label, count,
  ::  then the data tree and a put-data form.  same shape as
  ::  render-form-row but with a customizable label and no lord-meta
  ::  lookup (these subtrees are not view roots).
  ::
  |=  [this-url=tape label=tape our=ship dat=data cod=code =stem]
  ^-  manx
  =/  pax=tape  (pate stem)
  =/  full-pith=pith  (welp `pith`[p+our ~] stem)
  =/  sub-data=data   (~(dip do dat) full-pith)
  =/  count=@ud       ~(wyt do sub-data)
  =/  live=(unit meta)  (~(get ox cod) full-pith)
  ;div.fc.g2.p3.bd1.br2.b2
    ;div.fr.g2.ac
      ;span.mono.bold: {pax}
      ;span.o6.fs-2: {label}
      ;span.o6.fs-2: ({(scow %ud count)})
    ==
    ;+  ?~  live  ;/  ""
        (render-lens-subs u.live)
    ;+  (render-data-tree this-url full-pith stem & sub-data)
    ;+
    %+  ds-form-post  this-url
    ;form.fr.g2.ac(method "post")
      ;input(type "hidden", name "op", value "put-data");
      ;input(type "hidden", name "view-pax", value pax);
      ;input.p-2.br2.bd1.mono.fs-2.grow
        =type  "text"
        =name  "sub-pax"
        =placeholder  "/sub/path (optional)"
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
++  render-form-views
  ::
  ::  one section listing every %form view in the app, each with a
  ::  data tree and a put-data form.
  ::
  |=  [this-url=tape our=ship dat=data cod=code vws=(map stem view)]
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
      (render-form-row this-url our dat cod stem)
    ==
  ==
::
++  render-form-row
  ::
  ::  one row per %form view: shows the view's pith, the data tree
  ::  rooted at it, then a form for inserting a new node at a
  ::  sub-path.
  ::
  |=  [this-url=tape our=ship dat=data cod=code =stem]
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
    ;+  (render-data-tree this-url full-pith stem & sub-data)
    ;+
    %+  ds-form-post  this-url
    ;form.fr.g2.ac(method "post")
      ;input(type "hidden", name "op", value "put-data");
      ;input(type "hidden", name "view-pax", value pax);
      ;input.p-2.br2.bd1.mono.fs-2.grow
        =type  "text"
        =name  "sub-pax"
        =placeholder  "/sub/path (optional)"
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
  |=  [this-url=tape our=ship dat=data cod=code vws=(map stem view)]
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
      (render-lens-row this-url our dat cod stem vw)
    ==
  ==
::
++  render-lens-row
  ::
  ::  one row per %lens view: shows pith, metadata, and the current
  ::  derived data subtree.  read-only.
  ::
  |=  [this-url=tape our=ship dat=data cod=code =stem vw=view]
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
    ;+  (render-data-tree this-url full-pith stem | sub-data)
  ==
::
++  render-data-tree
  ::
  ::  recursive tree render of a $data subtree rooted at abs-pax,
  ::  scoped to the %form view at view-stem.  each node row shows
  ::  segment, leaf preview (when present), and child count.
  ::  toggling a row expands to show full leaf, controls, and
  ::  children.  if .editable is set, each row gets a delete control
  ::  (for leaves) and an inline add-child form.  the root level
  ::  starts expanded; deeper levels start collapsed.
  ::
  |=  [this-url=tape abs-pax=pith view-stem=stem editable=? root=data]
  ^-  manx
  =/  view-pax-cord=@t  (crip (pate view-stem))
  ::  empty-state at the form root.
  ::
  ?:  ?&  ?=(~ leaf.root)
          =(~ (tap:modi kids.root))
      ==
    ;div.fr.g2.ac.p3.bd1.br2.b3.o6.fs-2
      ;span: no data yet
      ;+  ?.  editable  ;/  ""
          ;span: — insert below
    ==
  =|  rel=pith
  =|  sug=(unit iota)
  =/  d  root
  |-
  ^-  manx
  =/  full-pith=pith    (welp abs-pax rel)
  ::  bare path: omit the leading [p our] ingress-do-move prepends.
  ::
  =/  bare-pith=pith    (welp view-stem rel)
  =/  bare-pith-cord=@t  (crip (pate bare-pith))
  =/  rel-cord=@t       (crip (pate rel))
  =/  nude=(unit node)  leaf.d
  =/  has-leaf=?        ?=(^ nude)
  =/  kid-pairs=(list [iota _root])  (tap:modi kids.d)
  =/  has-kids=?        ?=(^ kid-pairs)
  =/  is-root=?         ?=(~ rel)
  =/  nid=tape          (uid full-pith)
  =/  open-init=tape    ?:(is-root "true" "false")
  =/  preview=tape
    ?~  nude  ""
    (scag 60 (print-node u.nude))
  ;div.fc.bdl1.b2.pl2
    =data-signals
      "\{'_open{nid}': {open-init}, '_add{nid}': false}"
    ;+
    %^  ds-class  "active"  "$_open{nid}"
    %^  ds-on     "click"   "$_open{nid} = !$_open{nid}"
    ;div.fr.g2.ac.p-2.b1.hover
      ;span.mono.bold
        ;-
        ?~  sug  "/"
        (print-node-strict u.sug)
      ==
      ;+  ?.  has-leaf  ;/  ""
          ;span.o6.fs-2.mono
            ;-  (weld "%" (print-aura (need nude)))
          ==
      ;+  ?.  has-leaf  ;/  ""
          ;span.mono.fs-2.scroll-x.grow.preview: {preview}
      ;+  ?:  has-leaf  ;/  ""
          ;span.grow;
      ;+  ?.  has-kids  ;/  ""
          ;span.o6.fs-2: ({(scow %ud (lent kid-pairs))})
    ==
    ;+
    %+  ds-show  "$_open{nid}"
    ;div.fc.g1
      ::  expanded leaf detail + delete control.
      ::
      ;+  ?.  has-leaf  ;/  ""
          ;div.fr.g2.ac.p2.bd1.br2.b3
            ;div.mono.fs-2.pre.scroll-x.grow
              ;-  (print-node (need nude))
            ==
            ;+  ?.  editable  ;/  ""
                %+  ds-form-post  this-url
                ;form(method "post")
                  ;input(type "hidden", name "op", value "del-data");
                  ;input
                    =type  "hidden"
                    =name  "pax"
                    =value  (trip bare-pith-cord)
                    ;*  ~
                  ==
                  ;button.p-2.br2.bd1.b3.hover.f-1: del
                ==
          ==
      ::  add-child toggle + inline form.
      ::
      ;+  ?.  editable  ;/  ""
          ;div.fc.g1
            ;div.fr.g2.ac
              ;+
              %^  ds-on  "click"  "$_add{nid} = !$_add{nid}"
              ;button.p-2.br2.bd1.b2.hover.fs-2: + add child
            ==
            ;+
            %+  ds-show  "$_add{nid}"
            %+  ds-form-post  this-url
            ;form.fr.g2.ac(method "post")
              ;input(type "hidden", name "op", value "put-data");
              ;input
                =type  "hidden"
                =name  "view-pax"
                =value  (trip view-pax-cord)
                ;*  ~
              ==
              ;input
                =type  "hidden"
                =name  "sub-pax"
                =value  (trip rel-cord)
                ;*  ~
              ==
              ;input.p-2.br2.bd1.mono.fs-2
                =type  "text"
                =name  "seg"
                =placeholder  "segment (e.g. /foo)"
                =spellcheck  "false"
                =required  ""
                ;*  ~
              ==
              ;input.p-2.br2.bd1.mono.fs-2.grow
                =type  "text"
                =name  "value"
                =placeholder  "value"
                =spellcheck  "false"
                =required  ""
                ;*  ~
              ==
              ;button.p-2.br2.bd1.b2.hover.fs-2: insert
            ==
          ==
      ::  recurse into kids.
      ::
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
