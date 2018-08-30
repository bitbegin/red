Red/System []

#include %../../../quick-test/quick-test.reds
#include %../../../runtime/bignum.reds

~~~start-file~~~ "bignum tests"

big: as bignum! 0
big2: as bignum! 0

===start-group=== "load positive int"
	--test-- "load-pos-int-1"
		big: _bignum/load-int 0
		--assert _bignum/bn-zero? big
		_bignum/bn-free big

	--test-- "load-pos-int-2"
		big: _bignum/load-int 100
		--assert 0 = _bignum/compare-int big 100
		_bignum/bn-free big

	--test-- "load-pos-int-3"
		big: _bignum/load-int 10000
		--assert 0 = _bignum/compare-int big 10000
		_bignum/bn-free big

	--test-- "load-pos-int-4"
		big: _bignum/load-int 1000000
		--assert 0 = _bignum/compare-int big 1000000
		_bignum/bn-free big

	--test-- "load-pos-int-5"
		big: _bignum/load-int 100000000
		--assert 0 = _bignum/compare-int big 100000000
		_bignum/bn-free big

	--test-- "load-pos-int-6"
		big: _bignum/load-int 1000000000
		--assert 0 = _bignum/compare-int big 1000000000
		_bignum/bn-free big

===end-group===

===start-group=== "load negative int"
	--test-- "load-neg-int-1"
		big: _bignum/load-int -0
		--assert _bignum/bn-zero? big
		_bignum/bn-free big

	--test-- "load-neg-int-2"
		big: _bignum/load-int -100
		--assert 0 = _bignum/compare-int big -100
		_bignum/bn-free big

	--test-- "load-neg-int-3"
		big: _bignum/load-int -10000
		--assert 0 = _bignum/compare-int big -10000
		_bignum/bn-free big

	--test-- "load-neg-int-4"
		big: _bignum/load-int -1000000
		--assert 0 = _bignum/compare-int big -1000000
		_bignum/bn-free big

	--test-- "load-neg-int-5"
		big: _bignum/load-int -100000000
		--assert 0 = _bignum/compare-int big -100000000
		_bignum/bn-free big

	--test-- "load-neg-int-6"
		big: _bignum/load-int -1000000000
		--assert 0 = _bignum/compare-int big -1000000000
		_bignum/bn-free big

===end-group===

===start-group=== "load int and negative"
	--test-- "load-int-neg-1"
		big: _bignum/load-int 0
		big2: _bignum/bn-negative big false
		--assert 0 = _bignum/compare-int big2 -0 
		_bignum/bn-free big
		_bignum/bn-free big2

	--test-- "load-int-neg-2"
		big: _bignum/load-int 100
		big2: _bignum/bn-negative big false
		--assert 0 = _bignum/compare-int big2 -100
		_bignum/bn-free big
		_bignum/bn-free big2

	--test-- "load-int-neg-3"
		big: _bignum/load-int 10000
		big2: _bignum/bn-negative big false
		--assert 0 = _bignum/compare-int big2 -10000
		_bignum/bn-free big
		_bignum/bn-free big2

	--test-- "load-int-neg-4"
		big: _bignum/load-int 1000000
		big2: _bignum/bn-negative big false
		--assert 0 = _bignum/compare-int big2 -1000000
		_bignum/bn-free big
		_bignum/bn-free big2

	--test-- "load-int-neg-5"
		big: _bignum/load-int 100000000
		big2: _bignum/bn-negative big false
		--assert 0 = _bignum/compare-int big2 -100000000
		_bignum/bn-free big
		_bignum/bn-free big2

	--test-- "load-int-neg-6"
		big: _bignum/load-int 1000000000
		big2: _bignum/bn-negative big false
		--assert 0 = _bignum/compare-int big2 -1000000000
		_bignum/bn-free big
		_bignum/bn-free big2

===end-group===

