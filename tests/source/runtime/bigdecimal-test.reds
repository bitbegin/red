Red/System []

#include %../../../quick-test/quick-test.reds
#include %../../../runtime/bigdecimal.reds

~~~start-file~~~ "bigdecimal tests"

;-- this test file use precision of 20 digits in decimal
bigdecimal/set-default-prec 20
;-- use -1000000000 for exp min
bigdecimal/set-exp-min -1000000000
;-- use 1000000000 for exp max
bigdecimal/set-exp-max  1000000000
;-- use ROUND-DOWN for rounding mode
bigdecimal/set-rounding-mode ROUND-DOWN

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
		str: "-0.0000000000000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 22
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-23"
		str: "+0.0000000000000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! str + 1 as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-24"
		str: "0.00000000000000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "1.0E-20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-25"
		str: "+0.00000000000000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "1.0E-20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-26"
		str: "-0.00000000000000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 8
		--assert 0 = compare-memory as byte-ptr! "-1.0E-20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-27"
		str: "0.000000000000000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "1.0E-21" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-28"
		str: "+0.000000000000000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "1.0E-21" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-29"
		str: "-0.000000000000000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 8
		--assert 0 = compare-memory as byte-ptr! "-1.0E-21" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-30"
		str: "0.0000000000000000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "1.0E-22" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-31"
		str: "+0.0000000000000000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "1.0E-22" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-32"
		str: "-0.0000000000000000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 8
		--assert 0 = compare-memory as byte-ptr! "-1.0E-22" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-33"
		str: "01234567890.123456789"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! str + 1 as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-34"
		str: "01234567890.123456789111"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! str + 1 as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-35"
		str: "01234567890.123456789111E999"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 26
		--assert 0 = compare-memory as byte-ptr! "1.2345678901234567891E1008" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-36"
		str: "-01234567890.123456789111E999"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 27
		--assert 0 = compare-memory as byte-ptr! "-1.2345678901234567891E1008" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-37"
		str: "+01234567890.123456789111E999"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 26
		--assert 0 = compare-memory as byte-ptr! "1.2345678901234567891E1008" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-38"
		str: "01234567890.123456789111E-999"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 26
		--assert 0 = compare-memory as byte-ptr! "1.2345678901234567891E-990" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-39"
		str: "-01234567890.123456789111E-999"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 27
		--assert 0 = compare-memory as byte-ptr! "-1.2345678901234567891E-990" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-40"
		str: "+01234567890.123456789111E-999"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 26
		--assert 0 = compare-memory as byte-ptr! "1.2345678901234567891E-990" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-41"
		str: "9.0E1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 14
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-42"
		str: "-9.0E1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 15
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-43"
		str: "+9.0E1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 14
		--assert 0 = compare-memory as byte-ptr! str + 1 as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-44"
		str: "9.0E-1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 15
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-45"
		str: "-9.0E-1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 16
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-46"
		str: "+9.0E-1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 15
		--assert 0 = compare-memory as byte-ptr! str + 1 as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-47"
		str: "9.00000E-1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 15
		--assert 0 = compare-memory as byte-ptr! "9.0E-1000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-48"
		str: "00009.00000E-1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 15
		--assert 0 = compare-memory as byte-ptr! "9.0E-1000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-49"
		str: "-00009.00000E-1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 16
		--assert 0 = compare-memory as byte-ptr! "-9.0E-1000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-50"
		str: "+00009.00000E-1000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 15
		--assert 0 = compare-memory as byte-ptr! "9.0E-1000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-51"
		str: "00009.00000E-00001000000000"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 15
		--assert 0 = compare-memory as byte-ptr! "9.0E-1000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-52"
		str: "1.0E1000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.#INF" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-53"
		str: "-1.0E1000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.#INF" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-54"
		str: "+1.0E1000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.#INF" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-55"
		str: "1.0E-1000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.#INF" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-56"
		str: "-1.0E-1000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.#INF" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-57"
		str: "+1.0E-1000000001"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.#INF" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-58"
		str: "1.#INF"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-59"
		str: "-1.#INF"
		big: bigdecimal/load-float str -1
		ibuf: 0
		ilen: 0
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! str as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "load-and-form-60"
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

