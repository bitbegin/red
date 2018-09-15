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
	bint		[bigint!]
	expo		[integer!]
	prec		[integer!]
	dlen		[integer!]
	digit		[byte-ptr!]
]

bigdecimal: context [
	default-prec: 20
	exp-min: -1000000000
	exp-max:  1000000000

	set-default-prec: func [precise [integer!]][
		default-prec: either precise >= 2 [precise][2]
	]

	set-exp-min: func [exp [integer!]][
		exp-min: either exp >= -1000000000 [exp][-1000000000]
	]

	set-exp-max: func [exp [integer!]][
		exp-max: either exp <= 1000000000 [exp][1000000000]
	]

	alloc*: func [
		return:			[bigdecimal!]
		/local
			p			[byte-ptr!]
	][
		p: allocate size? bigdecimal!
		as bigdecimal! p
	]

	free*: func [big [bigdecimal!]][
		if big <> null [
			bigint/free* big/bint
			if big/digit <> null [
				free big/digit
			]
			free as byte-ptr! big
		]
	]

	load-nan: func [
		return:				[bigdecimal!]
		/local
			bint			[bigint!]
			big				[bigdecimal!]
	][
		bint: bigint/load-int -1

		big: alloc*
		big/bint: bint
		big/expo: 7FFFFFFFh
		big/prec: default-prec
		big/dlen: 0
		big/digit: null
		big
	]

	load-inf: func [
		sign				[integer!]
		return:				[bigdecimal!]
		/local
			bint			[bigint!]
			big				[bigdecimal!]
	][
		bint: bigint/load-int 0
		bint/used: 1
		bint/sign: sign

		big: alloc*
		big/bint: bint
		big/expo: 7FFFFFFFh
		big/prec: default-prec
		big/dlen: 0
		big/digit: null
		big
	]

	load-int: func [
		int					[integer!]
		return:				[bigdecimal!]
		/local
			bint			[bigint!]
			ibuf			[integer!]
			ilen			[integer!]
			big				[bigdecimal!]
			p				[int-ptr!]
	][
		bint: bigint/load-int int
		if int = 0 [bint/used: 1]
		ibuf: 0
		ilen: 0
		if false = bigint/form bint 10 :ibuf :ilen [
			bigint/free* bint
			return load-nan
		]
		big: alloc*
		big/bint: bint
		big/expo: 0
		big/prec: default-prec
		big/dlen: ilen
		big/digit: as byte-ptr! ibuf
		big
	]

	load-uint: func [
		uint				[integer!]
		return:				[bigdecimal!]
		/local
			bint			[bigint!]
			ibuf			[integer!]
			ilen			[integer!]
			big				[bigdecimal!]
			p				[int-ptr!]
	][
		bint: bigint/load-uint uint
		if uint = 0 [bint/used: 1]
		ibuf: 0
		ilen: 0
		if false = bigint/form bint 10 :ibuf :ilen [
			bigint/free* bint
			return load-nan
		]
		big: alloc*
		big/bint: bint
		big/expo: 0
		big/prec: default-prec
		big/dlen: ilen
		big/digit: as byte-ptr! ibuf
		big
	]

	;-- count same char from buffer tail
	count-same-char: func [
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
			zcnt			[integer!]
			total			[integer!]
			temp			[integer!]
			prec			[integer!]
			buffer			[byte-ptr!]
			bint			[bigint!]
			ibuf			[integer!]
			ilen			[integer!]
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
					exp?: true
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

		either exp? [
			either dot? [
				intLen: dotp - 1
				ptLen: expp - dotp - 1
				zcnt: count-same-char as byte-ptr! bak + dotp ptLen #"0"
				ptLen: ptLen - zcnt
			][
				intLen: expp - 1
				ptLen: 0
			]
		][
			either dot? [
				intLen: dotp - 1
				ptLen: len - dotp
				zcnt: count-same-char as byte-ptr! bak + dotp ptLen #"0"
				;print-line ["dotp: " dotp " zcnt: " zcnt " ptLen: " ptLen]
				ptLen: ptLen - zcnt
			][
				intLen: len
				ptLen: 0
			]
			exp: 0
		]

		;print-line ["esign: " esign " exp: " exp " intLen: " intLen " ptLen: " ptLen]
		if esign = -1 [
			exp: 0 - exp
		]
		exp: exp - ptLen
		total: intLen + ptLen

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
		copy-memory buffer as byte-ptr! bak intLen
		if all [dot? ptLen > 0] [
			copy-memory buffer + intLen as byte-ptr! bak + dotp ptLen
		]

		either sign = 0 [
			prec: default-prec
		][
			prec: default-prec + 1
		]

		if total > prec [
			exp: exp + (total - prec)
			total: prec
		]

		bint: bigint/load-str as c-string! buffer total 10
		either bint <> null [
			bigint/shrink bint
			if bigint/zero?* bint [bint/used: 1 bint/sign: 1]
			ibuf: 0
			ilen: 0
			if false = bigint/form bint 10 :ibuf :ilen [
				free buffer
				bigint/free* bint
				return load-nan
			]
			big: alloc*
			big/bint: bint
			big/expo: exp
			big/prec: default-prec
			big/dlen: ilen
			big/digit: as byte-ptr! ibuf
		][
			big: load-nan
		]
		free buffer
		big
	]

	load-bigint: func [
		big					[bigint!]
		prec				[integer!]
		return:				[bigdecimal!]
		/local
			ibuf			[integer!]
			ilen			[integer!]
			bint			[bigint!]
			ret				[bigdecimal!]
	][
		ibuf: 0
		ilen: 0
		if false = bigint/form big 10 :ibuf :ilen [
			return load-nan
		]
		if ilen > prec [
			bint: bigint/load-str as c-string! ibuf prec 10
			ret: alloc*
			ret/bint: bint
			ret/expo: ilen - prec
			ret/prec: prec
			ret/dlen: prec
			ret/digit: as byte-ptr! ibuf
			return ret
		]
		bint: bigint/copy* big big/used
		ret: alloc*
		ret/bint: bint
		ret/expo: 0
		ret/prec: prec
		ret/dlen: ilen
		ret/digit: as byte-ptr! ibuf
		ret
	]

	decimalize-int: func [
		value				[integer!]
		return:				[c-string!]
		/local
			s				[c-string!]
			r				[c-string!]
			m				[c-string!]
			rem				[integer!]
			t				[integer!]
			i				[integer!]
			rsize			[integer!]
			j				[integer!]
			p				[byte-ptr!]
	][
		s: "0000000000"
		r: "0000000000"
		m: "0123456789"

		i: 1
		rem: value
		until [
			t: (rem % 10) + 1
			s/i: m/t
			rem: rem / 10

			i: i + 1
			rem = 0
		]
		s/i: null-byte

		rsize: i - 1
		j: 1
		p: as byte-ptr! s + rsize - 1
		loop rsize [
			r/j: p/1

			p: p - 1
			j: j + 1
		]
		r/j: null-byte
		r
	]

	point-form: func [
		ibuf				[byte-ptr!]
		ilen				[integer!]
		expo				[integer!]
		obuf				[int-ptr!]
		olen				[int-ptr!]
		/local
			sign			[integer!]
			size			[integer!]
			buf				[byte-ptr!]
			p				[byte-ptr!]
			pos				[integer!]
			point			[integer!]
			zcnt			[integer!]
			zpad			[integer!]
	][
		sign: 1
		if ibuf/1 = #"-" [sign: -1 ibuf: ibuf + 1 ilen: ilen - 1]

		if expo >= 0 [
			; x..x 0..0 null
			size: ilen + expo + 1
			if sign = -1 [size: size + 1]
			buf: allocate size
			p: buf

			pos: 1
			if sign = -1 [
				p/pos: #"-"
				pos: pos + 1
			]
			copy-memory p + pos - 1 ibuf ilen
			pos: pos + ilen
			loop expo [
				p/pos: #"0"
				pos: pos + 1
			]
			p/pos: null-byte
			p/size: null-byte
			obuf/value: as integer! buf
			olen/value: pos - 1
			exit
		]

		point: 0 - expo
		either point >= ilen [
			zcnt: count-same-char ibuf ilen #"0"
			; 0. x..x null
			size: point + 2 - zcnt + 1
			if sign = -1 [size: size + 1]
			buf: allocate size
			p: buf

			pos: 1
			if sign = -1 [
				p/pos: #"-"
				pos: pos + 1
			]
			p/pos: #"0"
			pos: pos + 1
			p/pos: #"."
			pos: pos + 1
			zpad: point - ilen
			set-memory p + pos - 1 #"0" zpad
			pos: pos + zpad
			copy-memory p + pos - 1 ibuf ilen - zcnt
			pos: pos + ilen - zcnt
			p/pos: null-byte
		][
			; x..x . y..y null
			size: ilen + 1 + 1
			if sign = -1 [size: size + 1]
			buf: allocate size
			p: buf

			pos: 1
			if sign = -1 [
				p/pos: #"-"
				pos: pos + 1
			]
			copy-memory p + pos - 1 ibuf ilen - point
			pos: pos + ilen - point

			zcnt: count-same-char ibuf + ilen - point point #"0"
			;print-line ["ilen: " ilen " point: " point " zcnt: " zcnt]
			either point <= zcnt [
				p/pos: null-byte
			][
				p/pos: #"."
				pos: pos + 1
				copy-memory p + pos - 1 ibuf + ilen - point point - zcnt
				pos: pos + point - zcnt
				p/pos: null-byte
			]
		]

		p/size: null-byte
		obuf/value: as integer! buf
		olen/value: pos - 1
	]

	exp-form: func [
		ibuf				[byte-ptr!]
		ilen				[integer!]
		expo				[integer!]
		obuf				[int-ptr!]
		olen				[int-ptr!]
		/local
			sign			[integer!]
			zcnt			[integer!]
			eLen			[integer!]
			eSign			[integer!]
			eStr			[c-string!]
			eSLen			[integer!]
			size			[integer!]
			point			[integer!]
			buf				[byte-ptr!]
			pi				[int-ptr!]
			p				[byte-ptr!]
			pos				[integer!]
	][
		sign: 1
		if ibuf/1 = #"-" [sign: -1 ibuf: ibuf + 1 ilen: ilen - 1]

		zcnt: count-same-char ibuf ilen #"0"

		either expo >= 0 [
			eLen: ilen - 1 + expo
			eStr: decimalize-int eLen
			eSLen: length? eStr
			eSign: 1
			; x . y..y E e..e null
			size: ilen + 1 - zcnt + 1 + eSLen + 1
		][
			point: 0 - expo
			either point >= ilen [
				eLen: point - ilen + 1
				eStr: decimalize-int eLen
				eSLen: length? eStr
				eSign: -1
				size: ilen + 1 - zcnt + 2 + eSLen + 1
			][
				eLen: ilen - point - 1
				eStr: decimalize-int eLen
				eSLen: length? eStr
				eSign: 1
				size: ilen + 1 - zcnt + 1 + eSLen + 1
			]
		]

		size: size + 1			;-- for one point at least
		if sign = -1 [size: size + 1]
		;print-line ["point: " point " ilen: " ilen " zcnt: " zcnt " eLen: " eLen " eStr: " eStr " eSLen: " eSLen " eSign: " eSign " size: " size]
		buf: allocate size
		p: buf

		pos: 1
		if sign = -1 [
			p/pos: #"-"
			pos: pos + 1
		]
		p/pos: ibuf/1
		pos: pos + 1
		p/pos: #"."
		pos: pos + 1
		either 0 = (ilen - zcnt - 1) [
			p/pos: #"0"
			pos: pos + 1
		][
			copy-memory p + pos - 1 ibuf + 1 ilen - zcnt - 1
			pos: pos + ilen - zcnt - 1
		]
		p/pos: #"E"
		pos: pos + 1
		if eSign = -1 [p/pos: #"-" pos: pos + 1]
		copy-memory p + pos - 1 as byte-ptr! eStr eSLen
		pos: pos + eSLen
		p/pos: null-byte

		p/size: null-byte
		obuf/value: as integer! buf
		olen/value: pos - 1
	]

	form: func [
		big					[bigdecimal!]
		obuf				[int-ptr!]
		olen				[int-ptr!]
		return:				[logic!]
		/local
			bint			[bigint!]
			buf				[byte-ptr!]
			size			[integer!]
			exp?			[logic!]
			nbuf			[integer!]
			nlen			[integer!]
	][
		bint: big/bint
		if big/expo = 7FFFFFFFh [
			if bigint/zero?* bint [
				if bint/sign = 1 [
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
			big/expo = 7FFFFFFFh
			big/expo = 80000000h
		][
			buf: allocate 7
			copy-memory buf as byte-ptr! "1.#NaN" 7
			obuf/value: as integer! buf
			olen/value: 6
			return true
		]

		if any [
			big/expo = 0
			bigint/zero?* bint
		][
			size: big/dlen + 1
			buf: allocate size
			buf/size: null-byte
			copy-memory buf big/digit big/dlen
			obuf/value: as integer! buf
			olen/value: big/dlen
			return true
		]

		exp?: false
		if any [
			all [
				big/expo > 0
				(big/expo + big/dlen) > big/prec
			]
			all [
				big/expo < 0
				big/expo < (0 - big/prec)
			]
		][
			exp?: true
		]

		nbuf: 0
		nlen: 0
		either exp? [
			exp-form big/digit big/dlen big/expo :nbuf :nlen
		][
			point-form big/digit big/dlen big/expo :nbuf :nlen
		]

		obuf/value: nbuf
		olen/value: nlen
		return true
	]

	zero?*: func [
		big					[bigdecimal!]
		return:				[logic!]
	][
		if any [
			big/expo = 7FFFFFFFh
			big/expo = 80000000h
		][return false]
		if bigint/zero?* big/bint [return true]
		false
	]

	#if debug? = yes [
		dump: func [
			big				[bigdecimal!]
			/local
				bint		[bigint!]
				p			[int-ptr!]
		][
			print-line [lf "===============dump bigdecimal!==============="]
			either big = null [
				print-line "null"
			][
				bigint/dump big/bint
				print-line ["expo: " big/expo " prec: " big/prec " dlen: " big/dlen]
				print-line as c-string! big/digit
			]
			print-line [lf "=============dump bigdecimal! end============="]
		]
	]

]
