::  /gen/doctest: run all doctests and put their reports under
::                /[our]/~/doctest
::
::    `:oxal +doctest` builds every script in /lib/doctests, runs each
::    through the pure runner, converts the resulting $report to a
::    $data via +report-to-data, and pokes oxal with %do-move to insert
::    that data as a [%data ...] node at /~/doctest/<stem>.  the agent
::    prefixes [%p our], so the final piths are /[our]/~/doctest/<stem>.
::
/-  *doctest
/+  *zozo, dt=doctest
/~  scripts  script  /lib/doctests
::
:-  %say
|=  $:  [now=@da eny=@uvJ bec=beak]
        ~
        ~
    ==
=*  our  p.bec
=|  changes=(set chng)
=/  entries=(list [@ta script])  ~(tap by scripts)
|-
?~  entries
  :-  %do-move
  ^-  (set chng)
  changes
=/  [name=@ta =script]  i.entries
=/  =stem  (parse-stem-name:dt name)
=/  =report  (run-script:dt script our now)
=/  d=data  (report-to-data:dt report)
=/  =chng
  :+  %ins
    (welp ~[n+~ %doctest] stem)
  [%data d]
$(entries t.entries, changes (~(put in changes) chng))