===start-group=== "load uint"
	--test-- "load-uint-1"
		big: _bignum/load-uint 0
		--assert _bignum/bn-zero? big
		_bignum/bn-free big

	--test-- "load-uint-2"
		big: _bignum/load-uint 100
		--assert 0 = _bignum/compare-int big 100
		_bignum/bn-free big

	--test-- "load-uint-3"
		big: _bignum/load-uint 10000
		--assert 0 = _bignum/compare-int big 10000
		_bignum/bn-free big

	--test-- "load-uint-4"
		big: _bignum/load-uint 1000000
		--assert 0 = _bignum/compare-int big 1000000
		_bignum/bn-free big

	--test-- "load-uint-5"
		big: _bignum/load-uint 100000000
		--assert 0 = _bignum/compare-int big 100000000
		_bignum/bn-free big

	--test-- "load-uint-6"
		big: _bignum/load-uint 1000000000
		--assert 0 = _bignum/compare-int big 1000000000
		_bignum/bn-free big

	--test-- "load-uint-7"
		big: _bignum/load-uint -100
		--assert 1 = _bignum/compare-int big 100
		_bignum/bn-free big

	--test-- "load-uint-8"
		big: _bignum/load-uint -10000
		--assert 1 = _bignum/compare-int big 10000
		_bignum/bn-free big

	--test-- "load-uint-9"
		big: _bignum/load-uint -1000000
		--assert 1 = _bignum/compare-int big 1000000
		_bignum/bn-free big

	--test-- "load-uint-10"
		big: _bignum/load-uint -100000000
		--assert 1 = _bignum/compare-int big 100000000
		_bignum/bn-free big

	--test-- "load-uint-11"
		big: _bignum/load-uint -1000000000
		--assert 1 = _bignum/compare-int big 1000000000
		_bignum/bn-free big

===end-group===

