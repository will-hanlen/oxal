::  tests for node and pith serialization / deserialization
::
::  exercises the round-tripable printers (+nate, +pate, +nare, +pare)
::  against their parser inverses (+sily, +stib, +ream).
::
/+  *test, *zozo-0
::
|%
::  +round-node-tape: node -> tape -> node (url-safe)
::
++  round-node-tape
  |=  n=node
  ^-  node
  (sily (nate n))
::
::  +round-pith-tape: pith -> tape -> pith (url-safe)
::
++  round-pith-tape
  |=  p=pith
  ^-  pith
  (stib (pate p))
::
::  +round-node-source: node -> hoon-source tape -> node (via ream)
::
++  round-node-source
  |=  n=node
  ^-  node
  !<(node (slap !>(.) (ream (crip (nare n)))))
::
::  +round-pith-source: pith -> hoon-source tape -> pith (via ream)
::
++  round-pith-source
  |=  p=pith
  ^-  pith
  !<(pith (slap !>(.) (ream (crip (pare p)))))
::
::  ::  ::  ::  ::  ::  ::  ::  ::
::  node round trips (url-safe)
::  ::  ::  ::  ::  ::  ::  ::  ::
::
++  test-node-tas
  =/  n=node  %foo
  (expect-eq !>(n) !>((round-node-tape n)))
::
++  test-node-empty-tas
  =/  n=node  %$
  (expect-eq !>(n) !>((round-node-tape n)))
::
++  test-node-ud
  =/  n=node  ud+42
  (expect-eq !>(n) !>((round-node-tape n)))
::
++  test-node-ud-zero
  =/  n=node  ud+0
  (expect-eq !>(n) !>((round-node-tape n)))
::
++  test-node-ux
  =/  n=node  ux+0xdead.beef
  (expect-eq !>(n) !>((round-node-tape n)))
::
++  test-node-p
  =/  n=node  p+~zod
  (expect-eq !>(n) !>((round-node-tape n)))
::
++  test-node-p-comet
  =/  n=node  p+~nec
  (expect-eq !>(n) !>((round-node-tape n)))
::
++  test-node-da
  =/  n=node  da+~2026.4.30
  (expect-eq !>(n) !>((round-node-tape n)))
::
++  test-node-f-yes
  =/  n=node  [%f &]
  (expect-eq !>(n) !>((round-node-tape n)))
::
++  test-node-f-no
  =/  n=node  [%f |]
  (expect-eq !>(n) !>((round-node-tape n)))
::
++  test-node-n
  =/  n=node  [%n ~]
  (expect-eq !>(n) !>((round-node-tape n)))
::
++  test-node-ta
  =/  n=node  ta+~.hello
  (expect-eq !>(n) !>((round-node-tape n)))
::
::  ::  ::  ::  ::  ::  ::  ::  ::
::  pith round trips (url-safe)
::  ::  ::  ::  ::  ::  ::  ::  ::
::
++  test-pith-empty
  =/  p=pith  ~
  (expect-eq !>(p) !>((round-pith-tape p)))
::
++  test-pith-single-tas
  =/  p=pith  /foo
  (expect-eq !>(p) !>((round-pith-tape p)))
::
++  test-pith-multi-tas
  =/  p=pith  /foo/bar/baz
  (expect-eq !>(p) !>((round-pith-tape p)))
::
++  test-pith-mixed
  =/  pa=pith  ~[%foo ud+1 %bar p+~zod]
  (expect-eq !>(pa) !>((round-pith-tape pa)))
::
++  test-pith-nested
  =/  pa=pith  ~[%apps [%pith /foo/users] %view]
  (expect-eq !>(pa) !>((round-pith-tape pa)))
::
::  ::  ::  ::  ::  ::  ::  ::  ::
::  fixed-string deserialization
::  ::  ::  ::  ::  ::  ::  ::  ::
::
++  test-sily-tas
  %+  expect-eq
    !>(`node`%foo)
    !>((sily "%foo"))
::
++  test-sily-ud
  %+  expect-eq
    !>(`node`ud+42)
    !>((sily "42"))
::
++  test-sily-p
  %+  expect-eq
    !>(`node`p+~zod)
    !>((sily "~zod"))
::
++  test-stib-empty
  %+  expect-eq
    !>(`pith`~)
    !>((stib "/"))
::
++  test-stib-simple
  %+  expect-eq
    !>(`pith`/foo/bar)
    !>((stib "/foo/bar"))
::
::  ::  ::  ::  ::  ::  ::  ::  ::
::  fixed-string serialization
::  ::  ::  ::  ::  ::  ::  ::  ::
::
++  test-nate-tas
  %+  expect-eq
    !>("%foo")
    !>((nate %foo))
::
++  test-nate-ud
  %+  expect-eq
    !>("42")
    !>((nate ud+42))
::
++  test-pate-empty
  %+  expect-eq
    !>("/")
    !>((pate ~))
