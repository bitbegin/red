Red/System []

#include %../../../quick-test/quick-test.reds
#include %../../../runtime/bigint.reds

~~~start-file~~~ "bigint tests"

big: as bigint! 0
big2: as bigint! 0

===start-group=== "load positive int"
	--test-- "load-pos-int-1"
		big: bigint/load-int 0
		--assert bigint/zero?* big
		bigint/free* big

	--test-- "load-pos-int-2"
		big: bigint/load-int 100
		--assert 0 = bigint/compare-int big 100
		bigint/free* big

	--test-- "load-pos-int-3"
		big: bigint/load-int 10000
		--assert 0 = bigint/compare-int big 10000
		bigint/free* big

	--test-- "load-pos-int-4"
		big: bigint/load-int 1000000
		--assert 0 = bigint/compare-int big 1000000
		bigint/free* big

	--test-- "load-pos-int-5"
		big: bigint/load-int 100000000
		--assert 0 = bigint/compare-int big 100000000
		bigint/free* big

	--test-- "load-pos-int-6"
		big: bigint/load-int 1000000000
		--assert 0 = bigint/compare-int big 1000000000
		bigint/free* big

===end-group===

===start-group=== "load negative int"
	--test-- "load-neg-int-1"
		big: bigint/load-int -0
		--assert bigint/zero?* big
		bigint/free* big

	--test-- "load-neg-int-2"
		big: bigint/load-int -100
		--assert 0 = bigint/compare-int big -100
		bigint/free* big

	--test-- "load-neg-int-3"
		big: bigint/load-int -10000
		--assert 0 = bigint/compare-int big -10000
		bigint/free* big

	--test-- "load-neg-int-4"
		big: bigint/load-int -1000000
		--assert 0 = bigint/compare-int big -1000000
		bigint/free* big

	--test-- "load-neg-int-5"
		big: bigint/load-int -100000000
		--assert 0 = bigint/compare-int big -100000000
		bigint/free* big

	--test-- "load-neg-int-6"
		big: bigint/load-int -1000000000
		--assert 0 = bigint/compare-int big -1000000000
		bigint/free* big

===end-group===

===start-group=== "load int and negative"
	--test-- "load-int-neg-1"
		big: bigint/load-int 0
		big2: bigint/negative* big false
		--assert 0 = bigint/compare-int big2 -0
		bigint/free* big
		bigint/free* big2

	--test-- "load-int-neg-2"
		big: bigint/load-int 100
		big2: bigint/negative* big false
		--assert 0 = bigint/compare-int big2 -100
		bigint/free* big
		bigint/free* big2

	--test-- "load-int-neg-3"
		big: bigint/load-int 10000
		big2: bigint/negative* big false
		--assert 0 = bigint/compare-int big2 -10000
		bigint/free* big
		bigint/free* big2

	--test-- "load-int-neg-4"
		big: bigint/load-int 1000000
		big2: bigint/negative* big false
		--assert 0 = bigint/compare-int big2 -1000000
		bigint/free* big
		bigint/free* big2

	--test-- "load-int-neg-5"
		big: bigint/load-int 100000000
		big2: bigint/negative* big false
		--assert 0 = bigint/compare-int big2 -100000000
		bigint/free* big
		bigint/free* big2

	--test-- "load-int-neg-6"
		big: bigint/load-int 1000000000
		big2: bigint/negative* big false
		--assert 0 = bigint/compare-int big2 -1000000000
		bigint/free* big
		bigint/free* big2

===end-group===

===start-group=== "load uint"
	--test-- "load-uint-1"
		big: bigint/load-uint 0
		--assert bigint/zero?* big
		bigint/free* big

	--test-- "load-uint-2"
		big: bigint/load-uint 100
		--assert 0 = bigint/compare-int big 100
		bigint/free* big

	--test-- "load-uint-3"
		big: bigint/load-uint 10000
		--assert 0 = bigint/compare-int big 10000
		bigint/free* big

	--test-- "load-uint-4"
		big: bigint/load-uint 1000000
		--assert 0 = bigint/compare-int big 1000000
		bigint/free* big

	--test-- "load-uint-5"
		big: bigint/load-uint 100000000
		--assert 0 = bigint/compare-int big 100000000
		bigint/free* big

	--test-- "load-uint-6"
		big: bigint/load-uint 1000000000
		--assert 0 = bigint/compare-int big 1000000000
		bigint/free* big

	--test-- "load-uint-7"
		big: bigint/load-uint -100
		--assert 1 = bigint/compare-int big 100
		bigint/free* big

	--test-- "load-uint-8"
		big: bigint/load-uint -10000
		--assert 1 = bigint/compare-int big 10000
		bigint/free* big

	--test-- "load-uint-9"
		big: bigint/load-uint -1000000
		--assert 1 = bigint/compare-int big 1000000
		bigint/free* big

	--test-- "load-uint-10"
		big: bigint/load-uint -100000000
		--assert 1 = bigint/compare-int big 100000000
		bigint/free* big

	--test-- "load-uint-11"
		big: bigint/load-uint -1000000000
		--assert 1 = bigint/compare-int big 1000000000
		bigint/free* big

