/+  *vineio
::
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
;<  =acer  bind:m  (scry ,acer /gx/oxal/acer/noun)
=/  app-name=@tas  ~|  %not-found  (head rest.bowl)
=/  =app  (got-app acer app-name)
::
|^
  :::
  ?:  =('POST' method.bowl)
    =/  body=(map @t @t)  formencoded-body:vio
    =/  op=@t  (~(got by body) 'op')
    ;<  ~  bind:m
      ?:  =('set-source' op)
        ::
        =/  source=@t   (fix-newlines (~(got by body) 'source'))
        (poke-our:vio %update-app !>([app-name source]))
      !!
    =/  is-ds=?
      =((get-header:http 'datastar-request' header-list.bowl) `'true')
    ?.  is-ds  ~|  %not-datastar  !!
    ;<  ax=^acer  bind:m  (scry ,^acer /gx/oxal/acer/noun)
    =.  acer  ax
    ;<  ~  bind:m
      %-  send-simple-payload:vio
      :-  [200 ['content-type' 'text/html']~]
      :-  ~
      %-  as-octt:mimes:html
      %-  en-xml:html
      part-file
    (pure:m !>(~))
  ::
  ;<  ~  bind:m
    %-  send-simple-payload:vio
    (node-to-simple-payload manx+hymn)
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
  ^-  manx
  ;div#file: the file {<now.bowl>}
::
--