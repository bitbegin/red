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
	size		[integer!]
	expo		[integer!]
	prec		[integer!]
	used		[integer!]
]

#enum ROUNDING! [
	ROUND-UP							;Rounds away from zero
	ROUND-DOWN							;Rounds towards zero
	ROUND-CEIL							;Rounds towards Infinity
	ROUND-FLOOR							;Rounds towards -Infinity
	ROUND-HALF-UP						;Rounds towards nearest neighbour. If equidistant, rounds away from zero
	ROUND-HALF-DOWN						;Rounds towards nearest neighbour. If equidistant, rounds towards zero
	ROUND-HALF-EVEN						;Rounds towards nearest neighbour. If equidistant, rounds towards even neighbour
	ROUND-HALF-ODD						;Rounds towards nearest neighbour. If equidistant, rounds towards odd neighbour
	ROUND-HALF-CEIL						;Rounds towards nearest neighbour. If equidistant, rounds towards Infinity
	ROUND-HALF-FLOOR					;Rounds towards nearest neighbour. If equidistant, rounds towards -Infinity
]

bigdecimal: context [
	#define DECIMAL-BASE			100000000
	#define DECIMAL-BASE-LEN		8

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
			big				[bigdecimal!]
	][
		if len > (2 * unit-max) [return null]
		if len <= 0 [return null]

		size: len * 4 + size? bigdecimal!
		p: allocate size
		if p = null [return null]
		set-memory p null-byte size
		big: as bigdecimal! p
		big/size: len
		big/prec: default-prec
		big
	]

	free*: func [big [bigdecimal!]][
		if big <> null [free as byte-ptr! big]
	]

	copy*: func [
		big					[bigdecimal!]
		return:				[bigdecimal!]
		/local
			bused			[integer!]
			ret				[bigdecimal!]
			pb				[byte-ptr!]
			pr				[byte-ptr!]
	][
		bused: either big/used >= 0 [big/used][0 - big/used]
		if any [big = null bused = 0] [return null]

		ret: alloc* bused
		if ret = null [return null]
		ret/size: bused
		ret/expo: big/expo
		ret/prec: big/prec
		ret/used: big/used
		pr: as byte-ptr! (ret + 1)
		pb: as byte-ptr! (big + 1)
		copy-memory pr pb bused * 4
		ret
	]

	expand*: func [
		big					[bigdecimal!]
		size				[integer!]			;-- expand size in integer!
		return:				[bigdecimal!]
		/local
			bsize			[integer!]
			bsign			[integer!]
			bused			[integer!]
			nsize			[integer!]
			ret				[bigdecimal!]
			cp-size			[integer!]
			pb				[byte-ptr!]
			pr				[byte-ptr!]
	][
		if big = null [return null]
		if size < 0 [return null]

		bsize: big/size
		either big/used >= 0 [
			bsign: 1
			bused: big/used
		][
			bsign: -1
			bused: 0 - big/used
		]
		nsize: either size > bsize [size][bsize]
		ret: alloc* nsize
		if ret = null [return null]
		ret/size: nsize
		ret/expo: big/expo
		ret/prec: big/prec
		ret/used: either bsign > 0 [size][0 - size]
		cp-size: either size > bused [bused][size]
		pr: as byte-ptr! (ret + 1)
		pb: as byte-ptr! (big + 1)
		copy-memory pr pb cp-size * 4
		ret
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
			uint			[integer!]
			sign			[integer!]
			big				[bigdecimal!]
			p				[int-ptr!]
			q				[integer!]
			r				[integer!]
	][
		either int >= 0 [
			uint: int
			sign: 1
		][
			uint: 0 - int
			sign: -1
		]
		if bigint/uint-less uint DECIMAL-BASE [
			big: alloc* 1
			if big = null [return null]
			big/used: either sign > 0 [1][-1]
			p: as int-ptr! (big + 1)
			p/1: uint
			return big
		]
		q: 0 r: 0
		if false = bigint/uint-div uint DECIMAL-BASE :q :r [
			return null
		]
		big: alloc* 2
		if big = null [return null]
		big/used: either sign > 0 [2][-2]
		p: as int-ptr! (big + 1)
		p/1: r
		p/2: q
		big
	]

	load-uint: func [
		uint				[integer!]
		return:				[bigdecimal!]
		/local
			big				[bigdecimal!]
			p				[int-ptr!]
			q				[integer!]
			r				[integer!]
	][
		if bigint/uint-less uint DECIMAL-BASE [
			big: alloc* 1
			if big = null [return null]
			big/used: 1
			p: as int-ptr! (big + 1)
			p/1: uint
			return big
		]
		q: 0 r: 0
		if false = bigint/uint-div uint DECIMAL-BASE :q :r [
			return null
		]
		big: alloc* 2
		if big = null [return null]
		big/used: 2
		p: as int-ptr! (big + 1)
		p/1: r
		p/2: q
		big
	]

	shrink: func [
		big					[bigdecimal!]
		/local
			bsign			[integer!]
			bused			[integer!]
			pb				[int-ptr!]
			nused			[integer!]
	][
		either big/used >= 0 [
			bsign: 1
			bused: big/used
		][
			bsign: -1
			bused: 0 - big/used
		]
		if bused = 0 [exit]

		pb: as int-ptr! (big + 1)
		pb: pb + bused - 1
		nused: bused
		loop bused [
			either pb/1 = 0 [
				nused: nused - 1
			][
				break
			]
			pb: pb - 1
		]
		if nused = 0 [nused: 1]
		big/used: either bsign > 0 [nused][0 - nused]
	]

	zero?*: func [
		big					[bigdecimal!]
		return:				[logic!]
		/local
			bused			[integer!]
			pb				[int-ptr!]
	][
		bused: either big/used >= 0 [big/used][0 - big/used]
		if bused = 0 [return true]
		pb: as int-ptr! (big + 1)
		if all [bused = 1 pb/1 = 0][return true]
		false
	]

	absolute-compare: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		return:				[integer!]
		/local
			b1used			[integer!]
			b2used			[integer!]
			p1				[int-ptr!]
			p2				[int-ptr!]
	][
		b1used: either big1/used >= 0 [big1/used][0 - big1/used]
		b2used: either big2/used >= 0 [big2/used][0 - big2/used]
		if all [b1used = 0 b2used = 0][return 0]

		if b1used > b2used [return 1]
		if b2used > b1used [return -1]

		p1: (as int-ptr! (big1 + 1)) + b1used - 1
		p2: (as int-ptr! (big2 + 1)) + b2used - 1
		loop b1used [
			if bigint/uint-less p2/1 p1/1 [return 1]
			if bigint/uint-less p1/1 p2/1 [return -1]
			p1: p1 - 1
			p2: p2 - 1
		]
		return 0
	]

	compare: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		return:				[integer!]
		/local
			b1sign			[integer!]
			b2sign			[integer!]
	][
		b1sign: either big1/used >= 0 [1][-1]
		b2sign: either big2/used >= 0 [1][-1]

		if all [zero?* big1 zero?* big2][return 0]
		if zero?* big1 [return either b2sign = 1 [-1][1]]
		if zero?* big2 [return either b1sign = 1 [1][-1]]

		if all [b1sign = 1 b2sign = -1][return 1]
		if all [b2sign = 1 b1sign = -1][return -1]

		if b1sign = 1 [
			return absolute-compare big1 big2
		]
		absolute-compare big2 big1
	]

	negative*: func [
		big					[bigdecimal!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			ret				[bigdecimal!]
	][
		ret: copy* big
		ret/used: 0 - ret/used
		if free? [free* big]
		ret
	]

	negative?*: func [
		big					[bigdecimal!]
		return:				[logic!]
	][
		if zero?* big [return false]
		if big/used < 0 [return true]
		false
	]

	positive*: func [
		big					[bigdecimal!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			ret				[bigdecimal!]
	][
		ret: copy* big
		if ret/used < 0 [ret/used: 0 - ret/used]
		if free? [free* big]
		ret
	]

	positive?*: func [
		big					[bigdecimal!]
		return:				[logic!]
	][
		if zero?* big [return false]
		if big/used > 0 [return true]
		false
	]

	absolute*: func [
		big					[bigdecimal!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			ret				[bigdecimal!]
	][
		ret: copy* big
		if ret/used < 0 [ret/used: 0 - ret/used]
		if free? [free* big]
		ret
	]

	compare-int: func [
		big1				[bigdecimal!]
		int					[integer!]
		return:				[integer!]
		/local
			big				[bigdecimal!]
			ret				[integer!]
	][
		if all [zero?* big1 int = 0][return 0]
		if zero?* big1 [return either int > 0 [-1][1]]
		if int = 0 [return either big1/used >= 0 [1][-1]]

		big: load-int int
		ret: compare big1 big
		free* big
		ret
	]

	compare-uint: func [
		big1				[bigdecimal!]
		uint				[integer!]
		return:				[integer!]
		/local
			big				[bigdecimal!]
			ret				[integer!]
	][
		if all [zero?* big1 uint = 0][return 0]
		if zero?* big1 [return -1]
		if uint = 0 [return either big1/used >= 0 [1][-1]]

		big: load-uint uint
		ret: compare big1 big
		free* big
		ret
	]

	absolute-add: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		return:				[bigdecimal!]
		/local
			b1used			[integer!]
			b2used			[integer!]
			big				[bigdecimal!]
			p				[int-ptr!]
			p2				[int-ptr!]
			i				[integer!]
			c				[integer!]
			tmp				[integer!]
	][
		b1used: either big1/used >= 0 [big1/used][0 - big1/used]
		b2used: either big2/used >= 0 [big2/used][0 - big2/used]
		p2: as int-ptr! (big2 + 1)

		big: expand* big1 either big1/size > big2/size [big1/size][big2/size]
		big/used: b1used
		p: as int-ptr! (big + 1)


		c: 0
		i: 0
		loop b2used [
			tmp: p2/1
			p/1: p/1 + c
			c: 0
			unless bigint/uint-less p/1 DECIMAL-BASE [
				c: 1
				p/1: p/1 - DECIMAL-BASE
			]
			p/1: p/1 + tmp
			unless bigint/uint-less p/1 DECIMAL-BASE [
				c: c + 1
				p/1: p/1 - DECIMAL-BASE
			]
			p: p + 1
			p2: p2 + 1
			i: i + 1
		]

		while [c > 0][
			p/1: p/1 + c
			c: 0
			unless bigint/uint-less p/1 DECIMAL-BASE [
				c: 1
				p/1: p/1 - DECIMAL-BASE
			]
			i: i + 1
			p: p + 1
		]
		if big/used < i [
			big/used: i
		]
		big
	]

	sub-hlp: func [
		n					[integer!]
		s					[int-ptr!]
		d					[int-ptr!]
		/local
			c				[integer!]
			z				[integer!]
	][
		c: 0
		loop n [
			z: 0
			if bigint/uint-less d/1 c [
				z: 1
				d/1: DECIMAL-BASE - c + d/1
			]
			c: z
			if bigint/uint-less d/1 s/1 [
				c: c + 1
				d/1: d/1 + DECIMAL-BASE
			]
			d/1: d/1 - s/1
			s: s + 1
			d: d + 1
		]

		while [c <> 0][
			z: 0
			if bigint/uint-less d/1 c [
				z: 1
				d/1: DECIMAL-BASE - c + d/1
			]
			c: z
			d: d + 1
		]
	]

	;-- big1 must large than big2
	absolute-sub: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		return:				[bigdecimal!]
		/local
			b1used			[integer!]
			b2used			[integer!]
			big				[bigdecimal!]
	][
		b1used: either big1/used >= 0 [big1/used][0 - big1/used]
		b2used: either big2/used >= 0 [big2/used][0 - big2/used]

		if b1used < b2used [return null]

		big: copy* big1
		big/used: b1used

		sub-hlp b2used as int-ptr! (big2 + 1) as int-ptr! (big + 1)

		shrink big
		big
	]

	add: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			b1sign			[integer!]
			b2sign			[integer!]
			big				[bigdecimal!]
			p				[int-ptr!]
	][
		if all [zero?* big1 zero?* big2][
			if free? [free* big1]
			return load-int 0
		]
		if zero?* big1 [
			big: copy* big2
			if free? [free* big1]
			return big
		]
		if zero?* big2 [
			big: copy* big1
			if free? [free* big1]
			return big
		]

		b1sign: either big1/used >= 0 [1][-1]
		b2sign: either big2/used >= 0 [1][-1]

		either b1sign <> b2sign [
			either (absolute-compare big1 big2) >= 0 [
				big: absolute-sub big1 big2
				if b1sign = -1 [big/used: 0 - big/used]
			][
				big: absolute-sub big2 big1
				if b2sign = -1 [big/used: 0 - big/used]
			]
		][
			either (absolute-compare big1 big2) >= 0 [
				big: absolute-add big1 big2
			][
				big: absolute-add big2 big1
			]
			if b1sign = -1 [big/used: 0 - big/used]
		]
		if big/used = -1 [
			p: as int-ptr! (big + 1)
			if p/1 = 0 [
				big/used: 1
			]
		]
		if free? [free* big1]
		big
	]

	sub: func [
		big1				[bigdecimal!]
		big2				[bigdecimal!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			b1sign			[integer!]
			b2sign			[integer!]
			big				[bigdecimal!]
			p				[int-ptr!]
	][
		if all [zero?* big1 zero?* big2][
			if free? [free* big1]
			return load-int 0
		]
		if zero?* big1 [
			big: copy* big2
			big/used: 0 - big/used
			if free? [free* big1]
			return big
		]
		if zero?* big2 [
			big: copy* big1
			if free? [free* big1]
			return big
		]

		b1sign: either big1/used >= 0 [1][-1]
		b2sign: either big2/used >= 0 [1][-1]

		either b1sign = b2sign [
			either (absolute-compare big1 big2) >= 0 [
				big: absolute-sub big1 big2
				if b1sign = -1 [big/used: 0 - big/used]
			][
				big: absolute-sub big2 big1
				if b1sign = 1 [big/used: 0 - big/used]
			]
		][
			either (absolute-compare big1 big2) >= 0 [
				big: absolute-add big1 big2
			][
				big: absolute-add big2 big1
			]
			if b1sign = -1 [big/used: 0 - big/used]
		]
		if big/used = -1 [
			p: as int-ptr! (big + 1)
			if p/1 = 0 [
				big/used: 1
			]
		]
		if free? [free* big1]
		big
	]

	add-int: func [
		big1				[bigdecimal!]
		int					[integer!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			big				[bigdecimal!]
			ret				[bigdecimal!]
	][
		if all [zero?* big1 int = 0][
			if free? [free* big1]
			return load-int 0
		]
		if zero?* big1 [
			if free? [free* big1]
			return load-int int
		]
		if int = 0 [
			big: copy* big1
			if free? [free* big1]
			return big
		]

		big: load-int int
		ret: add big1 big free?
		free* big
		ret
	]

	add-uint: func [
		big1				[bigdecimal!]
		uint				[integer!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			big				[bigdecimal!]
			ret				[bigdecimal!]
	][
		if all [zero?* big1 uint = 0][
			if free? [free* big1]
			return load-uint 0
		]
		if zero?* big1 [
			if free? [free* big1]
			return load-uint uint
		]
		if uint = 0 [
			big: copy* big1
			if free? [free* big1]
			return big
		]

		big: load-uint uint
		ret: add big1 big free?
		free* big
		ret
	]

	sub-int: func [
		big1				[bigdecimal!]
		int					[integer!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			big				[bigdecimal!]
			ret				[bigdecimal!]
	][
		if all [zero?* big1 int = 0][
			if free? [free* big1]
			return load-int 0
		]
		if zero?* big1 [
			if free? [free* big1]
			return load-int 0 - int
		]
		if int = 0 [
			big: copy* big1
			if free? [free* big1]
			return big
		]

		big: load-int int
		ret: sub big1 big free?
		free* big
		ret
	]

	sub-uint: func [
		big1				[bigdecimal!]
		uint				[integer!]
		free?				[logic!]
		return:				[bigdecimal!]
		/local
			big				[bigdecimal!]
			ret				[bigdecimal!]
	][
		if all [zero?* big1 uint = 0][
			if free? [free* big1]
			return load-uint 0
		]
		if zero?* big1 [
			big: load-uint uint
			big/used: 0 - big/used
			if free? [free* big1]
			return big
		]
		if uint = 0 [
			big: copy* big1
			if free? [free* big1]
			return big
		]

		big: load-uint uint
		ret: sub big1 big free?
		free* big
		ret
	]

	#if debug? = yes [
		dump: func [
			big				[bigdecimal!]
			/local
				bused		[integer!]
				bsign		[integer!]
				p			[int-ptr!]
		][
			print-line [lf "===============dump bigdecimal!==============="]
			either big = null [
				print-line "null"
			][
				either big/used >= 0 [
					bsign: 1
					bused: big/used
				][
					bsign: -1
					bused: 0 - big/used
				]
				print-line ["size: " big/size " used: " bused " sign: " bsign " expo: " big/expo " prec: " big/prec]
				p: as int-ptr! (big + 1)
				p: p + bused - 1
				loop bused [
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

big: bigdecimal/load-int -900000000
bigdecimal/dump big

big2: bigdecimal/load-uint 900000000
bigdecimal/dump big2


big3: bigdecimal/add big big2 false
bigdecimal/dump big3

big4: bigdecimal/sub big big2 false
bigdecimal/dump big4

bigdecimal/free* big
bigdecimal/free* big2
bigdecimal/free* big3
