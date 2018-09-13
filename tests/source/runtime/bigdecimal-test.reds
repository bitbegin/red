Red/System []

#include %../../../quick-test/quick-test.reds
#include %../../../runtime/bigdecimal.reds

~~~start-file~~~ "bigdecimal tests"

===start-group=== "load and form"
	--test-- "load-and-form-1"
		str: "0.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 1
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen

	--test-- "load-and-form-2"
		str: "1.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 1
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen

	--test-- "load-and-form-3"
		str: "10.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 2
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen

	--test-- "load-and-form-4"
		str: "100.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 3
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen

	--test-- "load-and-form-5"
		str: "1000000000.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 10
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen

	--test-- "load-and-form-6"
		str: "10000000000000000000.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen

	--test-- "load-and-form-7"
		str: "100000000000000000000.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen

	--test-- "load-and-form-8"
		str: "100000000000000000000.1"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen

	--test-- "load-and-form-9"
		str: "10000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 5
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen

	--test-- "load-and-form-10"
		str: "0.1"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 3
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen

	--test-- "load-and-form-11"
		str: "0.01"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 4
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen

	--test-- "load-and-form-12"
		str: "0.0000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 12
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen

	--test-- "load-and-form-13"
		str: "0.0000000000000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen

	--test-- "load-and-form-14"
		str: "01234567890.123456789"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! str + 1 as byte-ptr! ibuf ilen

	--test-- "load-and-form-15"
		str: "01234567890.123456789111"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! str + 1 as byte-ptr! ibuf ilen

	--test-- "load-and-form-16"
		str: "01234567890.123456789111E999"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "1.234567890123456789E1008" as byte-ptr! ibuf ilen

	--test-- "load-and-form-17"
		str: "01234567890.123456789111E-999"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "1.234567890123456789E-990" as byte-ptr! ibuf ilen

	--test-- "load-and-form-18"
		str: "9.0E1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 14
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen

	--test-- "load-and-form-19"
		str: "9.0E-1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 15
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen

	--test-- "load-and-form-20"
		str: "1.0E1000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.#INF" as byte-ptr! ibuf ilen

	--test-- "load-and-form-21"
		str: "1.0E-1000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.#INF" as byte-ptr! ibuf ilen

	--test-- "load-and-form-22"
		str: "1.#INF"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen

	--test-- "load-and-form-23"
		str: "-1.#INF"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen

	--test-- "load-and-form-24"
		str: "1.#NaN"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen

		;print-line ["ilen: " ilen]
		;print-line ["ibuf: " as c-string! ibuf]
===end-group===

~~~end-file~~~