===start-group=== "zero*?"
	--test-- "zero*?-1"
		str: "0.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/zero?* big
		bigdecimal/free* big

	--test-- "zero*?-2"
		str: "+00000.00000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/zero?* big
		bigdecimal/free* big

	--test-- "zero*?-3"
		str: "-00000.00000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/zero?* big
		bigdecimal/free* big

	--test-- "zero*?-4"
		str: "1.0"
		big: bigdecimal/load-float str -1
		--assert false = bigdecimal/zero?* big
		bigdecimal/free* big

	--test-- "zero*?-5"
		str: "0.1"
		big: bigdecimal/load-float str -1
		--assert false = bigdecimal/zero?* big
		bigdecimal/free* big

	--test-- "zero*?-6"
		str: "1.#INF"
		big: bigdecimal/load-float str -1
		--assert false = bigdecimal/zero?* big
		bigdecimal/free* big

	--test-- "zero*?-7"
		str: "-1.#INF"
		big: bigdecimal/load-float str -1
		--assert false = bigdecimal/zero?* big
		bigdecimal/free* big

	--test-- "zero*?-8"
		str: "1.#NaN"
		big: bigdecimal/load-float str -1
		--assert false = bigdecimal/zero?* big
		bigdecimal/free* big

===end-group===

===start-group=== "ROUND-UP test"
	bigdecimal/set-rounding-mode ROUND-UP

	--test-- "ROUND-UP-1"
		str: "10000000000000000000.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-2"
		str: "10000000000000000000.2"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-3"
		str: "10000000000000000000.5"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-4"
		str: "10000000000000000000.8"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-5"
		str: "99999999999999999999.9"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-6"
		str: "-10000000000000000000.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-7"
		str: "-10000000000000000000.2"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-8"
		str: "-10000000000000000000.5"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-9"
		str: "-10000000000000000000.8"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-10"
		str: "-99999999999999999999.9"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-11"
		str: "100000000000000000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-12"
		str: "100000000000000000002"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 24
		--assert 0 = compare-memory as byte-ptr! "1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-13"
		str: "100000000000000000005"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 24
		--assert 0 = compare-memory as byte-ptr! "1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-14"
		str: "100000000000000000008"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 24
		--assert 0 = compare-memory as byte-ptr! "1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-15"
		str: "999999999999999999999"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E21" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-16"
		str: "-100000000000000000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-17"
		str: "-100000000000000000002"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "-1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-18"
		str: "-100000000000000000005"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "-1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-19"
		str: "-100000000000000000008"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "-1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-UP-20"
		str: "-999999999999999999999"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E21" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

===end-group===

===start-group=== "ROUND-DOWN test"
	bigdecimal/set-rounding-mode ROUND-DOWN

	--test-- "ROUND-DOWN-1"
		str: "10000000000000000000.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-2"
		str: "10000000000000000000.2"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-3"
		str: "10000000000000000000.5"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-4"
		str: "10000000000000000000.8"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-5"
		str: "99999999999999999999.9"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "99999999999999999999" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-6"
		str: "-10000000000000000000.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-7"
		str: "-10000000000000000000.2"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-8"
		str: "-10000000000000000000.5"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-9"
		str: "-10000000000000000000.8"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-10"
		str: "-99999999999999999999.9"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-99999999999999999999" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-11"
		str: "100000000000000000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-12"
		str: "100000000000000000002"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-13"
		str: "100000000000000000005"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-14"
		str: "100000000000000000008"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-15"
		str: "999999999999999999999"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 24
		--assert 0 = compare-memory as byte-ptr! "9.9999999999999999999E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-16"
		str: "-100000000000000000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-17"
		str: "-100000000000000000002"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-18"
		str: "-100000000000000000005"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-19"
		str: "-100000000000000000008"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-DOWN-20"
		str: "-999999999999999999999"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "-9.9999999999999999999E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

===end-group===

