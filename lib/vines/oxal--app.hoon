::  /ted/http-oxal--app  :  detail page for a single app
::
::    GET   /oxal/app/<name>   show one app's source, computed views, edit form
::    POST  /oxal/app/<name>   stub: ops not yet wired; redirects
::
::  a bare /oxal/app (no name) bounces to the list page at /oxal/apps.
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
  ::
  ::  CRUD ops are not yet wired to the agent — bounce back to the
  ::  same URL the form was submitted from.
  ::
  ;<  ~  bind:m
    %+  send-simple-payload:vio
      [303 ['location' (spat (welp [prefix rest]:bowl))]~]
    ~
  (pure:m !>(~))
::
?~  rest.bowl
  ::
  ::  no app name in the URL — redirect to the list page.
  ::
  ;<  ~  bind:m
    %+  send-simple-payload:vio
      [303 ['location' '/oxal/apps']~]
    ~
  (pure:m !>(~))
::
;<  =acer  bind:m  (scry ,acer /gx/oxal/acer/noun)
=/  name=@ta  i.rest.bowl
=/  found=(unit app)  (find-app apps.acer name)
;<  ~  bind:m
  %-  send-simple-payload:vio
  %+  node-to-simple-payload  %manx
  (render-detail name found)
(pure:m !>(~))
::
|%
++  find-app
  ::
  ::  linear scan of apps for a name match.
  ::
  |=  [aps=(list [name=term =app]) want=@ta]
  ^-  (unit app)
  ?~  aps  ~
  ?:  =(name.i.aps want)  `app.i.aps
  $(aps t.aps)
::
++  render-detail
  ::
  ::  detail page: nav crumb, then either the app body or a notice.
  ::
  |=  [name=@ta found=(unit app)]
  ^-  manx
  ;feather.p5.fc.g5.pb15(title "oxal app")
    ;nav.fr.g2.ac
      ;a.p-2.br2.bd1.b2.hover
        =href  "/oxal/apps"
        ; apps
      ==
      ;span.o5: /
      ;span.bold.mono: {(trip name)}
    ==
    ;+  ?~  found
        ;div.p5.bd1.br2.o6
          ;span: no app named
          ;span.bold.mono: {(trip name)}
        ==
      (render-detail-body name u.found)
  ==
::
++  render-detail-body
  ::
  ::  body of the detail page: source, computed views, edit form.
  ::
  |=  [name=@ta =app]
  ^-  manx
  ;div.fc.g5
    ;+  ?~  error.app  ;/  ""
        ;section.fc.g2
          ;h2.f-1: error
          ;div.p3.bd1.br2.b3.mono.fs-2.f-1
            ;+  (render-tang u.error.app)
          ==
        ==
    ;section.fc.g2
      ;h2: source
      ;pre.p3.bd1.br2.b2.mono.fs-2
        ;-  (trip source.app)
      ==
    ==
    ;section.fc.g2
      ;h2
        ;-  "views ({(scow %ud ~(wyt by views.app))})"
      ==
      ;div.fc.g2
        ;*
        =;  =marl  ?^  marl  marl
          ;=
            ;div.o6.fs-2: no computed views
          ==
        %+  turn  ~(tap by views.app)
        |=  [=stem =view]
        ;div.fr.g3.p2.bd1.br2.b2
          ;span.mono.grow: {(pate stem)}
          ;span.o6.fs-2: {(trip -.view)}
        ==
      ==
    ==
    ;section.fc.g2
      ;h2: edit
      ;form.fc.g2(method "post")
        ;input(type "hidden", name "op", value "update-app");
        ;input(type "hidden", name "name", value (trip name));
        ;label.fc.g2
          ;span: source
          ;feather-textarea.p3.mono.br2.bd1.fs-2
            =name  "source"
            =rows  "12"
            =required  ""
            =spellcheck  "false"
            ;-  (trip source.app)
          ==
        ==
        ;div.fr.g2.ac
          ;button.p-2.br2.bd1.b2.hover: save
          ;span.f5.o6: stub — not wired to agent
        ==
      ==
    ==
  ==
--
