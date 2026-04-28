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
  ;div#file.p4
    ;+
    %-  render-file
    %-  ~(partial fe file.ax)
    ~(key by views.app)
  ==
::
++  render-file
  ::
  =|  sug=(unit iota)
  =|  pax=pith
  |_  fap=file
  ++  $  level
  ++  level
    ^-  manx
    ;div
      ;+  part-row
      ;+  part-kids
    ==
  ::
  ++  render-node
    |=  =node
    ;span.fr.g2
      ;+  ?@  node  ;span:"%"
          ;span.fs-2.f4: {(print-aura node)}:
      ;span: {(print-node node)}
    ==
  ::
  ++  part-row
    ^-  manx
    ;div.fr.g2
      ;span
        ;+  ?~  sug  ;span:"/"
            (render-node u.sug)
      ==
    ==
  ::
  ::
  ++  part-kids
    ^-  manx
    ;div.pl4
      ;*
      %+  turn  ~(kid-list fe fap)
      |=  [=iota =file]
      level(sug `iota, pax (snoc pax iota), fap file)
    ==
  ::
  --
::
--