Red/System [
	Title:   "bignum"
	Author:  "bitbegin"
	File: 	 %bignum.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

bignum: context [
	ciL:				4				;-- bignum! unit is 4 bytes; chars in limb
	biL:				ciL << 3		;-- bits in limb
	biLH:				ciL << 2		;-- half bits in limb
	BN_MAX_LIMB:		1024			;-- support 1024 * 32 bits
	BN_WINDOW_SIZE:		6				;-- Maximum window size used for modular exponentiation

	bignum!: alias struct! [
		size		[integer!]			;-- size in integer!
		used		[integer!]			;-- used length in integer!
		sign		[integer!]
		data		[int-ptr!]
	]

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
		if size < 0 [
			fire [
				TO_ERROR(script out-of-range)
				integer/push size
			]
		]
		BN_MAX_LIMB: size
	]

	bn-alloc: func [
		size			[integer!]			;-- size in integer!
		return:			[bignum!]
		/local
			len			[integer!]
			p			[byte-ptr!]
			big			[bignum!]
	][
		if size > BN_MAX_LIMB [
			fire [
				TO_ERROR(script out-of-range)
				integer/push size
			]
		]

		len: size * 4 + size? bignum!
		p: allocate len
		set-memory p null-byte len
		big: as bignum! p
		big/size: size
		big/used: 0
		big/sign: 1
		big/data: as int-ptr! (p + size? bignum!)
		big
	]

	bn-free: func [big [bignum!]][
		if big <> null [free as byte-ptr! big]
	]

	bn-copy: func [
		big					[bignum!]
		expand				[integer!]			;-- expand size in integer!
		return:				[bignum!]
		/local
			size			[integer!]
			cp-size			[integer!]
			ret				[bignum!]
	][
		if big = null [return null]
		size: either expand > big/size [expand][big/size]
		ret: bn-alloc size
		ret/size: size
		ret/used: expand
		ret/sign: big/sign
		cp-size: either expand > big/used [big/used][expand]
		copy-memory as byte-ptr! ret/data as byte-ptr! big/data cp-size * 4
		ret
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
		big			[bignum!]
		return:		[integer!]
		/local
			i-p		[int-ptr!]
			ret		[integer!]
	][
		if big/used = 0 [return 0]

		ret: biL - clz GET-INT-AT(big/data big/used)
		ret: ret + ((big/used - 1) * biL)
		ret
	]

	len?: func [
		big			[bignum!]
		return:		[integer!]
		/local
			ret		[integer!]
	][
		ret: bitlen? big
		ret: (ret + 7) >>> 3
		ret
	]

	grow: func [
		big			[bignum!]
		size		[integer!]
		return:		[bignum!]
		/local
			ret		[bignum!]
	][
		if size = 0 [return big]

		ex_size: size - big/size
		if (size - big/size) > 0 [ 
			ret: bn-copy big size
			bn-free big
			return ret
		]
		big
	]

	shrink: func [
		big			[bignum!]
		/local
			p		[int-ptr!]
			len		[integer!]
	][
		p: big/data + big/used
		loop big/used [
			either p/value = 0 [
				big/used: big/used - 1
			][
				break
			]
			p: p - 1
		]
		if big/used = 0 [
			big/used: 1
		]
	]

	;-- u1 < u2
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

	lset: func [
		big			[bignum!]
		int			[integer!]
		/local
			p		[int-ptr!]
	][
		set-memory as byte-ptr! big/data null-byte big/size * 4

		p: big/data
		either int >= 0 [
			p/value: int
			big/sign: 1
		][
			p/value: 0 - int
			big/sign: -1
		]
		big/used: 1
	]

	left-shift: func [
		big			[bignum!]
		count		[integer!]
		return:		[bignum!]
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
	][
		r0: 0
		v0: count / biL
		t1: count and (biL - 1)
		i: bitlen? big
		i: i + count
		p: big/data

		if (big/used * biL) < i [
			size: i / biL
			if i % biL <> 0 [
				size: size + 1
			]
			big: grow big size
		]

		if v0 > 0 [
			i: big/used
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
			while [i < big/used][
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
			shrink big
		]
		big
	]

	right-shift: func [
		big			[bignum!]
		count		[integer!]
		/local
			i		[integer!]
			v0		[integer!]
			v1		[integer!]
			r0		[integer!]
			r1		[integer!]
			p		[int-ptr!]
			p1		[int-ptr!]
			p2		[int-ptr!]
	][
		r0: 0
		v0: count / biL
		v1: count and (biL - 1)

		p: big/data

		if any [
			v0 > big/used
			all [
				v0 = big/used
				v1 > 0
			]
		][
			lset big 0
			exit
		]

		if v0 > 0 [
			i: 0
			while [i < (big/used - v0)][
				p1: p + i
				p2: p + i + v0
				p1/1: p2/1
				i: i + 1
			]

			while [i < big/used][
				p1: p + i
				p1/1: 0
				i: i + 1
			]
		]

		if v1 > 0 [
			i: big/used
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
			shrink big
		]
	]

	absolute-add: func [
		big1		[bignum!]
		big2		[bignum!]
		return:		[bignum!]
		/local
			big		[bignum!]
			p		[int-ptr!]
			p2		[int-ptr!]
			i		[integer!]
			c		[integer!]
			tmp		[integer!]
	][
		p2: big2/data

		big: bn-copy big1 either big1/size > big2/size [big1/size][big2/size]
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
		big1		[bignum!]
		big2		[bignum!]
		return:		[bignum!]
		/local
			big		[bignum!]
	][
		if big1/used < big2/used [
			fire [
				TO_ERROR(script out-of-range)
				integer/push big2/used
			]
		]

		big: bn-copy big1 big1/used
		big/sign: 1

		sub-hlp big2/used big2/data big/data

		shrink big
		big
	]

	absolute-compare: func [
		big1		[bignum!]
		big2		[bignum!]
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

		p1: big1/data + big1/used
		p2: big2/data + big2/used
		loop big1/used [
			if uint-less p2/1 p1/1 [return 1]
			if uint-less p1/1 p2/1 [return -1]
			p1: p1 - 1
			p2: p2 - 1
		]
		return 0
	]

	add: func [
		big1		[bignum!]
		big2		[bignum!]
		return:		[bignum!]
		/local
			big		[bignum!]
	][
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
		big
	]

	sub: func [
		big1		[red-bignum!]
		big2		[red-bignum!]
		return:		[red-bignum!]
		/local
			big		[bignum!]
	][
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
		big
	]

]
