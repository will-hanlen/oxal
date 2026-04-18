/-  *vine
/+  *strandio
/+  *zozo
|%
++  init
  ::
  =/  m  (strand ,http-bowl)
  ;<  args=vase  bind:m  (take-poke %http-bowl)
  %-  pure:m
  !<  http-bowl  args
  ::
++  server
  |_  http-bowl
  ++  poke-our
    ::
    |=  =cage
    =/  m  (strand ,~)
    ^-  form:m
    ;<  ~  bind:m  (^poke-our dap cage)
    (sleep ~s0)
  ++  send-head
    ::
    |=  =response-header:http
    =/  m  (strand ,~)
    ^-  form:m
    =/  paths  ~[/http-response/[rid]]
    %-  send-raw-card
    [%give %fact paths %http-response-header !>(response-header)]
  ++  send-data
    ::
    |=  =(unit octs)
    =/  m  (strand ,~)
    ^-  form:m
    =/  paths  ~[/http-response/[rid]]
    %-  send-raw-card
    [%give %fact paths %http-response-data !>(unit)]
    ::
  ++  send-kick
    ::
    =/  m  (strand ,~)
    ^-  form:m
    =/  paths  ~[/http-response/[rid]]
    %-  send-raw-card
    [%give %kick paths ~]
    ::
  ++  send-simple-payload
    ::
    |=  pl=simple-payload:http
    =/  m  (strand ,~)
    ^-  form:m
    =/  paths  ~[/http-response/[rid]]
    %-  send-raw-cards
    :~  [%give %fact paths %http-response-header !>(-.pl)]
        [%give %fact paths %http-response-data !>(+.pl)]
        [%give %kick paths ~]
    ==
  ++  formencoded-body
    ::
    ^-  (map @t @t)
    %-  fall  :_  ~
    %-  mole  |.
    (malt (rash +:(need body) yquy:de-purl:html))
    ::
  --
--