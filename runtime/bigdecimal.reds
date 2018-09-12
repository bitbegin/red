Red/System [
	Title:   "big decimal lib"
	Author:  "bitbegin"
	File: 	 %bigdecimal.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#include %bigint.reds

bigdecimal!: alias struct! [
	size		[integer!]				;-- size in integer!
	used		[integer!]				;-- used length in integer!
	sign		[integer!]
	expo		[integer!]
	prec		[integer!]
	data		[int-ptr!]
]

bigdecimal: context [
	default-prec: 20

	set-default-prec: func [
		precise				[integer!]
	][
		default-prec: either precise >= 2 [precise][2]
	]

	load-int: func [
		int					[integer!]
		return:				[bigdecimal!]
		/local
			big				[bigdecimal!]
	][
		big: as bigdecimal! bigint/load-int int
		if int = 0 [big/used: 1]
		big/expo: 0
		big/prec: default-prec
		big
	]

	load-uint: func [
		uint				[integer!]
		return:				[bigdecimal!]
		/local
			big				[bigdecimal!]
	][
		big: as bigdecimal! bigint/load-uint uint
		if uint = 0 [big/used: 1]
		big/expo: 0
		big/prec: default-prec
		big
	]

	load-nan: func [
		return:				[bigdecimal!]
		/local
			big				[bigdecimal!]
	][
		big: as bigdecimal! bigint/load-int -1
		big/expo: 7FFFFFFFh
		big/prec: default-prec
		big
	]

	load-inf: func [
		sign				[integer!]
		return:				[bigdecimal!]
		/local
			big				[bigdecimal!]
	][
		big: as bigdecimal! bigint/load-int 0
		big/used: 1
		big/expo: either sign = 1 [7FFFFFFFh][80000000h]
		big/prec: default-prec
		big
	]

	load-float: func [
		str					[c-string!]
		slen				[integer!]
		return:				[bigdecimal!]
		/local
			len				[integer!]
			bak				[c-string!]
			pos				[integer!]
			dot?			[logic!]
			dotp			[integer!]
			exp?			[logic!]
			exp				[integer!]
			expp			[integer!]
			esign			[integer!]
			intLen			[integer!]
			ptLen			[integer!]
			total			[integer!]
			buffer			[byte-ptr!]
			big				[bigdecimal!]
	][
		len: length? str
		if slen > 0 [
			len: either len < slen [len][slen]
		]

		if all [
			len = 6
			0 = compare-memory as byte-ptr! str as byte-ptr! "1.#INF" 6
		][
			return load-inf 1
		]

		if all [
			len = 7
			0 = compare-memory as byte-ptr! str as byte-ptr! "-1.#INF" 7
		][
			return load-inf -1
		]

		if all [
			len = 6
			0 = compare-memory as byte-ptr! str as byte-ptr! "1.#NaN" 6
		][
			return load-nan
		]

		bak: str
		pos: 1
		dot?: false
		exp?: false
		until [
			case [
				str/1 = #"." [
					either dot? [
						return null
					][
						dot?: true
						dotp: pos
					]
				]
				any [str/1 = #"e" str/1 = #"E"][
					exp?: true
					expp: pos
					exp: 0
					esign: 1
					pos: pos + 1
					str: str + 1
					if pos > len [return null]
					if str/1 = #"-" [esign: -1 pos: pos + 1 str: str + 1 if pos > len [return null]]
					if str/1 = #"+" [esign: 1 pos: pos + 1 str: str + 1 if pos > len [return null]]

					while [pos <= len] [
						if any [str/1 < #"0" str/1 > #"9"][return null]
						exp: exp * 10 + as integer! (str/1 - #"0")
						pos: pos + 1
						str: str + 1
					]
				]
				any [str/1 < #"0" str/1 > #"9"][return null]
				true []
			]
			pos: pos + 1
			str: str + 1
			pos > len
		]

		either exp? [
			either dot? [
				intLen: dotp - 1
				ptLen: expp - dotp - 1
			][
				intLen: expp - 1
				ptLen: 0
			]
		][
			either dot? [
				intLen: dotp - 1
				ptLen: len - dotp
			][
				intLen: len
				ptLen: 0
			]
			exp: 0
		]
		exp: exp - ptLen

		total: intLen + ptLen
		buffer: allocate total
		copy-memory buffer as byte-ptr! bak intLen
		if dot? [
			copy-memory buffer + intLen as byte-ptr! bak + dotp ptLen
		]

		if total > default-prec [
			exp: exp + (total - default-prec)
			total: default-prec
		]

		big: as bigdecimal! bigint/load-str as c-string! buffer total 10
		if big <> null [
			if bigint/zero?* as bigint! big [big/used: 1]
			big/expo: exp
			big/prec: default-prec
		]
		big
	]

	free*: func [big [bigdecimal!]][
		if big <> null [free as byte-ptr! big]
	]

	#if debug? = yes [
		dump: func [
			big			[bigdecimal!]
			/local
				p		[int-ptr!]
		][
			print-line [lf "===============dump bigdecimal!==============="]
			either big = null [
				print-line "null"
			][
				print-line ["size: " big/size " used: " big/used " sign: " big/sign " expo: " big/expo " prec: " big/prec " addr: " big/data]
				p: big/data
				p: p + big/used - 1
				loop big/used [
					prin-hex-chars ((p/1 >>> 24) and FFh) 2
					prin-hex-chars ((p/1 >>> 16) and FFh) 2
					prin-hex-chars ((p/1 >>> 8) and FFh) 2
					prin-hex-chars (p/1 and FFh) 2
					print " "
					p: p - 1
				]
			]
			print-line [lf "=============dump bigdecimal! end============="]
		]
	]

]

big: bigdecimal/load-float "0.0" 3
bigdecimal/dump big
bigdecimal/free* big
big: bigdecimal/load-float "1.0" 3
bigdecimal/dump big
bigdecimal/free* big
big: bigdecimal/load-float "10.0" 4
bigdecimal/dump big
bigdecimal/free* big
big: bigdecimal/load-float "100.0" 5
bigdecimal/dump big
bigdecimal/free* big
big: bigdecimal/load-float "100" 3
bigdecimal/dump big
bigdecimal/free* big
big: bigdecimal/load-float "2.0" 3
bigdecimal/dump big
bigdecimal/free* big
big: bigdecimal/load-float "0.1" 3
bigdecimal/dump big
bigdecimal/free* big
big: bigdecimal/load-float "0.01" 4
bigdecimal/dump big
bigdecimal/free* big

big: bigdecimal/load-float "01234567890.123456789" 21
bigdecimal/dump big
bigdecimal/free* big

big: bigdecimal/load-float "01234567890.123456789111" 24
bigdecimal/dump big
bigdecimal/free* big

big: bigdecimal/load-float "1.#INF" 6
bigdecimal/dump big
bigdecimal/free* big

big: bigdecimal/load-float "-1.#INF" 7
bigdecimal/dump big
bigdecimal/free* big

big: bigdecimal/load-float "1.#NaN" 6
bigdecimal/dump big
bigdecimal/free* big
