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
	expo		[integer!]
	prec		[integer!]
]

bigdecimal: context [

	default-prec: 20
	exp-min: -1000000000
	exp-max:  1000000000
	rounding-mode: ROUND-HALF-UP
	unit-max: default-prec / 4

	set-default-prec: func [precise [integer!]][
		default-prec: either precise >= 2 [precise][2]
		unit-max: unit-size? default-prec
	]

	set-exp-min: func [exp [integer!]][
		exp-min: either exp >= -1000000000 [exp][-1000000000]
	]

	set-exp-max: func [exp [integer!]][
		exp-max: either exp <= 1000000000 [exp][1000000000]
	]

	set-rounding-mode: func [mode [ROUNDING!]][
		rounding-mode: mode
	]

	unit-size?: func [
		slen				[integer!]
		return:				[integer!]
		/local
			c				[integer!]
			unit			[integer!]
	][
		c: either (slen % DECIMAL-BASE-LEN) = 0 [0][1]
		unit: slen / DECIMAL-BASE-LEN + c
		unit
	]

	alloc*: func [
		len					[integer!]
		return:				[bigdecimal!]
		/local
			size			[integer!]
			p				[byte-ptr!]
			big				[bigint!]
	][
		big: bigint/alloc-limit len 2 * unit-max
		if big = null [return null]
		big/prec: default-prec
		as bigdecimal! big
	]

	free*: func [big [bigdecimal!]][
		if big <> null [free as byte-ptr! big]
	]

	copy*: func [
		big					[bigdecimal!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/copy* as bigint! big
	]

	expand*: func [
		big					[bigdecimal!]
		size				[integer!]			;-- expand size in integer!
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/expand* as bigint! big size
	]

	load-nan: func [
		return:				[bigdecimal!]
		/local
			big				[bigdecimal!]
			p				[int-ptr!]
	][
		big: alloc* 1
		if big = null [return null]
		big/expo: 7FFFFFFFh
		big/used: -1
		p: as int-ptr! (big + 1)
		p/1: 1
		big
	]

	load-inf: func [
		sign				[integer!]
		return:				[bigdecimal!]
		/local
			big				[bigdecimal!]
			p				[int-ptr!]
			digit			[c-string!]
	][
		big: alloc* 1
		if big = null [return null]
		big/expo: 7FFFFFFFh
		big/used: either sign > 0 [1][-1]
		p: as int-ptr! (big + 1)
		p/1: 0
		big
	]

	load-int: func [
		int					[integer!]
		return:				[bigdecimal!]
		/local
			ret				[bigdecimal!]
	][
		ret: as bigdecimal! bigint/dec-load-int int
		ret/prec: default-prec
		ret
	]

	load-uint: func [
		uint				[integer!]
		return:				[bigdecimal!]
		/local
			ret				[bigdecimal!]
	][
		ret: as bigdecimal! bigint/dec-load-uint uint
		ret/prec: default-prec
		ret
	]

	shrink: func [
		big					[bigdecimal!]
	][
		bigint/shrink as bigint! big
	]

	left-shift: func [
		big					[bigdecimal!]
		count				[integer!]
		free?				[logic!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/left-shift big count free?
	]

	right-shift: func [
		big					[bigdecimal!]
		count				[integer!]
		free?				[logic!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/right-shift big count free?
	]

	zero?*: func [
		big					[bigdecimal!]
		return:				[logic!]
		/local
			bused			[integer!]
			pb				[int-ptr!]
	][
		bigint/zero?* as bigint! big
	]

	absolute-compare: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		return:				[integer!]
	][
		bigint/absolute-compare as bigint! big1 as bigint! big2
	]

	compare: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		return:				[integer!]
	][
		bigint/compare as bigint! big1 as bigint! big2
	]

	negative*: func [
		big					[bigdecimal!]
		free?				[logic!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/negative* as bigint! big free?
	]

	negative?*: func [
		big					[bigdecimal!]
		return:				[logic!]
	][
		bigint/negative?* as bigint! big
	]

	positive*: func [
		big					[bigdecimal!]
		free?				[logic!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/positive* as bigint! big free?
	]

	positive?*: func [
		big					[bigdecimal!]
		return:				[logic!]
	][
		bigint/positive?* as bigint! big
	]

	absolute*: func [
		big					[bigdecimal!]
		free?				[logic!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/absolute* as bigint! big free?
	]

	compare-int: func [
		big1				[bigdecimal!]
		int					[integer!]
		return:				[integer!]
	][
		bigint/compare-int as bigint! big1 int
	]

	compare-uint: func [
		big1				[bigdecimal!]
		uint				[integer!]
		return:				[integer!]
	][
		bigint/compare-uint as bigint! big1 uint
	]

	absolute-add: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/absolute-add as bigint! big1 as bigint! big2
	]

	;-- big1 must large than big2
	absolute-sub: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/absolute-sub as bigint! big1 as bigint! big2
	]

	add: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		free?				[logic!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/add as bigint! big1 as bigint! big2 free?
	]

	sub: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		free?				[logic!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/sub as bigint! big1 as bigint! big2 free?
	]

	add-int: func [
		big1				[bigdecimal!]
		int					[integer!]
		free?				[logic!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/add-int as bigint! big1 int free?
	]

	add-uint: func [
		big1				[bigdecimal!]
		uint				[integer!]
		free?				[logic!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/add-uint as bigint! big1 uint free?
	]

	sub-int: func [
		big1				[bigdecimal!]
		int					[integer!]
		free?				[logic!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/sub-int as bigint! big1 int free?
	]

	sub-uint: func [
		big1				[bigdecimal!]
		uint				[integer!]
		free?				[logic!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/sub-uint as bigint! big1 uint free?
	]

	absolute-mul: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/absolute-mul as bigint! big1 as bigint! big2
	]

	mul: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		free?				[logic!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/mul as bigint! big1 as bigint! big2 free?
	]

	mul-int: func [
		big1				[bigdecimal!]
		int					[integer!]
		free?				[logic!]
		return:				[bigdecimal!]
	][
		as bigdecimal! bigint/mul-int as bigint! big1 int free?
	]

	mul-uint: func [
		big1				[bigdecimal!]
		uint				[integer!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			big				[bigdecimal!]
			ret				[bigdecimal!]
	][
		as bigdecimal! bigint/mul-uint as bigint! big1 uint free?
	]

	div: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		iQ					[int-ptr!]
		iR					[int-ptr!]
		free?				[logic!]
		return:				[logic!]
	][
		bigint/div as bigint! big1 as bigint! big2 iQ iR free?
	]

	div-int: func [
		big1				[bigdecimal!]
		int					[integer!]
		iQ					[int-ptr!]
		iR					[int-ptr!]
		free?				[logic!]
		return:				[logic!]
	][
		bigint/div-int as bigint! big1 int iQ iR free?
	]

	div-uint: func [
		big1				[bigdecimal!]
		uint				[integer!]
		iQ					[int-ptr!]
		iR					[int-ptr!]
		free?				[logic!]
		return:				[logic!]
	][
		bigint/div-uint as bigint! big1 uint iQ iR free?
	]

	modulo: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		iR					[int-ptr!]
		free?				[logic!]
		return:				[logic!]
	][
		bigint/modulo as bigint! big1 as bigint! big2 iR free?
	]

	modulo-int: func [
		big1				[bigdecimal!]
		int					[integer!]
		iR					[int-ptr!]
		free?				[logic!]
		return:				[logic!]
	][
		bigint/modulo-int as bigint! big1 int iR free?
	]

	modulo-uint: func [
		big1				[bigdecimal!]
		uint				[integer!]
		iR					[int-ptr!]
		free?				[logic!]
		return:				[logic!]
	][
		bigint/modulo-uint as bigint! big1 uint iR free?
	]

	;-- count same char from buffer tail
	count-char-from-tail: func [
		str					[byte-ptr!]
		slen				[integer!]
		chr					[byte!]
		return:				[integer!]
		/local
			p				[byte-ptr!]
			cnt				[integer!]
	][
		p: str + slen - 1
		cnt: 0
		loop slen [
			either p/1 = chr [cnt: cnt + 1 p: p - 1][break]
		]
		cnt
	]

	;-- count same char from buffer head
	count-char-from-head: func [
		str					[byte-ptr!]
		slen				[integer!]
		chr					[byte!]
		return:				[integer!]
		/local
			p				[byte-ptr!]
			cnt				[integer!]
	][
		p: str
		cnt: 0
		loop slen [
			either p/1 = chr [cnt: cnt + 1 p: p + 1][break]
		]
		cnt
	]

	str-to-uint: func [
		str					[c-string!]
		slen				[integer!]
		uint				[int-ptr!]
		return:				[logic!]
		/local
			len				[integer!]
			ret				[integer!]
			temp			[byte!]
	][
		len: DECIMAL-BASE-LEN
		if slen > 0 [
			len: either len < slen [len][slen]
		]

		ret: 0
		loop len [
			temp: str/1
			if any [temp > #"9" temp < #"0"][return false]
			temp: temp - #"0"
			ret: ret * 10 + temp
			str: str + 1
		]
		if uint <> null [
			uint/value: ret
		]
		true
	]

	load-str: func [
		str					[c-string!]
		slen				[integer!]
		return:				[bigdecimal!]
		/local
			len				[integer!]
			sign			[integer!]
			blen			[integer!]
			tlen			[integer!]
			ret				[bigdecimal!]
			p				[int-ptr!]
			size			[integer!]
	][
		len: length? str
		if slen > 0 [
			len: either len < slen [len][slen]
		]

		sign: 1
		case [
			str/1 = #"+" [sign: 1 str: str + 1 len: len - 1]
			str/1 = #"-" [sign: -1 str: str + 1 len: len - 1]
			true []
		]

		if len = 0 [return load-int 0]

		blen: len / DECIMAL-BASE-LEN
		tlen: len % DECIMAL-BASE-LEN
		if tlen <> 0 [blen: blen + 1]
		ret: alloc* blen
		ret/used: either sign > 0 [blen][0 - blen]
		p: as int-ptr! (ret + 1)
		p: p + blen - 1

		if tlen <> 0[
			if false = str-to-uint str tlen p [free* ret return load-nan]
			p: p - 1
			str: str + tlen
			len: len - tlen
		]

		while [len > 0][
			if false = str-to-uint str DECIMAL-BASE-LEN p [free* ret return load-nan]
			p: p - 1
			str: str + DECIMAL-BASE-LEN
			len: len - DECIMAL-BASE-LEN
		]
		shrink ret
		ret
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
			sign			[integer!]
			exp				[integer!]
			expp			[integer!]
			esign			[integer!]
			intLen			[integer!]
			ptLen			[integer!]
			int-tail-zero	[integer!]
			point-tail-zero	[integer!]
			int-head-zero	[integer!]
			point-head-zero	[integer!]
			total			[integer!]
			temp			[integer!]
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
		sign: 0
		case [
			str/1 = #"-" [sign: -1 pos: pos + 1 str: str + 1]
			str/1 = #"+" [sign: 1 pos: pos + 1 str: str + 1]
			true []
		]
		until [
			case [
				str/1 = #"." [
					either dot? [
						return load-nan
					][
						dot?: true
						dotp: pos
					]
				]
				any [str/1 = #"e" str/1 = #"E"][
					either exp? [
						return load-nan
					][
						exp?: true
					]
					expp: pos
					exp: 0
					esign: 1
					pos: pos + 1
					str: str + 1
					if pos > len [return load-nan]
					case [
						str/1 = #"-" [esign: -1 pos: pos + 1 str: str + 1 if pos > len [return load-nan]]
						str/1 = #"+" [esign: 1 pos: pos + 1 str: str + 1 if pos > len [return load-nan]]
						true []
					]

					while [pos <= len] [
						if any [str/1 < #"0" str/1 > #"9"][return load-nan]
						exp: exp * 10 + as integer! (str/1 - #"0")
						pos: pos + 1
						str: str + 1
					]
				]
				any [str/1 < #"0" str/1 > #"9"][return load-nan]
				true []
			]
			pos: pos + 1
			str: str + 1
			pos > len
		]

		int-head-zero: 0
		point-head-zero: 0
		either exp? [
			either dot? [
				intLen: dotp - 1
				ptLen: expp - dotp - 1
				point-tail-zero: count-char-from-tail as byte-ptr! bak + dotp ptLen #"0"
				ptLen: ptLen - point-tail-zero
				if intLen <= 0 [
					point-head-zero: count-char-from-head as byte-ptr! bak + dotp ptLen #"0"
				]
			][
				intLen: expp - 1
				ptLen: 0
			]
		][
			either dot? [
				intLen: dotp - 1
				ptLen: len - dotp
				point-tail-zero: count-char-from-tail as byte-ptr! bak + dotp ptLen #"0"
				;print-line ["dotp: " dotp " point-tail-zero: " point-tail-zero " ptLen: " ptLen]
				ptLen: ptLen - point-tail-zero
				if intLen <= 0 [
					point-head-zero: count-char-from-head as byte-ptr! bak + dotp ptLen #"0"
				]
			][
				intLen: len
				ptLen: 0
			]
			exp: 0
		]
		int-tail-zero: 0
		if ptLen <= 0 [
			int-tail-zero: count-char-from-tail as byte-ptr! bak intLen #"0"
		]
		if any [
			all [
				sign = 0
				intLen > 1
			]
			all [
				sign <> 0
				intLen > 2
			]
		][
			int-head-zero: count-char-from-head as byte-ptr! bak intLen #"0"
		]

		;print-line ["esign: " esign " exp: " exp " intLen: " intLen " ptLen: " ptLen]
		;print-line ["int-head-zero: " int-head-zero " point-head-zero: " point-head-zero]
		if esign = -1 [
			exp: 0 - exp
		]
		exp: exp - ptLen
		total: (intLen - int-head-zero) + (ptLen - point-head-zero)
		if ptLen <= 0 [
			exp: exp + int-tail-zero
			total: total - int-tail-zero
		]

		temp: total - 1 + exp
		if sign <> 0 [
			temp: temp - 1
		]
		if any [
			temp < exp-min
			temp > exp-max
		][
			if sign = -1 [return load-inf -1]
			return load-inf 1
		]

		buffer: allocate total
		if (intLen - int-head-zero - int-tail-zero) > 0 [
			copy-memory buffer as byte-ptr! bak + int-head-zero intLen - int-head-zero - int-tail-zero
		]
		if all [dot? (ptLen - point-head-zero) > 0] [
			copy-memory buffer + (intLen - int-head-zero) as byte-ptr! bak + dotp + point-head-zero ptLen - point-head-zero
		]

		big: load-str as c-string! buffer total
		big/expo: exp
		if sign < 0 [big/used: 0 - big/used]

		free buffer
		;big: round big true
		big
	]

	#if debug? = yes [
		dump: func [
			big				[bigdecimal!]
		][
			bigint/dump as bigint! big
		]
	]

]