::
++  test-pate-simple
  %+  expect-eq
    !>("/foo/bar")
    !>((pate /foo/bar))
::
::  ::  ::  ::  ::  ::  ::  ::  ::
::  nare round trips (via ream)
::  ::  ::  ::  ::  ::  ::  ::  ::
::
++  test-nare-tas
  =/  n=node  %foo
  (expect-eq !>(n) !>((round-node-source n)))
::
++  test-nare-empty-tas
  =/  n=node  %$
  (expect-eq !>(n) !>((round-node-source n)))
::
++  test-nare-ud
  =/  n=node  ud+42
  (expect-eq !>(n) !>((round-node-source n)))
::
++  test-nare-p
  =/  n=node  p+~zod
  (expect-eq !>(n) !>((round-node-source n)))
::
++  test-nare-da
  =/  n=node  da+~2026.4.30
  (expect-eq !>(n) !>((round-node-source n)))
::
++  test-nare-t
  =/  n=node  [%t 'hello world']
  (expect-eq !>(n) !>((round-node-source n)))
::
++  test-nare-t-multiline
  =/  n=node  [%t 'line one\0aline two\0aline three']
  (expect-eq !>(n) !>((round-node-source n)))
::
::  ::  ::  ::  ::  ::  ::  ::  ::
::  nare literal output
::  ::  ::  ::  ::  ::  ::  ::  ::
::
++  test-nare-t-format
  ::  the canonical multi-line cord form
  ::
  %+  expect-eq
    !>(":-  %t\0a'''\0ahello\0a'''")
    !>((nare [%t 'hello']))
::
::  ::  ::  ::  ::  ::  ::  ::  ::
::  pare round trips (via ream)
::  ::  ::  ::  ::  ::  ::  ::  ::
::
++  test-pare-empty
  =/  p=pith  ~
  (expect-eq !>(p) !>((round-pith-source p)))
::
++  test-pare-simple
  =/  p=pith  /foo/bar
  (expect-eq !>(p) !>((round-pith-source p)))
::
++  test-pare-mixed
  =/  pa=pith  ~[%foo ud+1 %bar p+~zod]
  (expect-eq !>(pa) !>((round-pith-source pa)))
::
++  test-pare-nested
  =/  pa=pith  ~[%blog [%pith ~[da+~2021.1.1]]]
  (expect-eq !>(pa) !>((round-pith-source pa)))
::
++  test-pare-nested-empty
  =/  pa=pith  ~[[%pith ~]]
  (expect-eq !>(pa) !>((round-pith-source pa)))
::
++  test-pare-nested-deep
  =/  pa=pith  ~[%a [%pith ~[%b [%pith ~[%c]]]]]
  (expect-eq !>(pa) !>((round-pith-source pa)))
::
::  ::  ::  ::  ::  ::  ::  ::  ::
::  node-summary
::  ::  ::  ::  ::  ::  ::  ::  ::
::
++  test-node-summary-tas
  %+  expect-eq
    !>("foo")
    !>((node-summary %foo))
::
++  test-node-summary-ud
  %+  expect-eq
    !>("42")
    !>((node-summary ud+42))
::
++  test-node-summary-p
  %+  expect-eq
    !>("~zod")
    !>((node-summary p+~zod))
::
++  test-node-summary-pith
  %+  expect-eq
    !>("/foo/bar")
    !>((node-summary [%pith /foo/bar]))
::
++  test-node-summary-mime
  =/  =mime  [/text/plain (as-octs:mimes:html 'hello world')]
  %+  expect-eq
    !>("/text/plain (11 bytes)")
    !>((node-summary [%mime mime]))
::
++  test-node-summary-truncates
  =/  long=@t  (rap 3 (reap 100 'x'))
  =/  out=tape  (node-summary [%t long])
  %+  expect-eq
    !>(80)
    !>((lent out))
::
++  test-node-summary-no-newlines
  =/  =node  [%t 'hello\0aworld']
  =/  out=tape  (node-summary node)
  %+  expect-eq
    !>(~)
    !>((find "\0a" out))
::
++  test-node-summary-manx-tag
  =/  =manx  ;div;
  %+  expect-eq
    !>(";div")
    !>((node-summary [%manx manx]))
::
++  test-node-summary-manx-id
  =/  =manx  ;div(id "foo");
  %+  expect-eq
    !>(";div#foo")
    !>((node-summary [%manx manx]))
::
++  test-node-summary-manx-class
  =/  =manx  ;div(class "alpha beta");
  %+  expect-eq
    !>(";div.alpha.beta")
    !>((node-summary [%manx manx]))
::
++  test-node-summary-manx-other-attrs
  =/  =manx  ;div(id "x", data-foo "y", role "main");
  =/  out=tape  (node-summary [%manx manx])
  %+  expect-eq
    !>(";div#x +2 attrs")
    !>(out)
--
