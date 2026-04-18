::  /ted/http-oxal--sse-sub  :  SSE stream of %oxal subs facts + 25s keepalive
::
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
=/  sub=wire  [%sub rest.bowl]
::
;<  ~  bind:m  (watch sub [our.bowl %oxal] sub)
;<  ~  bind:m
  %+  send-head:vio  200
  :~  ['content-type' 'text/event-stream']
      ['cache-control' 'no-cache']
      ['connection' 'keep-alive']
  ==
|-  ::  outer: (re)arm the 25s timer
;<  now=@da  bind:m  get-time
=/  until=@da  (add now ~s25)
;<  ~  bind:m  (send-wait until)
|-  ::  inner: drain facts until the timer fires
;<  ev=event  bind:m  (take-fact-or-wake sub until)
?-  -.ev
::
    %kick
  ;<  ~  bind:m
    %-  send-data:vio
    `(as-octs:mimes:html (sse-data "stream over"))
  ;<  ~  bind:m  send-kick:vio
  (pure:m !>(~))
    %fact
  ;<  ~  bind:m
    %-  send-data:vio
    `(as-octs:mimes:html (sse-data ~(ram re (sell q.cage.ev))))
  $
::
    %wake
  ;<  ~  bind:m
    %-  send-data:vio
    `(as-octs:mimes:html (sse-data "keepalive"))
  ^$
==
::
|%
+$  event  $%([%fact =cage] [%wake ~] [%kick ~])
::
++  take-fact-or-wake
  ::
  ::  unblock on either a %fact on +wire or a %wake for +until
  ::
  |=  [=wire until=@da]
  =/  m  (strand ,event)
  ^-  form:m
  |=  tin=strand-input:strand
  ?+    in.tin
      `[%skip ~]
  ::
      ~  `[%wait ~]
  ::
      [~ %agent * %fact *]
    ?.  =(watch+wire wire.u.in.tin)
      `[%skip ~]
    `[%done %fact cage.sign.u.in.tin]
  ::
      [~ %agent * %kick ~]
    ?.  =(watch+wire wire.u.in.tin)
      `[%skip ~]
    `[%done %kick ~]
  ::
      [~ %sign [%wait @ ~] %behn %wake *]
    ?.  =((scot %da until) i.t.wire.u.in.tin)
      `[%skip ~]
    `[%done %wake ~]
  ==
::
++  sse-data
  ::
  ::  encode a tape as one SSE event, splitting \0a into separate data: lines
  ::
  |=  text=tape
  ^-  @t
  %-  crip
  %+  weld  (predent "data: " text)
  "\0a\0a"
--
