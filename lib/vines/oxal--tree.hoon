::  /ted/http-oxal  :  tree rendering of a $file
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
  =/  body  formencoded-body:vio
  =/  command  (fix-newlines (cat 3 (~(got by body) 'command') '\0a\0a'))
  =/  =cage
    =;  =(each cage tang)
      ?:  ?=(%.y -.each)  p.each
      %-  (slog p.each)
      :-  %do-move
      !>
      %-  silt
      :~  [%ins /error da+now.bowl]
      ==
    %-  mule  |.
    !<  cage
    %+  slap  !>(.)
    (ream command)
  ;<  ~  bind:m  (poke-our:vio cage)
  ;<  ~  bind:m
    %+  send-simple-payload:vio
      [303 ['location' (spat (welp [prefix rest]:bowl))]~]
    ~
  (pure:m !>(~))
::
;<  =acer  bind:m  (scry ,acer /gx/oxal/acer/noun)
::
=/  hymn=manx
  ::
  ;html
    ;head
      ;title: oxal
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
    ==
    ;body.p5.fc.g9.pb15
      ;h1: {(pate rest.bowl)}
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
      ;+  form-command
      ;div
        ;+
        =/  root-file  file.acer :: (~(dip fe file.acer) /[p+our.bowl])
        =|  sug=(unit iota)
        |-
        =/  meta  (fall leaf.code.root-file *meta)
        =/  nude  leaf.data.root-file
        =/  has-node  ?=(^ nude)
        =/  has-view  ?=(^ view.meta)
        ;div.fc
          ;+  %^  add-class-if  &(=(0 case.meta) !has-view)  "o2"
          ;details.br2.bd1.scroll-none
            ;+  (render-summary sug nude data.root-file meta)
            ;div.p2.bdt1.fc.g3
              ;+  (render-view meta)
              ;+  (render-bound meta)
              ;+  (render-subs subs.meta)
              ;+  (render-logs logs.meta)
            ==
          ==
          ;div.pl4.fc.pt2
            ;*
            %+  turn  ~(kid-list fe root-file)
            |=  [=iota =file]
            ^$(root-file file, sug `iota)
          ==
        ==
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
  |=  =meta
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
      ;form.fc.g2
        ;textarea.p3.pre.mono.br2.bd1.fs-2
          =name  "source"
          =rows  "8"
          =placeholder  ?^(view.meta "there was a view here" "no view yere")
          ;-  ?~  view.meta  ""
              ?@  code.u.view.meta
                (trip code.u.view.meta)
              %+  weld  "> "
              (pate (ref-to-pith source-ref.code.u.view.meta))
        ==
        ;button.p2.br2.bd1.b2.hover
          ; save
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
++  form-command
  ::
  ;div.fc.g3
    ;form.br3.bd1.mono.relative(method "post")
      ;textarea.pre.p3.fs-1.pb5.wf.focus.br3
        =id  "command"
        =name  "command"
        =spellcheck  "false"
        =rows  "10"
        =placeholder  "cage to poke to %oxal"
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
        :~  :-  'do-move'
            '''
            :-  %do-move  !>
            %-  sy
            :~
              :+  %ins  /beep  ud+12
            ==
            '''
          ::
            :-  'install'
            '''
            :-  %install  !>
            :-  /my-app
            ^-  source
            :-
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
            :*  dep=[~walrus-migrev-dolseg /bing/bong]
                lyf=0
                cas=0
                err=~
            ==
            '''
          ::
            :-  'install doubler'
            '''
            :-  %install  !>
            :-  /my-app
            ^-  source
            :-
            \0'''
            |=  [snap=data did=move life=@ud case=@ud]
            ^-  move
            =/  src=move
              ?.  =(~ did)  did
              %-  silt
              %+  turn  ~(tap do snap)
              |=  [pax=pith nod=node]
              ^-  chng
              [%ins pax nod]
            %-  silt
            %+  murn  ~(tap in src)
            |=  =chng
            ?-  -.chng
              %del  [~ chng]
              %ins
                ?.  ?=([%ud *] node.chng)  ~
                [~ chng(node ud+(mul 2 ud.node.chng))]
            ==
            \0'''
            :*  dep=[~walrus-migrev-dolseg /bing/bong]
                lyf=0
                cas=0
                err=~
            ==
            '''
          ::
            :-  'uninstall'
            '''
            :-  %uninstall  !>
            ^-  pith
            /my-app
            '''
          ::
            :-  'cull'
            '''
            :-  %cull  !>
            ^-  pith
            /bing
            '''
          ::
            :-  'set-grow'
            '''
            :-  %set-grow  !>
            ^-  [pith ?]
            :-  /my-path
            %.y
            '''
          ::
            :-  'set-eyre'
            '''
            :-  %set-eyre  !>
            ^-  [pith (unit auth)]
            :-  /my-path
            [~ %white ~]
            '''
          ::
            :-  'set-gall'
            '''
            :-  %set-gall  !>
            ^-  [pith (unit auth)]
            :-  /my-path
            [~ %white ~]
            '''
          ::
            :-  'hear-move'
            '''
            :-  %hear-move  !>
            ^-  [=ship pax=pith snap=data =move =life =case]
            :*  ~zod
                /boop
                %+  ~(put do *data)  /yeet  ud+99
                [%ins /yeet ud+99]
                0
                1
            ==
            '''
          ::
            :-  'wipe'  ':-  %wipe  !>(~)'
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
++  print-auth
  |=  =auth
  ^-  tape
  ;:  welp
    (trip -.auth)
    ":"
    <~(wyt in exceptions.auth)>
  ==
--
