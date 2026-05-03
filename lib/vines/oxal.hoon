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
      ;title: oxal
      ;link(rel "icon", href "data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\"/>");
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
    ==
    ;body.p4.pb15.fc.g6
      ;strong: oxal
      ;div.fc.bbv
        ;*
        %+  turn
          ^-  (list path)
          :~
            /apps
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
  ==
::
(pure:m !>(~))
