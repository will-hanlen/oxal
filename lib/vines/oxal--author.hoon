::  /ted/http-oxal--author  :  authoring ui for oxal views
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
;<  our=ship  bind:m  (scry ,ship /gx/oxal/our/noun)
::
?:  =('POST' method.bowl)
  =/  body  formencoded-body:vio
  =/  =cage  (body-to-cage body our now.bowl)
  ;<  ~  bind:m  (poke-our:vio cage)
  ;<  ~  bind:m
    %+  send-simple-payload:vio
      [303 ['location' (spat (welp [prefix rest]:bowl))]~]
    ~
  (pure:m !>(~))
::
=/  views=(list (pair pith meta))
  %+  skim  ~(tap ox code.file.acer)
  |=  [=pith =meta]  ?=(^ view.meta)
::
=/  hymn=manx
  ;html
    ;head
      ;title: oxal author
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
    ==
    ;body.p5.fc.g9.pb15
      ;h1: author
      ;+  (render-compose our)
      ;h2: existing views
      ;+  (render-views views)
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
++  render-compose
  ::
  ::  top-of-page form for installing a new view.  three user inputs
  ::  (install path, dep ship, dep pith) plus a source textarea.
  ::
  |=  our=ship
  ^-  manx
  ;details(open "")
    ;summary: compose new view
    ;div.fc.g3.p2
      ;form.fc.g2(method "post")
        ;input(type "hidden", name "op", value "install");
        ;label.fr.g2.ac
          ;span: install path
          ;input.p-2.br2.bd1.mono.grow
            =type  "text"
            =name  "pax"
            =placeholder  "/my-view"
            =required  ""
            =spellcheck  "false"
            =value  ""
            ;*  ~
          ==
        ==
        ;label.fr.g2.ac
          ;span: dep ship
          ;input.p-2.br2.bd1.mono
            =type  "text"
            =name  "ship"
            =placeholder  (weld "~" (scow %p our))
            =spellcheck  "false"
            =value  (weld "~" (scow %p our))
            ;*  ~
          ==
          ;span: dep pith
          ;input.p-2.br2.bd1.mono.grow
            =type  "text"
            =name  "dep"
            =placeholder  "/some/pith"
            =required  ""
            =spellcheck  "false"
            =value  "/"
            ;*  ~
          ==
        ==
        ;label.fc.g2
          ;span: source (transformer)
          ;textarea.p3.pre.mono.br2.bd1.fs-2
            =name  "source"
            =rows  "12"
            =placeholder  "|=  [snap=data did=move life=@ud case=@ud]\0a^-  move\0adid"
            =required  ""
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
++  render-views
  ::
  ::  list of all currently-installed views.  each row expands to show
  ::  the view source and per-view controls.
  ::
  |=  views=(list (pair pith meta))
  ^-  manx
  ;div.fc.g3
    ;+  ?^  views  ;/  ""
        ;div.o6: no views installed
    ;*
    %+  turn  views
    |=  [pax=pith =meta]
    (render-view-row pax meta)
  ==
::
++  render-view-row
  ::
  ::  a single view row: summary with badges, expandable inline
  ::  reinstall form, and uninstall / bump controls.
  ::
  |=  [pax=pith =meta]
  ^-  manx
  =/  pax-t=@t  (crip (pate pax))
  =/  src=source  (need view.meta)
  =/  has-err  ?=(^ err.src)
  =/  code-t=@t
    ?@  code.src  code.src
    (crip (weld "> " (pate (ref-to-pith source-ref.code.src))))
  ;details.br2.bd1
    ;summary.p2.fr.g3.ac
      ;+  %+  add-class  ?:(has-err "f-1" "f-3")
          ;span.bold
            ;-  (pate pax)
          ==
      ;span.o6.f5
        ;-  "> "
        ;-  (scow %p ship.dep.src)
        ;-  (pate pith.dep.src)
      ==
      ;span.grow;
      ;span.o6.f5: L{<lyf.src>}
      ;span.o6.f5: C{<cas.src>}
      ;+  ?.  has-err  ;/  ""
          ;span.bold.f-1: err
    ==
    ;div.p3.fc.g3.bdt1
      ;+  ?.  has-err  ;/  ""  (render-tang err.src)
      ;form.fc.g2(method "post")
        ;input(type "hidden", name "op", value "install");
        ;input(type "hidden", name "pax", value (trip pax-t));
        ;label.fr.g2.ac
          ;span: dep ship
          ;input.p-2.br2.bd1.mono
            =type  "text"
            =name  "ship"
            =spellcheck  "false"
            =value  (weld "~" (scow %p ship.dep.src))
            ;*  ~
          ==
          ;span: dep pith
          ;input.p-2.br2.bd1.mono.grow
            =type  "text"
            =name  "dep"
            =spellcheck  "false"
            =value  (pate pith.dep.src)
            ;*  ~
          ==
        ==
        ;label.fc.g2
          ;span: source
          ;textarea.p3.pre.mono.br2.bd1.fs-2
            =name  "source"
            =rows  "12"
            ;-  (trip code-t)
          ==
        ==
        ;div.fr.g2
          ;button.p-2.br2.bd1.b2.hover: reinstall
        ==
      ==
      ;div.fr.g2
        ;form(method "post")
          ;input(type "hidden", name "op", value "bump");
          ;input(type "hidden", name "pax", value (trip pax-t));
          ;button.p-2.br2.bd1.b2.hover: bump
        ==
        ;form(method "post")
          ;input(type "hidden", name "op", value "uninstall");
          ;input(type "hidden", name "pax", value (trip pax-t));
          ;button.p-2.br2.bd1.b2.hover: uninstall
        ==
      ==
    ==
  ==
::
++  body-to-cage
  ::
  ::  build a cage from a decoded form body keyed by 'op'.  supports
  ::  install, uninstall, bump.  on install, dep ship defaults to our
  ::  if the field is blank or unparseable.
  ::
  |=  [body=(map @t @t) our=ship now=@da]
  ^-  cage
  =/  op=@t  (fall (~(get by body) 'op') 'noop')
  ?:  =(op 'install')
    =/  pax=pith  (cord-to-pith (~(got by body) 'pax'))
    =/  dep-pith=pith  (cord-to-pith (~(got by body) 'dep'))
    =/  ship-t=@t  (fall (~(get by body) 'ship') '')
    =/  dep-ship=ship
      ?:  =(ship-t '')  our
      =/  parsed=(each ship tang)
        %-  mule  |.  `ship`(slav %p ship-t)
      ?:  ?=(%.y -.parsed)  p.parsed
      %-  (slog leaf+"author: bad ship, defaulting to our" p.parsed)
      our
    =/  src=@t  (fix-newlines (~(got by body) 'source'))
    [%install !>([pax `source-code`src [dep-ship dep-pith]])]
  ?:  =(op 'uninstall')
    =/  pax=pith  (cord-to-pith (~(got by body) 'pax'))
    [%uninstall !>(pax)]
  ?:  =(op 'bump')
    =/  pax=pith  (cord-to-pith (~(got by body) 'pax'))
    [%bump !>(pax)]
  ~|  bad-op+op
  !!
::
--
