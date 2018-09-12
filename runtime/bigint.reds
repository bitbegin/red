Red/System [
	Title:   "big integer lib"
	Author:  "bitbegin"
	File: 	 %bigint.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

bigint!: alias struct! [
	size		[integer!]				;-- size in integer!
	used		[integer!]				;-- used length in integer!
	sign		[integer!]
	resv		[integer!]
	resv2		[integer!]
	data		[int-ptr!]
]

bigint: context [

	ciL:				4				;-- bigint! unit is 4 bytes; chars in limb
	biL:				ciL << 3		;-- bits in limb
	biLH:				ciL << 2		;-- half bits in limb
	BN_MAX_LIMB:		1024			;-- support 1024 * 32 bits

	#define MULADDC_INIT [
		s0: 0 s1: 0 b0: 0 b1: 0 r0: 0 r1: 0 rx: 0 ry: 0
		b0: (b << biLH) >>> biLH
		b1: b >>> biLH
	]
	#define MULADDC_CORE [
		s0: (s/1 << biLH) >>> biLH
		s1: s/1 >>> biLH		s: s + 1
		rx: s0 * b1 			r0: s0 * b0
		ry: s1 * b0 			r1: s1 * b1
		r1: r1 + (rx >>> biLH)
		r1: r1 + (ry >>> biLH)
		rx: rx << biLH 			ry: ry << biLH
		r0: r0 + rx 			r1: r1 + as integer! (uint-less r0 rx)
		r0: r0 + ry 			r1: r1 + as integer! (uint-less r0 ry)
		r0: r0 + c 				r1: r1 + as integer! (uint-less r0 c)
		r0: r0 + d/1			r1: r1 + as integer! (uint-less r0 d/1)
		c: r1					d/1: r0		d: d + 1
	]
	#define MULADDC_STOP []

	set-max-size: func [size [integer!]][
		if size > 0 [BN_MAX_LIMB: size]
	]

	alloc*: func [
		size			[integer!]			;-- size in integer!
		return:			[bigint!]
		/local
			len			[integer!]
			p			[byte-ptr!]
			big			[bigint!]
	][
		if size > BN_MAX_LIMB [return null]

		len: size * 4 + size? bigint!
		p: allocate len
		set-memory p null-byte len
		big: as bigint! p
		big/size: size
		big/used: 0
		big/sign: 1
		big/resv: 0
		big/resv2: 0
		big/data: as int-ptr! (p + size? bigint!)
		big
	]

	free*: func [big [bigint!]][
		if big <> null [free as byte-ptr! big]
	]

	copy*: func [
		big					[bigint!]
		expand				[integer!]			;-- expand size in integer!
		return:				[bigint!]
		/local
			size			[integer!]
			cp-size			[integer!]
			ret				[bigint!]
	][
		if big = null [return null]
		size: either expand > big/size [expand][big/size]
		ret: alloc* size
		ret/size: size
		ret/used: expand
		ret/sign: big/sign
		ret/resv: big/resv
		big/resv2: big/resv2
		cp-size: either expand > big/used [big/used][expand]
		copy-memory as byte-ptr! ret/data as byte-ptr! big/data cp-size * 4
		ret
	]

	from-int: func [
		big					[bigint!]
		int					[integer!]
		/local
			p				[int-ptr!]
	][
		p: big/data
		p/1: either int >= 0 [
			big/sign: 1
			int
		][
			big/sign: -1
			0 - int
		]
		big/used: 1
		if int = 0 [big/used: 0]
	]

	from-uint: func [
		big					[bigint!]
		uint				[integer!]
		/local
			p				[int-ptr!]
	][
		p: big/data
		big/sign: 1
		p/1: uint
		big/used: 1
		if uint = 0 [big/used: 0]
	]

	load-int: func [
		int					[integer!]
		return:				[bigint!]
		/local
			big				[bigint!]
	][
		big: alloc* 2
		from-int big int
		big
	]

	load-uint: func [
		uint				[integer!]
		return:				[bigint!]
		/local
			big				[bigint!]
	][
		big: alloc* 2
		from-uint big uint
		big
	]

	load-ulong: func [
		uL					[integer!]
		uH					[integer!]
		return:				[bigint!]
		/local
			big				[bigint!]
			p				[int-ptr!]
	][
		big: alloc* 3
		p: big/data
		big/sign: 1
		p/1: uL
		p/2: uH
		big/used: 2
		if all [uL = 0 uH = 0][big/used: 0]
		big
	]

	;-- Count leading zero bits in a given integer
	clz: func [
		int			[integer!]
		return:		[integer!]
		/local
			mask	[integer!]
			ret		[integer!]
	][
		mask: 1 << (biL - 1)
		ret: 0

		loop biL [
			if (int and mask) <> 0 [
				break
			]
			mask: mask >>> 1
			ret: ret + 1
		]
		ret
	]

	bitlen?: func [
		big			[bigint!]
		return:		[integer!]
		/local
			p		[int-ptr!]
			ret		[integer!]
	][
		if big/used = 0 [return 0]

		p: big/data + big/used - 1
		ret: biL - clz p/1
		ret: ret + ((big/used - 1) * biL)
		ret
	]

	len?: func [
		big			[bigint!]
		return:		[integer!]
		/local
			ret		[integer!]
	][
		ret: bitlen? big
		ret: (ret + 7) >>> 3
		ret
	]

	shrink: func [
		big			[bigint!]
		/local
			p		[int-ptr!]
			len		[integer!]
	][
		if big/used = 0 [exit]
		p: big/data + big/used - 1
		loop big/used [
			either p/value = 0 [
				big/used: big/used - 1
			][
				break
			]
			p: p - 1
		]
	]

	;-- u1 < u2
	;#either config/cpu/little-endian? [
		uint-less: func [
			u1			[integer!]
			u2			[integer!]
			return:		[logic!]
			/local
				p1		[byte-ptr!]
				p2		[byte-ptr!]
		][
			p1: as byte-ptr! :u1
			p2: as byte-ptr! :u2
			if p1/4 < p2/4 [return true]
			if p1/4 > p2/4 [return false]
			if p1/3 < p2/3 [return true]
			if p1/3 > p2/3 [return false]
			if p1/2 < p2/2 [return true]
			if p1/2 > p2/2 [return false]
			if p1/1 < p2/1 [return true]
			if p1/1 > p2/1 [return false]
			return false
		]
	;][
	;	uint-less: func [
	;		u1			[integer!]
	;		u2			[integer!]
	;		return:		[logic!]
	;		/local
	;			p1		[byte-ptr!]
	;			p2		[byte-ptr!]
	;	][
	;		p1: as byte-ptr! :u1
	;		p2: as byte-ptr! :u2
	;		if p1/1 < p2/1 [return true]
	;		if p1/1 > p2/1 [return false]
	;		if p1/2 < p2/2 [return true]
	;		if p1/2 > p2/2 [return false]
	;		if p1/3 < p2/3 [return true]
	;		if p1/3 > p2/3 [return false]
	;		if p1/4 < p2/4 [return true]
	;		if p1/4 > p2/4 [return false]
	;		return false
	;	]
	;]

	lset: func [
		big			[bigint!]
		int			[integer!]
		/local
			p		[int-ptr!]
	][
		set-memory as byte-ptr! big/data null-byte big/size * 4

		from-int big int
	]

	left-shift: func [
		big			[bigint!]
		count		[integer!]
		free?		[logic!]
		return:		[bigint!]
		/local
			i		[integer!]
			v0		[integer!]
			t1		[integer!]
			r0		[integer!]
			r1		[integer!]
			size	[integer!]
			p		[int-ptr!]
			p1		[int-ptr!]
			p2		[int-ptr!]
			ret		[bigint!]
	][
		if big/used = 0 [
			if free? [free* big]
			return load-int 0
		]
		r0: 0
		v0: count / biL
		t1: count and (biL - 1)
		i: bitlen? big
		i: i + count

		either (big/used * biL) < i [
			size: i / biL
			if i % biL <> 0 [
				size: size + 1
			]
		][
			size: big/used
		]

		ret: copy* big size

		p: ret/data

		if v0 > 0 [
			i: ret/used
			while [i > v0][
				p1: p + i - 1
				p2: p + i - v0 - 1
				p1/1: p2/1
				i: i - 1
			]

			while [i > 0][
				p1: p + i - 1
				p1/1: 0
				i: i - 1
			]
		]

		if t1 > 0 [
			i: v0
			while [i < ret/used][
				p1: p + i
				r1: p1/1 >>> (biL - t1)
				p1/1: p1/1 << t1
				p1/1: p1/1 or r0
				r0: r1
				i: i + 1
			]
		]

		if any [
			v0 > 0
			t1 > 0
		][
			shrink ret
		]
		if free? [free* big]
		ret
	]

	right-shift: func [
		big			[bigint!]
		count		[integer!]
		free?		[logic!]
		return:		[bigint!]
		/local
			i		[integer!]
			v0		[integer!]
			v1		[integer!]
			r0		[integer!]
			r1		[integer!]
			p		[int-ptr!]
			p1		[int-ptr!]
			p2		[int-ptr!]
			ret		[bigint!]
	][
		if big/used = 0 [
			if free? [free* big]
			return load-int 0
		]
		r0: 0
		v0: count / biL
		v1: count and (biL - 1)

		ret: copy* big big/used
		p: ret/data

		if any [
			v0 > ret/used
			all [
				v0 = ret/used
				v1 > 0
			]
		][
			lset ret 0
			if free? [free* big]
			return ret
		]

		if v0 > 0 [
			i: 0
			while [i < (ret/used - v0)][
				p1: p + i
				p2: p + i + v0
				p1/1: p2/1
				i: i + 1
			]

			while [i < ret/used][
				p1: p + i
				p1/1: 0
				i: i + 1
			]
		]

		if v1 > 0 [
			i: ret/used
			while [i > 0][
				p1: p + i - 1
				r1: p1/1 << (biL - v1)
				p1/1: p1/1 >>> v1
				p1/1: p1/1 or r0
				r0: r1
				i: i - 1
			]
		]

		if any [
			v0 > 0
			v1 > 0
		][
			shrink ret
		]
		if free? [free* big]
		ret
	]

	absolute-add: func [
		big1		[bigint!]
		big2		[bigint!]
		return:		[bigint!]
		/local
			big		[bigint!]
			p		[int-ptr!]
			p2		[int-ptr!]
			i		[integer!]
			c		[integer!]
			tmp		[integer!]
	][
		p2: big2/data

		big: copy* big1 either big1/size > big2/size [big1/size][big2/size]
		big/sign: 1
		big/used: big1/used
		p: big/data

		c: 0
		i: 0
		loop big2/used [
			tmp: p2/1
			p/1: p/1 + c
			c: as integer! (uint-less p/1 c)
			p/1: p/1 + tmp
			c: c + as integer! (uint-less p/1 tmp)
			p: p + 1
			p2: p2 + 1
			i: i + 1
		]

		while [c > 0][
			p/1: p/1 + c
			c: as integer! (uint-less p/1 c)
			i: i + 1
			p: p + 1
		]
		if big/used < i [
			big/used: i
		]
		big
	]

	sub-hlp: func [
		n			[integer!]
		s			[int-ptr!]
		d			[int-ptr!]
		/local
			c		[integer!]
			z		[integer!]
	][
		c: 0
		loop n [
			z: as integer! (uint-less d/1 c)
			d/1: d/1 - c
			c: z + as integer! (uint-less d/1 s/1)
			d/1: d/1 - s/1
			s: s + 1
			d: d + 1
		]

		while [c <> 0][
			z: as integer! (uint-less d/1 c)
			d/1: d/1 - c
			c: z
			d: d + 1
		]
	]

	;-- big1 must large than big2
	absolute-sub: func [
		big1		[bigint!]
		big2		[bigint!]
		return:		[bigint!]
		/local
			big		[bigint!]
	][
		if big1/used < big2/used [return null]

		big: copy* big1 big1/used
		big/sign: 1

		sub-hlp big2/used big2/data big/data

		shrink big
		big
	]

	add: func [
		big1		[bigint!]
		big2		[bigint!]
		free?		[logic!]
		return:		[bigint!]
		/local
			big		[bigint!]
	][
		if all [big1/used = 0 big2/used = 0][
			if free? [free* big1]
			return load-int 0
		]
		if big1/used = 0 [
			big: copy* big2 big2/used
			if free? [free* big1]
			return big
		]
		if big2/used = 0 [
			big: copy* big1 big1/used
			if free? [free* big1]
			return big
		]

		either big1/sign <> big2/sign [
			either (absolute-compare big1 big2) >= 0 [
				big: absolute-sub big1 big2
				big/sign: big1/sign
			][
				big: absolute-sub big2 big1
				big/sign: big2/sign
			]
		][
			big: absolute-add big1 big2
			big/sign: big1/sign
		]
		if free? [free* big1]
		big
	]

	sub: func [
		big1		[bigint!]
		big2		[bigint!]
		free?		[logic!]
		return:		[bigint!]
		/local
			big		[bigint!]
	][
		if all [big1/used = 0 big2/used = 0][
			if free? [free* big1]
			return load-int 0
		]
		if big1/used = 0 [
			big: copy* big2 big2/used
			big/sign: either big2/sign = 1 [-1][1]
			if free? [free* big1]
			return big
		]
		if big2/used = 0 [
			big: copy* big1 big1/used
			if free? [free* big1]
			return big
		]

		either big1/sign = big2/sign [
			either (absolute-compare big1 big2) >= 0 [
				big: absolute-sub big1 big2
				big/sign: big1/sign
			][
				big: absolute-sub big2 big1
				big/sign: 0 - big1/sign
			]
		][
			big: absolute-add big1 big2
			big/sign: big1/sign
		]
		if free? [free* big1]
		big
	]

	add-int: func [
		big1		[bigint!]
		int			[integer!]
		free?		[logic!]
		return:		[bigint!]
		/local
			big		[bigint!]
			ret		[bigint!]
	][
		if all [big1/used = 0 int = 0][
			if free? [free* big1]
			return load-int 0
		]
		if big1/used = 0 [
			if free? [free* big1]
			return load-int int
		]
		if int = 0 [
			big: copy* big1 big1/used
			if free? [free* big1]
			return big
		]

		big: load-int int
		ret: add big1 big free?
		free* big
		ret
	]

	add-uint: func [
		big1		[bigint!]
		uint		[integer!]
		free?		[logic!]
		return:		[bigint!]
		/local
			big		[bigint!]
			ret		[bigint!]
	][
		if all [big1/used = 0 uint = 0][
			if free? [free* big1]
			return load-uint 0
		]
		if big1/used = 0 [
			if free? [free* big1]
			return load-uint uint
		]
		if uint = 0 [
			big: copy* big1 big1/used
			if free? [free* big1]
			return big
		]

		big: load-uint uint
		ret: add big1 big free?
		free* big
		ret
	]

	sub-int: func [
		big1		[bigint!]
		int			[integer!]
		free?		[logic!]
		return:		[bigint!]
		/local
			big		[bigint!]
			ret		[bigint!]
	][
		if all [big1/used = 0 int = 0][
			if free? [free* big1]
			return load-int 0
		]
		if big1/used = 0 [
			if free? [free* big1]
			return load-int 0 - int
		]
		if int = 0 [
			big: copy* big1 big1/used
			if free? [free* big1]
			return big
		]

		big: load-int int
		ret: sub big1 big free?
		free* big
		ret
	]

	sub-uint: func [
		big1		[bigint!]
		uint		[integer!]
		free?		[logic!]
		return:		[bigint!]
		/local
			big		[bigint!]
			ret		[bigint!]
	][
		if all [big1/used = 0 uint = 0][
			if free? [free* big1]
			return load-uint 0
		]
		if big1/used = 0 [
			big: load-uint uint
			big/sign: -1
			if free? [free* big1]
			return big
		]
		if uint = 0 [
			big: copy* big1 big1/used
			if free? [free* big1]
			return big
		]

		big: load-uint uint
		ret: sub big1 big free?
		free* big
		ret
	]

	absolute-compare: func [
		big1		[bigint!]
		big2		[bigint!]
		return:		[integer!]
		/local
			p1		[int-ptr!]
			p2		[int-ptr!]
	][
		if all [
			big1/used = 0
			big2/used = 0
		][
			return 0
		]

		if big1/used > big2/used [return 1]
		if big2/used > big1/used [return -1]

		p1: big1/data + big1/used - 1
		p2: big2/data + big2/used - 1
		loop big1/used [
			if uint-less p2/1 p1/1 [return 1]
			if uint-less p1/1 p2/1 [return -1]
			p1: p1 - 1
			p2: p2 - 1
		]
		return 0
	]

	compare: func [
		big1		[bigint!]
		big2		[bigint!]
		return:		[integer!]
	][
		if all [big1/used = 0 big2/used = 0][
			return 0
		]
		if big1/used = 0 [
			return either big2/sign = 1 [-1][1]
		]
		if big2/used = 0 [
			return either big1/sign = 1 [1][-1]
		]

		if all [
			big1/sign = 1
			big2/sign = -1
		][
			return 1
		]

		if all [
			big2/sign = 1
			big1/sign = -1
		][
			return -1
		]

		if big1/sign = 1 [
			return absolute-compare big1 big2
		]
		absolute-compare big2 big1
	]

	zero?*: func [
		big			[bigint!]
		return:		[logic!]
		/local
			p		[int-ptr!]
	][
		if big/used = 0 [return true]
		p: big/data
		if all [big/used = 1 p/value = 0][return true]
		false
	]

	negative*: func [
		big			[bigint!]
		free?		[logic!]
		return:		[bigint!]
		/local
			ret		[bigint!]
	][
		ret: copy* big big/used
		if zero?* big [
			if free? [free* big]
			return ret
		]
		ret/sign: either big/sign = 1 [-1][1]
		if free? [free* big]
		ret
	]

	negative?*: func [
		big			[bigint!]
		return:		[logic!]
	][
		if zero?* big [return false]
		if big/sign = -1 [return true]
		false
	]

	positive?*: func [
		big			[bigint!]
		return:		[logic!]
	][
		if zero?* big [return false]
		if big/sign = 1 [return true]
		false
	]

	absolute*: func [
		big			[bigint!]
		free?		[logic!]
		return:		[bigint!]
		/local
			ret		[bigint!]
	][
		ret: copy* big big/used
		if zero?* big [
			if free? [free* big]
			return ret
		]
		ret/sign: 1
		if free? [free* big]
		ret
	]

	;-- don't allocate memory, just change sign field
	set-negative: func [
		big			[bigint!]
	][
		if zero?* big [exit]
		big/sign: either big/sign = 1 [-1][1]
	]

	compare-int: func [
		big1		[bigint!]
		int			[integer!]
		return:		[integer!]
		/local
			big		[bigint!]
			ret		[integer!]
	][
		if all [big1/used = 0 int = 0][
			return 0
		]
		if big1/used = 0 [
			return either int > 0 [-1][1]
		]
		if int = 0 [
			return either big1/sign = 1 [1][-1]
		]

		big: load-int int
		ret: compare big1 big
		free* big
		ret
	]

	compare-uint: func [
		big1		[bigint!]
		uint		[integer!]
		return:		[integer!]
		/local
			big		[bigint!]
			ret		[integer!]
	][
		if all [big1/used = 0 uint = 0][
			return 0
		]
		if big1/used = 0 [
			return -1
		]
		if uint = 0 [
			return either big1/sign = 1 [1][-1]
		]

		big: load-uint uint
		ret: compare big1 big
		free* big
		ret
	]

	mul-hlp: func [
		i			[integer!]
		s			[int-ptr!]
		d			[int-ptr!]
		b			[integer!]
		/local
			c		[integer!]
			t		[integer!]
			s0		[integer!]
			s1		[integer!]
			b0		[integer!]
			b1		[integer!]
			r0		[integer!]
			r1		[integer!]
			rx		[integer!]
			ry		[integer!]
	][
		c: 0
		t: 0

		while [i >= 16][
			MULADDC_INIT
			MULADDC_CORE	MULADDC_CORE
			MULADDC_CORE	MULADDC_CORE
			MULADDC_CORE	MULADDC_CORE
			MULADDC_CORE	MULADDC_CORE

			MULADDC_CORE	MULADDC_CORE
			MULADDC_CORE	MULADDC_CORE
			MULADDC_CORE	MULADDC_CORE
			MULADDC_CORE	MULADDC_CORE
			MULADDC_STOP
			i: i - 16
		]

		while [i >= 8][
			MULADDC_INIT
			MULADDC_CORE	MULADDC_CORE
			MULADDC_CORE	MULADDC_CORE

			MULADDC_CORE	MULADDC_CORE
			MULADDC_CORE	MULADDC_CORE
			MULADDC_STOP
			i: i - 8
		]

		while [i > 0][
			MULADDC_INIT
			MULADDC_CORE
			MULADDC_STOP
			i: i - 1
		]

		t: t + 1

		until [
			d/1: d/1 + c
			c: as integer! (uint-less d/1  c)
			d: d + 1
			c = 0
		]
	]

	mul: func [
		big1		[bigint!]
		big2		[bigint!]
		free?		[logic!]
		return:		[bigint!]
		/local
			big		[bigint!]
			p		[int-ptr!]
			p1		[int-ptr!]
			p2		[int-ptr!]
			len1	[integer!]
			len2	[integer!]
			pt		[int-ptr!]
			len		[integer!]
	][
		if any [big1/used = 0 big2/used = 0][
			if free? [free* big1]
			return load-int 0
		]

		p1: big1/data
		p2: big2/data
		len1: big1/used
		len2: big2/used

		len: len1 + len2 + 1
		big: alloc* len
		big/used: len
		p: big/data

		len1: len1 + 1
		while [len2 > 0]
		[
			pt: p2 + len2 - 1
			mul-hlp (len1 - 1) p1 (p + len2 - 1) pt/1
			len2: len2 - 1
		]

		big/sign: big1/sign * big2/sign
		shrink big
		if free? [free* big1]
		big
	]

	mul-int: func [
		big1		[bigint!]
		int			[integer!]
		free?		[logic!]
		return:		[bigint!]
		/local
			big	 	[bigint!]
			ret		[bigint!]
	][
		if any [big1/used = 0 int = 0][
			if free? [free* big1]
			return load-int 0
		]

		big: load-int int
		ret: mul big1 big free?
		free* big
		ret
	]

	mul-uint: func [
		big1		[bigint!]
		uint		[integer!]
		free?		[logic!]
		return:		[bigint!]
		/local
			big	 	[bigint!]
			ret		[bigint!]
	][
		if any [big1/used = 0 uint = 0][
			if free? [free* big1]
			return load-int 0
		]

		big: load-uint uint
		ret: mul big1 big free?
		free* big
		ret
	]

	uint-div: func [
		u1				[integer!]
		u0				[integer!]
		q				[int-ptr!]
		r				[int-ptr!]
		return:			[logic!]
		/local
			i			[integer!]
	][
		if u0 = 0 [
			return false
		]

		if uint-less u1 u0 [
			q/value: 0
			r/value: u1
			return true
		]

		i: 0
		while [true] [
			u1: u1 - u0
			i: i + 1
			if uint-less u1 u0 [
				q/value: i
				r/value: u1
				return true
			]
		]
		q/value: i
		r/value: 0
		return true
	]

	long-divide: func [
		u1				[integer!]
		u0				[integer!]
		d				[integer!]
		ret				[int-ptr!]
		return:			[logic!]
		/local
			radix		[integer!]
			hmask		[integer!]
			d0			[integer!]
			d1			[integer!]
			q0			[integer!]
			q1			[integer!]
			rt			[integer!]
			rAX			[integer!]
			r0			[integer!]
			u0_msw		[integer!]
			u0_lsw		[integer!]
			s			[integer!]
			tmp			[integer!]
	][
		radix: 1 << biLH
		hmask: radix - 1

		if d = 0 [
			return false
		]

		if not uint-less u1 d [
			ret/value: -1
			return true
		]

		s: clz d
		d: d << s

		u1: u1 << s
		tmp: u0 >>> (biL - s)
		tmp: tmp and ((0 - s) >> (biL - 1))
		u1: u1 or tmp
		u0: u0 << s

		d1: d >>> biLH
		d0: d and hmask

		u0_msw: u0 >>> biLH
		u0_lsw: u0 and hmask

		q1: 0
		rt: 0
		if false = uint-div u1 d1 :q1 :rt [
			return false
		]
		r0: u1 - (d1 * q1)

		while [
			any [
				not uint-less q1 radix
				uint-less (radix * r0 + u0_msw) (q1 * d0)
			]
		][
			q1: q1 - 1
			r0: r0 + d1

			unless uint-less r0 radix [break]
		]

		rAX: (u1 * radix) + (u0_msw - (q1 * d))
		q0: 0
		rt: 0
		if false = uint-div rAX d1 :q0 :rt [
			return false
		]
		r0: rAX - (q0 * d1)

		while [
			any [
				not uint-less q0 radix
				uint-less (radix * r0 + u0_lsw) (q0 * d0)
			]
		][
			q0: q0 - 1
			r0: r0 + d1

			unless uint-less r0 radix [break]
		]

		ret/value: q1 * radix + q0
		return true
	]

	;-- A = Q * B + R
	div: func [
		A			[bigint!]
		B			[bigint!]
		iQ			[int-ptr!]
		iR			[int-ptr!]
		free?		[logic!]
		return:		[logic!]
		/local
			Q		[bigint!]
			R		[bigint!]
			X		[bigint!]
			Y		[bigint!]
			Z		[bigint!]
			T1		[bigint!]
			T2		[bigint!]
			i		[integer!]
			n		[integer!]
			t		[integer!]
			k		[integer!]
			px		[int-ptr!]
			py		[int-ptr!]
			pz		[int-ptr!]
			pt1		[int-ptr!]
			pt2		[int-ptr!]
			tmp		[integer!]
			tmp2	[integer!]
	][
		if 0 = compare-int B 0 [
			return false
		]

		if 0 > absolute-compare A B [
			if iQ <> null [
				Q: load-int 0
				iQ/value: as integer! Q
			]
			if iR <> null [
				R: copy* A A/used
				iR/value: as integer! R
			]
			if free? [free* A]
			return true
		]

		X: copy* A A/used
		X/sign: 1
		Y: copy* B B/used
		Y/sign: 1
		Z: alloc* A/used + 2
		Z/used: A/used + 2
		T1: alloc* 2
		T1/used: 2
		T2: alloc* 3
		T2/used: 3

		k: (bitlen? Y) % biL

		either k < (biL - 1) [
			k: biL - 1 - k
			X: left-shift X k true
			Y: left-shift Y k true
		][
			k: 0
		]

		n: X/used
		t: Y/used
		Y: left-shift Y biL * (n - t) true

		pz: Z/data

		while [0 <= compare X Y][
			tmp: n - t + 1
			pz/tmp: pz/tmp + 1
			X: sub X Y true
		]
		Y: right-shift Y biL * (n - t) true

		px: X/data
		py: Y/data
		pt1: T1/data
		pt2: T2/data

		i: n
		while [i > t][
			tmp: i - t
			either not uint-less px/i py/t [
				pz/tmp: -1
			][
				tmp2: i - 1
				if false = long-divide px/i px/tmp2 py/t pz + tmp - 1 [
					free* X
					free* Y
					free* Z
					free* T1
					free* T2
					return false
				]
			]

			pz/tmp: pz/tmp + 1
			until [
				pz/tmp: pz/tmp - 1
				lset T1 0
				pt1: T1/data
				pt1/1: either t < 2 [
					0
				][
					tmp2: t - 1
					py/tmp2
				]
				pt1/2: py/t
				T1/used: 2

				T1: mul-uint T1 pz/tmp true

				lset T2 0
				pt2: T2/data
				pt2/1: either i < 3 [
					0
				][
					tmp2: i - 2
					px/tmp2
				]
				pt2/2: either i < 2 [
					0
				][
					tmp2: i - 1
					px/tmp2
				]
				pt2/3: px/i
				T2/used: 3

				0 >= compare T1 T2
			]

			T1: mul-uint Y pz/tmp false
			T1: left-shift T1 biL * (tmp - 1) true
			X: sub X T1 true
			px: X/data
			if 0 > compare-int X 0 [
				free* T1
				T1: copy* Y Y/used
				T1: left-shift T1 biL * (tmp - 1) true
				X: add X T1 true
				px: X/data
				pz/tmp: pz/tmp - 1
			]
			i: i - 1
		]

		shrink Z

		either iQ <> null [
			Q: Z
			Q/sign: A/sign * B/sign
			iQ/value: as integer! Q
		][
			free* Z
		]

		X: right-shift X k true
		X/sign: A/sign
		shrink X

		either iR <> null [
			R: X
			iR/value: as integer! R
		][
			free* X
		]

		free* Y
		free* T1
		free* T2
		if free? [free* A]
		true
	]

	div-int: func [
		A			[bigint!]
		int			[integer!]
		iQ			[int-ptr!]
		iR			[int-ptr!]
		free?		[logic!]
		return:		[logic!]
		/local
			big		[bigint!]
			ret		[logic!]
	][
		big: load-int int
		ret: div A big iQ iR free?
		free* big
		ret
	]

	div-uint: func [
		A			[bigint!]
		uint		[integer!]
		iQ			[int-ptr!]
		iR			[int-ptr!]
		free?		[logic!]
		return:		[logic!]
		/local
			big		[bigint!]
			ret		[logic!]
	][
		big: load-uint uint
		ret: div A big iQ iR free?
		free* big
		ret
	]

	modulo: func [
		A			[bigint!]
		B			[bigint!]
		iR			[int-ptr!]
		free?		[logic!]
		return:		[logic!]
		/local
			iR2		[integer!]
			R		[bigint!]
			BT		[bigint!]
	][
		if zero?* B [
			return false
		]

		iR2: 0
		if false = div A B null :iR2 false [
			return false
		]
		R: as bigint! iR2

		if 0 > compare-int R 0 [
			BT: add B R false
			free* R
			R: BT
		]

		if 0 <= compare R B [
			BT: sub B R false
			free* R
			R: BT
		]

		iR/value: as integer! R
		if free? [free* A]
		true
	]

	modulo-int: func [
		A			[bigint!]
		b			[integer!]
		iR			[int-ptr!]
		free?		[logic!]
		return:		[logic!]
		/local
			p		[int-ptr!]
			x		[integer!]
			y		[integer!]
			z		[integer!]
			rt		[integer!]
	][
		if b = 0 [
			return false
		]

		if b = 1 [
			iR/value: 0
			if free? [free* A]
			return true
		]

		p: A/data
		if b = 2 [
			iR/value: p/1 and 1
			if free? [free* A]
			return true
		]

		y: 0
		p: p + A/used - 1
		loop A/used [
			x: p/1
			y: (y << biLH) or (x >>> biLH)
			z: 0
			rt: 0
			if false = uint-div y b :z :rt [
				iR/value: -1
				if free? [free* A]
				return true
			]
			y: y - (z * b)

			x: x << biLH
			y: (y << biLH) or (x >>> biLH)
			z: 0
			rt: 0
			if false = uint-div y b :z :rt [
				iR/value: -1
				if free? [free* A]
				return true
			]
			y: y - (z * b)

			p: p - 1
		]

		if all [
			A/sign < 0
			y <> 0
		][
			y: b - y
		]
		iR/value: y
		if free? [free* A]
		return true
	]

	;-- behave like rebol
	mod: func [
		A			[bigint!]
		B			[bigint!]
		iR			[int-ptr!]
		free?		[logic!]
		return:		[logic!]
		/local
			iR2		[integer!]
			R		[bigint!]
			T1		[bigint!]
	][
		if zero?* B [
			return false
		]

		iR2: 0
		if false = div A B null :iR2 false [
			return false
		]
		R: as bigint! iR2

		if 0 > compare-int R 0 [
			R: add R B true
		]

		T1: add R R false
		T1: sub T1 B true
		if all [
			0 = compare R B
			positive?* T1
		][
			R: sub R B true
		]

		free* T1
		iR/value: as integer! R
		if free? [free* A]
		true
	]

	load-bin: func [
		bin					[byte-ptr!]
		len					[integer!]
		return:				[bigint!]
		/local
			size			[integer!]
			big				[bigint!]
			p				[int-ptr!]
			p2				[byte-ptr!]
			i				[integer!]
			value			[integer!]
			shift			[integer!]
	][
		if len < 0 [return null]
		size: len / 4
		if len % 4 <> 0 [size: size + 1]
		big: alloc* size
		big/used: size
		p: big/data
		p2: bin + len - 1
		i: 0
		until [
			either len >= 4 [
				shift: 0
				value: 0
				loop 4 [
					value: value + ((as integer! p2/1) << shift)
					p2: p2 - 1
					shift: shift + 8
				]
				p/1: value
				p: p + 1
				len: len - 4
			][
				shift: 0
				value: 0
				until [
					value: value + ((as integer! p2/1) << shift)
					p2: p2 - 1
					shift: shift + 8
					len: len - 1
					len <= 0
				]
				p/1: value
			]
			len <= 0
		]
		big
	]

	equal-bin?: func [
		big					[bigint!]
		bin					[byte-ptr!]
		len					[integer!]
		return:				[logic!]
		/local
			len2			[integer!]
			p				[int-ptr!]
			pbin			[byte-ptr!]
			i				[integer!]
			value			[integer!]
			shift			[integer!]
	][
		if len < 0 [return false]
		len2: big/used * 4
		if any [len2 < len len2 > (len + 4)] [return false]
		p: big/data
		pbin: bin + len - 1
		i: 0
		until [
			either len >= 4 [
				shift: 0
				value: 0
				loop 4 [
					value: value + ((as integer! pbin/1) << shift)
					pbin: pbin - 1
					shift: shift + 8
				]
				if p/1 <> value [return false]
				p: p + 1
				len: len - 4
			][
				shift: 0
				value: 0
				until [
					value: value + ((as integer! pbin/1) << shift)
					pbin: pbin - 1
					shift: shift + 8
					len: len - 1
					len <= 0
				]
				if p/1 <> value [return false]
				len: 0
			]
			len <= 0
		]
		true
	]

	radix-table: "0123456789ABCDEF"

	chr-index: func [
		chr					[byte!]
		radix				[integer!]
		return:				[integer!]
		/local
			i				[integer!]
	][
		i: 1
		loop radix [
			if chr = radix-table/i [return i - 1]
			i: i + 1
		]
		-1
	]

	load-str: func [
		str					[c-string!]
		slen				[integer!]
		radix				[integer!]
		return:				[bigint!]
		/local
			sign			[integer!]
			size			[integer!]
			len				[integer!]
			nsize			[integer!]
			big				[bigint!]
			p				[int-ptr!]
			p2				[byte-ptr!]
			index			[integer!]
			value			[integer!]
			shift			[integer!]
	][
		if any [radix < 2 radix > 16] [return null]
		size: length? str
		if slen > 0 [
			size: either size < slen [size][slen]
		]
		if size < 0 [return null]
		either radix = 16 [
			p2: as byte-ptr! str
			p2: p2 + size - 1
			sign: 1
			if str/1 = #"-" [sign: -1 size: size - 1]
			if str/1 = #"+" [sign: 1 size: size - 1]
			len: size
			if len < 0 [return null]
			nsize: size * 4 / biL
			if size * 4 % biL <> 0 [
				nsize: nsize + 1
			]

			big: alloc* nsize
			p: big/data

			until [
				either len >= 8 [
					shift: 0
					value: 0
					loop 8 [
						index: chr-index p2/1 radix
						if index = -1 [break]
						value: value + (index << shift)
						p2: p2 - 1
						shift: shift + 4
					]
					if index = -1 [break]
					p/1: value
					p: p + 1
					len: len - 8
				][
					shift: 0
					value: 0
					until [
						index: chr-index p2/1 radix
						if index = -1 [break]
						value: value + (index << shift)
						p2: p2 - 1
						shift: shift + 4
						len: len - 1
						len <= 0
					]
					if index = -1 [break]
					p/1: value
				]
				len <= 0
			]
			big/sign: sign
			big/used: nsize
		][
			big: load-int 0
			p2: as byte-ptr! str
			sign: 1
			if str/1 = #"-" [sign: -1 p2: p2 + 1 size: size - 1]
			if str/1 = #"+" [sign: 1 p2: p2 + 1 size: size - 1]
			loop size [
				index: chr-index p2/1 radix
				if index = -1 [break]
				big: mul-int big radix true
				big: add-int big index true
				p2: p2 + 1
			]
			big/sign: sign
		]
		big
	]

	write-hlp: func [
		big			[bigint!]
		radix		[integer!]
		buf			[integer!]
		return:		[logic!]
		/local
			ret		[integer!]
			pi		[int-ptr!]
			Q		[bigint!]
			iQ		[integer!]
			pb		[byte-ptr!]
	][
		if any [radix < 2 radix > 16] [return false]

		ret: 0
		if false = modulo-int big radix :ret false [return false]
		iQ: 0
		if false = div-int big radix :iQ null false [return false]
		Q: as bigint! iQ
		if 0 <> compare-int Q 0 [
			if false = write-hlp Q radix buf [
				free* Q
				return false
			]
		]
		free* Q

		pi: as int-ptr! buf
		pb: as byte-ptr! pi/1
		either ret < 10 [
			pb/1: (as byte! ret) + 30h
		][
			pb/1: (as byte! ret) + 37h
		]
		pi/1: pi/1 + 1
		true
	]

	write-string: func [
		big			[bigint!]
		radix		[integer!]
		obuf		[int-ptr!]
		olen		[int-ptr!]
		return:		[logic!]
		/local
			T		[bigint!]
			n		[integer!]
			buf		[byte-ptr!]
			p		[integer!]
			p2		[byte-ptr!]
			px		[int-ptr!]
			i		[integer!]
			j		[integer!]
			k		[integer!]
			c		[integer!]
			id		[integer!]
	][
		if any [radix < 2 radix > 16] [return false]

		n: bitlen? big
		if radix >= 4 [n: n >>> 1]
		if radix >= 16 [n: n >>> 1]
		n: n + 3 + ((n + 1) and 1)

		buf: allocate n + 4
		px: as int-ptr! buf
		px/1: n

		p: as integer! (buf + 4)

		if big/sign = -1 [
			p2: as byte-ptr! p
			p2/1: #"-"
			p: p + 1
		]

		px: big/data

		either radix = 16 [
			i: big/used
			k: 0
			while [i > 0][
				j: ciL
				while [j > 0][
					c: (px/i >>> ((j - 1) << 3)) and FFh
					if all [
						c = 0
						k = 0
						(i + j) <> 2
					][
						j: j - 1
						continue
					]

					id: c and F0h >> 4 + 1
					p2: as byte-ptr! p
					p2/1: radix-table/id
					p: p + 1
					id: c and 0Fh + 1
					p2: as byte-ptr! p
					p2/1: radix-table/id
					p: p + 1

					k: 1
					j: j - 1
				]
				i: i - 1
			]
		][
			T: copy* big big/used
			if T/sign = -1 [
				T/sign: 1
			]

			if false = write-hlp T radix as integer! :p [
				free* T
				free buf
				return false
			]
			free* T
		]

		olen/value: p - as integer! (buf + 4)
		obuf/value: as integer! buf
		p2: as byte-ptr! p
		p2/1: as byte! 0
		p: p + 1
		true
	]

	#if debug? = yes [
		dump: func [
			big			[bigint!]
			/local
				p		[int-ptr!]
		][
			print-line [lf "===============dump bigint!==============="]
			either big = null [
				print-line "null"
			][
				print-line ["size: " big/size " used: " big/used " sign: " big/sign " resv: " big/resv " resv2: " big/resv2 " addr: " big/data]
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
			print-line [lf "=============dump bigint! end============="]
		]
	]

]
