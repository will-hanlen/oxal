/+  *vineio
::
::
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
;<  bindings=(list [=binding:eyre =duct action=action:eyre])  bind:m
  %+  scry
    ,(list [binding:eyre duct action:eyre])
  /e/bindings
::
;<  ~  bind:m
  %-  send-simple-payload:vio
  %+  node-to-simple-payload  %manx
  ;feather.fc.bbv.p5.pb15(title "eyre bindings")
    ::
    ;h1.pb3: eyre bindings
    ::
    ;*
    %+  turn  bindings
    |=  [=binding:eyre =duct action=action:eyre]
    ;div.fr.g3.py2
      ;span.o6.f4
        ;-  ?~  site.binding  "host:*"
            (weld "host:" (trip u.site.binding))
      ==
      ;span.bold
        ;-  (spud path.binding)
      ==
      ;span.o6
        ;-  <action>
      ==
    ==
  ==
::
(pure:m !>(~))