===start-group=== "ROUND-CEIL test"
	bigdecimal/set-rounding-mode ROUND-CEIL

	--test-- "ROUND-CEIL-1"
		str: "10000000000000000000.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-2"
		str: "10000000000000000000.2"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-3"
		str: "10000000000000000000.5"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-4"
		str: "10000000000000000000.8"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-5"
		str: "99999999999999999999.9"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-6"
		str: "-10000000000000000000.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-7"
		str: "-10000000000000000000.2"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-8"
		str: "-10000000000000000000.5"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-9"
		str: "-10000000000000000000.8"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-10"
		str: "-99999999999999999999.9"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-99999999999999999999" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-11"
		str: "100000000000000000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-12"
		str: "100000000000000000002"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 24
		--assert 0 = compare-memory as byte-ptr! "1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-13"
		str: "100000000000000000005"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 24
		--assert 0 = compare-memory as byte-ptr! "1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-14"
		str: "100000000000000000008"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 24
		--assert 0 = compare-memory as byte-ptr! "1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-15"
		str: "999999999999999999999"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E21" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-16"
		str: "-100000000000000000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-17"
		str: "-100000000000000000002"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-18"
		str: "-100000000000000000005"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-19"
		str: "-100000000000000000008"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-CEIL-20"
		str: "-999999999999999999999"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "-9.9999999999999999999E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

===end-group===

===start-group=== "ROUND-FLOOR test"
	bigdecimal/set-rounding-mode ROUND-FLOOR

	--test-- "ROUND-FLOOR-1"
		str: "10000000000000000000.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-2"
		str: "10000000000000000000.2"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-3"
		str: "10000000000000000000.5"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-4"
		str: "10000000000000000000.8"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-5"
		str: "99999999999999999999.9"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "99999999999999999999" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-6"
		str: "-10000000000000000000.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-7"
		str: "-10000000000000000000.2"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-8"
		str: "-10000000000000000000.5"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-9"
		str: "-10000000000000000000.8"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-10"
		str: "-99999999999999999999.9"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-11"
		str: "100000000000000000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-12"
		str: "100000000000000000002"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-13"
		str: "100000000000000000005"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-14"
		str: "100000000000000000008"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-15"
		str: "999999999999999999999"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 24
		--assert 0 = compare-memory as byte-ptr! "9.9999999999999999999E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-16"
		str: "-100000000000000000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-17"
		str: "-100000000000000000002"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "-1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-18"
		str: "-100000000000000000005"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "-1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-19"
		str: "-100000000000000000008"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "-1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-FLOOR-20"
		str: "-999999999999999999999"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E21" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

===end-group===

===start-group=== "ROUND-HALF-UP test"
	bigdecimal/set-rounding-mode ROUND-HALF-UP

	--test-- "ROUND-HALF-UP-1"
		str: "10000000000000000000.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-2"
		str: "10000000000000000000.2"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-3"
		str: "10000000000000000000.5"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-4"
		str: "10000000000000000000.8"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-5"
		str: "99999999999999999999.9"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-6"
		str: "-10000000000000000000.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-7"
		str: "-10000000000000000000.2"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-8"
		str: "-10000000000000000000.5"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-9"
		str: "-10000000000000000000.8"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-10"
		str: "-99999999999999999999.9"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-11"
		str: "100000000000000000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-12"
		str: "100000000000000000002"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-13"
		str: "100000000000000000005"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 24
		--assert 0 = compare-memory as byte-ptr! "1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-14"
		str: "100000000000000000008"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 24
		--assert 0 = compare-memory as byte-ptr! "1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-15"
		str: "999999999999999999999"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E21" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-16"
		str: "-100000000000000000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-17"
		str: "-100000000000000000002"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-18"
		str: "-100000000000000000005"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "-1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-19"
		str: "-100000000000000000008"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "-1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-UP-20"
		str: "-999999999999999999999"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E21" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

===end-group===

