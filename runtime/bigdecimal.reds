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

	NaN?: func [
		big					[bigdecimal!]
		return:				[logic!]
		/local
			p				[int-ptr!]
	][
		p: as int-ptr! (big + 1)
		if all [big/expo = 7FFFFFFFh p/1 <> 0][return true]
		false
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

	INF?: func [
		big					[bigdecimal!]
		return:				[logic!]
		/local
			p				[int-ptr!]
	][
		p: as int-ptr! (big + 1)
		if all [big/expo = 7FFFFFFFh p/1 = 0][return true]
		false
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

	;-- count decimal zero from tail
	count-zero: func [
		uint				[integer!]
		return:				[integer!]
		/local
			len				[integer!]
			temp			[integer!]
			ret				[integer!]
	][
		if uint = 0 [return DECIMAL-BASE-LEN]
		len: bigint/base10-len? uint
		temp: uint
		ret: 0
		loop len [
			if (temp % 10) <> 0 [break]
			ret: ret + 1
			temp: temp / 10
		]
		ret
	]

	shrink-exp: func [
		big					[bigdecimal!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			expo			[integer!]
			bused			[integer!]
			p				[int-ptr!]
			cnt				[integer!]
			sum				[integer!]
			ret				[bigdecimal!]
	][
		expo: big/expo
		if any [
			expo = 7FFFFFFFh
			expo = 80000000h
		][
			ret: copy* big
			if free? [free* big]
			return ret
		]

		if zero?*-exp big [
			ret: copy* big
			ret/expo: 0
			if free? [free* big]
			return ret
		]
		bused: either big/used >= 0 [big/used][0 - big/used]
		p: as int-ptr! (big + 1)
		sum: 0
		loop bused [
			cnt: count-zero p/1
			sum: sum + cnt
			p: p + 1
			if cnt <> DECIMAL-BASE-LEN [break]
		]

		ret: right-shift big sum free?
		ret/expo: ret/expo + sum
		ret
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
	][
		bigint/zero?* as bigint! big
	]

	zero?*-exp: func [
		big					[bigdecimal!]
		return:				[logic!]
		/local
			expo			[integer!]
	][
		expo: big/expo
		if any [
			expo = 7FFFFFFFh
			expo = 80000000h
		][
			return false
		]
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
		bigint/modulo* as bigint! big1 as bigint! big2 iR free? rounding-mode
	]

	modulo-int: func [
		big1				[bigdecimal!]
		int					[integer!]
		iR					[int-ptr!]
		free?				[logic!]
		return:				[logic!]
	][
		bigint/modulo-int* as bigint! big1 int iR free? rounding-mode
	]

	modulo-uint: func [
		big1				[bigdecimal!]
		uint				[integer!]
		iR					[int-ptr!]
		free?				[logic!]
		return:				[logic!]
	][
		bigint/modulo-uint* as bigint! big1 uint iR free? rounding-mode
	]

	digit-at: func [
		uint				[integer!]
		index				[integer!]
		return:				[integer!]
		/local
			ret				[integer!]
	][
		ret: uint % bigint/dec-exp index + 1
		if index > 0 [
			ret: ret / bigint/dec-exp index
		]
		ret
	]

	round: func [
		big					[bigdecimal!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			bprec			[integer!]
			bused			[integer!]
			bsign			[integer!]
			slen			[integer!]
			p				[int-ptr!]
			pos				[integer!]
			offset			[integer!]
			tail			[integer!]
			c				[integer!]
			ret				[bigdecimal!]
	][
		bprec: big/prec
		either big/used >= 0 [
			bused: big/used
			bsign: 1
		][
			bused: 0 - big/used
			bsign: -1
		]
		slen: bigint/digit-len? as bigint! big
		if slen <= bprec [
			ret: shrink-exp big free?
			return ret
		]
		pos: (slen - bprec) / DECIMAL-BASE-LEN
		offset: (slen - bprec) % DECIMAL-BASE-LEN
		p: as int-ptr! (big + 1)
		p: p + pos
		either offset = 0 [
			tail: digit-at p/1 0
			p: p - 1
			c: digit-at p/1 7
		][
			tail: digit-at p/1 offset
			c: digit-at p/1 offset - 1
		]

		ret: right-shift big slen - bprec free?
		switch rounding-mode [
			ROUND-UP			[
				either bsign > 0 [
					ret: add-uint ret 1 true
				][
					ret: sub-uint ret 1 true
				]
			]
			ROUND-DOWN			[]
			ROUND-CEIL			[
				if bsign > 0 [
					ret: add-uint ret 1 true
				]
			]
			ROUND-FLOOR			[
				if bsign < 0 [
					ret: sub-uint ret 1 true
				]
			]
			ROUND-HALF-UP		[
				if c >= 5 [
					either bsign > 0 [
						ret: add-uint ret 1 true
					][
						ret: sub-uint ret 1 true
					]
				]
			]
			ROUND-HALF-DOWN		[
				if c > 5 [
					either bsign > 0 [
						ret: add-uint ret 1 true
					][
						ret: sub-uint ret 1 true
					]
				]
			]
			ROUND-HALF-EVEN		[
				if any [
					c > 5
					all [
						c = 5
						any [
							tail = 1 tail = 3 tail = 5 tail = 7 tail = 9
						]
					]
				][
					either bsign > 0 [
						ret: add-uint ret 1 true
					][
						ret: sub-uint ret 1 true
					]
				]
			]
			ROUND-HALF-ODD		[
				if any [
					c > 5
					all [
						c = 5
						any [
							tail = 0 tail = 2 tail = 4 tail = 6 tail = 8
						]
					]
				][
					either bsign > 0 [
						ret: add-uint ret 1 true
					][
						ret: sub-uint ret 1 true
					]
				]
			]
			ROUND-HALF-CEIL		[
				case [
					c > 5 [
						either bsign > 0 [
							ret: add-uint ret 1 true
						][
							ret: sub-uint ret 1 true
						]
					]
					c = 5 [
						if bsign > 0 [
							ret: add-uint ret 1 true
						]
					]
					true []
				]
			]
			ROUND-HALF-FLOOR	[
				case [
					c > 5 [
						either bsign > 0 [
							ret: add-uint ret 1 true
						][
							ret: sub-uint ret 1 true
						]
					]
					c = 5 [
						if bsign < 0 [
							ret: sub-uint ret 1 true
						]
					]
					true []
				]
			]
		]
		ret/expo: ret/expo + (slen - bprec)
		ret: shrink-exp ret true
		ret
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
		if all [intLen > 1 ptLen <= 0] [
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
		;print-line ["int-head-zero: " int-head-zero " point-head-zero: " point-head-zero " int-tail-zero: " int-tail-zero]
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
		set-memory buffer null-byte total
		if (intLen - int-head-zero - int-tail-zero) > 0 [
			copy-memory buffer as byte-ptr! bak + int-head-zero intLen - int-head-zero - int-tail-zero
		]
		if all [dot? (ptLen - point-head-zero) > 0] [
			copy-memory buffer + (intLen - int-head-zero) as byte-ptr! bak + dotp + point-head-zero ptLen - point-head-zero
		]

		big: load-str as c-string! buffer total
		big/expo: exp

		free buffer
		big: round big true
		big
	]

	point-form: func [
		big					[bigdecimal!]
		obuf				[int-ptr!]
		olen				[int-ptr!]
		/local
			bsign			[integer!]
			bused			[integer!]
			expo			[integer!]
			dlen			[integer!]
			size			[integer!]
			p				[byte-ptr!]
			pt				[byte-ptr!]
			pb				[int-ptr!]
			pad8?			[logic!]
			int-s			[c-string!]
			s-len			[integer!]
			pos				[integer!]
			pos2			[integer!]
			point			[integer!]
			zpad			[integer!]
	][
		either big/used >= 0 [
			bsign: 1
			bused: big/used
		][
			bsign: -1
			bused: 0 - big/used
		]
		expo: big/expo
		dlen: bigint/digit-len? big
		pb: as int-ptr! (big + 1)
		pb: pb + bused - 1
		pad8?: false

		if expo >= 0 [
			; x..x 0..0 null
			size: expo + 1 + dlen
			if bsign < 0 [size: size + 1]
			p: allocate size

			pos: 1
			if bsign < 0 [
				p/pos: #"-"
				pos: pos + 1
			]

			loop bused [
				int-s: bigint/form-decimal pb/1 pad8?
				s-len: length? int-s
				copy-memory p + pos - 1 as byte-ptr! int-s s-len
				unless pad8? [pad8?: true]
				pos: pos + s-len
				pb: pb - 1
			]

			loop expo [
				p/pos: #"0"
				pos: pos + 1
			]
			p/pos: null-byte
			p/size: null-byte
			obuf/value: as integer! p
			olen/value: pos - 1
			exit
		]

		point: 0 - expo
		either point >= dlen [
			; 0. x..x null
			size: point + 2 + 1
			if bsign < 0 [size: size + 1]
			p: allocate size

			pos: 1
			if bsign < 0 [
				p/pos: #"-"
				pos: pos + 1
			]
			p/pos: #"0"
			pos: pos + 1
			p/pos: #"."
			pos: pos + 1
			zpad: point - dlen
			set-memory p + pos - 1 #"0" zpad
			pos: pos + zpad

			loop bused [
				int-s: bigint/form-decimal pb/1 pad8?
				s-len: length? int-s
				copy-memory p + pos - 1 as byte-ptr! int-s s-len
				unless pad8? [pad8?: true]
				pos: pos + s-len
				pb: pb - 1
			]

			p/pos: null-byte
		][
			; x..x . y..y null
			size: dlen + 1 + 1
			if bsign < 0 [size: size + 1]
			p: allocate size

			pos: 1
			if bsign < 0 [
				p/pos: #"-"
				pos: pos + 1
			]

			pt: allocate dlen + 1
			pos2: 1

			loop bused [
				int-s: bigint/form-decimal pb/1 pad8?
				s-len: length? int-s
				copy-memory pt + pos2 - 1 as byte-ptr! int-s s-len
				unless pad8? [pad8?: true]
				pos2: pos2 + s-len
				pb: pb - 1
			]
			pos2: dlen + 1
			pt/pos2: null-byte

			copy-memory p + pos - 1 pt dlen - point
			pos: pos + dlen - point

			p/pos: #"."
			pos: pos + 1
			copy-memory p + pos - 1 pt + dlen - point point
			pos: pos + point
			p/pos: null-byte
			free pt
		]

		p/size: null-byte
		obuf/value: as integer! p
		olen/value: pos - 1
	]

	exp-form: func [
		big					[bigdecimal!]
		obuf				[int-ptr!]
		olen				[int-ptr!]
		/local
			bsign			[integer!]
			bused			[integer!]
			expo			[integer!]
			dlen			[integer!]
			sign			[integer!]
			eLen			[integer!]
			eSign			[integer!]
			eStr			[c-string!]
			eSLen			[integer!]
			size			[integer!]
			point			[integer!]
			pi				[int-ptr!]
			p				[byte-ptr!]
			pos				[integer!]
			pb				[int-ptr!]
			pad8?			[logic!]
			int-s			[c-string!]
			s-len			[integer!]
			pt				[byte-ptr!]
			pos2			[integer!]
	][
		either big/used >= 0 [
			bsign: 1
			bused: big/used
		][
			bsign: -1
			bused: 0 - big/used
		]
		expo: big/expo
		dlen: bigint/digit-len? big
		pb: as int-ptr! (big + 1)
		pb: pb + bused - 1
		pad8?: false
		point: 0
		either expo >= 0 [
			eLen: dlen - 1 + expo
			;eStr: bigint/form-decimal eLen false
			eSLen: bigint/base10-len? eLen
			eSign: 1
			; x . y..y E e..e null
			size: dlen + 1 + 1 + eSLen + 1
		][
			point: 0 - expo
			either point >= dlen [
				eLen: point - dlen + 1
				;eStr: bigint/form-decimal eLen false
				eSLen: bigint/base10-len? eLen
				eSign: -1
				; 0 . x..x E - e..e null
				size: 2 + dlen + 1 + 1 + eSLen + 1
			][
				eLen: dlen - point - 1
				;eStr: bigint/form-decimal eLen false
				eSLen: bigint/base10-len? eLen
				eSign: 1
				; x . y..y E e..e null
				size: dlen + 1 + 1 + eSLen + 1
			]
		]

		size: size + 1			;-- for one point at least
		if bsign = -1 [size: size + 1]
		; print-line ["point: " point " dlen: " dlen " eLen: " eLen " eStr: " eStr " eSLen: " eSLen " eSign: " eSign " size: " size]

		pt: allocate dlen + 1
		pos2: 1

		loop bused [
			int-s: bigint/form-decimal pb/1 pad8?
			s-len: length? int-s
			copy-memory pt + pos2 - 1 as byte-ptr! int-s s-len
			unless pad8? [pad8?: true]
			pos2: pos2 + s-len
			pb: pb - 1
		]
		pos2: dlen + 1
		pt/pos2: null-byte

		p: allocate size

		pos: 1
		if bsign = -1 [
			p/pos: #"-"
			pos: pos + 1
		]
		p/pos: pt/1
		pos: pos + 1
		p/pos: #"."
		pos: pos + 1
		either 0 = (dlen - 1) [
			p/pos: #"0"
			pos: pos + 1
		][
			copy-memory p + pos - 1 pt + 1 dlen - 1
			pos: pos + dlen - 1
		]
		p/pos: #"E"
		pos: pos + 1
		if eSign = -1 [p/pos: #"-" pos: pos + 1]
		eStr: bigint/form-decimal eLen false
		copy-memory p + pos - 1 as byte-ptr! eStr eSLen
		pos: pos + eSLen
		p/pos: null-byte
		p/size: null-byte

		free pt
		obuf/value: as integer! p
		olen/value: pos - 1
	]

	form: func [
		big					[bigdecimal!]
		obuf				[int-ptr!]
		olen				[int-ptr!]
		return:				[logic!]
		/local
			bsign			[integer!]
			bused			[integer!]
			expo			[integer!]
			dlen			[integer!]
			pb				[int-ptr!]
			pad8?			[logic!]
			int-s			[c-string!]
			s-len			[integer!]
			pos				[integer!]
			buf				[byte-ptr!]
			size			[integer!]
			exp?			[logic!]
			nbuf			[integer!]
			nlen			[integer!]
	][
		either big/used >= 0 [
			bsign: 1
			bused: big/used
		][
			bsign: -1
			bused: 0 - big/used
		]
		expo: big/expo
		dlen: bigint/digit-len? big

		if expo = 7FFFFFFFh [
			if zero?* big [
				if bsign = 1 [
					buf: allocate 7
					copy-memory buf as byte-ptr! "1.#INF" 7
					obuf/value: as integer! buf
					olen/value: 6
					return true
				]
				buf: allocate 8
				copy-memory buf as byte-ptr! "-1.#INF" 8
				obuf/value: as integer! buf
				olen/value: 7
				return true
			]
		]

		if any [
			expo = 7FFFFFFFh
			expo = 80000000h
		][
			buf: allocate 7
			copy-memory buf as byte-ptr! "1.#NaN" 7
			obuf/value: as integer! buf
			olen/value: 6
			return true
		]

		pb: as int-ptr! (big + 1)
		pb: pb + bused - 1
		pad8?: false

		if expo = 0 [
			size: dlen + 1
			if bsign < 0 [size: size + 1]
			buf: allocate size
			buf/size: null-byte
			pos: 1
			if bsign < 0 [
				buf/pos: #"-"
				pos: pos + 1
			]
			loop bused [
				int-s: bigint/form-decimal pb/1 pad8?
				s-len: length? int-s
				copy-memory buf + pos - 1 as byte-ptr! int-s s-len
				unless pad8? [pad8?: true]
				pos: pos + s-len
				pb: pb - 1
			]
			buf/pos: null-byte
			obuf/value: as integer! buf
			olen/value: size - 1
			return true
		]

		exp?: false
		if any [
			all [
				big/expo > 0
				(big/expo + dlen) > big/prec
			]
			all [
				big/expo < 0
				big/expo <= (0 - big/prec)
			]
		][
			exp?: true
		]

		nbuf: 0
		nlen: 0
		either exp? [
			exp-form big :nbuf :nlen
		][
			point-form big :nbuf :nlen
		]

		obuf/value: nbuf
		olen/value: nlen
		return true
	]

	;-- functions for exp decimal!
	left-shift-exp: func [
		big					[bigdecimal!]
		count				[integer!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			ret				[bigdecimal!]
	][
		ret: copy* big
		ret/expo: ret/expo + count
		if free? [free* big]
		ret
	]

	right-shift-exp: func [
		big					[bigdecimal!]
		count				[integer!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			ret				[bigdecimal!]
	][
		ret: copy* big
		ret/expo: ret/expo - count
		if free? [free* big]
		ret
	]

	compare-exp: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		return:				[integer!]
		/local
			nan1?			[logic!]
			nan2?			[logic!]
			b1sign			[integer!]
			b2sign			[integer!]
			b1expo			[integer!]
			b2expo			[integer!]
			inf1?			[logic!]
			inf2?			[logic!]
			prec			[integer!]
			emax			[bigdecimal!]
			emin			[bigdecimal!]
			max-expo		[integer!]
			min-expo		[integer!]
			bt1				[bigdecimal!]
			temp			[integer!]
			ret				[integer!]
	][
		nan1?: NaN? big1
		nan2?: NaN? big2
		if any [nan1? nan2?][
			if all [nan1? nan2?][return 0]
			if nan1? [return 1]
			return -1
		]
		b1sign: either big1/used >= 0 [1][-1]
		b2sign: either big2/used >= 0 [1][-1]
		inf1?: INF? big1
		inf2?: INF? big2
		if any [inf1? inf2?][
			if all [inf1? inf2?][
				if b1sign = b2sign [return 0]
				return either b1sign > b2sign [1][-1]
			]
			if inf1? [
				return b1sign
			]
			return 0 - b2sign
		]

		b1expo: big1/expo
		b2expo: big2/expo
		if b1expo = b2expo [
			return compare big1 big2
		]

		if b1sign <> b2sign [
			return either b1sign > b2sign [1][-1]
		]

		either b1expo > b2expo [
			emax: big1
			emin: big2
		][
			emin: big1
			emax: big2
		]
		max-expo: emax/expo
		min-expo: emin/expo

		prec: either big1/prec > big2/prec [big1/prec][big2/prec]
		if (max-expo - min-expo) >= prec [
			return either b1expo > b2expo [b1sign][0 - b1sign]
		]

		temp: max-expo - min-expo
		bt1: left-shift emax temp false
		bt1/expo: emax/expo - temp
		ret: either b1expo > b2expo [
			compare bt1 big2
		][
			compare big1 bt1
		]
		free* bt1
		ret
	]

	add-exp: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			b1sign			[integer!]
			b2sign			[integer!]
			b1expo			[integer!]
			b2expo			[integer!]
			inf1?			[logic!]
			inf2?			[logic!]
			prec			[integer!]
			emax			[bigdecimal!]
			emin			[bigdecimal!]
			max-expo		[integer!]
			min-expo		[integer!]
			bt1				[bigdecimal!]
			bt2				[bigdecimal!]
			temp			[integer!]
			ret				[bigdecimal!]
	][
		if any [NaN? big1 NaN? big2][
			ret: load-nan
			if free? [free* big1]
			return ret
		]

		b1sign: either big1/used >= 0 [1][-1]
		b2sign: either big2/used >= 0 [1][-1]
		inf1?: INF? big1
		inf2?: INF? big2
		if any [inf1? inf2?][
			if all [inf1? inf2?][
				if b1sign = b2sign [return load-inf b1sign]
				return load-inf 1
			]
			if inf1? [
				return load-inf b1sign
			]
			return load-inf b2sign
		]

		b1expo: big1/expo
		b2expo: big2/expo
		prec: either big1/prec > big2/prec [big1/prec][big2/prec]
		if b1expo = b2expo [
			ret: add big1 big2 free?
			ret/prec: prec
			ret: round ret true
			if free? [free* big1]
			return ret
		]

		either b1expo > b2expo [
			emax: big1
			emin: big2
		][
			emin: big1
			emax: big2
		]
		max-expo: emax/expo
		min-expo: emin/expo

		if (max-expo - min-expo - bigint/digit-len? emin) >= prec [
			temp: prec + 1 - bigint/digit-len? emax
			bt1: left-shift emax temp false
			bt1/expo: emax/expo - temp
			bt2: load-uint 1
			bt2/expo: bt1/expo
			if big2/used < 0 [bt2/used: 0 - bt2/used]
			ret: add bt1 bt2 true
			ret/prec: prec
			ret: round ret true
			free* bt2
			if free? [free* big1]
			return ret
		]

		temp: max-expo - min-expo
		bt1: left-shift emax temp false
		bt1/expo: emax/expo - temp
		ret: add bt1 emin true
		ret/prec: prec
		ret: round ret true
		if free? [free* big1]
		ret
	]

	sub-exp: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			b1sign			[integer!]
			b2sign			[integer!]
			b1expo			[integer!]
			b2expo			[integer!]
			inf1?			[logic!]
			inf2?			[logic!]
			prec			[integer!]
			emax			[bigdecimal!]
			emin			[bigdecimal!]
			max-expo		[integer!]
			min-expo		[integer!]
			bt1				[bigdecimal!]
			bt2				[bigdecimal!]
			temp			[integer!]
			ret				[bigdecimal!]
	][
		if any [NaN? big1 NaN? big2][
			ret: load-nan
			if free? [free* big1]
			return ret
		]

		b1sign: either big1/used >= 0 [1][-1]
		b2sign: either big2/used >= 0 [1][-1]
		inf1?: INF? big1
		inf2?: INF? big2
		if any [inf1? inf2?][
			if all [inf1? inf2?][
				if b1sign = b2sign [return load-inf b1sign]
				return load-inf either b1sign > b2sign [1][-1]
			]
			if inf1? [
				return load-inf b1sign
			]
			return load-inf 0 - b2sign
		]

		b1expo: big1/expo
		b2expo: big2/expo

		prec: either big1/prec > big2/prec [big1/prec][big2/prec]
		if b1expo = b2expo [
			ret: sub big1 big2 free?
			ret/prec: prec
			ret: round ret true
			if free? [free* big1]
			return ret
		]

		either b1expo > b2expo [
			emax: big1
			emin: big2
		][
			emin: big1
			emax: big2
		]
		max-expo: emax/expo
		min-expo: emin/expo

		if (max-expo - min-expo - bigint/digit-len? emin) >= prec [
			temp: prec + 1 - bigint/digit-len? emax
			bt1: left-shift emax temp false
			bt1/expo: emax/expo - temp
			bt2: load-uint 1
			bt2/expo: bt1/expo
			if emin/used < 0 [bt2/used: 0 - bt2/used]
			ret: either b1expo > b2expo [
				sub bt1 bt2 false
			][
				sub bt2 bt1 false
			]
			ret/prec: prec
			ret: round ret true
			free* bt1
			free* bt2
			if free? [free* big1]
			return ret
		]

		temp: max-expo - min-expo
		bt1: left-shift emax temp false
		bt1/expo: emax/expo - temp
		ret: either b1expo > b2expo [
			sub bt1 emin false
		][
			sub emin bt1 false
		]
		free* bt1
		ret/prec: prec
		ret: round ret true
		if free? [free* big1]
		ret
	]

	mul-exp: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			prec			[integer!]
			ret				[bigdecimal!]
	][
		if any [NaN? big1 NaN? big2][
			ret: load-nan
			if free? [free* big1]
			return ret
		]
		if any [INF? big1 INF? big2][
			ret: load-inf either big1/used >= 0 [1][-1]
			if free? [free* big1]
			return ret
		]
		prec: either big1/prec > big2/prec [big1/prec][big2/prec]
		ret: mul big1 big2 free?
		ret/expo: big1/expo + big2/expo
		ret/prec: prec
		ret: round ret true
		if free? [free* big1]
		ret
	]

	#if debug? = yes [
		dump: func [
			big				[bigdecimal!]
		][
			bigint/dump as bigint! big
		]
	]

]
