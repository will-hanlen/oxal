/+  *vineio
::
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
;<  ax=acer  bind:m  (scry ,acer /gx/oxal/acer/noun)
=/  app-name=@tas  ~|  %not-found  (head rest.bowl)
=/  =app  (got-app ax app-name)
::
|^
  :::
  ?:  =('POST' method.bowl)
    =/  body=(map @t @t)  formencoded-body:vio
    =/  op=@tas           (~(got by body) 'op')
    =/  is-ds=?           =((get-header:vio 'datastar-request') `'true')
    =/  route             [is-ds op]
    ::
    ?+  route  ~|  route-not-found/route  !!
      :::
      [%.y %set-source]
        ::
        =/  source=@t   (fix-newlines (~(got by body) 'source'))
        ;<  ~  bind:m  (poke-our:vio %update-app !>([app-name source]))
        ;<  new-ax=acer  bind:m  (scry ,acer /gx/oxal/acer/noun)
        =.  ax  new-ax
        =.  app  (got-app ax app-name)
        ;<  ~  bind:m  (send-html-payload:vio part-file)
        (pure:m !>(~))
      ::
    ==
  ::
  ;<  ~  bind:m  (send-html-payload:vio hymn)
  ::
  (pure:m !>(~))
::
++  post  "@post('{(pate (welp [prefix rest]:bowl))}', \{contentType: 'form'})"
::
++  hymn
  ::
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
      ;title: {(trip app-name)}
      ;link(rel "icon", href "data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\"/>");
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
      ;script(type "module", src "/hawk-init/feather/1/textarea");
      ;script(type "module", src "/hawk-init/feather/1/text-editor");
      ;script(type "module", src "/hawk-init/feather/1/slide-panels");
      ;script(type "module", src "/hawk-init/feather/1/datastar");
    ==
    ;body.fc.bbv
      ;+  part-header
      ;feather-slide-panels
        ;+  part-file
        ;+  part-source 
      ==
    ==
  ==
  ::
::
++  part-header
  ::
  ^-  manx
  ;header.fr.af.bbh.mono.b2
    ;a.b2.f3.hover.p-3
      =href  "/oxal/apps"
      ; <
    ==
    ;strong.grow.p-3: {"%"}{(trip app-name)}
    ;button.p-3.b2.f-3.hover
      =data-on_click  "$edit = !$edit"
      =data-class_toggled  "$edit"
      ; edit
    ==
  ==
  ::
::
++  part-error
  ::
  ^-  manx
  ?~  error.app  ;/  ""
  ;div
    ;+  (render-tang u.error.app)
  ==
::
++  part-source
  ::
  ^-  manx
  ;form.hf.fc.grow.bbv.scroll-none
    =data-show  "$edit"
    =data-on_submit  post
    =data-indicator  "_savesource"
    =data-class_o7  "$_savesource"
    ;+  part-error
    ;input(type "hidden", name "op", value "set-source");
    ;feather-text-editor.grow.fs-1
      =auto-indent  ""
      =name  "source"
      ;-  (trip source.app)
    ==
    ;button.p3.b3.hover
      =data-attr_disabled  "$_savesource"
      ; save
    ==
  ==
::
++  part-file
  ::
  =/  partial=file
    %-  ~(partial fe file.ax)
    %-  ~(run in ~(key by views.app))
    |=  =pith
    [p+our.bowl pith]
  ;div#file.p4.fc.grow.hf.scroll-always
    :: ;div.f6
    ::   :: ;div: {<~(key by views.app)>}
    ::   ;*
    ::   %+  turn  ~(tap ox code.partial)
    ::   |=  [=pith =meta]
    ::   :: ?~  lord.meta  ~
    ::   :: :-  ~
    ::   ;div.fr.g2
    ::     ;div: {(pate pith)}
    ::     ;div: {<lord.meta>}
    ::   ==
    ::   ::
    ::   ;div: end
    :: ==
    ;+
    %-  render-file
    partial
  ==
::
++  render-file
  :::
  =|  sug=(unit iota)
  =|  pax=pith
  =|  under-view=_|
  =|  under-lens=_|
  =|  under-form=_|
  =|  at-view=_|
  =|  at-lens=_|
  =|  at-form=_|
  =|  cod=code
  =|  dat=data
  |_  fap=file
  ++  $  level
  ::
  ++  level
    ::
    ^-  manx
    ;div
      ;+  part-row
      ;+  part-kids
    ==
  ::
  ++  render-node
    ::
    |=  =node
    ;span.fr.ae
      ;+  ?@  node  ;span.fs-2.o6:"%"
          ;span.fs-2.o6: {(print-aura node)}:
      ;span: {(print-node node)}
    ==
  ::
  ++  part-row
    ::
    ^-  manx
    ;div.fr.g2
      ;+  %^  add-class-if  under-lens  "f-4"
          %^  add-class-if  under-form  "f-3"
          %^  add-class-if  at-view  "bold"
      ;span
        ;+  ?~  sug  ;span:"/"
            (render-node u.sug)
      ==
    ==
  ::
  ++  part-kids
    ::
    ^-  manx
    ;div.pl4
      ;*
      %+  turn  ~(kid-list fe fap)
      |=  [=iota =file]
      =/  node-meta=meta  (fall leaf.code.file *meta)
      =/  at-view     ?=(^ lord.node-meta)
      =/  at-lens     &(?=(^ lord.node-meta) ?=(%lens -.view.u.lord.node-meta))
      =/  at-form     &(?=(^ lord.node-meta) ?=(%form -.view.u.lord.node-meta))
      %=  level
        sug  `iota
        pax  (snoc pax iota)
        at-view  at-view
        at-lens  at-lens
        at-form  at-form
        under-view  |(under-view at-view)
        under-lens  |(under-lens at-lens)
        under-form  |(under-form at-form)
        fap  file
      ==
    ==
  ::
  --
::
--