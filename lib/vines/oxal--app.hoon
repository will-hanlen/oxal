/+  *vineio
::
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
;<  =acer  bind:m  (scry ,acer /gx/oxal/acer/noun)
=/  app-name=@tas  (head rest.bowl)
=/  =app  (got-app acer app-name)
::
|^
  ;<  ~  bind:m
    %-  send-simple-payload:vio
    %+  node-to-simple-payload  %manx
    %+  wrap  (trip app-name)
    ;=
      ;+  part-header
      ;+  part-error
      ;+  part-source
      ;+  part-file
    ==
  ::
  (pure:m !>(~))
::
++  wrap
  ::
  |=  [title=tape body=marl]
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
      ;title: {title}
      ;link(rel "icon", href "data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\"/>");
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
      ;script(type "module", src "/hawk-init/feather/1/textarea");
      ;script(type "module", src "/hawk-init/feather/1/datastar");
    ==
    ;body:(*body)
  ==
  ::
::
++  part-header
  ::
  ^-  manx
  ;header: none yet
  ::
::
++  part-error
  ::
  ^-  manx
  ?~  error.app  ;/  ""
  ;div
    ;+  (render-tang u.error.app)
  ==
::
++  part-source
  ::
  ^-  manx
  ;div: source code
::
++  part-file
  ::
  ^-  manx
  ;div: the file
::
--