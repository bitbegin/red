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
		big/used: 1
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
			ret				[bignum!]
	][
		if big = null [return null]
		size: either expand > big/size [expand][big/size]
		ret: bn-alloc size
		ret/size: size
		ret/used: size
		ret/sign: big/sign
		copy-memory as byte-ptr! ret/data as byte-ptr! big/data ret/size * 4
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



]
