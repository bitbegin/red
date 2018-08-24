Red/System []

#include %../../../quick-test/quick-test.reds
#include %../../../runtime/bignum.reds

~~~start-file~~~ "bignum tests"

big: as bignum! 0
big2: as bignum! 0

===start-group=== "load positive int"
	--test-- "load-pos-int-1"
		_bignum/bn-free big
		big: _bignum/load-int 0
		--assert _bignum/bn-zero? big
	--test-- "load-pos-int-2"
		_bignum/bn-free big
		big: _bignum/load-int 100
		--assert 0 = _bignum/compare-int big 100
	--test-- "load-pos-int-3"
		_bignum/bn-free big
		big: _bignum/load-int 10000
		--assert 0 = _bignum/compare-int big 10000
	--test-- "load-pos-int-4"
		_bignum/bn-free big
		big: _bignum/load-int 1000000
		--assert 0 = _bignum/compare-int big 1000000
	--test-- "load-pos-int-5"
		_bignum/bn-free big
		big: _bignum/load-int 100000000
		--assert 0 = _bignum/compare-int big 100000000
	--test-- "load-pos-int-6"
		_bignum/bn-free big
		big: _bignum/load-int 1000000000
		--assert 0 = _bignum/compare-int big 1000000000

===end-group===

===start-group=== "load negative int"
	--test-- "load-neg-int-1"
		_bignum/bn-free big
		big: _bignum/load-int -0
		--assert _bignum/bn-zero? big
	--test-- "load-neg-int-2"
		_bignum/bn-free big
		big: _bignum/load-int -100
		--assert 0 = _bignum/compare-int big -100
	--test-- "load-neg-int-3"
		_bignum/bn-free big
		big: _bignum/load-int -10000
		--assert 0 = _bignum/compare-int big -10000
	--test-- "load-neg-int-4"
		_bignum/bn-free big
		big: _bignum/load-int -1000000
		--assert 0 = _bignum/compare-int big -1000000
	--test-- "load-neg-int-5"
		_bignum/bn-free big
		big: _bignum/load-int -100000000
		--assert 0 = _bignum/compare-int big -100000000
	--test-- "load-neg-int-6"
		_bignum/bn-free big
		big: _bignum/load-int -1000000000
		--assert 0 = _bignum/compare-int big -1000000000

===end-group===

===start-group=== "load int and negative"
	--test-- "load-int-neg-1"
		_bignum/bn-free big
		big: _bignum/bn-negative _bignum/load-int 0
		--assert 0 = _bignum/compare-int big -0 
	--test-- "load-int-neg-2"
		_bignum/bn-free big
		big: _bignum/bn-negative _bignum/load-int 100
		--assert 0 = _bignum/compare-int big -100
	--test-- "load-int-neg-3"
		_bignum/bn-free big
		big: _bignum/bn-negative _bignum/load-int 10000
		--assert 0 = _bignum/compare-int big -10000
	--test-- "load-int-neg-4"
		_bignum/bn-free big
		big: _bignum/bn-negative _bignum/load-int 1000000
		--assert 0 = _bignum/compare-int big -1000000
	--test-- "load-int-neg-5"
		_bignum/bn-free big
		big: _bignum/bn-negative _bignum/load-int 100000000
		--assert 0 = _bignum/compare-int big -100000000
	--test-- "load-int-neg-6"
		_bignum/bn-free big
		big: _bignum/bn-negative _bignum/load-int 1000000000
		--assert 0 = _bignum/compare-int big -1000000000

===end-group===

===start-group=== "load uint"
	--test-- "load-uint-1"
		_bignum/bn-free big
		big: _bignum/load-uint 0
		--assert _bignum/bn-zero? big
	--test-- "load-uint-2"
		_bignum/bn-free big
		big: _bignum/load-uint 100
		--assert 0 = _bignum/compare-int big 100
	--test-- "load-uint-3"
		_bignum/bn-free big
		big: _bignum/load-uint 10000
		--assert 0 = _bignum/compare-int big 10000
	--test-- "load-uint-4"
		_bignum/bn-free big
		big: _bignum/load-uint 1000000
		--assert 0 = _bignum/compare-int big 1000000
	--test-- "load-uint-5"
		_bignum/bn-free big
		big: _bignum/load-uint 100000000
		--assert 0 = _bignum/compare-int big 100000000
	--test-- "load-uint-6"
		_bignum/bn-free big
		big: _bignum/load-uint 1000000000
		--assert 0 = _bignum/compare-int big 1000000000
	--test-- "load-uint-7"
		_bignum/bn-free big
		big: _bignum/load-uint -100
		--assert 1 = _bignum/compare-int big 100
	--test-- "load-uint-8"
		_bignum/bn-free big
		big: _bignum/load-uint -10000
		--assert 1 = _bignum/compare-int big 10000
	--test-- "load-uint-9"
		_bignum/bn-free big
		big: _bignum/load-uint -1000000
		--assert 1 = _bignum/compare-int big 1000000
	--test-- "load-uint-10"
		_bignum/bn-free big
		big: _bignum/load-uint -100000000
		--assert 1 = _bignum/compare-int big 100000000
	--test-- "load-uint-11"
		_bignum/bn-free big
		big: _bignum/load-uint -1000000000
		--assert 1 = _bignum/compare-int big 1000000000
===end-group===

===start-group=== "load bin"
	--test-- "load-bin-1"
		_bignum/bn-free big
		bin1: [#"^(11)" #"^(22)" #"^(33)" #"^(44)" #"^(55)" #"^(66)" #"^(77)"]
		big: _bignum/load-bin bin1 size? bin1
		--assert _bignum/equal-bin? big bin1 size? bin1
	--test-- "load-bin-2"
		_bignum/bn-free big
		bin2: [#"^(00)" #"^(11)" #"^(22)" #"^(33)" #"^(44)" #"^(55)" #"^(66)" #"^(77)" #"^(88)" #"^(99)" #"^(AA)" #"^(BB)" #"^(CC)" #"^(DD)" #"^(EE)" #"^(FF)"]
		big: _bignum/load-bin bin2 size? bin2
		--assert _bignum/equal-bin? big bin2 size? bin2
	--test-- "load-bin-3"
		_bignum/bn-free big
		bin3: [#"^(3B)" #"^(9A)" #"^(CA)" #"^(00)"]
		big: _bignum/load-bin bin3 size? bin3
		--assert 0 = _bignum/compare-int big 1000000000
	--test-- "load-bin-4"
		_bignum/bn-free big
		bin4: [#"^(0D)" #"^(E0)" #"^(B6)" #"^(B3)" #"^(A7)" #"^(64)" #"^(00)" #"^(00)"]
		big: _bignum/load-bin bin4 size? bin4
		big2: _bignum/mul-int _bignum/load-int 1000000000 1000000000
		--assert 0 = _bignum/compare big big2

===end-group===

~~~end-file~~~
