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
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-2"
		str: "+00000.00000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 1
		--assert 0 = compare-memory as byte-ptr! str + 1 as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-3"
		str: "-00000.00000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 1
		--assert 0 = compare-memory as byte-ptr! str + 1 as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-4"
		str: "1.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 1
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-5"
		str: "10.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 2
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-6"
		str: "100.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 3
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-7"
		str: "1000000000.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 10
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-8"
		str: "10000000000000000000.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-9"
		str: "100000000000000000000.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-10"
		str: "100000000000000000000.1"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-11"
		str: "-1.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 2
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-12"
		str: "-1000000000.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 11
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-13"
		str: "-10000000000000000000.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-14"
		str: "-100000000000000000000.0"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-15"
		str: "-100000000000000000000.1"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-16"
		str: "+100000000000000000000.1"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-17"
		str: "10000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 5
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-18"
		str: "0.1"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 3
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-19"
		str: "0.01"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 4
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-20"
		str: "0.0000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 12
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-21"
		str: "0.0000000000000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-22"
		str: "0.00000000000000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 1
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-23"
		str: "-0.0000000000000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 22
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-24"
		str: "+0.0000000000000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! str + 1 as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-25"
		str: "01234567890.123456789"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! str + 1 as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-26"
		str: "01234567890.123456789111"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! str + 1 as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-27"
		str: "01234567890.123456789111E999"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "1.234567890123456789E1008" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-28"
		str: "-01234567890.123456789111E999"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 26
		--assert 0 = compare-memory as byte-ptr! "-1.234567890123456789E1008" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-29"
		str: "+01234567890.123456789111E999"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "1.234567890123456789E1008" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-30"
		str: "01234567890.123456789111E-999"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "1.234567890123456789E-990" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-31"
		str: "-01234567890.123456789111E-999"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 26
		--assert 0 = compare-memory as byte-ptr! "-1.234567890123456789E-990" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-32"
		str: "+01234567890.123456789111E-999"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "1.234567890123456789E-990" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-33"
		str: "9.0E1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 14
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-34"
		str: "-9.0E1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 15
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-35"
		str: "+9.0E1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 14
		--assert 0 = compare-memory as byte-ptr! str + 1 as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-36"
		str: "9.0E-1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 15
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-37"
		str: "-9.0E-1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 16
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-38"
		str: "+9.0E-1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 15
		--assert 0 = compare-memory as byte-ptr! str + 1 as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-39"
		str: "9.00000E-1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 15
		--assert 0 = compare-memory as byte-ptr! "9.0E-1000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-40"
		str: "00009.00000E-1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 15
		--assert 0 = compare-memory as byte-ptr! "9.0E-1000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-41"
		str: "-00009.00000E-1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 16
		--assert 0 = compare-memory as byte-ptr! "-9.0E-1000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-42"
		str: "+00009.00000E-1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 15
		--assert 0 = compare-memory as byte-ptr! "9.0E-1000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-43"
		str: "00009.00000E-00001000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 15
		--assert 0 = compare-memory as byte-ptr! "9.0E-1000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-44"
		str: "1.0E1000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.#INF" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-45"
		str: "-1.0E1000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.#INF" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-46"
		str: "+1.0E1000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.#INF" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-47"
		str: "1.0E-1000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.#INF" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-48"
		str: "-1.0E-1000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.#INF" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-49"
		str: "+1.0E-1000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.#INF" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-50"
		str: "1.#INF"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-51"
		str: "-1.#INF"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-52"
		str: "1.#NaN"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

		;print-line ["ilen: " ilen]
		;print-line ["ibuf: " as c-string! ibuf]
===end-group===

~~~end-file~~~
