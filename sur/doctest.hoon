::  /sur/doctest: types for the structured doctest runner
::
::    a doctest is a hoon source file in /lib/doctests that produces
::    a $script.  the runner walks every script, runs each section,
::    and writes structured per-section results into the oxal data
::    tree at /[our]/docs/<stem>.  rendering is left to lens views.
::
/+  *zozo
|%
::  $script: a doctest source file produces a script.
::
::    title: human-readable name; lands at /docs/<stem>/title
::    steps: ordered sections to run
::
+$  script
  $:  title=cord
      steps=(list section)
  ==
::
::  $section: one entry in a script's step list.
::
::    %prose: pure markup; renderers can wrap or restyle
::    %unit:  hoon source compiling to a tang; ~ = pass
::    %full:  ingress-op sequence + acer-test gate over the result
::
+$  section
  $%  [%prose =manx]
      [%unit =unit-test]
      [%full =full-test]
  ==
::
::  $unit-test: code slaps to a vase; result is cast to tang.
::    empty tang or a crash-free %.y leaves no trace = pass.
::
+$  unit-test
  $:  description=manx
      code=@t
  ==
::
::  $full-test: drive the agent through ingress-ops on a fresh acer,
::    then run an acer-test gate against the resulting state.
::
::    show-file: also store data.file.acer at /file-snapshot
::    ops:       sequence of agent pokes to apply, in order
::    code:      source of an acer-test gate
::
+$  full-test
  $:  description=manx
      show-file=?
      ops=(list ingress-op)
      code=@t
  ==
::
::  $ingress-op: one of the oxal agent's existing pokes.  the runner
::    dispatches each op into the matching +ingress-* arm of +ae.
::    effects are discarded; tests inspect the resulting acer only.
::
+$  ingress-op
  $%  [%do-move changes=(set chng)]
      [%install-app name=term source=@t]
      [%uninstall-app name=term]
      [%update-app name=term source=@t]
      [%bump pax=pith]
      [%set-grow pax=pith val=?]
      [%set-eyre pax=pith val=(unit auth)]
      [%set-gall pax=pith val=(unit auth)]
      [%hear-remote =ship pax=pith snap=data =move =life =case]
      [%hear-remote-code =ship pax=pith snap=code =meta-move =life =case]
  ==
::
::  $acer-test: a check gate over the acer that results from running
::    a full-test's ops.  empty tang = pass; non-empty tang is stored
::    at /docs/<stem>/sections/[ud+i]/tang and is the failure trace.
::
+$  acer-test  $-(acer tang)
--
