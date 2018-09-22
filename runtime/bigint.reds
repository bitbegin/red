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
	expo		[integer!]
	prec		[integer!]
]

#define DECIMAL-BASE			100000000
#define DECIMAL-BASE-LEN		8

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

	#define DEC_MULADDC_INIT [
		s0: 0 s1: 0 b0: 0 b1: 0 r0: 0 r1: 0 rx: 0 ry: 0
		b0: b and FFFFh
		b1: b >>> 16
	]
	#define DEC_MULADDC_CORE [
		s0: s/1 and FFFFh
		s1: s/1 >>> 16			s: s + 1
		rx: s0 * b1 			r0: s0 * b0
		ry: s1 * b0 			r1: s1 * b1
		r1: r1 + (rx >>> 16)
		r1: r1 + (ry >>> 16)
		rx: rx << 16 			ry: ry << 16
		r0: r0 + rx 			r1: r1 + as integer! (uint-less r0 rx)
		r0: r0 + ry 			r1: r1 + as integer! (uint-less r0 ry)
		r0: r0 + c 				r1: r1 + as integer! (uint-less r0 c)
		r0: r0 + d/1			r1: r1 + as integer! (uint-less r0 d/1)
		c: long-divide r1 r0 DECIMAL-BASE d
		d: d + 1
	]
	#define DEC_MULADDC_STOP []

	set-max-size: func [size [integer!]][
		if size > 0 [BN_MAX_LIMB: size]
	]

	alloc-limit: func [
		len					[integer!]
		imax				[integer!]
		return:				[bigint!]
		/local
			size			[integer!]
			p				[byte-ptr!]
			big				[bigint!]
	][
		if len > imax [return null]
		if len <= 0 [return null]

		size: len * 4 + size? bigint!
		p: allocate size
		if p = null [return null]
		set-memory p null-byte size
		big: as bigint! p
		big/size: len
		big
	]

	alloc*: func [
		len					[integer!]			;-- size in integer!
		return:				[bigint!]
	][
		alloc-limit len BN_MAX_LIMB
	]

	free*: func [big [bigint!]][
		if big <> null [free as byte-ptr! big]
	]

	copy*: func [
		big					[bigint!]
		return:				[bigint!]
		/local
			bused			[integer!]
			ret				[bigint!]
			pb				[byte-ptr!]
			pr				[byte-ptr!]
	][
		bused: either big/used >= 0 [big/used][0 - big/used]
		if any [big = null bused = 0] [return null]

		ret: alloc* bused
		if ret = null [return null]
		ret/size: bused
		ret/used: big/used
		ret/expo: big/expo
		ret/prec: big/prec
		pr: as byte-ptr! (ret + 1)
		pb: as byte-ptr! (big + 1)
		copy-memory pr pb bused * 4
		ret
	]

	expand*: func [
		big					[bigint!]
		size				[integer!]			;-- expand size in integer!
		return:				[bigint!]
		/local
			bsize			[integer!]
			bsign			[integer!]
			bused			[integer!]
			nsize			[integer!]
			ret				[bigint!]
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
		ret/used: either bsign > 0 [size][0 - size]
		ret/expo: big/expo
		ret/prec: big/prec
		cp-size: either size > bused [bused][size]
		pr: as byte-ptr! (ret + 1)
		pb: as byte-ptr! (big + 1)
		copy-memory pr pb cp-size * 4
		ret
	]

	from-int: func [
		big					[bigint!]
		int					[integer!]
		/local
			pb				[int-ptr!]
			uint			[integer!]
	][
		pb: as int-ptr! (big + 1)
		either int >= 0 [
			uint: int
		][
			uint: 0 - int
		]
		pb/1: uint
		big/used: either int >= 0 [1][-1]
	]

	from-uint: func [
		big					[bigint!]
		uint				[integer!]
		/local
			pb				[int-ptr!]
	][
		pb: as int-ptr! (big + 1)
		pb/1: uint
		big/used: 1
	]

	load-int: func [
		int					[integer!]
		return:				[bigint!]
		/local
			big				[bigint!]
	][
		big: alloc* 1
		if big = null [return null]
		from-int big int
		big
	]

	load-uint: func [
		uint				[integer!]
		return:				[bigint!]
		/local
			big				[bigint!]
	][
		big: alloc* 1
		if big = null [return null]
		from-uint big uint
		big
	]

	load-ulong: func [
		uL					[integer!]
		uH					[integer!]
		return:				[bigint!]
		/local
			big				[bigint!]
			pb				[int-ptr!]
	][
		if uH = 0 [return load-uint uL]

		big: alloc* 2
		if big = null [return null]
		pb: as int-ptr! (big + 1)
		pb/1: uL
		pb/2: uH
		big/used: 2
		big
	]

	zero?*: func [
		big					[bigint!]
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
		big1				[bigint!]
		big2				[bigint!]
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
			if uint-less p2/1 p1/1 [return 1]
			if uint-less p1/1 p2/1 [return -1]
			p1: p1 - 1
			p2: p2 - 1
		]
		return 0
	]

	compare: func [
		big1				[bigint!]
		big2				[bigint!]
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
		big					[bigint!]
		free?				[logic!]
		return:				[bigint!]
		/local
			ret				[bigint!]
	][
		ret: copy* big
		ret/used: 0 - ret/used
		if free? [free* big]
		ret
	]

	negative?*: func [
		big					[bigint!]
		return:				[logic!]
	][
		if zero?* big [return false]
		if big/used < 0 [return true]
		false
	]

	positive*: func [
		big					[bigint!]
		free?				[logic!]
		return:				[bigint!]
		/local
			ret				[bigint!]
	][
		ret: copy* big
		if ret/used < 0 [ret/used: 0 - ret/used]
		if free? [free* big]
		ret
	]

	positive?*: func [
		big					[bigint!]
		return:				[logic!]
	][
		if zero?* big [return false]
		if big/used > 0 [return true]
		false
	]

	absolute*: func [
		big					[bigint!]
		free?				[logic!]
		return:				[bigint!]
		/local
			ret				[bigint!]
	][
		ret: copy* big
		if ret/used < 0 [ret/used: 0 - ret/used]
		if free? [free* big]
		ret
	]

	compare-int: func [
		big1				[bigint!]
		int					[integer!]
		return:				[integer!]
		/local
			big				[bigint!]
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
		big1				[bigint!]
		uint				[integer!]
		return:				[integer!]
		/local
			big				[bigint!]
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

	;-- Count leading zero bits in a given integer
	count-leading-zero: func [
		int					[integer!]
		return:				[integer!]
		/local
			mask			[integer!]
			ret				[integer!]
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

	bit-len?: func [
		big					[bigint!]
		return:				[integer!]
		/local
			bused			[integer!]
			pb				[int-ptr!]
			ret				[integer!]
	][
		bused: either big/used >= 0 [big/used][0 - big/used]
		if bused = 0 [return 0]

		pb: as int-ptr! (big + 1)
		ret: biL - count-leading-zero pb/bused
		ret: ret + ((bused - 1) * biL)
		ret
	]

	form-decimal: func [
		value				[integer!]
		pad8?				[logic!]
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

		if pad8? [copy-memory as byte-ptr! s as byte-ptr! "00000000" 9]

		i: 1
		rem: value
		until [
			t: (rem % 10) + 1
			s/i: m/t
			rem: rem / 10

			i: i + 1
			any [
				rem = 0
				all [pad8? i > 8]
			]
		]
		either pad8? [
			rsize: 8
		][
			rsize: i - 1
			s/i: null-byte
		]

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

	base10-len?: func [
		uint				[integer!]
		return:				[integer!]
	][
		if bigint/uint-less uint 10 [return 1]
		if bigint/uint-less uint 100 [return 2]
		if bigint/uint-less uint 1000 [return 3]
		if bigint/uint-less uint 10000 [return 4]
		if bigint/uint-less uint 100000 [return 5]
		if bigint/uint-less uint 1000000 [return 6]
		if bigint/uint-less uint 10000000 [return 7]
		if bigint/uint-less uint 100000000 [return 8]
		if bigint/uint-less uint 1000000000 [return 9]
		10
	]

	digit-len?: func [
		big					[bigint!]
		return:				[integer!]
		/local
			bused			[integer!]
			p				[int-ptr!]
			ret				[integer!]
	][
		bused: either big/used >= 0 [big/used][0 - big/used]
		if bused = 0 [return 0]

		p: as int-ptr! (big + 1)
		ret: (bused - 1) * DECIMAL-BASE-LEN + base10-len? p/bused
		ret
	]

	shrink: func [
		big					[bigint!]
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

	;-- u1 < u2
	;#either config/cpu/little-endian? [
		uint-less: func [
			u1				[integer!]
			u2				[integer!]
			return:			[logic!]
			/local
				p1			[byte-ptr!]
				p2			[byte-ptr!]
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
	;		u1				[integer!]
	;		u2				[integer!]
	;		return:			[logic!]
	;		/local
	;			p1			[byte-ptr!]
	;			p2			[byte-ptr!]
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

	uint-mul: func [
		u1					[integer!]
		u2					[integer!]
		hr					[int-ptr!]
		lr					[int-ptr!]
		/local
			h1				[integer!]
			l1				[integer!]
			h2				[integer!]
			l2				[integer!]
			hx				[integer!]
			lx				[integer!]
			c				[integer!]
			l1l2			[integer!]
			h1l2			[integer!]
			h2l1			[integer!]
			h1h2			[integer!]
			temp			[integer!]
	][
		h1: u1 >>> 16
		l1: u1 and FFFFh
		h2: u2 >>> 16
		l2: u2 and FFFFh
		l1l2: l1 * l2
		h1l2: h1 * l2
		h2l1: h2 * l1
		h1h2: h1 * h2
		temp: h1l2 << 16
		lx: l1l2 + temp
		c: as integer! uint-less lx temp
		temp: h2l1 << 16
		lx: lx + temp
		c: c + as integer! uint-less lx temp
		hx: h1h2 + (h1l2 >>> 16) + (h2l1 >>> 16) + c
		hr/value: hx
		lr/value: lx
	]

	dec-exp: func [
		expo				[integer!]
		return:				[integer!]
	][
		switch expo [
			0				[1]
			1				[10]
			2				[100]
			3				[1000]
			4				[10000]
			5				[100000]
			6				[1000000]
			7				[10000000]
			8				[100000000]
			default			[0]
		]
	]

	dec-left-shift: func [
		big					[bigint!]
		count				[integer!]
		free?				[logic!]
		return:				[bigint!]
		/local
			bused			[integer!]
			i				[integer!]
			v0				[integer!]
			t1				[integer!]
			r0				[integer!]
			r1				[integer!]
			size			[integer!]
			pr				[int-ptr!]
			pb				[int-ptr!]
			p1				[int-ptr!]
			p2				[int-ptr!]
			temp			[integer!]
			mh				[integer!]
			ml				[integer!]
			q				[integer!]
			r				[integer!]
			ret				[bigint!]
	][
		bused: either big/used >= 0 [big/used][0 - big/used]
		if bused = 0 [
			if free? [free* big]
			return load-int 0
		]

		r0: 0
		v0: count / DECIMAL-BASE-LEN
		t1: count and (DECIMAL-BASE-LEN - 1)
		i: digit-len? big
		i: i + count

		either (bused * DECIMAL-BASE-LEN) < i [
			size: i / DECIMAL-BASE-LEN
			if i % DECIMAL-BASE-LEN <> 0 [
				size: size + 1
			]
		][
			size: bused
		]

		ret: alloc* size
		ret/used: either big/used >= 0 [size][0 - size]
		ret/expo: big/expo
		ret/prec: big/prec
		pr: as int-ptr! (ret + 1)
		pb: as int-ptr! (big + 1)

		either t1 > 0 [
			i: v0
			while [i < size][
				p1: pr + i
				p2: pb + i - v0
				temp: either (i - v0) >= bused [0][p2/1]
				mh: 0 ml: 0
				uint-mul temp dec-exp t1 :mh :ml
				either mh = 0 [
					q: 0 r: 0
					uint-div ml DECIMAL-BASE :q :r
				][
					r: 0
					q: long-divide mh ml DECIMAL-BASE :r
				]
				p1/1: r + r0
				if p1/1 >= DECIMAL-BASE [
					q: q + 1
					p1/1: p1/1 - DECIMAL-BASE
				]
				r0: q
				i: i + 1
			]
		][
			copy-memory as byte-ptr! (pr + v0) as byte-ptr! pb bused * 4
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

	bin-left-shift: func [
		big					[bigint!]
		count				[integer!]
		free?				[logic!]
		return:				[bigint!]
		/local
			bused			[integer!]
			i				[integer!]
			v0				[integer!]
			t1				[integer!]
			r0				[integer!]
			r1				[integer!]
			size			[integer!]
			pr				[int-ptr!]
			pb				[int-ptr!]
			p1				[int-ptr!]
			p2				[int-ptr!]
			temp			[integer!]
			ret				[bigint!]
	][
		bused: either big/used >= 0 [big/used][0 - big/used]
		if bused = 0 [
			if free? [free* big]
			return load-int 0
		]

		r0: 0
		v0: count / biL
		t1: count and (biL - 1)
		i: bit-len? big
		i: i + count

		either (bused * biL) < i [
			size: i / biL
			if i % biL <> 0 [
				size: size + 1
			]
		][
			size: bused
		]

		ret: alloc* size
		ret/used: either big/used >= 0 [size][0 - size]
		ret/expo: big/expo
		ret/prec: big/prec
		pr: as int-ptr! (ret + 1)
		pb: as int-ptr! (big + 1)

		either t1 > 0 [
			i: v0
			while [i < size][
				p1: pr + i
				p2: pb + i - v0
				temp: either (i - v0) >= bused [0][p2/1]
				r1: temp >>> (biL - t1)
				p1/1: temp << t1
				p1/1: p1/1 or r0
				r0: r1
				i: i + 1
			]
		][
			copy-memory as byte-ptr! (pr + v0) as byte-ptr! pb bused * 4
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

	left-shift: func [
		big					[bigint!]
		count				[integer!]
		free?				[logic!]
		return:				[bigint!]
	][
		either big = null [
			return null
		][
			either big/prec = 0 [
				return bin-left-shift big count free?
			][
				return dec-left-shift big count free?
			]
		]
	]

	right-shift: func [
		big					[bigint!]
		count				[integer!]
		free?				[logic!]
		return:				[bigint!]
		/local
			bused			[integer!]
			i				[integer!]
			v0				[integer!]
			v1				[integer!]
			r0				[integer!]
			r1				[integer!]
			pr				[int-ptr!]
			pb				[int-ptr!]
			p1				[int-ptr!]
			p2				[int-ptr!]
			ret				[bigint!]
	][
		bused: either big/used >= 0 [big/used][0 - big/used]
		if big/used = 0 [
			if free? [free* big]
			return load-int 0
		]

		r0: 0
		v0: count / biL
		v1: count and (biL - 1)

		if any [
			v0 > bused
			all [
				v0 = bused
				v1 > 0
			]
		][
			if free? [free* big]
			return load-int 0
		]

		ret: alloc* bused
		ret/used: big/used
		ret/expo: big/expo
		ret/prec: big/prec
		pr: as int-ptr! (ret + 1)
		pb: as int-ptr! (big + 1)

		either v1 > 0 [
			i: bused - v0
			while [i > 0][
				p1: pr + i - 1
				p2: pb + i - 1 + v0
				r1: p2/1 << (biL - v1)
				p1/1: p2/1 >>> v1
				p1/1: p1/1 or r0
				r0: r1
				i: i - 1
			]
		][
			copy-memory as byte-ptr! pr as byte-ptr! (pb + v0) (bused - v0) * 4
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

	dec-absolute-add: func [
		big1				[bigint!]
		big2				[bigint!]
		return:				[bigint!]
		/local
			b1used			[integer!]
			b2used			[integer!]
			big				[bigint!]
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
		big/expo: big1/expo
		big/prec: big1/prec
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

	bin-absolute-add: func [
		big1				[bigint!]
		big2				[bigint!]
		return:				[bigint!]
		/local
			b1used			[integer!]
			b2used			[integer!]
			big				[bigint!]
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
		big/expo: big1/expo
		big/prec: big1/prec
		p: as int-ptr! (big + 1)

		c: 0
		i: 0
		loop b2used [
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

	absolute-add: func [
		big1				[bigint!]
		big2				[bigint!]
		return:				[bigint!]
	][
		if any [big1/prec = 0 big2/prec = 0][
			return bin-absolute-add big1 big2
		]
		dec-absolute-add big1 big2
	]

	dec-sub-hlp: func [
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
		big1				[bigint!]
		big2				[bigint!]
		return:				[bigint!]
		/local
			b1used			[integer!]
			b2used			[integer!]
			big				[bigint!]
	][
		b1used: either big1/used >= 0 [big1/used][0 - big1/used]
		b2used: either big2/used >= 0 [big2/used][0 - big2/used]

		if b1used < b2used [return null]

		big: copy* big1
		big/used: b1used
		big/expo: big1/expo
		big/prec: big1/prec

		either any [big1/prec = 0 big2/prec = 0][
			sub-hlp b2used as int-ptr! (big2 + 1) as int-ptr! (big + 1)
		][
			dec-sub-hlp b2used as int-ptr! (big2 + 1) as int-ptr! (big + 1)
		]

		shrink big
		big
	]

	add: func [
		big1				[bigint!]
		big2				[bigint!]
		free?				[logic!]
		return:				[bigint!]
		/local
			b1sign			[integer!]
			b2sign			[integer!]
			big				[bigint!]
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
		big1				[bigint!]
		big2				[bigint!]
		free?				[logic!]
		return:				[bigint!]
		/local
			b1sign			[integer!]
			b2sign			[integer!]
			big				[bigint!]
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
		big1				[bigint!]
		int					[integer!]
		free?				[logic!]
		return:				[bigint!]
		/local
			big				[bigint!]
			ret				[bigint!]
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
		big1				[bigint!]
		uint				[integer!]
		free?				[logic!]
		return:				[bigint!]
		/local
			big				[bigint!]
			ret				[bigint!]
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
		big1				[bigint!]
		int					[integer!]
		free?				[logic!]
		return:				[bigint!]
		/local
			big				[bigint!]
			ret				[bigint!]
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
		big1				[bigint!]
		uint				[integer!]
		free?				[logic!]
		return:				[bigint!]
		/local
			big				[bigint!]
			ret				[bigint!]
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

	dec-mul-hlp: func [
		i					[integer!]
		s					[int-ptr!]
		d					[int-ptr!]
		b					[integer!]
		/local
			c				[integer!]
			t				[integer!]
			s0				[integer!]
			s1				[integer!]
			b0				[integer!]
			b1				[integer!]
			r0				[integer!]
			r1				[integer!]
			rx				[integer!]
			ry				[integer!]
	][
		c: 0
		t: 0

		while [i >= 16][
			DEC_MULADDC_INIT
			DEC_MULADDC_CORE	DEC_MULADDC_CORE
			DEC_MULADDC_CORE	DEC_MULADDC_CORE
			DEC_MULADDC_CORE	DEC_MULADDC_CORE
			DEC_MULADDC_CORE	DEC_MULADDC_CORE

			DEC_MULADDC_CORE	DEC_MULADDC_CORE
			DEC_MULADDC_CORE	DEC_MULADDC_CORE
			DEC_MULADDC_CORE	DEC_MULADDC_CORE
			DEC_MULADDC_CORE	DEC_MULADDC_CORE
			MULADDC_STOP
			i: i - 16
		]

		while [i >= 8][
			DEC_MULADDC_INIT
			DEC_MULADDC_CORE	DEC_MULADDC_CORE
			DEC_MULADDC_CORE	DEC_MULADDC_CORE

			DEC_MULADDC_CORE	DEC_MULADDC_CORE
			DEC_MULADDC_CORE	DEC_MULADDC_CORE
			DEC_MULADDC_STOP
			i: i - 8
		]

		while [i > 0][
			DEC_MULADDC_INIT
			DEC_MULADDC_CORE
			DEC_MULADDC_STOP
			i: i - 1
		]

		t: t + 1

		until [
			d/1: d/1 + c
			c: 0
			unless bigint/uint-less d/1 DECIMAL-BASE [
				c: 1
				d/1: d/1 - DECIMAL-BASE
			]
			d: d + 1
			c = 0
		]
	]

	mul-hlp: func [
		i					[integer!]
		s					[int-ptr!]
		d					[int-ptr!]
		b					[integer!]
		/local
			c				[integer!]
			t				[integer!]
			s0				[integer!]
			s1				[integer!]
			b0				[integer!]
			b1				[integer!]
			r0				[integer!]
			r1				[integer!]
			rx				[integer!]
			ry				[integer!]
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

	absolute-mul: func [
		big1				[bigint!]
		big2				[bigint!]
		return:				[bigint!]
		/local
			b1used			[integer!]
			b2used			[integer!]
			p1				[int-ptr!]
			p2				[int-ptr!]
			big				[bigint!]
			p				[int-ptr!]
			pt				[int-ptr!]
			len				[integer!]
	][
		if any [zero?* big1 zero?* big2][
			return load-int 0
		]

		b1used: either big1/used >= 0 [big1/used][0 - big1/used]
		b2used: either big2/used >= 0 [big2/used][0 - big2/used]
		p1: as int-ptr! (big1 + 1)
		p2: as int-ptr! (big2 + 1)

		len: b1used + b2used + 1
		big: alloc* len
		big/used: len
		big/expo: big1/expo
		big/prec: big1/prec
		p: as int-ptr! (big + 1)

		b1used: b1used + 1
		while [b2used > 0]
		[
			pt: p2 + b2used - 1
			either any [big1/prec = 0 big2/prec = 0][
				mul-hlp (b1used - 1) p1 (p + b2used - 1) pt/1
			][
				dec-mul-hlp (b1used - 1) p1 (p + b2used - 1) pt/1
			]
			b2used: b2used - 1
		]

		shrink big
		big
	]

	mul: func [
		big1				[bigint!]
		big2				[bigint!]
		free?				[logic!]
		return:				[bigint!]
		/local
			b1sign			[integer!]
			b2sign			[integer!]
			big				[bigint!]
	][
		if any [zero?* big1 zero?* big2][
			if free? [free* big1]
			return load-int 0
		]

		b1sign: either big1/used >= 0 [1][-1]
		b2sign: either big2/used >= 0 [1][-1]

		either (absolute-compare big1 big2) >= 0 [
			big: absolute-mul big1 big2
		][
			big: absolute-mul big2 big1
		]
		if b1sign <> b2sign [big/used: 0 - big/used]

		if free? [free* big1]
		big
	]

	mul-int: func [
		big1				[bigint!]
		int					[integer!]
		free?				[logic!]
		return:				[bigint!]
		/local
			big				[bigint!]
			ret				[bigint!]
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
		big1				[bigint!]
		uint				[integer!]
		free?				[logic!]
		return:				[bigint!]
		/local
			big				[bigint!]
			ret				[bigint!]
	][
		if any [zero?* big1 uint = 0][
			if free? [free* big1]
			return load-int 0
		]

		big: load-uint uint
		ret: mul big1 big free?
		free* big
		ret
	]

	uint-div: func [
		a					[integer!]
		b					[integer!]
		q					[int-ptr!]
		r					[int-ptr!]
		return:				[logic!]
		/local
			ah				[integer!]
			al				[integer!]
			bh				[integer!]
			bl				[integer!]
			qh				[integer!]
			ql				[integer!]
			rh				[integer!]
			rl				[integer!]
			a2				[integer!]
			i				[integer!]
	][
		if b = 0 [
			return false
		]

		;-- [a > 0 b < 0] or [b > a > 0] or [a < b < 0]
		if uint-less a b [
			q/value: 0
			r/value: a
			return true
		]

		;-- [a > 0 b > 0]
		if all [a > 0 b > 0][
			q/value: a / b
			r/value: a % b
			return true
		]

		;-- [a < 0 b > 0]
		if all [a < 0 b > 0][
			ah: a >>> 16
			al: a and FFFFh
			bh: b >>> 16
			bl: b and FFFFh
			either bh = 0 [
				if ah >= bl [
					qh: ah / bl
					rh: ah % bl
					a2: (rh << 16) or al
					ql: a2 / bl
					q/value: (qh << 16) or ql
					r/value: a2 % bl
					return true
				]
				ql: 8000h
				a2: a - (b * ql)
			][
				ql: ah / bh / 2
				a2: a - (b * ql)
			]
			while [a2 < 0][
				a2: a2 - b
				ql: ql + 1
			]
			ql: ql + (a2 / b)
			q/value: ql
			r/value: a2 % b
			return true
		]

		;-- [b < a < 0]
		i: 0
		until [
			a: a - b
			i: i + 1
			uint-less a b
		]
		q/value: i
		r/value: a
		return true
	]

	;-- only support u1 < d
	long-divide: func [
		u1					[integer!]
		u0					[integer!]
		d					[integer!]
		r					[int-ptr!]
		return:				[integer!]
		/local
			radix			[integer!]
			hmask			[integer!]
			d0				[integer!]
			d1				[integer!]
			q0				[integer!]
			q1				[integer!]
			rAX				[integer!]
			r0				[integer!]
			u0_msw			[integer!]
			u0_lsw			[integer!]
			s				[integer!]
			tmp				[integer!]
	][
		radix: 1 << biLH
		hmask: radix - 1

		if any [d = 0 not uint-less u1 d] [
			if r <> null [r/value: -1]
			return -1
		]

		s: count-leading-zero d
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
		r0: 0
		uint-div u1 d1 :q1 :r0

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
		r0: 0
		uint-div rAX d1 :q0 :r0

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

		if r <> null [
			r/value: (rAX * radix + u0_lsw - (q0 * d)) >>> s
		]

		return q1 * radix + q0
	]

	;-- A = Q * B + R
	absolute-div: func [
		A					[bigint!]
		B					[bigint!]
		iQ					[int-ptr!]
		iR					[int-ptr!]
		return:				[logic!]
		/local
			Q				[bigint!]
			R				[bigint!]
			Aused			[integer!]
			Bused			[integer!]
			X				[bigint!]
			Y				[bigint!]
			Z				[bigint!]
			T1				[bigint!]
			T2				[bigint!]
			i				[integer!]
			n				[integer!]
			t				[integer!]
			k				[integer!]
			px				[int-ptr!]
			py				[int-ptr!]
			pz				[int-ptr!]
			pt1				[int-ptr!]
			pt2				[int-ptr!]
			tmp				[integer!]
			tmp2			[integer!]
	][
		if zero?* B [return false]

		if 0 > absolute-compare A B [
			if iQ <> null [
				Q: load-int 0
				Q/expo: A/expo
				Q/prec: A/prec
				iQ/value: as integer! Q
			]
			if iR <> null [
				R: copy* A
				iR/value: as integer! R
			]
			return true
		]

		Aused: either A/used >= 0 [A/used][0 - A/used]
		Bused: either B/used >= 0 [B/used][0 - B/used]

		X: absolute* A false
		Y: absolute* B false
		Z: alloc* Aused + 2
		Z/used: Aused + 2
		T1: alloc* 2
		T1/used: 2
		T2: alloc* 3
		T2/used: 3

		k: (bit-len? Y) % biL

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

		pz: as int-ptr! (Z + 1)

		while [0 <= compare X Y][
			tmp: n - t + 1
			pz/tmp: pz/tmp + 1
			X: sub X Y true
		]
		Y: right-shift Y biL * (n - t) true

		px: as int-ptr! (X + 1)
		py: as int-ptr! (Y + 1)
		pt1: as int-ptr! (T1 + 1)
		pt2: as int-ptr! (T2 + 1)

		i: n
		while [i > t][
			tmp: i - t
			either not uint-less px/i py/t [
				pz/tmp: -1
			][
				tmp2: i - 1
				pz/tmp: long-divide px/i px/tmp2 py/t null
			]

			pz/tmp: pz/tmp + 1
			until [
				pz/tmp: pz/tmp - 1
				pt1: as int-ptr! (T1 + 1)
				pt1/1: either t < 2 [
					0
				][
					tmp2: t - 1
					py/tmp2
				]
				pt1/2: py/t
				T1/used: 2
				T1: mul-uint T1 pz/tmp true
				pt2: as int-ptr! (T2 + 1)
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

			free* T1
			T1: mul-uint Y pz/tmp false
			T1: left-shift T1 biL * (tmp - 1) true
			X: sub X T1 true
			px: as int-ptr! (X + 1)
			if 0 > compare-int X 0 [
				free* T1
				T1: copy* Y
				T1: left-shift T1 biL * (tmp - 1) true
				X: add X T1 true
				px: as int-ptr! (X + 1)
				pz/tmp: pz/tmp - 1
			]
			i: i - 1
		]

		either iQ <> null [
			shrink Z
			Q: Z
			Q/expo: A/expo
			Q/prec: A/prec
			iQ/value: as integer! Q
		][
			free* Z
		]

		either iR <> null [
			R: right-shift X k true
			R/expo: A/expo
			R/prec: A/prec
			shrink R
			iR/value: as integer! R
		][
			free* X
		]

		free* Y
		free* T1
		free* T2
		true
	]

	;-- A = Q * B + R
	div: func [
		A					[bigint!]
		B					[bigint!]
		iQ					[int-ptr!]
		iR					[int-ptr!]
		free?				[logic!]
		return:				[logic!]
		/local
			Q				[bigint!]
			R				[bigint!]
			Asign			[integer!]
			Bsign			[integer!]
	][
		if zero?* B [return false]
		Asign: either A/used >= 0 [1][-1]
		Bsign: either B/used >= 0 [1][-1]

		if false = absolute-div A B iQ iR [
			return false
		]
		if iQ <> null [
			Q: as bigint! iQ/value
			if all [not zero?* Q Asign <> Bsign][Q/used: 0 - Q/used]
		]
		if iR <> null [
			R: as bigint! iR/value
			if all [not zero?* R Asign = -1] [R/used: 0 - R/used]
		]
		if free? [free* A]
		true
	]

	div-int: func [
		A					[bigint!]
		int					[integer!]
		iQ					[int-ptr!]
		iR					[int-ptr!]
		free?				[logic!]
		return:				[logic!]
		/local
			big				[bigint!]
			ret				[logic!]
	][
		big: load-int int
		ret: div A big iQ iR free?
		free* big
		ret
	]

	div-uint: func [
		A					[bigint!]
		uint				[integer!]
		iQ					[int-ptr!]
		iR					[int-ptr!]
		free?				[logic!]
		return:				[logic!]
		/local
			big				[bigint!]
			ret				[logic!]
	][
		big: load-uint uint
		ret: div A big iQ iR free?
		free* big
		ret
	]

	modulo: func [
		A					[bigint!]
		B					[bigint!]
		iR					[int-ptr!]
		free?				[logic!]
		return:				[logic!]
		/local
			iR2				[integer!]
			R				[bigint!]
			BT				[bigint!]
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
		A					[bigint!]
		b					[integer!]
		iR					[int-ptr!]
		free?				[logic!]
		return:				[logic!]
		/local
			p				[int-ptr!]
			Aused			[integer!]
			Asign			[integer!]
			x				[integer!]
			y				[integer!]
			z				[integer!]
			rt				[integer!]
	][
		if b = 0 [
			return false
		]

		if b = 1 [
			iR/value: 0
			if free? [free* A]
			return true
		]

		p: as int-ptr! (A + 1)
		if b = 2 [
			iR/value: p/1 and 1
			if free? [free* A]
			return true
		]

		either A/used >= 0 [
			Asign: 1
			Aused: A/used
		][
			Asign: -1
			Aused: 0 - A/used
		]

		y: 0
		p: p + Aused - 1
		loop Aused [
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
			Asign < 0
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
		A					[bigint!]
		B					[bigint!]
		iR					[int-ptr!]
		free?				[logic!]
		return:				[logic!]
		/local
			iR2				[integer!]
			R				[bigint!]
			T1				[bigint!]
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
		p: as int-ptr! (big + 1)
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
			bused			[integer!]
			len2			[integer!]
			p				[int-ptr!]
			pbin			[byte-ptr!]
			i				[integer!]
			value			[integer!]
			shift			[integer!]
	][
		if len < 0 [return false]
		bused: either big/used >= 0 [big/used][0 - big/used]
		len2: bused * 4
		if any [len2 < len len2 > (len + 4)] [return false]
		p: as int-ptr! (big + 1)
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
			case [
				str/1 = #"-" [sign: -1 size: size - 1]
				str/1 = #"+" [sign: 1 size: size - 1]
				true [sign: 1]
			]
			len: size
			if len < 0 [return null]
			nsize: size * 4 / biL
			if size * 4 % biL <> 0 [
				nsize: nsize + 1
			]

			big: alloc* nsize
			p: as int-ptr! (big + 1)

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
			either sign = 1 [big/used: nsize][big/used: 0 - nsize]
		][
			big: load-int 0
			p2: as byte-ptr! str
			case [
				str/1 = #"-" [sign: -1 p2: p2 + 1 size: size - 1]
				str/1 = #"+" [sign: 1 p2: p2 + 1 size: size - 1]
				true [sign: 1]
			]
			loop size [
				index: chr-index p2/1 radix
				if index = -1 [break]
				big: mul-int big radix true
				big: add-int big index true
				p2: p2 + 1
			]
			if sign = -1 [big/used: 0 - big/used]
		]
		big
	]

	form-hlp: func [
		big					[bigint!]
		radix				[integer!]
		buf					[integer!]
		return:				[logic!]
		/local
			ret				[integer!]
			pi				[int-ptr!]
			Q				[bigint!]
			iQ				[integer!]
			pb				[byte-ptr!]
	][
		if any [radix < 2 radix > 16] [return false]

		ret: 0
		if false = modulo-int big radix :ret false [return false]
		iQ: 0
		if false = div-int big radix :iQ null false [return false]
		Q: as bigint! iQ
		if 0 <> compare-int Q 0 [
			if false = form-hlp Q radix buf [
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

	form: func [
		big					[bigint!]
		radix				[integer!]
		obuf				[int-ptr!]
		olen				[int-ptr!]
		return:				[logic!]
		/local
			T				[bigint!]
			n				[integer!]
			buf				[byte-ptr!]
			p				[integer!]
			bused			[integer!]
			bsign			[integer!]
			p2				[byte-ptr!]
			px				[int-ptr!]
			i				[integer!]
			j				[integer!]
			k				[integer!]
			c				[integer!]
			id				[integer!]
	][
		if zero?* big [
			buf: allocate 4
			buf/1: #"0"
			buf/2: null-byte
			olen/value: 1
			obuf/value: as integer! buf
			return true
		]

		if any [radix < 2 radix > 16] [return false]

		n: bit-len? big
		if radix >= 4 [n: n >>> 1]
		if radix >= 16 [n: n >>> 1]
		n: n + 3 + ((n + 1) and 1)

		buf: allocate n + 1
		p: as integer! buf

		either big/used >= 0 [
			bsign: 1
			bused: big/used
		][
			bsign: -1
			bused: 0 - big/used
		]

		if bsign = -1 [
			p2: as byte-ptr! p
			p2/1: #"-"
			p: p + 1
		]

		px: as int-ptr! (big + 1)

		either radix = 16 [
			i: bused
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
			T: absolute* big false

			if false = form-hlp T radix as integer! :p [
				free* T
				free buf
				return false
			]
			free* T
		]

		olen/value: p - as integer! buf
		obuf/value: as integer! buf
		p2: as byte-ptr! p
		p2/1: as byte! 0
		true
	]

	#if debug? = yes [
		dec-dump: func [
			big				[bigint!]
			/local
				bused		[integer!]
				bsign		[integer!]
				p			[int-ptr!]
				pad8?		[logic!]
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
				pad8?: false
				loop bused [
					print form-decimal p/1 pad8?
					unless pad8? [pad8?: true]
					print " "
					p: p - 1
				]
			]
			print-line [lf "=============dump bigdecimal! end============="]
		]
		bin-dump: func [
			big				[bigint!]
			/local
				bused		[integer!]
				bsign		[integer!]
				p			[int-ptr!]
		][
			print-line [lf "---------------dump bigint!---------------"]
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
				print-line ["size: " big/size " used: " bused " sign: " bsign]
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
			print-line [lf "-------------dump bigint! end-------------"]
		]
		dump: func [
			big				[bigint!]
		][
			either big = null [
				print-line "null"
			][
				either big/prec = 0 [
					bin-dump big
				][
					dec-dump big
				]
			]
		]
	]

]
