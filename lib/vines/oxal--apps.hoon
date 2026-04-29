::  /ted/http-oxal--apps  :  list page (CRUD over all apps in the acer)
::
::    GET   /oxal/apps   list of apps + create form
::    POST  /oxal/apps   op=new-app pokes oxal with %install-app;
::                       other ops (update-app, delete-app) are no-ops.
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
  =/  form=(map @t @t)  formencoded-body:vio
  =/  op=@t  (~(gut by form) 'op' '')
  ?:  =('new-app' op)
    =/  name=term   (~(got by form) 'name')
    =/  source=@t   (fix-newlines (~(got by form) 'source'))
    ;<  ~  bind:m  (poke-our:vio %install-app !>([name source]))
    ;<  ~  bind:m
      %+  send-simple-payload:vio
        [303 ['location' '/oxal/apps']~]
      ~
    (pure:m !>(~))
  ?:  =('delete-app' op)
    =/  name=term  (~(got by form) 'name')
    ;<  ~  bind:m  (poke-our:vio %uninstall-app !>(name))
    ;<  ~  bind:m
      %+  send-simple-payload:vio
        [303 ['location' '/oxal/apps']~]
      ~
    (pure:m !>(~))
  ?:  =('reinstall-app' op)
    =/  name=term  (~(got by form) 'name')
    ;<  ~  bind:m  (poke-our:vio %reinstall-app !>(name))
    ;<  ~  bind:m
      %+  send-simple-payload:vio
        [303 ['location' '/oxal/apps']~]
      ~
    (pure:m !>(~))
  ::  unknown op: bounce back unchanged.
  ::
  ;<  ~  bind:m
    %+  send-simple-payload:vio
      [303 ['location' (spat (welp [prefix rest]:bowl))]~]
    ~
  (pure:m !>(~))
::
;<  =acer  bind:m  (scry ,acer /gx/oxal/acer/noun)
;<  ~  bind:m
  %-  send-simple-payload:vio
  %+  node-to-simple-payload  %manx
  (render-list bowl apps.acer)
(pure:m !>(~))
::
|%
++  render-list
  ::
  ::  list page: header, app rows, create form.
  ::
  |=  [bowl=http-bowl aps=(list [name=term =app])]
  ^-  manx
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
      ;title: oxal apps
      ;link(rel "icon", href "data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\"/>");
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
      ;script(type "module", src "/hawk-init/feather/1/textarea");
    ==
    ;body.p5.fc.g5.pb15
      ;h1: apps
      ;div.fr.g3.f4.o6
        ;span
          ;-  "{(scow %ud (lent aps))} app"
          ;-  ?:(=(1 (lent aps)) "" "s")
        ==
      ==
      ;div.fc.g3
        ;*
        =;  =marl  ?^  marl  marl
          ;=
            ;div.p3.bd1.br2.o6: no apps
          ==
        %+  turn  aps
        |=  [name=term =app]
        (render-row bowl name app)
      ==
      ;div.fc.g3.bdt1.pt5
        ;h2: create app
        ;form.fc.g2(method "post")
          ;input(type "hidden", name "op", value "new-app");
          ;label.fc.g2
            ;span: name
            ;input.p-2.br2.bd1.mono
              =type  "text"
              =name  "name"
              =placeholder  "my-app"
              =required  ""
              =spellcheck  "false"
              ;*  ~
            ==
          ==
          ;label.fc.g2
            ;span: source
            ;feather-textarea.p3.mono.br2.bd1.fs-2
              =name  "source"
              =rows  "18"
              =placeholder  "|=  [our=@p name=term globals=data locals=data]  ..."
              =required  ""
              =spellcheck  "false"
              ;*  ~
            ==
          ==
          ;div.fr.g2.ac
            ;button.p-2.br2.bd1.b2.hover: create
          ==
        ==
      ==
    ==
  ==
::
++  render-row
  ::
  ::  one row in the apps list: link, view-count, delete form.
  ::
  |=  [bowl=http-bowl name=term =app]
  ^-  manx
  =/  href=tape  (trip (spat /oxal/app/[name]))
  =/  views=@ud  ~(wyt by views.app)
  ;div.fr.g3.p3.bd1.br2.b2.ac
    ;a.bold.mono.grow.hover
      =href  href
      ;-  (trip name)
    ==
    ;span.o6.fs-2
      ;-  "{(scow %ud views)} view"
      ;-  ?:(=(1 views) "" "s")
    ==
    ;form(method "post")
      ;input(type "hidden", name "op", value "reinstall-app");
      ;input(type "hidden", name "name", value (trip name));
      ;button.p-2.br2.bd1.b2.hover.f-1: reinstall
    ==
    ;form(method "post")
      ;input(type "hidden", name "op", value "delete-app");
      ;input(type "hidden", name "name", value (trip name));
      ;button.p-2.br2.bd1.b3.hover.f-1: delete
    ==
  ==
--