===start-group=== "load bin"
	--test-- "load-bin-1"
		bin1: [#"^(11)" #"^(22)" #"^(33)" #"^(44)" #"^(55)" #"^(66)" #"^(77)"]
		big: _bignum/load-bin bin1 size? bin1
		--assert _bignum/equal-bin? big bin1 size? bin1
		_bignum/bn-free big

	--test-- "load-bin-2"
		bin2: [#"^(00)" #"^(11)" #"^(22)" #"^(33)" #"^(44)" #"^(55)" #"^(66)" #"^(77)" #"^(88)" #"^(99)" #"^(AA)" #"^(BB)" #"^(CC)" #"^(DD)" #"^(EE)" #"^(FF)"]
		big: _bignum/load-bin bin2 size? bin2
		--assert _bignum/equal-bin? big bin2 size? bin2
		_bignum/bn-free big

	--test-- "load-bin-3"
		bin3: [#"^(3B)" #"^(9A)" #"^(CA)" #"^(00)"]
		big: _bignum/load-bin bin3 size? bin3
		--assert 0 = _bignum/compare-int big 1000000000
		_bignum/bn-free big

	--test-- "load-bin-4"
		bin4: [#"^(0D)" #"^(E0)" #"^(B6)" #"^(B3)" #"^(A7)" #"^(64)" #"^(00)" #"^(00)"]
		big: _bignum/load-bin bin4 size? bin4
		big2: _bignum/load-int 1000000000
		big3: _bignum/mul-int big2 1000000000 false
		--assert 0 = _bignum/compare big big3
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3

===end-group===

===start-group=== "load str base10"
	--test-- "load-base10-1"
		str: "1000000000"
		big: _bignum/load-str str -1 10
		--assert 0 = _bignum/compare-int big 1000000000
		_bignum/bn-free big

	--test-- "load-base10-2"
		str: "1000000000000000000"
		big: _bignum/load-str str -1 10
		big2: _bignum/load-bin bin4 size? bin4
		--assert 0 = _bignum/compare big big2
		_bignum/bn-free big
		_bignum/bn-free big2

	--test-- "load-base10-3"
		str: "+1000000000000000000"
		big: _bignum/load-str str -1 10
		big2: _bignum/load-bin bin4 size? bin4
		--assert 0 = _bignum/compare big big2
		_bignum/bn-free big
		_bignum/bn-free big2

	--test-- "load-base10-4"
		str: "-1000000000000000000"
		big: _bignum/load-str str -1 10
		big2: _bignum/load-bin bin4 size? bin4
		big3: _bignum/bn-negative big2 false
		--assert 0 = _bignum/compare big big3
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3

===end-group===

===start-group=== "load str base16"
	--test-- "load-base16-1"
		str: "3B9ACA00"
		big: _bignum/load-str str -1 16
		--assert 0 = _bignum/compare-int big 1000000000
		_bignum/bn-free big

	--test-- "load-base16-2"
		str: "DE0B6B3A7640000"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-bin bin4 size? bin4
		--assert 0 = _bignum/compare big big2
		_bignum/bn-free big
		_bignum/bn-free big2

	--test-- "load-base16-3"
		str: "112233445566778899AABBCCDDEEFF"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-bin bin2 size? bin2
		--assert 0 = _bignum/compare big big2
		_bignum/bn-free big
		_bignum/bn-free big2

	--test-- "load-base16-4"
		str: "+112233445566778899AABBCCDDEEFF"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-bin bin2 size? bin2
		--assert 0 = _bignum/compare big big2
		_bignum/bn-free big
		_bignum/bn-free big2

	--test-- "load-base16-5"
		str: "-112233445566778899AABBCCDDEEFF"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-bin bin2 size? bin2
		_bignum/set-negative big2
		--assert 0 = _bignum/compare big big2
		_bignum/bn-free big
		_bignum/bn-free big2

===end-group===

===start-group=== "add tests"
	--test-- "add-test-1"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929D"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/add-int big 1 false
		--assert 0 = _bignum/compare big2 big3
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3

	--test-- "add-test-2"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "6AC1F425FF4780EB"
		str3: "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FD4B8E42103A0D1387"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/load-str str3 -1 16
		big4: _bignum/add big big2 false
		--assert 0 = _bignum/compare big3 big4
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3
		_bignum/bn-free big4

	--test-- "add-test-3"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "0702DF9D88CF598EABA3C232E9F96A446AD47CD7750B5FD78F064BE96E4242F1"
		str3: "7253349BD9020AF45B0E4DC5704234189F2B7862E69180D46FD299D3A907D58D"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/load-str str3 -1 16
		big4: _bignum/add big big2 false
		--assert 0 = _bignum/compare big3 big4
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3
		_bignum/bn-free big4

	--test-- "add-test-4"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "47CB2D6F7235DEE2CA0E35D738DD27871A6D051A12C7FE9972A9266878200416"
		str3: "B31B826DC26890487978C169BF25F15B4EC400A5844E1F9653757452B2E596B2"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/load-str str3 -1 16
		big4: _bignum/add big big2 false
		--assert 0 = _bignum/compare big3 big4
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3
		_bignum/bn-free big4

	--test-- "add-test-5"
		str:  "-6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "-47CB2D6F7235DEE2CA0E35D738DD27871A6D051A12C7FE9972A9266878200416"
		str3: "-B31B826DC26890487978C169BF25F15B4EC400A5844E1F9653757452B2E596B2"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/load-str str3 -1 16
		big4: _bignum/add big big2 false
		--assert 0 = _bignum/compare big3 big4
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3
		_bignum/bn-free big4

	--test-- "add-test-6"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929B"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/add-int big -1 false
		--assert 0 = _bignum/compare big2 big3
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3

===end-group===

===start-group=== "sub tests"
	--test-- "sub-test-1"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929B"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/sub-int big 1 false
		--assert 0 = _bignum/compare big2 big3
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3

	--test-- "sub-test-2"
		str:  "B8672F8CEEBC1448"
		str2: "89EFE4B2D8A7D514"
		str3: "2E774ADA16143F34"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/load-str str3 -1 16
		big4: _bignum/sub big big2 false
		--assert 0 = _bignum/compare big3 big4
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3
		_bignum/bn-free big4

	--test-- "sub-test-3"
		str:   "6AC1F425FF4780EB"
		str2:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FD4B8E42103A0D1387"
		str3: "-6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/load-str str3 -1 16
		big4: _bignum/sub big big2 false
		--assert 0 = _bignum/compare big3 big4
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3
		_bignum/bn-free big4

	--test-- "sub-test-4"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "04AE8A6D08BF7373C00975299FC06DD2FD26000FA91F6C40BF87C8C44C6A3019"
		str3: "66A1CA9147733DF1EF611668E6885C013730FB7BC866B4BC21448525EE5B6283"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/load-str str3 -1 16
		big4: _bignum/sub big big2 false
		--assert 0 = _bignum/compare big3 big4
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3
		_bignum/bn-free big4

===end-group===

===start-group=== "mul tests"
	--test-- "mul-test-1"
		str:  "02"
		str2: "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str3: "D6A0A9FCA06562CB5ED517250C9193A868ADF716E30C41F9C1989BD4758B2538"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/load-str str3 -1 16
		big4: _bignum/mul big big2 false
		--assert 0 = _bignum/compare big3 big4
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3
		_bignum/bn-free big4

	--test-- "mul-test-2"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "02"
		str3: "D6A0A9FCA06562CB5ED517250C9193A868ADF716E30C41F9C1989BD4758B2538"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/load-str str3 -1 16
		big4: _bignum/mul big big2 false
		--assert 0 = _bignum/compare big3 big4
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3
		_bignum/bn-free big4

	--test-- "mul-test-3"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "02"
		str3: "D6A0A9FCA06562CB5ED517250C9193A868ADF716E30C41F9C1989BD4758B2538"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/load-str str3 -1 16
		big4: _bignum/mul-int big 2 false
		--assert 0 = _bignum/compare big3 big4
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3
		_bignum/bn-free big4

	--test-- "mul-test-4"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "-02"
		str3: "-D6A0A9FCA06562CB5ED517250C9193A868ADF716E30C41F9C1989BD4758B2538"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/load-str str3 -1 16
		big4: _bignum/mul big big2 false
		--assert 0 = _bignum/compare big3 big4
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3
		_bignum/bn-free big4

	--test-- "mul-test-5"
		str:  "B8672F8CEEBC1448"
		str2: "6AC1F425FF4780EB"
		str3: "4CE66F58EC3858F34F2E3A8288C29E18"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/load-str str3 -1 16
		big4: _bignum/mul big big2 false
		--assert 0 = _bignum/compare big3 big4
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3
		_bignum/bn-free big4

	--test-- "mul-test-6"
		str:  "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		str2: "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		str3: "14B66DC327250550964E355433697545A3163C9C55F1F90FC36640DBE2EA768FBEB61186DEA18938972D845C5FA77C672F86B7CB4A02ADC81A2CD5D4D8690FA8FBE8B7F27C22F906D54F4A0955B82270F037BF6F49DFE8DC9C22CF99F9C8FBBF4B16F5D4AEFC3422AD9EAD514F868E5E6E7C5F7E0F8BA9386DC0A8D6115D71C602EA4D22E32FC33CD4005C9C2C851D89751C363AB64E0BE757E326FB9875100"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/load-str str3 -1 16
		big4: _bignum/mul big big2 false
		--assert 0 = _bignum/compare big3 big4
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3
		_bignum/bn-free big4

===end-group===

===start-group=== "left-shift tests"
	--test-- "left-shift-test-1"
		str:  "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		str3: "91A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C480000000000000000000000000000000"
		big: _bignum/load-str str -1 16
		big3: _bignum/load-str str3 -1 16
		big4: _bignum/left-shift big 123 false
		--assert 0 = _bignum/compare big3 big4
		_bignum/bn-free big
		_bignum/bn-free big3
		_bignum/bn-free big4

===end-group===

===start-group=== "right-shift tests"
	--test-- "right-shift-test-1"
		str:  "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		str3: "2468ACF1202468ACF1202468ACF1202468ACF1202468ACF1202468ACF1202468ACF1202468ACF1202468ACF1202468ACF1202468ACF1202468ACF1202468ACF12"
		big: _bignum/load-str str -1 16
		big3: _bignum/load-str str3 -1 16
		big4: _bignum/right-shift big 123 false
		--assert 0 = _bignum/compare big3 big4
		_bignum/bn-free big
		_bignum/bn-free big3
		_bignum/bn-free big4

===end-group===

===start-group=== "div tests"
	--test-- "div-test-1"
		str:  "4CE66F58EC3858F34F2E3A8288C29E18"
		str2: "B8672F8CEEBC1448"
		str3: "6AC1F425FF4780EB"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/load-str str3 -1 16
		pQ: 0
		pR: 0
		--assert true = _bignum/div big big2 :pQ :pR false
		big4: as bignum! pQ
		big5: as bignum! pR
		--assert 0 = _bignum/compare big3 big4
		--assert 0 = _bignum/compare-int big5 0
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3
		_bignum/bn-free big4
		_bignum/bn-free big5

	--test-- "div-test-2"
		str:  "14B66DC327250550964E355433697545A3163C9C55F1F90FC36640DBE2EA768FBEB61186DEA18938972D845C5FA77C672F86B7CB4A02ADC81A2CD5D4D8690FA8FBE8B7F27C22F906D54F4A0955B82270F037BF6F49DFE8DC9C22CF99F9C8FBBF4B16F5D4AEFC3422AD9EAD514F868E5E6E7C5F7E0F8BA9386DC0A8D6115D71C602EA4D22E32FC33CD4005C9C2C851D89751C363AB64E0BE757E326FB9875100"
		str2: "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		str3: "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/load-str str3 -1 16
		pQ: 0
		pR: 0
		--assert true = _bignum/div big big2 :pQ :pR false
		big4: as bignum! pQ
		big5: as bignum! pR
		--assert 0 = _bignum/compare big3 big4
		--assert 0 = _bignum/compare-int big5 0
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3
		_bignum/bn-free big4
		_bignum/bn-free big5

	--test-- "div-test-3"
		str:  "14B66DC327250550964E355433697545A3163C9C55F1F90FC36640DBE2EA768FBEB61186DEA18938972D845C5FA77C672F86B7CB4A02ADC81A2CD5D4D8690FA8FBE8B7F27C22F906D54F4A0955B82270F037BF6F49DFE8DC9C22CF99F9C8FBBF4B16F5D4AEFC3422AD9EAD514F868E5E6E7C5F7E0F8BA9386DC0A8D6115D71C602EA4D22E32FC33CD4005C9C2C851D89751C363AB64E0BE757E326FB9875101"
		str2: "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		str3: "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		big: _bignum/load-str str -1 16
		big2: _bignum/load-str str2 -1 16
		big3: _bignum/load-str str3 -1 16
		pQ: 0
		pR: 0
		--assert true = _bignum/div big big2 :pQ :pR false
		big4: as bignum! pQ
		big5: as bignum! pR
		--assert 0 = _bignum/compare big3 big4
		--assert 0 = _bignum/compare-int big5 1
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3
		_bignum/bn-free big4
		_bignum/bn-free big5

===end-group===

===start-group=== "mod(behave like rebol) tests"
	--test-- "mod-test-1"
		big: _bignum/load-int 5
		big2: _bignum/load-int 3
		pR: 0
		--assert true = _bignum/mod big big2 :pR false
		big3: as bignum! pR
		--assert 0 = _bignum/compare-int big3 2
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3

	--test-- "mod-test-2"
		big: _bignum/load-int 5
		big2: _bignum/load-int -3
		pR: 0
		--assert true = _bignum/mod big big2 :pR false
		big3: as bignum! pR
		--assert 0 = _bignum/compare-int big3 2
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3

	--test-- "mod-test-3"
		big: _bignum/load-int -5
		big2: _bignum/load-int -3
		pR: 0
		--assert true = _bignum/mod big big2 :pR false
		big3: as bignum! pR
		--assert 0 = _bignum/compare-int big3 -5
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3

	--test-- "mod-test-4"
		big: _bignum/load-int -5
		big2: _bignum/load-int 3
		pR: 0
		--assert true = _bignum/mod big big2 :pR false
		big3: as bignum! pR
		--assert 0 = _bignum/compare-int big3 1
		_bignum/bn-free big
		_bignum/bn-free big2
		_bignum/bn-free big3

===end-group===

===start-group=== "write-string tests"
	--test-- "write-string-1"
		str: "1000000000000000000"
		big: _bignum/load-str str -1 10
		iBuf: 0
		iLen: 0
		--assert true = _bignum/write-string big 10 :iBuf :iLen
		buf: (as c-string! iBuf) + 4
		big2: _bignum/load-str buf -1 10
		--assert 0 = _bignum/compare big big2
		_bignum/bn-free big
		_bignum/bn-free big2
		free as byte-ptr! iBuf

	--test-- "write-string-2"
		str: "-1000000000000000000"
		big: _bignum/load-str str -1 10
		iBuf: 0
		iLen: 0
		--assert true = _bignum/write-string big 10 :iBuf :iLen
		buf: (as c-string! iBuf) + 4
		big2: _bignum/load-str buf -1 10
		--assert 0 = _bignum/compare big big2
		_bignum/bn-free big
		_bignum/bn-free big2
		free as byte-ptr! iBuf

	--test-- "write-string-3"
		str: "112233445566778899AABBCCDDEEFF"
		big: _bignum/load-str str -1 16
		iBuf: 0
		iLen: 0
		--assert true = _bignum/write-string big 16 :iBuf :iLen
		buf: (as c-string! iBuf) + 4
		big2: _bignum/load-str buf -1 16
		--assert 0 = _bignum/compare big big2
		_bignum/bn-free big
		_bignum/bn-free big2
		free as byte-ptr! iBuf

	--test-- "write-string-4"
		str: "-112233445566778899AABBCCDDEEFF"
		big: _bignum/load-str str -1 16
		iBuf: 0
		iLen: 0
		--assert true = _bignum/write-string big 16 :iBuf :iLen
		buf: (as c-string! iBuf) + 4
		big2: _bignum/load-str buf -1 16
		--assert 0 = _bignum/compare big big2
		_bignum/bn-free big
		_bignum/bn-free big2
		free as byte-ptr! iBuf

===end-group===

===start-group=== "complex tests"
	--test-- "complex-1"
		strA: "EFE021C2645FD1DC586E69184AF4A31ED5F53E93B5F123FA41680867BA110131944FE7952E2517337780CB0DB80E61AAE7C8DDC6C5C6AADEB34EB38A2F40D5E6"
		A: _bignum/load-str strA -1 16
		strE: "B2E7EFD37075B9F03FF989C7C5051C2034D2A323810251127E7BF8625A4F49A5F3E27F4DA8BD59C47D6DAABA4C8127BD5B5C25763222FEFCCFC38B832366C29E"
		E: _bignum/load-str strE -1 16
		strN: "0066A198186C18C10B2F5ED9B522752A9830B69916E535C8F047518A889A43A594B6BED27A168D31D4A52F88925AA8F5"
		N: _bignum/load-str strN -1 16
		T: _bignum/mul A N false
		strU: "602AB7ECA597A3D6B56FF9829A5E8B859E857EA95A03512E2BAE7391688D264AA5663B0341DB9CCFD2C4C5F421FEC8148001B72E848A38CAE1C65F78E56ABDEFE12D3C039B8A02D6BE593F0BBBDA56F1ECF677152EF804370C1A305CAF3B5BF130879B56C61DE584A0F53A2447A51E"
		U: _bignum/load-str strU -1 16
		--assert 0 = _bignum/compare T U
		iX: 0
		iY: 0
		--assert true = _bignum/div A N :iX :iY false
		X: as bignum! iX
		Y: as bignum! iY
		strX2: "256567336059E52CAE22925474705F39A94"
		X2: _bignum/load-str strX2 -1 16
		strY2: "6613F26162223DF488E9CD48CC132C7A0AC93C701B001B092E4E5B9F73BCD27B9EE50D0657C77F374E903CDFA4C642"
		Y2: _bignum/load-str strY2 -1 16
		--assert 0 = _bignum/compare X X2
		--assert 0 = _bignum/compare Y Y2
		_bignum/bn-free A
		_bignum/bn-free E
		_bignum/bn-free N
		_bignum/bn-free T
		_bignum/bn-free U
		_bignum/bn-free X
		_bignum/bn-free Y
		_bignum/bn-free X2
		_bignum/bn-free Y2

===end-group===

~~~end-file~~~
