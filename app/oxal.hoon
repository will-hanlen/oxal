::  oxal
::
/+  vine
/+  *zozo
::
|%
+$  state-0  [%0 =acer verb=_|]
+$  state-n  $%(state-0)
--
::
=|  state-0
=*  state  -
^-  agent:gall
%-  (agent:vine %oxal)
=<
|_  =bowl:gall
+*  this  .
    cor  ~(. +> [bowl ~])
++  on-init
  ::
  ^-  (quip card:agent:gall _this)
  :_  this
  :~  bind-card
  ==
  ::
++  on-load
  ::
  |=  ole=vase
  ^-  (quip card:agent:gall _this)
  =/  =(unit state-0)  (mole |.(!<(state-0 ole)))
  :-  ~[bind-card]
  ?~  unit  this
  this(state u.unit)
  ::
++  on-poke
  ::
  |=  [=mark =vase]
  ^-  (quip card:agent:gall _this)
  =^  cards  state  abet:(poke:cor mark vase)
  :-  cards  this
  ::
++  on-fail
  ::
  |=  [=term =tang]
  ^-  (quip card:agent:gall _this)
  %-  (slog term tang)
  `this
  ::
++  on-watch
  ::
  |=  =path
  ^-  (quip card:agent:gall _this)
  ?+  path  `this
    [%sub *]
      =/  pax=pith  (pave t.path)
      =/  full-pax=pith  [p+our.bowl pax]
      ~|  forbidden/(spud path)
      ?:  (lth (lent full-pax) 2)  !!
      =/  =meta  (fall (~(get ox code.file.acer) full-pax) *meta)
      ?~  gall.meta  !!
      ?>  (check-auth u.gall.meta our.bowl src.bowl)
      =/  resp  (~(initial-watch-response ae [acer our.bowl verb &]) full-pax)
      :_  this  :~
        [%give %fact ~ %oxal-snap !>(resp)]
      ==
    ::
    [%life *]  `this
    [%snap *]  `this
    [%logs *]  `this
  ==
  ::
++  on-leave
  ::
  |=  =path
  ^-  (quip card:agent:gall _this)
  `this
  ::
++  on-agent
  ::
  |=  [=wire =sign:agent:gall]
  ^-  (quip card:agent:gall _this)
  `this
  ::
++  on-arvo
  ::
  |=  [=wire =sign-arvo]
  ^-  (quip card:agent:gall _this)
  `this
  ::
++  on-save   !>  state
++  on-peek
  ::
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  ~
    [%x %acer ~]       ``noun+!>(acer)
    [%x %data *]        ``noun+!>((~(dip do data.file.acer) (pave t.t.path)))
    [%x %code *]        ``noun+!>((~(dip ox code.file.acer) (pave t.t.path)))
    [%x %file ~]        ``noun+!>(file.acer)
    [%x %our ~]         ``noun+!>(our.bowl)
  ==
  ::
--
::
|_  [=bowl:gall cards=(list card:agent:gall)]
++  cor   .
++  abet  :-  (flop cards)  state
++  emit  |=  =card:agent:gall  cor(cards [card cards])
++  emil  |=  caz=(list card:agent:gall)  cor(cards (welp (flop caz) cards))
::
++  bind-card  [%pass /eyre-inner-bind %arvo %e %connect [~ `path`['-' ~]] %oxal]
::
++  poke
  |=  [=mark =vase]
  ^+  cor
  ?+  mark  ~|(bad-poke/mark !!)
    :::
    %verb
      ::
      =+  !<  val=?  vase
      %-  (slog leaf+"verbosity: {?:(val "y" "n")}" ~)
      cor(verb val)
      ::
    %do-move
      ::
      =+  !<  =move  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(~(ingress-do-move ae [acer our.bowl verb &]) [move %.n])
      (emil cz)
      ::
    %install
      ::
      =+  !<  [pax=pith =source]  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(~(ingress-install ae [acer our.bowl verb &]) pax source)
      (emil cz)
      ::
    %uninstall
      ::
      =+  !<  pax=pith  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(~(ingress-uninstall ae [acer our.bowl verb &]) pax)
      (emil cz)
      ::
    %cull
      ::
      =+  !<  pax=pith  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(~(ingress-cull ae [acer our.bowl verb &]) pax)
      (emil cz)
      ::
    %set-grow
      ::
      =+  !<  [pax=pith val=?]  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(~(ingress-set-grow ae [acer our.bowl verb &]) pax val)
      (emil cz)
      ::
    %set-eyre
      ::
      =+  !<  [pax=pith val=(unit auth)]  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(~(ingress-set-eyre ae [acer our.bowl verb &]) pax val)
      (emil cz)
      ::
    %set-gall
      ::
      =+  !<  [pax=pith val=(unit auth)]  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(~(ingress-set-gall ae [acer our.bowl verb &]) pax val)
      (emil cz)
      ::
    ::
    ::  dev-only shim: exercise +ingress-hear-remote without networking.
    ::  remove once the gall-networking layer lands.
    ::
    %hear-remote
      ::
      =+  !<  [=ship pax=pith snap=data =move =life =case]  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(~(ingress-hear-remote ae [acer our.bowl verb &]) ship pax snap move life case)
      (emil cz)
      ::
    %wipe
      ::
      =.  file.acer  *file
      %-  (slog 'oxal: wipe' ~)
      cor
    %handle-http-request
      ::
      =+  !<  [rid=@ta req=inbound-request:eyre]  vase
      =/  [line=path query=(map @t @t)]  (parse-url url.request.req)
      =/  =stem  [p+our.bowl (tail (pave line))]
      =/  =meta  (fall (~(get ox code.file.acer) stem) *meta)
      =/  allowed=?
        ?~  eyre.meta  |
        (check-auth u.eyre.meta our.bowl src.bowl)
      %-  emil
      ?.  allowed
        %+  payload-cards  rid
        :-  [403 ['content-type' 'text/plain']~]
        `(as-octs:mimes:html 'forbidden')
      ?~  nude=(~(get do data.file.acer) stem)
        %+  payload-cards  rid
        :-  [404 ['content-type' 'text/plain']~]
        `(as-octs:mimes:html 'not found')
      %+  payload-cards  rid
      (node-to-simple-payload u.nude)
      ::
  ==
  ::
--
