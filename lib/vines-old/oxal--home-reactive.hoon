::  attempt to make a reactive renderer with fully cached state
::  fat morph without full re-render
::
::  STATUS: BROKEN
::
::
/+  *vineio
::
=<
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
?:  =(method.bowl 'POST')
  ::
  =/  body  formencoded-body:vio
  :: =/  =cage  (body-to-cage:render body now.bowl)
  :: ;<  ~  bind:m  (poke-our:vio cage)
  ;<  ~  bind:m  (send-simple-payload:vio [200 ~] ~)
  (pure:m !>(~))
::
?>  =(method.bowl 'GET')
?.  .=  `'true'  (get-header:http 'datastar-request' header-list.bowl)
  ::
  ;<  ~  bind:m
    %-  send-simple-payload:vio
    %+  node-to-simple-payload  %manx
    ;html
      ;head
        ;title: oxal viewer
        ;meta(charset "utf-8");
        ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
        ;script(type "module", src "/hawk-init/feather/1/textarea");
        ;script(type "module", src "/hawk-init/feather/1/text-editor");
        ;script(type "module", src "/hawk-init/feather/1/datastar");
        ;link(rel "icon", href "data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\"/>");
      ==
      ;body
        =data-init  "@get('{(pate (welp [prefix rest]:bowl))}')"
        ;div#top
          ; initializing
        ==
      ==
    ==
  ::
  (pure:m !>(~))
::
::
=/  sub=wire  (welp #/both rest.bowl)
;<  nope=(unit tang)  bind:m  (soft-watch-our:vio sub sub)
?^  nope
  ;<  ~  bind:m
    %+  send-simple-payload:vio  [200 ['content-type' 'text/html']~]
    :-  ~
    %-  as-octt:mimes:html
    %-  en-xml:html
    ;div#top.p5
      ;+  (render-tang u.nope)
    ==
  (pure:m !>(~))
;<  ~  bind:m
  %+  send-head:vio  200
  :~  ['content-type' 'text/event-stream']
      ['cache-control' 'no-cache']
      ['connection' 'keep-alive']
  ==
::
=|  local=acer
::
=.  local
  =<  +
  =<  abet
  %-  ~(ingress-install ae [local our.bowl | |])
  =-  [/rendered - [our.bowl /raw]]
  '''
  |=  [mine=data snap=data =move *]
  ^+  move
  %-  silt
  :~  :+  %ins  /
        :-  %manx
        ;div
          ;div
            ;*
            =;  =marl  ?^  marl  marl
              ;=
                ;div: no file
              ==
            %+  turn  ~(tap do snap)
            |=  [=pith =node]
            ;div: {(pate pith)}
          ==
        ==
  ==
  '''
::
|-  ::  outer: (re)arm the 25s timer
;<  now=@da  bind:m  get-time
=/  until=@da  (add now ~s25)
;<  ~  bind:m  (send-wait until)
::
|-  ::  inner: drain facts until the timer fires
;<  ev=event  bind:m  (take-fact-or-wake sub until)
?-  -.ev
  :::
  %kick
    ::
    ;<  ~  bind:m
      %-  send-data:vio
      %-  sse-body-swap
      ;div
        ; kicked
      ==
    ;<  ~  bind:m  send-kick:vio
    (pure:m !>(~))
  ::
  %fact
    ::
    =.  local  (consume-cage local our.bowl cage.ev)
    ;<  ~  bind:m
      %-  send-data:vio
      %-  sse-body-swap
      =/  render-pith  #/[p+our.bowl]/rendered
      %+  fall  (~(tet do data.file.local) %manx render-pith)
      ;div
        ;div: no rendering at {(pate render-pith)}
        ;div: {<now.bowl>}
      ==
    $
  ::
  %wake
    ::
    ;<  ~  bind:m
      %-  send-data:vio
      (sse-data "keepalive")
    ^$
  ::
==
::
|%
+$  event  $%([%fact =cage] [%wake ~] [%kick ~])
::
++  consume-cage
  |=  [local=acer our=@p fact=cage]
  ^+  local
  ?+    p.fact
    :::
      ~&  unknown-cage-to-consume/-.fact
      local
    ::
    %oxal-snap
      ::
      =+  !<([snap=data =move =life =case] q.fact)
      ~&  heard-oxal-snap/move
      =<  +
      =<  abet
      %-  ~(ingress-hear-remote ae [local our | |])
      [our /raw snap move life case]
      ::
    %oxal-code
      ::
      =+  !<([snap=code =meta-move =life =case] q.fact)
      ~&  heard-oxal-code/meta-move
      =<  +
      =<  abet
      %-  ~(ingress-hear-remote-code ae [local our | |])
      [our /raw snap meta-move life case]
      ::
  ==
::
++  take-fact-or-wake
  ::
  ::  unblock on either a %fact on +wire or a %wake for +until
  ::
  |=  [=wire until=@da]
  =/  m  (strand ,event)
  ^-  form:m
  |=  tin=strand-input:strand
  ?+    in.tin  `[%skip ~]
    :::
    ~  `[%wait ~]
    ::
    [~ %agent * %fact *]
      ::
      ?.  =(watch+wire wire.u.in.tin)
        `[%skip ~]
      `[%done %fact cage.sign.u.in.tin]
    ::
    [~ %agent * %kick ~]
      ::
      ?.  =(watch+wire wire.u.in.tin)
        `[%skip ~]
      `[%done %kick ~]
    ::
    [~ %sign [%wait @ ~] %behn %wake *]
      ::
      ?.  =((scot %da until) i.t.wire.u.in.tin)
        `[%skip ~]
      `[%done %wake ~]
    ::
  ==
::
++  sse-data
  ::
  ::  encode a tape as one SSE event, splitting \0a into separate data: lines
  ::
  |=  text=tape
  ^-  (unit octs)
  :-  ~
  %-  as-octt:mimes:html
  %+  weld  (predent "data: " text)
  "\0a\0a"
::
++  sse-body-swap
  |=  body=manx
  ^-  (unit octs)
  :-  ~
  %-  as-octt:mimes:html
  ^-  tape
  ;:  welp
    "event: datastar-patch-elements"
    "\0a"
    (predent "data: elements " (en-xml:html (set-attribute %id `"top" body)))
    "\0a\0a"
  ==
--