===end-group===

===start-group=== "load bin"
	--test-- "load-bin-1"
		bin1: [#"^(11)" #"^(22)" #"^(33)" #"^(44)" #"^(55)" #"^(66)" #"^(77)"]
		big: bigint/load-bin bin1 size? bin1
		--assert bigint/equal-bin? big bin1 size? bin1
		bigint/free* big

	--test-- "load-bin-2"
		bin2: [#"^(00)" #"^(11)" #"^(22)" #"^(33)" #"^(44)" #"^(55)" #"^(66)" #"^(77)" #"^(88)" #"^(99)" #"^(AA)" #"^(BB)" #"^(CC)" #"^(DD)" #"^(EE)" #"^(FF)"]
		big: bigint/load-bin bin2 size? bin2
		--assert bigint/equal-bin? big bin2 size? bin2
		bigint/free* big

	--test-- "load-bin-3"
		bin3: [#"^(3B)" #"^(9A)" #"^(CA)" #"^(00)"]
		big: bigint/load-bin bin3 size? bin3
		--assert 0 = bigint/compare-int big 1000000000
		bigint/free* big

	--test-- "load-bin-4"
		bin4: [#"^(0D)" #"^(E0)" #"^(B6)" #"^(B3)" #"^(A7)" #"^(64)" #"^(00)" #"^(00)"]
		big: bigint/load-bin bin4 size? bin4
		big2: bigint/load-int 1000000000
		big3: bigint/mul-int big2 1000000000 false
		--assert 0 = bigint/compare big big3
		bigint/free* big
		bigint/free* big2
		bigint/free* big3

===end-group===

===start-group=== "load str base10"
	--test-- "load-base10-1"
		str: "1000000000"
		big: bigint/load-str str -1 10
		--assert 0 = bigint/compare-int big 1000000000
		bigint/free* big

	--test-- "load-base10-2"
		str: "1000000000000000000"
		big: bigint/load-str str -1 10
		big2: bigint/load-bin bin4 size? bin4
		--assert 0 = bigint/compare big big2
		bigint/free* big
		bigint/free* big2

	--test-- "load-base10-3"
		str: "+1000000000000000000"
		big: bigint/load-str str -1 10
		big2: bigint/load-bin bin4 size? bin4
		--assert 0 = bigint/compare big big2
		bigint/free* big
		bigint/free* big2

	--test-- "load-base10-4"
		str: "-1000000000000000000"
		big: bigint/load-str str -1 10
		big2: bigint/load-bin bin4 size? bin4
		big3: bigint/negative* big2 false
		--assert 0 = bigint/compare big big3
		bigint/free* big
		bigint/free* big2
		bigint/free* big3

===end-group===

===start-group=== "load str base16"
	--test-- "load-base16-1"
		str: "3B9ACA00"
		big: bigint/load-str str -1 16
		--assert 0 = bigint/compare-int big 1000000000
		bigint/free* big

	--test-- "load-base16-2"
		str: "DE0B6B3A7640000"
		big: bigint/load-str str -1 16
		big2: bigint/load-bin bin4 size? bin4
		--assert 0 = bigint/compare big big2
		bigint/free* big
		bigint/free* big2

	--test-- "load-base16-3"
		str: "112233445566778899AABBCCDDEEFF"
		big: bigint/load-str str -1 16
		big2: bigint/load-bin bin2 size? bin2
		--assert 0 = bigint/compare big big2
		bigint/free* big
		bigint/free* big2

	--test-- "load-base16-4"
		str: "+112233445566778899AABBCCDDEEFF"
		big: bigint/load-str str -1 16
		big2: bigint/load-bin bin2 size? bin2
		--assert 0 = bigint/compare big big2
		bigint/free* big
		bigint/free* big2

	--test-- "load-base16-5"
		str: "-112233445566778899AABBCCDDEEFF"
		big: bigint/load-str str -1 16
		big2: bigint/load-bin bin2 size? bin2
		big2/used: 0 - big2/used
		--assert 0 = bigint/compare big big2
		bigint/free* big
		bigint/free* big2

===end-group===

===start-group=== "add tests"
	--test-- "add-test-1"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929D"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/add-int big 1 false
		--assert 0 = bigint/compare big2 big3
		bigint/free* big
		bigint/free* big2
		bigint/free* big3

	--test-- "add-test-2"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "6AC1F425FF4780EB"
		str3: "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FD4B8E42103A0D1387"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/add big big2 false
		--assert 0 = bigint/compare big3 big4
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4

	--test-- "add-test-3"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "0702DF9D88CF598EABA3C232E9F96A446AD47CD7750B5FD78F064BE96E4242F1"
		str3: "7253349BD9020AF45B0E4DC5704234189F2B7862E69180D46FD299D3A907D58D"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/add big big2 false
		--assert 0 = bigint/compare big3 big4
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4

	--test-- "add-test-4"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "47CB2D6F7235DEE2CA0E35D738DD27871A6D051A12C7FE9972A9266878200416"
		str3: "B31B826DC26890487978C169BF25F15B4EC400A5844E1F9653757452B2E596B2"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/add big big2 false
		--assert 0 = bigint/compare big3 big4
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4

	--test-- "add-test-5"
		str:  "-6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "-47CB2D6F7235DEE2CA0E35D738DD27871A6D051A12C7FE9972A9266878200416"
		str3: "-B31B826DC26890487978C169BF25F15B4EC400A5844E1F9653757452B2E596B2"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/add big big2 false
		--assert 0 = bigint/compare big3 big4
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4

	--test-- "add-test-6"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929B"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/add-int big -1 false
		--assert 0 = bigint/compare big2 big3
		bigint/free* big
		bigint/free* big2
		bigint/free* big3

===end-group===

===start-group=== "sub tests"
	--test-- "sub-test-1"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929B"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/sub-int big 1 false
		--assert 0 = bigint/compare big2 big3
		bigint/free* big
		bigint/free* big2
		bigint/free* big3

	--test-- "sub-test-2"
		str:  "B8672F8CEEBC1448"
		str2: "89EFE4B2D8A7D514"
		str3: "2E774ADA16143F34"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/sub big big2 false
		--assert 0 = bigint/compare big3 big4
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4

	--test-- "sub-test-3"
		str:   "6AC1F425FF4780EB"
		str2:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FD4B8E42103A0D1387"
		str3: "-6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/sub big big2 false
		--assert 0 = bigint/compare big3 big4
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4

	--test-- "sub-test-4"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "04AE8A6D08BF7373C00975299FC06DD2FD26000FA91F6C40BF87C8C44C6A3019"
		str3: "66A1CA9147733DF1EF611668E6885C013730FB7BC866B4BC21448525EE5B6283"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/sub big big2 false
		--assert 0 = bigint/compare big3 big4
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4

===end-group===

===start-group=== "uint-mul tests"
	--test-- "uint-mul-test-1"
		rh: 0
		rl: 0
		bigint/uint-mul 0 0 :rh :rl
		--assert rh = 0
		--assert rl = 0

	--test-- "uint-mul-test-2"
		rh: 0
		rl: 0
		bigint/uint-mul 0 1 :rh :rl
		--assert rh = 0
		--assert rl = 0

	--test-- "uint-mul-test-3"
		rh: 0
		rl: 0
		bigint/uint-mul 1 0 :rh :rl
		--assert rh = 0
		--assert rl = 0

	--test-- "uint-mul-test-4"
		rh: 0
		rl: 0
		bigint/uint-mul 1 1 :rh :rl
		--assert rh = 0
		--assert rl = 1

	--test-- "uint-mul-test-5"
		rh: 0
		rl: 0
		bigint/uint-mul 10 10 :rh :rl
		--assert rh = 0
		--assert rl = 100

	--test-- "uint-mul-test-6"
		rh: 0
		rl: 0
		bigint/uint-mul 100 100 :rh :rl
		--assert rh = 0
		--assert rl = 10000

	--test-- "uint-mul-test-7"
		rh: 0
		rl: 0
		bigint/uint-mul 100 100 :rh :rl
		--assert rh = 0
		--assert rl = 10000

	--test-- "uint-mul-test-8"
		rh: 0
		rl: 0
		bigint/uint-mul 1000 1000 :rh :rl
		--assert rh = 0
		--assert rl = 1000000

	--test-- "uint-mul-test-9"
		rh: 0
		rl: 0
		bigint/uint-mul 10000 10000 :rh :rl
		--assert rh = 0
		--assert rl = 100000000

	--test-- "uint-mul-test-10"
		rh: 0
		rl: 0
		bigint/uint-mul 100000 100000 :rh :rl
		--assert rh = 2
		--assert rl = 540BE400h

	--test-- "uint-mul-test-11"
		rh: 0
		rl: 0
		bigint/uint-mul 1000000 1000000 :rh :rl
		--assert rh = E8h
		--assert rl = D4A51000h

	--test-- "uint-mul-test-12"
		rh: 0
		rl: 0
		bigint/uint-mul 10000000 10000000 :rh :rl
		--assert rh = 5AF3h
		--assert rl = 107A4000h

	--test-- "uint-mul-test-13"
		rh: 0
		rl: 0
		bigint/uint-mul 100000000 100000000 :rh :rl
		--assert rh = 002386F2h
		--assert rl = 6FC10000h

	--test-- "uint-mul-test-14"
		rh: 0
		rl: 0
		bigint/uint-mul 1000000000 1000000000 :rh :rl
		--assert rh = 0DE0B6B3h
		--assert rl = A7640000h

	--test-- "uint-mul-test-15"
		rh: 0
		rl: 0
		bigint/uint-mul FFFFFFFFh FFFFFFFFh :rh :rl
		--assert rh = FFFFFFFEh
		--assert rl = 1

===end-group===

===start-group=== "uint-div tests"
	--test-- "uint-div-test-1"
		q: 0
		r: 0
		bigint/uint-div 0 1 :q :r
		--assert q = 0
		--assert r = 0

	--test-- "uint-div-test-2"
		q: 0
		r: 0
		bigint/uint-div 1 1 :q :r
		--assert q = 1
		--assert r = 0

	--test-- "uint-div-test-3"
		q: 0
		r: 0
		bigint/uint-div 7FFFFFFFh 00000001h :q :r
		--assert q = 7FFFFFFFh
		--assert r = 0

	--test-- "uint-div-test-4"
		q: 0
		r: 0
		bigint/uint-div 7FFFFFFFh 00000010h :q :r
		--assert q = 07FFFFFFh
		--assert r = 0Fh

	--test-- "uint-div-test-5"
		q: 0
		r: 0
		bigint/uint-div 7FFFFFFFh 00000100h :q :r
		--assert q = 007FFFFFh
		--assert r = 00FFh

	--test-- "uint-div-test-6"
		q: 0
		r: 0
		bigint/uint-div FFFFFFFFh 00000001h :q :r
		--assert q = FFFFFFFFh
		--assert r = 0

	--test-- "uint-div-test-7"
		q: 0
		r: 0
		bigint/uint-div FFFFFFFFh 00000010h :q :r
		--assert q = 0FFFFFFFh
		--assert r = 0Fh

	--test-- "uint-div-test-8"
		q: 0
		r: 0
		bigint/uint-div FFFFFFFFh 00000100h :q :r
		--assert q = 00FFFFFFh
		--assert r = 00FFh

	--test-- "uint-div-test-9"
		q: 0
		r: 0
		bigint/uint-div FFFFFFFFh 00001000h :q :r
		--assert q = 000FFFFFh
		--assert r = 0FFFh

	--test-- "uint-div-test-10"
		q: 0
		r: 0
		bigint/uint-div FFFFFFFFh 00010000h :q :r
		--assert q = 0000FFFFh
		--assert r = FFFFh

	--test-- "uint-div-test-11"
		q: 0
		r: 0
		bigint/uint-div FFFFFFFFh 00100000h :q :r
		--assert q = 00000FFFh
		--assert r = 000FFFFFh

	--test-- "uint-div-test-12"
		q: 0
		r: 0
		bigint/uint-div FFFFFFFFh 01000000h :q :r
		--assert q = 000000FFh
		--assert r = 00FFFFFFh

	--test-- "uint-div-test-13"
		q: 0
		r: 0
		bigint/uint-div FFFFFFFFh 10000000h :q :r
		--assert q = 0000000Fh
		--assert r = 0FFFFFFFh

	--test-- "uint-div-test-14"
		q: 0
		r: 0
		bigint/uint-div FFFFFFFFh 80000000h :q :r
		--assert q = 1
		--assert r = 7FFFFFFFh

	--test-- "uint-div-test-15"
		q: 0
		r: 0
		bigint/uint-div 80000000h FFFFh :q :r
		--assert q = 8000h
		--assert r = 8000h

===end-group===

===start-group=== "long-divide tests"
	--test-- "long-divide-test-1"
		r: 0
		q: bigint/long-divide 0 0 0 :r
		--assert q = -1
		--assert r = -1

	--test-- "long-divide-test-2"
		r: 0
		q: bigint/long-divide 1 1 0 :r
		--assert q = -1
		--assert r = -1

	--test-- "long-divide-test-3"
		r: 0
		q: bigint/long-divide 1 1 1 :r
		--assert q = -1
		--assert r = -1

	--test-- "long-divide-test-4"
		r: 0
		q: bigint/long-divide 0 10000 3 :r
		--assert q = 3333
		--assert r = 1

	--test-- "long-divide-test-5"
		r: 0
		q: bigint/long-divide 0 1000000000 3 :r
		--assert q = 333333333
		--assert r = 1

	--test-- "long-divide-test-6"
		r: 0
		q: bigint/long-divide 002386F2h 6FC10000h 100000000 :r
		--assert q = 100000000
		--assert r = 0

===end-group===

===start-group=== "mul tests"
	--test-- "mul-test-1"
		str:  "02"
		str2: "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str3: "D6A0A9FCA06562CB5ED517250C9193A868ADF716E30C41F9C1989BD4758B2538"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/mul big big2 false
		--assert 0 = bigint/compare big3 big4
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4

	--test-- "mul-test-2"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "02"
		str3: "D6A0A9FCA06562CB5ED517250C9193A868ADF716E30C41F9C1989BD4758B2538"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/mul big big2 false
		--assert 0 = bigint/compare big3 big4
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4

	--test-- "mul-test-3"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "02"
		str3: "D6A0A9FCA06562CB5ED517250C9193A868ADF716E30C41F9C1989BD4758B2538"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/mul-int big 2 false
		--assert 0 = bigint/compare big3 big4
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4

	--test-- "mul-test-4"
		str:  "6B5054FE5032B165AF6A8B928648C9D43456FB8B718620FCE0CC4DEA3AC5929C"
		str2: "-02"
		str3: "-D6A0A9FCA06562CB5ED517250C9193A868ADF716E30C41F9C1989BD4758B2538"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/mul big big2 false
		--assert 0 = bigint/compare big3 big4
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4

	--test-- "mul-test-5"
		str:  "B8672F8CEEBC1448"
		str2: "6AC1F425FF4780EB"
		str3: "4CE66F58EC3858F34F2E3A8288C29E18"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/mul big big2 false
		--assert 0 = bigint/compare big3 big4
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4

	--test-- "mul-test-6"
		str:  "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		str2: "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		str3: "14B66DC327250550964E355433697545A3163C9C55F1F90FC36640DBE2EA768FBEB61186DEA18938972D845C5FA77C672F86B7CB4A02ADC81A2CD5D4D8690FA8FBE8B7F27C22F906D54F4A0955B82270F037BF6F49DFE8DC9C22CF99F9C8FBBF4B16F5D4AEFC3422AD9EAD514F868E5E6E7C5F7E0F8BA9386DC0A8D6115D71C602EA4D22E32FC33CD4005C9C2C851D89751C363AB64E0BE757E326FB9875100"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/mul big big2 false
		--assert 0 = bigint/compare big3 big4
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4

===end-group===

===start-group=== "left-shift tests"
	--test-- "left-shift-test-1"
		str:  "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		str3: "91A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C48091A2B3C480000000000000000000000000000000"
		big: bigint/load-str str -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/left-shift big 123 false
		--assert 0 = bigint/compare big3 big4
		bigint/free* big
		bigint/free* big3
		bigint/free* big4

===end-group===

===start-group=== "right-shift tests"
	--test-- "right-shift-test-1"
		str:  "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		str3: "2468ACF1202468ACF1202468ACF1202468ACF1202468ACF1202468ACF1202468ACF1202468ACF1202468ACF1202468ACF1202468ACF1202468ACF1202468ACF12"
		big: bigint/load-str str -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/right-shift big 123 false
		--assert 0 = bigint/compare big3 big4
		bigint/free* big
		bigint/free* big3
		bigint/free* big4

===end-group===

===start-group=== "div tests"

	--test-- "div-test-1"
		str:  "1234567890123456789"
		str2: "1"
		str3: "1234567890123456789"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/div big big2 false
		big5: bigint/remainder big big2 false
		--assert 0 = bigint/compare big3 big4
		--assert 0 = bigint/compare-int big5 0
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4
		bigint/free* big5

	--test-- "div-test-2"
		str:  "4CE66F58EC3858F34F2E3A8288C29E18"
		str2: "B8672F8CEEBC1448"
		str3: "6AC1F425FF4780EB"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/div big big2 false
		big5: bigint/remainder big big2 false
		--assert 0 = bigint/compare big3 big4
		--assert 0 = bigint/compare-int big5 0
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4
		bigint/free* big5

	--test-- "div-test-3"
		str:  "14B66DC327250550964E355433697545A3163C9C55F1F90FC36640DBE2EA768FBEB61186DEA18938972D845C5FA77C672F86B7CB4A02ADC81A2CD5D4D8690FA8FBE8B7F27C22F906D54F4A0955B82270F037BF6F49DFE8DC9C22CF99F9C8FBBF4B16F5D4AEFC3422AD9EAD514F868E5E6E7C5F7E0F8BA9386DC0A8D6115D71C602EA4D22E32FC33CD4005C9C2C851D89751C363AB64E0BE757E326FB9875100"
		str2: "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		str3: "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/div big big2 false
		big5: bigint/remainder big big2 false
		--assert 0 = bigint/compare big3 big4
		--assert 0 = bigint/compare-int big5 0
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4
		bigint/free* big5

	--test-- "div-test-4"
		str:  "14B66DC327250550964E355433697545A3163C9C55F1F90FC36640DBE2EA768FBEB61186DEA18938972D845C5FA77C672F86B7CB4A02ADC81A2CD5D4D8690FA8FBE8B7F27C22F906D54F4A0955B82270F037BF6F49DFE8DC9C22CF99F9C8FBBF4B16F5D4AEFC3422AD9EAD514F868E5E6E7C5F7E0F8BA9386DC0A8D6115D71C602EA4D22E32FC33CD4005C9C2C851D89751C363AB64E0BE757E326FB9875101"
		str2: "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		str3: "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		big: bigint/load-str str -1 16
		big2: bigint/load-str str2 -1 16
		big3: bigint/load-str str3 -1 16
		big4: bigint/div big big2 false
		big5: bigint/remainder big big2 false
		--assert 0 = bigint/compare big3 big4
		--assert 0 = bigint/compare-int big5 1
		bigint/free* big
		bigint/free* big2
		bigint/free* big3
		bigint/free* big4
		bigint/free* big5

===end-group===

===start-group=== "mod(behave like rebol) tests"
	--test-- "mod-test-1"
		big: bigint/load-int 5
		big2: bigint/load-int 3
		pR: 0
		--assert true = bigint/mod big big2 :pR false
		big3: as bigint! pR
		--assert 0 = bigint/compare-int big3 2
		bigint/free* big
		bigint/free* big2
		bigint/free* big3

	--test-- "mod-test-2"
		big: bigint/load-int 5
		big2: bigint/load-int -3
		pR: 0
		--assert true = bigint/mod big big2 :pR false
		big3: as bigint! pR
		--assert 0 = bigint/compare-int big3 2
		bigint/free* big
		bigint/free* big2
		bigint/free* big3

	--test-- "mod-test-3"
		big: bigint/load-int -5
		big2: bigint/load-int -3
		pR: 0
		--assert true = bigint/mod big big2 :pR false
		big3: as bigint! pR
		--assert 0 = bigint/compare-int big3 -5
		bigint/free* big
		bigint/free* big2
		bigint/free* big3

	--test-- "mod-test-4"
		big: bigint/load-int -5
		big2: bigint/load-int 3
		pR: 0
		--assert true = bigint/mod big big2 :pR false
		big3: as bigint! pR
		--assert 0 = bigint/compare-int big3 1
		bigint/free* big
		bigint/free* big2
		bigint/free* big3

===end-group===

===start-group=== "form tests"
	--test-- "form-1"
		str: "1000000000000000000"
		big: bigint/load-str str -1 10
		iBuf: 0
		iLen: 0
		--assert true = bigint/form big 10 :iBuf :iLen
		buf: as c-string! iBuf
		big2: bigint/load-str buf -1 10
		--assert 0 = bigint/compare big big2
		bigint/free* big
		bigint/free* big2
		free as byte-ptr! iBuf

	--test-- "form-2"
		str: "-1000000000000000000"
		big: bigint/load-str str -1 10
		iBuf: 0
		iLen: 0
		--assert true = bigint/form big 10 :iBuf :iLen
		buf: as c-string! iBuf
		big2: bigint/load-str buf -1 10
		--assert 0 = bigint/compare big big2
		bigint/free* big
		bigint/free* big2
		free as byte-ptr! iBuf

	--test-- "form-3"
		str: "112233445566778899AABBCCDDEEFF"
		big: bigint/load-str str -1 16
		iBuf: 0
		iLen: 0
		--assert true = bigint/form big 16 :iBuf :iLen
		buf: as c-string! iBuf
		big2: bigint/load-str buf -1 16
		--assert 0 = bigint/compare big big2
		bigint/free* big
		bigint/free* big2
		free as byte-ptr! iBuf

	--test-- "form-4"
		str: "-112233445566778899AABBCCDDEEFF"
		big: bigint/load-str str -1 16
		iBuf: 0
		iLen: 0
		--assert true = bigint/form big 16 :iBuf :iLen
		buf: as c-string! iBuf
		big2: bigint/load-str buf -1 16
		--assert 0 = bigint/compare big big2
		bigint/free* big
		bigint/free* big2
		free as byte-ptr! iBuf

	--test-- "form-5"
		str: "0"
		big: bigint/load-str str -1 10
		iBuf: 0
		iLen: 0
		--assert true = bigint/form big 10 :iBuf :iLen
		--assert iLen = 1
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! iBuf iLen
		bigint/free* big
		free as byte-ptr! iBuf

	--test-- "form-6"
		str: "123456789012345678901234567890"
		big: bigint/load-str str -1 10
		iBuf: 0
		iLen: 0
		--assert true = bigint/form big 10 :iBuf :iLen
		--assert iLen = 30
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! iBuf iLen
		bigint/free* big
		free as byte-ptr! iBuf

===end-group===

===start-group=== "complex tests"
	--test-- "complex-1"
		strA: "EFE021C2645FD1DC586E69184AF4A31ED5F53E93B5F123FA41680867BA110131944FE7952E2517337780CB0DB80E61AAE7C8DDC6C5C6AADEB34EB38A2F40D5E6"
		A: bigint/load-str strA -1 16
		strE: "B2E7EFD37075B9F03FF989C7C5051C2034D2A323810251127E7BF8625A4F49A5F3E27F4DA8BD59C47D6DAABA4C8127BD5B5C25763222FEFCCFC38B832366C29E"
		E: bigint/load-str strE -1 16
		strN: "0066A198186C18C10B2F5ED9B522752A9830B69916E535C8F047518A889A43A594B6BED27A168D31D4A52F88925AA8F5"
		N: bigint/load-str strN -1 16
		T: bigint/mul A N false
		strU: "602AB7ECA597A3D6B56FF9829A5E8B859E857EA95A03512E2BAE7391688D264AA5663B0341DB9CCFD2C4C5F421FEC8148001B72E848A38CAE1C65F78E56ABDEFE12D3C039B8A02D6BE593F0BBBDA56F1ECF677152EF804370C1A305CAF3B5BF130879B56C61DE584A0F53A2447A51E"
		U: bigint/load-str strU -1 16
		--assert 0 = bigint/compare T U
		X: bigint/div A N false
		Y: bigint/remainder A N false
		strX2: "256567336059E52CAE22925474705F39A94"
		X2: bigint/load-str strX2 -1 16
		strY2: "6613F26162223DF488E9CD48CC132C7A0AC93C701B001B092E4E5B9F73BCD27B9EE50D0657C77F374E903CDFA4C642"
		Y2: bigint/load-str strY2 -1 16
		--assert 0 = bigint/compare X X2
		--assert 0 = bigint/compare Y Y2
		bigint/free* A
		bigint/free* E
		bigint/free* N
		bigint/free* T
		bigint/free* U
		bigint/free* X
		bigint/free* Y
		bigint/free* X2
		bigint/free* Y2

===end-group===

~~~end-file~~~