===start-group=== "ROUND-HALF-DOWN test"
	bigdecimal/set-rounding-mode ROUND-HALF-DOWN

	--test-- "ROUND-HALF-DOWN-1"
		str: "10000000000000000000.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-2"
		str: "10000000000000000000.2"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-3"
		str: "10000000000000000000.5"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-4"
		str: "10000000000000000000.8"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-5"
		str: "99999999999999999999.9"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-6"
		str: "-10000000000000000000.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-7"
		str: "-10000000000000000000.2"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-8"
		str: "-10000000000000000000.5"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-9"
		str: "-10000000000000000000.8"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-10"
		str: "-99999999999999999999.9"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-11"
		str: "100000000000000000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-12"
		str: "100000000000000000002"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-13"
		str: "100000000000000000005"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-14"
		str: "100000000000000000008"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 24
		--assert 0 = compare-memory as byte-ptr! "1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-15"
		str: "999999999999999999999"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E21" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-16"
		str: "-100000000000000000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-17"
		str: "-100000000000000000002"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-18"
		str: "-100000000000000000005"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-19"
		str: "-100000000000000000008"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "-1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-DOWN-20"
		str: "-999999999999999999999"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E21" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

===end-group===

===start-group=== "ROUND-HALF-CEIL test"
	bigdecimal/set-rounding-mode ROUND-HALF-CEIL

	--test-- "ROUND-HALF-CEIL-1"
		str: "10000000000000000000.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-2"
		str: "10000000000000000000.2"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-3"
		str: "10000000000000000000.5"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-4"
		str: "10000000000000000000.8"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-5"
		str: "99999999999999999999.9"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-6"
		str: "-10000000000000000000.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-7"
		str: "-10000000000000000000.2"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-8"
		str: "-10000000000000000000.5"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-9"
		str: "-10000000000000000000.8"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-10"
		str: "-99999999999999999999.9"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-11"
		str: "100000000000000000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-12"
		str: "100000000000000000002"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-13"
		str: "100000000000000000005"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 24
		--assert 0 = compare-memory as byte-ptr! "1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-14"
		str: "100000000000000000008"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 24
		--assert 0 = compare-memory as byte-ptr! "1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-15"
		str: "999999999999999999999"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E21" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-16"
		str: "-100000000000000000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-17"
		str: "-100000000000000000002"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-18"
		str: "-100000000000000000005"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-19"
		str: "-100000000000000000008"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "-1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-CEIL-20"
		str: "-999999999999999999999"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E21" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

===end-group===

===start-group=== "ROUND-HALF-FLOOR test"
	bigdecimal/set-rounding-mode ROUND-HALF-FLOOR

	--test-- "ROUND-HALF-FLOOR-1"
		str: "10000000000000000000.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-2"
		str: "10000000000000000000.2"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-3"
		str: "10000000000000000000.5"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-4"
		str: "10000000000000000000.8"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 20
		--assert 0 = compare-memory as byte-ptr! "10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-5"
		str: "99999999999999999999.9"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-6"
		str: "-10000000000000000000.0"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-7"
		str: "-10000000000000000000.2"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000000" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-8"
		str: "-10000000000000000000.5"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-9"
		str: "-10000000000000000000.8"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 21
		--assert 0 = compare-memory as byte-ptr! "-10000000000000000001" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-10"
		str: "-99999999999999999999.9"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-11"
		str: "100000000000000000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-12"
		str: "100000000000000000002"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-13"
		str: "100000000000000000005"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-14"
		str: "100000000000000000008"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 24
		--assert 0 = compare-memory as byte-ptr! "1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-15"
		str: "999999999999999999999"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 6
		--assert 0 = compare-memory as byte-ptr! "1.0E21" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-16"
		str: "-100000000000000000000"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-17"
		str: "-100000000000000000002"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-18"
		str: "-100000000000000000005"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "-1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-19"
		str: "-100000000000000000008"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 25
		--assert 0 = compare-memory as byte-ptr! "-1.0000000000000000001E20" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

	--test-- "ROUND-HALF-FLOOR-20"
		str: "-999999999999999999999"
		big: bigdecimal/load-float str -1
		--assert true = bigdecimal/form big :ibuf :ilen
		--assert ilen = 7
		--assert 0 = compare-memory as byte-ptr! "-1.0E21" as byte-ptr! ibuf ilen
		free as byte-ptr! ibuf
		bigdecimal/free* big

===end-group===

~~~end-file~~~
