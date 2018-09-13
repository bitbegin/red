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
	exp-min: -1000000000
	exp-max:  1000000000

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
		big/expo: 7FFFFFFFh
		big/sign: sign
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

		big: as bigdecimal! bigint/load-str as c-string! buffer total 10
		if big <> null [
			bigint/shrink as bigint! big
			if bigint/zero?* as bigint! big [big/used: 1 big/sign: 1]
			big/expo: exp
			big/prec: default-prec
		]
		free buffer
		big
	]

	load-bigint: func [
		big					[bigint!]
		return:				[bigdecimal!]
		/local
			ibuf			[integer!]
			ilen			[integer!]
			ret				[bigdecimal!]
			buf				[byte-ptr!]
	][
		ibuf: 0
		ilen: 0
		if false = bigint/form big 10 :ibuf :ilen [
			return null
		]
		buf: as byte-ptr! ibuf
		if ilen > default-prec [
			ret: as bigdecimal! bigint/load-str as c-string! buf default-prec 10
			ret/expo: ilen - default-prec
			ret/prec: default-prec
			free buf
			return ret
		]
		free buf
		ret: as bigdecimal! bigint/copy* big big/used
		ret/expo: 0
		ret/prec: default-prec
		ret
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

	decimalize-uint: func [
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
			eStr: decimalize-uint eLen
			eSLen: length? eStr
			eSign: 1
			; x . y..y E e..e null
			size: ilen + 1 - zcnt + 1 + eSLen + 1
		][
			point: 0 - expo
			either point >= ilen [
				eLen: point - ilen + 1
				eStr: decimalize-uint eLen
				eSLen: length? eStr
				eSign: -1
				size: ilen + 1 - zcnt + 2 + eSLen + 1
			][
				eLen: ilen - point - 1
				eStr: decimalize-uint eLen
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
			p				[int-ptr!]
			ibuf			[integer!]
			ilen			[integer!]
			buf				[byte-ptr!]
			exp?			[logic!]
			nbuf			[integer!]
			nlen			[integer!]
	][
		p: big/data
		if big/expo = 7FFFFFFFh [
			if bigint/zero?* as bigint! big [
				if big/sign = 1 [
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

		ibuf: 0
		ilen: 0
		if false = bigint/form as bigint! big 10 :ibuf :ilen [
			return false
		]
		buf: as byte-ptr! ibuf

		if any [
			big/expo = 0
			all [
				big/used = 1
				p/1 = 0
			]
		][
			obuf/value: ibuf
			olen/value: ilen
			return true
		]

		exp?: false
		if any [
			all [
				big/expo > 0
				(big/expo + ilen) > big/prec
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
			exp-form buf ilen big/expo :nbuf :nlen
		][
			point-form buf ilen big/expo :nbuf :nlen
		]
		free buf
		obuf/value: nbuf
		olen/value: nlen
		return true
	]

	free*: func [big [bigdecimal!]][
		if big <> null [free as byte-ptr! big]
	]

	#if debug? = yes [
		dump: func [
			big				[bigdecimal!]
			/local
				p			[int-ptr!]
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
