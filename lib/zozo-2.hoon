::  two: file engine
::
/+  *zozo-1
|%
++  fe
  |_  fil=file
  +*  dat  data.fil
      cod  code.fil
      de   ~(. do data.fil)
      ce   ~(. ox code.fil)
  ++  out  fil
  ++  cor  .
  ::
  ++  kid-list
    ::
    ::  children as files, merging data and code tree kids
    ::
    ^-  (list (pair iota file))
    =/  dk=(map iota data)  (malt kid-list:de)
    =/  ck=(map iota code)  (malt kid-list:ce)
    =/  all=(set iota)
      (~(uni in ~(key by dk)) ~(key by ck))
    %+  turn  ~(tap in all)
    |=  =iota
    :-  iota
    :-  (fall (~(get by dk) iota) *data)
    (fall (~(get by ck) iota) *code)
  ::
  ++  dip
    ::
    ::  descend both data and code trees to a path
    ::
    |=  pax=pith
    ^-  file
    [(~(dip do dat) pax) (~(dip ox cod) pax)]
  ::
  ++  dit
    ::
    ::  descend and return a new +fe at that path
    ::
    |=  pax=pith
    ~(. fe (dip pax))
  ::
  --
--
