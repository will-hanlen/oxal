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
    ::
  ++  soft-poke-our
    ::
    ::  poke our own agent and return the nack tang, if any: ~ on ack,
    ::  [~ tang] on nack.  does not crash the thread on nack, so callers
    ::  can render an error response.
    ::
    |=  =cage
    =/  m  (strand ,(unit tang))
    ^-  form:m
    =/  =card:agent:gall  [%pass /poke %agent [our dap] %poke cage]
    ;<  ~  bind:m  (send-raw-card card)
    |=  tin=strand-input:strand
    ?+  in.tin  `[%skip ~]
        ~  `[%wait ~]
        [~ %agent * %poke-ack *]
      ?.  =(/poke wire.u.in.tin)
        `[%skip ~]
      `[%done p.sign.u.in.tin]
    ==
    ::
  ++  soft-watch-our
    ::
    ::  watch our own agent and return the nack tang, if any: ~ on ack,
    ::  [~ tang] on nack.  does not crash the thread on nack, so callers
    ::  can render an error response.
    ::
    |=  [=wire =path]
    =/  m  (strand ,(unit tang))
    ^-  form:m
    =/  =card:agent:gall  [%pass watch+wire %agent [our dap] %watch path]
    ;<  ~  bind:m  (send-raw-card card)
    |=  tin=strand-input:strand
    ?+  in.tin  `[%skip ~]
        ~  `[%wait ~]
        [~ %agent * %watch-ack *]
      ?.  =(watch+wire wire.u.in.tin)
        `[%skip ~]
      `[%done p.sign.u.in.tin]
    ==
    ::
  ++  send-head
    ::
    |=  =response-header:http
    =/  m  (strand ,~)
    ^-  form:m
    =/  paths  ~[/http-response/[rid]]
    %-  send-raw-card
    [%give %fact paths %http-response-header !>(response-header)]
    ::
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
    ::
  ++  formencoded-body
    ::
    ^-  (map @t @t)
    %-  fall  :_  ~
    %-  mole  |.
    (malt (rash +:(need body) yquy:de-purl:html))
    ::
  --
--