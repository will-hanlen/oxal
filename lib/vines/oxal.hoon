::  /ted/http-oxal--bitt  :  render incoming subscriptions in sup.bowl
::
/+  *vineio
::
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
;<  ~  bind:m
  %-  send-simple-payload:vio
  %+  node-to-simple-payload  %manx
  ;feather.p4.pb15.fc.g6(title "oxal")
    ;strong: oxal
    ;div.fc.bbv
      ;*
      %+  turn
        ^-  (list path)
        :~  /tree
            /author
            /gall/sky
            /gall/sup
            /eyre/cache
            /eyre/bindings
        ==
      |=  =path
      ;a.underline.py3.b1.hover
        =href  (spud :(welp prefix.bowl rest.bowl path))
        ;-  (spud path)
      ==
    ==
  ==
::
(pure:m !>(~))
