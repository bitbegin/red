Red/System [
	Title:   "Bignum! datatype runtime functions"
	Author:  "bitbegin"
	File: 	 %bignum.reds
	Tabs:	 4
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

bignum: context [
	verbose: 1

	ciL:				4				;-- bignum! unit is 4 bytes; chars in limb
	biL:				ciL << 3		;-- bits in limb
	biLH:				ciL << 2		;-- half bits in limb
	BN_MAX_LIMB:		1024			;-- support 1024 * 32 bits
	BN_WINDOW_SIZE:		6				;-- Maximum window size used for modular exponentiation

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
				break;
			]
			mask: mask >>> 1
			ret: ret + 1
		]
		ret
	]

	bitlen: func [
		big			[red-bignum!]
		return:		[integer!]
		/local
			s		[series!]
			p		[int-ptr!]
			ret		[integer!]
	][
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset

		if big/used = 0 [return 0]

		p: P + big/used - 1

		ret: biL - clz p/1
		ret: ret + ((big/used - 1) * biL)
		ret
	]

	len: func [
		big			[red-bignum!]
		return:		[integer!]
		/local
			ret		[integer!]
	][
		ret: bitlen big
		ret: (ret + 7) >>> 3
		ret
	]

	left-shift: func [
		big			[red-bignum!]
		count		[integer!]
		/local
			ret		[integer!]
			i		[integer!]
			v0		[integer!]
			t1		[integer!]
			r0		[integer!]
			r1		[integer!]
			s		[series!]
			len		[integer!]
			p		[int-ptr!]
			p1		[int-ptr!]
			p2		[int-ptr!]
	][
		r0: 0
		v0: count / biL
		t1: count and (biL - 1)
		i: bitlen big
		i: i + count
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset

		if (big/used * biL) < i [
			len: i / biL
			if i % biL <> 0 [
				len: len + 1
			]
			grow big len
			s: GET_BUFFER(big)
			p: as int-ptr! s/offset
			big/used: len
		]

		len: big/used

		ret: 0

		if v0 > 0 [
			i: len
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
			while [i < len][
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
	]

	right-shift: func [
		big			[red-bignum!]
		count		[integer!]
		/local
			ret		[integer!]
			i		[integer!]
			v0		[integer!]
			v1		[integer!]
			r0		[integer!]
			r1		[integer!]
			s		[series!]
			len		[integer!]
			p		[int-ptr!]
			p1		[int-ptr!]
			p2		[int-ptr!]
	][
		r0: 0
		v0: count / biL
		v1: count and (biL - 1)

		s: GET_BUFFER(big)
		p: as int-ptr! s/offset

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

		len: big/used

		ret: 0

		if v0 > 0 [
			i: 0
			while [i < (len - v0)][
				p1: p + i
				p2: p + i + v0
				p1/1: p2/1
				i: i + 1
			]

			while [i < len][
				p1: p + i
				p1/1: 0
				i: i + 1
			]
		]

		if v1 > 0 [
			i: len
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

	serialize: func [
		big			[red-bignum!]
		buffer		[red-string!]
		only?		[logic!]
		all?		[logic!]
		flat?		[logic!]
		arg			[red-value!]
		part		[integer!]
		mold?		[logic!]
		return: 	[integer!]
		/local
			s		[series!]
			bytes	[integer!]
			p		[byte-ptr!]
			size	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/serialize"]]

		s: GET_BUFFER(big)
		p: as byte-ptr! s/offset
		either big/used = 0 [
			size: 1
		][
			size: big/used * 4
		]
		p: p + size

		bytes: 0
		if size > 30 [
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: part - 1
		]

		if big/sign = -1 [
			string/append-char GET_BUFFER(buffer) as-integer #"-"
			part: part - 1
		]

		loop size [
			p: p - 1
			string/concatenate-literal buffer string/byte-to-hex as-integer p/value
			bytes: bytes + 1
			if bytes % 32 = 0 [
				string/append-char GET_BUFFER(buffer) as-integer lf
				part: part - 1
			]
			part: part - 2
			if all [OPTION?(arg) part <= 0][return part]
		]
		if all [size > 30 bytes % 32 <> 0] [
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: part - 1
		]
		part - 1
	]

	serialize-oct: func [
		big			[red-bignum!]
		buffer		[red-string!]
		only?		[logic!]
		all?		[logic!]
		flat?		[logic!]
		arg			[red-value!]
		part		[integer!]
		mold?		[logic!]
		return: 	[integer!]
		/local
			s		[series!]
			bytes	[integer!]
			p		[byte-ptr!]
			size	[integer!]
			rsize	[red-integer!]
			tmp		[byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/serialize"]]

		s: GET_BUFFER(big)
		p: as byte-ptr! s/offset
		either big/used = 0 [
			size: 1
		][
			size: big/used * 4
		]

		rsize: integer/make-at stack/push* size
		tmp: allocate size * 10
		if 0 <> write-string big 10 tmp size * 10 rsize [
			print "something wrong!"
		]

		size: rsize/value
		p: tmp

		bytes: 0
		if size > 30 [
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: part - 1
		]

		if big/sign = -1 [
			string/append-char GET_BUFFER(buffer) as-integer #"-"
			part: part - 1
		]

		loop size - 1 [
			string/append-char GET_BUFFER(buffer) as-integer p/1
			bytes: bytes + 1
			if bytes % 32 = 0 [
				string/append-char GET_BUFFER(buffer) as-integer lf
				part: part - 1
			]
			part: part - 2
			if all [OPTION?(arg) part <= 0][
				free tmp
				return part
			]
			p: p + 1
		]
		if all [size > 30 bytes % 32 <> 0] [
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: part - 1
		]
		free tmp
		part - 1
	]

	do-math: func [
		type		[math-op!]
		return:		[red-value!]
		/local
			left	[red-bignum!]
			right	[red-bignum!]
			big		[red-bignum!]
			rem		[red-bignum!]
			int		[red-integer!]
			ret		[integer!]
	][
		left: as red-bignum! stack/arguments
		right: left + 1

		assert any [
			TYPE_OF(left) = TYPE_BIGNUM
		]
		assert any [
			TYPE_OF(right) = TYPE_INTEGER
			TYPE_OF(right) = TYPE_BIGNUM
		]
		
		big: make-at stack/push* 1
		switch TYPE_OF(right) [
			TYPE_INTEGER [
				switch type [
					OP_ADD [
						int: as red-integer! right
						add-int left int/value big
					]
					OP_SUB [
						int: as red-integer! right
						sub-int left int/value big
					]
					OP_MUL [
						int: as red-integer! right
						mul-int left int/value big
					]
					OP_REM [
						int: as red-integer! right
						ret: 0
						module-int :ret left int/value
						lset big ret
					]
				]
			]
			TYPE_BIGNUM [
				switch type [
					OP_ADD [
						add left right big
					]
					OP_SUB [
						sub left right big
					]
					OP_MUL [
						mul left right big
					]
					OP_DIV [
						rem: make-at stack/push* 1
						div big rem left right
					]
					OP_REM [
						module big left right
					]
				]
			]
		]
		SET_RETURN(big)
	]

	dump-bignum: func [
		big			[red-bignum!]
		/local
			s	 	[series!]
			p		[byte-ptr!]
	][
	#if debug? = yes [
		s: GET_BUFFER(big)
		p: as byte-ptr! s/offset
		print-line [lf "===============dump bignum!==============="]
		print-line ["used: " big/used " sign: " big/sign " addr: " p]
		p: p + (big/used * 4)
		loop big/used * 4 [
			p: p - 1
			prin-hex-chars as-integer p/1 2
		]
		print-line lf
		print-line ["=============dump bignum! end=============" lf]
	]]

	make-at: func [
		slot		[red-value!]
		len 		[integer!]
		return:		[red-bignum!]
		/local
			big		[red-bignum!]
			s		[series!]
			p4		[int-ptr!]
	][
		if len = 0 [len: 1]

		;-- make bignum!
		big: as red-bignum! slot
		big/header: TYPE_BIGNUM
		big/node:	alloc-series len 4 0
		big/sign:	1
		big/used:	1

		;-- init to zero
		s: GET_BUFFER(big)
		p4: as int-ptr! s/offset
		loop len [
			p4/1: 0
			p4: p4 + 1
		]
		big
	]

	copy: func [
		src	 		[red-bignum!]
		big			[red-bignum!]
		/local
			s1	 	[series!]
			s2	 	[series!]
			p1		[byte-ptr!]
			p2		[byte-ptr!]
			size	[integer!]
	][
		if src = big [exit]
		
		s1: GET_BUFFER(src)
		p1: as byte-ptr! s1/offset
		size: src/used * 4

		s2: GET_BUFFER(big)
		p2: as byte-ptr! s2/offset

		if s2/size < (size) [
			grow big src/used
			s2: GET_BUFFER(big)
			p2: as byte-ptr! s2/offset
		]

		big/sign: src/sign
		big/used: src/used
		if size > 0 [
			copy-memory p2 p1 size
		]
	]

	grow: func [
		big			[red-bignum!]
		len			[integer!]
		/local
			s	 	[series!]
			p		[int-ptr!]
			ex_size	[integer!]
			ex_len	[integer!]
	][
		if len > BN_MAX_LIMB [--NOT_IMPLEMENTED--]
		if len = 0 [exit]

		s: GET_BUFFER(big)
		ex_size: (len * 4) - s/size 
		if ex_size > 0 [ 
  			ex_len: ex_size / 4 
  			s: expand-series s (len * 4) 

			;-- set to zero
			p: as int-ptr! s/offset + big/used
			ex_len: len - big/used
			loop ex_len [
				p/1: 0
				p: p + 1
			]
			big/used: len
		]
	]

	shrink: func [
		big			[red-bignum!]
		/local
			s	 	[series!]
			p		[int-ptr!]
			len		[integer!]
	][
		s: GET_BUFFER(big)
		len: big/used
		p: as int-ptr! s/offset
		p: p + len
		loop len [
			p: p - 1
			either p/1 = 0 [
				big/used: big/used - 1
			][
				break
			]
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

	absolute-add: func [
		big1	 	[red-bignum!]
		big2		[red-bignum!]
		ret			[red-bignum!]
		/local
			big	 	[red-bignum!]
			s	 	[series!]
			s1	 	[series!]
			s2	 	[series!]
			p		[int-ptr!]
			p2		[int-ptr!]
			i		[integer!]
			c		[integer!]
			tmp		[integer!]
	][
		s1: GET_BUFFER(big1)
		s2: GET_BUFFER(big2)
		p2: as int-ptr! s2/offset

		big: make-at stack/push* 1
		copy big1 big
		big/sign: 1
		grow big big2/used
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset

		c: 0
		i: 0
		loop big2/used [
			tmp: p2/1
			p/1: p/1 + c
			c: as integer! (uint-less p/1  c)
			p/1: p/1 + tmp
			c: c + as integer! (uint-less p/1 tmp)
			p: p + 1
			p2: p2 + 1
			i: i + 1
		]

		while [c > 0][
			if (i * 4) >= s/size [
				grow big (i + 1)
				s: GET_BUFFER(big)
				p: as int-ptr! s/offset
				p: p + i
			]
			p/1: p/1 + c
			c: as integer! (uint-less p/1 c)
			i: i + 1
			p: p + 1
		]
		if big/used < i [
			big/used: i
		]
		copy big ret
	]

	sub-hlp: func [
		n			[integer!]
		s	 		[int-ptr!]
		d	 		[int-ptr!]
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
		big1	 	[red-bignum!]
		big2		[red-bignum!]
		ret	 		[red-bignum!]
		/local
			s	 	[series!]
			s1	 	[series!]
			s2	 	[series!]
			p		[int-ptr!]
			p2		[int-ptr!]
			len		[integer!]
			c		[integer!]
			z		[integer!]
			big		[red-bignum!]
	][
		s1: GET_BUFFER(big1)
		s2: GET_BUFFER(big2)
		p2: as int-ptr! s2/offset
		len: big2/used

		if big1/used < big2/used [--NOT_IMPLEMENTED--]

		big: make-at stack/push* 1
		copy big1 big
		big/sign: 1
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset

		sub-hlp len p2 p

		shrink big
		copy big ret
	]

	absolute-compare: func [
		big1	 	[red-bignum!]
		big2	 	[red-bignum!]
		return:	 	[integer!]
		/local
			s1	 	[series!]
			s2	 	[series!]
			p1		[int-ptr!]
			p2		[int-ptr!]
	][
		s1: GET_BUFFER(big1)
		s2: GET_BUFFER(big2)

		if all [
			big1/used = 0
			big2/used = 0
		][
			return 0
		]

		if big1/used > big2/used [return 1]
		if big2/used > big1/used [return -1]

		p1: as int-ptr! s1/offset
		p1: p1 + big1/used
		p2: as int-ptr! s2/offset
		p2: p2 + big2/used
		loop big1/used [
			p1: p1 - 1
			p2: p2 - 1
			if uint-less p2/1 p1/1 [return 1]
			if uint-less p1/1 p2/1 [return -1]
		]
		return 0
	]

	add: func [
		big1	 	[red-bignum!]
		big2		[red-bignum!]
		big	 		[red-bignum!]
	][
		either big1/sign <> big2/sign [
			either (absolute-compare big1 big2) >= 0 [
				absolute-sub big1 big2 big
				big/sign: big1/sign
			][
				absolute-sub big2 big1 big
				big/sign: big2/sign
			]
		][
			absolute-add big1 big2 big
			big/sign: big1/sign
		]
	]

	sub: func [
		big1	 	[red-bignum!]
		big2		[red-bignum!]
		big	 		[red-bignum!]
	][
		either big1/sign = big2/sign [
			either (absolute-compare big1 big2) >= 0 [
				absolute-sub big1 big2 big
				big/sign: big1/sign
			][
				absolute-sub big2 big1 big
				big/sign: 0 - big1/sign
			]
		][
			absolute-add big1 big2 big
			big/sign: big1/sign
		]
	]

	add-int: func [
		big1	 	[red-bignum!]
		int			[integer!]
		ret		 	[red-bignum!]
		/local
			big	 	[red-bignum!]
			s	 	[series!]
			p		[int-ptr!]
	][
		big: make-at stack/push* 1
		big/used: 1
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset
		p/1: either int >= 0 [
			big/sign: 1
			int
		][
			big/sign: -1
			0 - int
		]
		add big1 big ret
	]

	sub-int: func [
		big1	 	[red-bignum!]
		int			[integer!]
		ret		 	[red-bignum!]
		/local
			big	 	[red-bignum!]
			s	 	[series!]
			p		[int-ptr!]
	][
		big: make-at stack/push* 1
		big/used: 1
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset
		p/1: either int >= 0 [
			big/sign: 1
			int
		][
			big/sign: -1
			0 - int
		]
		sub big1 big ret
	]

	mul-hlp: func [
		i			[integer!]
		s	 		[int-ptr!]
		d	 		[int-ptr!]
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
	        MULADDC_CORE   MULADDC_CORE
	        MULADDC_CORE   MULADDC_CORE
	        MULADDC_CORE   MULADDC_CORE
	        MULADDC_CORE   MULADDC_CORE

	        MULADDC_CORE   MULADDC_CORE
	        MULADDC_CORE   MULADDC_CORE
	        MULADDC_CORE   MULADDC_CORE
	        MULADDC_CORE   MULADDC_CORE
	        MULADDC_STOP
			i: i - 16
		]

		while [i >= 8][
			MULADDC_INIT
			MULADDC_CORE   MULADDC_CORE
			MULADDC_CORE   MULADDC_CORE

			MULADDC_CORE   MULADDC_CORE
			MULADDC_CORE   MULADDC_CORE
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

	lset: func [
		big			[red-bignum!]
		int			[integer!]
		/local
			s	 	[series!]
			p		[byte-ptr!]
			p4		[int-ptr!]
	][
		grow big (big/used + 1)
		s: GET_BUFFER(big)
		p: as byte-ptr! s/offset
		p4: as int-ptr! s/offset
		set-memory p #"^@" s/size

		either int >= 0 [
			p4/1: int
			big/sign: 1
		][
			p4/1: 0 - int
			big/sign: -1
		]
		big/used: 1
	]

	mul: func [
		big1		[red-bignum!]
		big2		[red-bignum!]
		ret			[red-bignum!]
		/local
			big		[red-bignum!]
			s	 	[series!]
			s1	 	[series!]
			s2	 	[series!]
			p		[int-ptr!]
			p1		[int-ptr!]
			p2		[int-ptr!]
			len1	[integer!]
			len2	[integer!]
			pt		[int-ptr!]
			len		[integer!]
	][
		s1: GET_BUFFER(big1)
		s2: GET_BUFFER(big2)
		p1: as int-ptr! s1/offset
		p2: as int-ptr! s2/offset
		len1: big1/used
		len2: big2/used

		len: len1 + len2 + 1
		big: make-at stack/push* len
		big/used: len
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset

		len1: len1 + 1
		while [len2 > 0]
		[
			pt: p2 + len2 - 1
			mul-hlp (len1 - 1) p1 (p + len2 - 1) pt/1
			len2: len2 - 1
		]

		big/sign: big1/sign * big2/sign
		shrink big
		copy big ret
	]

	mul-int: func [
		big1		[red-bignum!]
		int			[integer!]
		ret			[red-bignum!]
		/local
			big	 	[red-bignum!]
			s	 	[series!]
			p		[int-ptr!]
	][
		big: make-at stack/push* 1
		big/used: 1
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset
		p/1: either int >= 0 [
			big/sign: 1
			int
		][
			big/sign: -1
			0 - int
		]
		mul big1 big ret
	]
	
	mul-uint: func [
		big1		[red-bignum!]
		uint		[integer!]
		ret			[red-bignum!]
		/local
			big	 	[red-bignum!]
			s	 	[series!]
			p		[int-ptr!]
	][
		big: make-at stack/push* 1
		big/used: 1
		big/sign: 1
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset
		p/1: uint
		mul big1 big ret
	]

	uint-div: func [
		u1				[integer!]
		u0				[integer!]
		return:			[integer!]
		/local
			i			[integer!]
	][
		if u0 = 0 [
			return u1 / u0
		]
		
		if uint-less u1 u0 [
			return 0
		]
		
		i: 0
		while [true] [
			u1: u1 - u0
			i: i + 1
			if uint-less u1 u0 [
				return i
			]
		]
		return i
	]
	
	long-divide: func [
		u1				[integer!]
		u0				[integer!]
		d				[integer!]
		return:			[integer!]
		/local
			radix		[integer!]
			hmask		[integer!]
			d0			[integer!]
			d1			[integer!]
			q0			[integer!]
			q1			[integer!]
			rAX			[integer!]
			r0			[integer!]
			quotient	[integer!]
			u0_msw		[integer!]
			u0_lsw		[integer!]
			s			[integer!]
			tmp			[integer!]
	][
		radix: 1 << biLH
		hmask: radix - 1

		if any [
			d = 0
			not uint-less u1 d
		][
			return -1
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
		
		q1: uint-div u1 d1
		r0: u1 - (d1 * q1)

		while [
			any [
				not uint-less q1 radix
				uint-less (radix * r0 + u0_msw) (q1 * d0)
			]
		][
			q1: q1 - 1;
			r0: r0 + d1

			unless uint-less r0 radix [break]
		]

		rAX: (u1 * radix) + (u0_msw - (q1 * d))
		q0: uint-div rAX d1
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

		quotient: q1 * radix + q0
		quotient
	]

	;-- A = Q * B + R
	div: func [
		Q	 		[red-bignum!]
		R	 		[red-bignum!]
		A	 		[red-bignum!]
		B	 		[red-bignum!]
		return:	 	[logic!]
		/local
			X		[red-bignum!]
			Y		[red-bignum!]
			Z		[red-bignum!]
			T1		[red-bignum!]
			T2		[red-bignum!]
			i		[integer!]
			n		[integer!]
			t		[integer!]
			k		[integer!]
			s	 	[series!]
			px		[int-ptr!]
			py		[int-ptr!]
			pz		[int-ptr!]
			pt1		[int-ptr!]
			pt2		[int-ptr!]
			tmp		[integer!]
			tmp2	[integer!]
			ret		[integer!]
	][
		if 0 = compare-int B 0 [
			fire [TO_ERROR(math zero-divide)]
			0								;-- pass the compiler's type-checking
			return false
		]

		if (absolute-compare A B) < 0 [
			lset Q 0
			copy A R
			return true
		]

		X: make-at stack/push* 1
		Y: make-at stack/push* 1
		Z: make-at stack/push* (A/used + 2)
		T1: make-at stack/push* 2
		T2: make-at stack/push* 3

		copy A X
		copy B Y
		X/sign: 1
		Y/sign: 1
		Z/used: A/used + 2
		T1/used: 2
		T2/used: 3
		
		k: (bitlen Y) % biL
		
		either k < (biL - 1) [
			k: biL - 1 - k
			left-shift X k
			left-shift Y k
		][
			k: 0
		]

		n: X/used
		t: Y/used
		left-shift Y (biL * (n - t))
		
		s: GET_BUFFER(X)
		px: as int-ptr! s/offset
		s: GET_BUFFER(Y)
		py: as int-ptr! s/offset
		s: GET_BUFFER(Z)
		pz: as int-ptr! s/offset
		s: GET_BUFFER(T1)
		pt1: as int-ptr! s/offset
		s: GET_BUFFER(T2)
		pt2: as int-ptr! s/offset

		while [(compare X Y) >= 0][
			tmp: n - t + 1
			pz/tmp: pz/tmp + 1
			sub X Y X
		]
		right-shift Y (biL * (n - t))

		i: n
		while [i > t][
			tmp: i - t
			either not uint-less px/i py/t [
				pz/tmp: -1
			][
				tmp2: i - 1
				pz/tmp: long-divide px/i px/tmp2 py/t
			]

			pz/tmp: pz/tmp + 1
			until [
				pz/tmp: pz/tmp - 1
				lset T1 0
				s: GET_BUFFER(T1)
				pt1: as int-ptr! s/offset
				pt1/1: either t < 2 [
					0
				][
					tmp2: t - 1
					py/tmp2
				]
				pt1/2: py/t
				T1/used: 2

				mul-uint T1 pz/tmp T1

				lset T2 0
				s: GET_BUFFER(T2)
				pt2: as int-ptr! s/offset
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
				
				(compare T1 T2) <= 0
			]

			mul-uint Y pz/tmp T1
			left-shift T1 (biL * (tmp - 1))
			sub X T1 X
			s: GET_BUFFER(X)
			px: as int-ptr! s/offset
			if (compare-int X 0) < 0 [
				copy Y T1
				;s: GET_BUFFER(T1)
				;pt1: as int-ptr! s/offset
				
				left-shift T1 (biL * (tmp - 1))
				add X T1 X
				s: GET_BUFFER(X)
				px: as int-ptr! s/offset
				pz/tmp: pz/tmp - 1
			]
			i: i - 1
		]
		
		shrink Z
		copy Z Q
		Q/sign: A/sign * B/sign
		
		right-shift X k
		X/sign: A/sign
		shrink X
		copy X R
		
		if (compare-int R 0) = 0 [
			R/sign: 1
		]
		return true
	]
	
	div-int: func [
		Q	 		[red-bignum!]
		R	 		[red-bignum!]
		A	 		[red-bignum!]
		int	 		[integer!]
		return:	 	[logic!]
		/local
			big	 	[red-bignum!]
			s	 	[series!]
			p		[int-ptr!]
	][
		big: make-at stack/push* 1
		big/used: 1
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset
		p/1: either int >= 0 [
			big/sign: 1
			int
		][
			big/sign: -1
			0 - int
		]
		div Q R A big
	]
	
	module: func [
		R	 		[red-bignum!]
		A	 		[red-bignum!]
		B	 		[red-bignum!]
		return:	 	[logic!]
		/local
			Q		[red-bignum!]
	][
		;-- temp error
		if (compare-int B 0) < 0 [
			fire [TO_ERROR(math zero-divide)]
			0								;-- pass the compiler's type-checking
			return false
		]
		
		Q: make-at stack/push* 1
		div Q R A B
		
		if (compare-int R 0) < 0 [
			add R B R
		]
		
		if (compare R B) >= 0 [
			sub R B R
		]
		
		return true
	]

	module-int: func [
		r	 		[int-ptr!]
		A	 		[red-bignum!]
		b	 		[integer!]
		return:	 	[logic!]
		/local
			s	 	[series!]
			p		[int-ptr!]
			x		[integer!]
			y		[integer!]
			z		[integer!]
	][
		;-- temp error
		if b <= 0 [
			fire [TO_ERROR(math zero-divide)]
			0								;-- pass the compiler's type-checking
			return false
		]
		
		s: GET_BUFFER(A)
		p: as int-ptr! s/offset
		
		if b = 1 [
			r/1: 0
			return true
		]
		
		if b = 2 [
			r/1: p/1 and 1
			return true
		]
		
		y: 0
		p: p + A/used - 1
		loop A/used [
			x: p/1
			y: (y << biLH) or (x >>> biLH)
			z: uint-div y b
			y: y - (z * b)
			
			x: x << biLH
			y: (y << biLH) or (x >>> biLH)
			z: uint-div y b
			y: y - (z * b)
			
			p: p - 1
		]
		
		if all [
			A/sign < 0
			y <> 0
		][
			y: b - y
		]
		
		r/1: y
		return true
	]

	compare: func [
		big1	 	[red-bignum!]
		big2	 	[red-bignum!]
		return:	 	[integer!]
	][
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

		either big1/sign = 1 [
			return absolute-compare big1 big2
		][
			return absolute-compare big2 big1
		]
	]

	compare-int: func [
		big1	 	[red-bignum!]
		int			[integer!]
		return:	 	[integer!]
		/local
			big	 	[red-bignum!]
			s	 	[series!]
			p		[int-ptr!]
	][
		big: make-at stack/push* 1
		big/used: 1
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset
		p/1: either int >= 0 [
			big/sign: 1
			int
		][
			big/sign: -1
			0 - int
		]
		compare big1 big
	]

	;--- Special Functions
	
	montg-init: func [
		mm	 		[int-ptr!]
		N			[red-bignum!]
		/local
			x		[integer!]
			m0		[integer!]
			i		[integer!]
			s	 	[series!]
			p		[int-ptr!]
	][
		s: GET_BUFFER(N)
		p: as int-ptr! s/offset
		
		m0: p/1
		
		x: m0
		x: x + (((m0 + 2) and 4) << 1)
		
		i: biL
		while [i >= 8] [
			x: x * (2 - (m0 * x))
			i: i / 2
		]
		
		mm/1: 1 - x
	]
	
	;-- Montgomery multiplication: R = A * B * R^-1 mod NN
	montg-mul: func [
		A			[red-bignum!]
		B			[red-bignum!]
		NN			[red-bignum!]
		mm			[integer!]
		T			[red-bignum!]
		R			[red-bignum!]
		/local
			i		[integer!]
			n		[integer!]
			m		[integer!]
			u0		[integer!]
			u1		[integer!]
			d		[int-ptr!]
			s	 	[series!]
			p		[int-ptr!]
			pa		[int-ptr!]
			pb		[int-ptr!]
			pn		[int-ptr!]
			pr		[int-ptr!]
	][
		lset T 0
		
		s: GET_BUFFER(T)
		d: as int-ptr! s/offset
		s: GET_BUFFER(NN)
		n: s/size
		pn: as int-ptr! s/offset
		s: GET_BUFFER(B)
		pb: as int-ptr! s/offset
		m: s/size
		m: either m < n [m][n]
		s: GET_BUFFER(A)
		pa: as int-ptr! s/offset
		
		i: 0
		loop n [
			;-- T = (T + u0*B + u1*N) / 2^biL
			p: pa + i
			u0: p/1
			u1: (d/1 + (u0 * pb/1)) * mm
			
			mul-hlp m pb d u0
			mul-hlp n pn d u1
			d/1: u0
			d: d + 1
			p: d + n + 1
			p/1: 0
			i: i + 1
		]
		
		T/used: n + 1
		shrink T
		copy T R
		s: GET_BUFFER(R)
		pr: as int-ptr! s/offset
		
		either (absolute-compare R NN) >= 0 [
			sub-hlp n pn pr
		][
			sub-hlp n pr pn
		]
		shrink R
	]

	;-- Montgomery reduction: R = A * R^-1 mod N
	montg-reduction: func [
		A			[red-bignum!]
		N			[red-bignum!]
		mm			[integer!]
		T			[red-bignum!]
		R			[red-bignum!]
		/local
			U		[red-bignum!]
	][
		U: make-at stack/push* 1
		lset U 1
		montg-mul A U N mm T R
	]

	W-Arr: as red-bignum! allocate (2 << BN_WINDOW_SIZE) * size? red-bignum!
	
	;-- Sliding-window exponentiation: X = A^E mod N
	exp-mod: func [
		A			[red-bignum!]
		E			[red-bignum!]
		N			[red-bignum!]
		_RR			[red-bignum!]
		X			[red-bignum!]
		/local
			ret		[integer!]
			wbits	[integer!]
			wsize	[integer!]
			one		[integer!]
			i		[integer!]
			j		[integer!]
			nblimbs	[integer!]
			bufsize	[integer!]
			nbits	[integer!]
			ei		[integer!]
			mm		[integer!]
			state	[integer!]
			neg		[logic!]
			RR		[red-bignum!]
			T		[red-bignum!]
			W		[red-bignum!]
			W1		[red-bignum!]
			Apos	[red-bignum!]
			s	 	[series!]
			p		[int-ptr!]
			pn		[int-ptr!]
			pe		[int-ptr!]
	][
		one: 1
		s: GET_BUFFER(N)
		pn: as int-ptr! s/offset
		
		;-- temp error
		if any [
			(compare-int N 0) < 0
			(pn/1 and 1) = 0
		][
			fire [TO_ERROR(math zero-divide)]
			0								;-- pass the compiler's type-checking
			exit
		]
		
		if (compare-int E 0) < 0 [
			fire [TO_ERROR(math zero-divide)]
			0								;-- pass the compiler's type-checking
			exit
		]
		
		mm: 0
		montg-init :mm N
		RR: make-at stack/push* 1
		lset RR 0
		T: make-at stack/push* 1
		lset T 0
		Apos: make-at stack/push* 1
		lset Apos 0
		
		i: 0
		loop (2 << BN_WINDOW_SIZE) [
			W: W-Arr + i
			W/header: TYPE_BIGNUM
			W/node:	alloc-series 16 4 0
			lset W 0
			i: i + 1
		]
		
		i: bitlen E
		wsize: either i > 671 [6][
			either i > 239 [5][
				either i > 79 [4][
					either i > 23 [3][1]
				]
			]
		]
		if wsize > BN_WINDOW_SIZE [
			wsize: BN_WINDOW_SIZE
		]
		
		s: GET_BUFFER(N)
		j: s/size + 1
		grow X j
		W: W-Arr + 1
		grow W j
		grow T j * 2
		
		neg: A/sign = -1
		
		if neg [
			copy A Apos
			Apos/sign: 1
			A: Apos
		]
		
		;-- If 1st call, pre-compute R^2 mod N
		s: GET_BUFFER(_RR)
		either (as integer! s/node) = 0 [
			lset RR 1
			s: GET_BUFFER(N)
			left-shift RR s/size * 2 * biL
			module RR N RR
			copy RR _RR
		][
			copy _RR RR
		]
		
		;-- W[1] = A * R^2 * R^-1 mod N = A * R mod N
		W: W-Arr + 1
		either (compare A N) >= 0 [
			module A N W
		][
			copy A W
		]
		montg-mul W RR N mm T W

	 	;-- X = R^2 * R^-1 mod N = R mod N
		copy RR X
		montg-reduction X N mm T X
		
		if wsize > 1 [
			;-- W[1 << (wsize - 1)] = W[1] ^ (wsize - 1)
			j: one << (wsize - 1)
			s: GET_BUFFER(N)
			W: W-Arr + j
			W1: W-Arr + 1
			grow W s/size + 1
			copy W1 W
			
			loop wsize - 1 [
				montg-mul W W N mm T W
			]
			
			;-- W[i] = W[i - 1] * W[1]
			i: j + 1
			while [i < (one << wsize)][
				W: W-Arr + i
				W1: W-Arr + i - 1
				s: GET_BUFFER(N)
				grow W s/size + 1
				copy W1 W
				W1: W-Arr + 1
				montg-mul W W1 N mm T W
				i: i + 1
			]
		]
		
		s: GET_BUFFER(E)
		pe: as int-ptr! s/offset
		nblimbs: s/size
	    bufsize: 0
	    nbits: 0
	    wbits: 0
	    state: 0
		
		while [true][
			if bufsize = 0 [
				if nblimbs = 0 [
					break
				]
				
				nblimbs: nblimbs - 1
				bufsize: 4 << 3
			]
			
			bufsize: bufsize - 1
			p: pe + nblimbs
			ei: (p/1 >>> bufsize) and 1
			
			if all [
				ei = 0
				state = 0
			][
				continue
			]
			
			if all [
				ei = 0
				state = 1
			][
				;-- out of window, square X
				montg-mul X X N mm T X
				continue
			]
			
			;-- add ei to current window
			state: 2
			
			nbits: nbits + 1
			wbits: wbits or (ei << ( wsize - nbits))
			
			if nbits = wsize [
				;-- X = X^wsize R^-1 mod N
				loop wsize [
					montg-mul X X N mm T X
				]
				
				;-- X = X * W[wbits] R^-1 mod N
				W: W-Arr + wbits
				montg-mul X W N mm T X
				state: state - 1
				nbits: 0
				wbits: 0
			]
		]
		
		;-- process the remaining bits
		loop nbits [
			montg-mul X X N mm T X
			
			wbits: wbits << 1
			
			if (wbits and (one << wsize)) <> 0 [
				W: W-Arr + 1
				montg-mul X W N mm T X
			]
		]
		
		;-- X = A^E * R * R^-1 mod N = A^E mod N
		montg-reduction X N mm T X
		
		if neg [
			X/sign: -1
			add N X X
		]
	]

	;--- Actions ---
	
	make: func [
		proto	 	[red-value!]
		spec	 	[red-value!]
		return:	 	[red-bignum!]
		/local
			int	 	[red-integer!]
			bin	 	[red-binary!]
			big	 	[red-bignum!]
			s	 	[series!]
			sbin	[series!]
			pbig	[byte-ptr!]
			head	[byte-ptr!]
			tail	[byte-ptr!]
			len		[integer!]
			size	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/make"]]

		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				big: make-at stack/push* 1
				lset big int/value
			]
			TYPE_BINARY [
				bin: as red-binary! spec
				sbin: GET_BUFFER(bin)
				head: (as byte-ptr! sbin/offset) + bin/head
				tail: as byte-ptr! sbin/tail
				size: as-integer tail - head
				either size = 0 [
					big: make-at stack/push* 1
					lset big 0
				][
					len: size / 4
					if size % 4 <> 0 [
						len: len + 1
					]
					big: make-at stack/push* len
					s: GET_BUFFER(big)
					pbig: as byte-ptr! s/offset
					big/used: len
					loop size [
						tail: tail - 1
						pbig/1: tail/1
						pbig: pbig + 1
					]

					shrink big
				]
			]
			default [--NOT_IMPLEMENTED--]
		]

		big
	]

	form: func [
		big		[red-bignum!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/form"]]

		serialize-oct big buffer no no no arg part no
	]

	mold: func [
		big		[red-bignum!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return:	[integer!]
		/local
			formed [c-string!]
			s	   [series!]
			unit   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/mold"]]

		serialize-oct big buffer only? all? flat? arg part yes
	]

	write-hlp: func [
		big			[red-bignum!]
		radix		[integer!]
		buf			[integer!]
		return:		[integer!]
		/local
			ret		[integer!]
			R		[red-bignum!]
			pi		[int-ptr!]
			Q		[red-bignum!]
			pb		[byte-ptr!]
	][
		if any [
			radix < 2
			radix > 16
		][
			return -1
		]

		ret: 0
		module-int :ret big radix
		R: make-at stack/push* 1
		Q: make-at stack/push* 1
		div-int Q R big radix
		if 0 <> compare-int Q 0 [
			write-hlp Q radix buf
		]

		pi: as int-ptr! buf
		pb: as byte-ptr! pi/1
		either ret < 10 [
			pb/1: as byte! ret + 30h
		][
			pb/1: as byte! ret + 37h
		]
		pi/1: pi/1 + 1
		0
	]

	write-string: func [
		big			[red-bignum!]
		radix		[integer!]
		buf			[byte-ptr!]
		buflen		[integer!]
		olen		[red-integer!]
		return: 	[integer!]
		/local
			T		[red-bignum!]
			n		[integer!]
			p		[integer!]
			p2		[byte-ptr!]
			s	 	[series!]
			px		[int-ptr!]
			i		[integer!]
			j		[integer!]
			k		[integer!]
			c		[integer!]
			h		[c-string!]
			id		[byte!]
	][
		if any [
			radix < 2
			radix > 16
		][
			return -1
		]

		n: bitlen big
		if radix >= 4 [n: n >>> 1]
		if radix >= 16 [n: n >>> 1]
		n: n + 3

		if buflen < n [
			olen/value: n
			return -1
		]

		p: as integer! buf

		if big/sign = -1 [
			p2: as byte-ptr! p
			p2/1: #"-"
			p: p + 1
		]

		s: GET_BUFFER(big)
		px: as int-ptr! s/offset
		h: "0123456789ABCDEF"

		either radix = 16 [
			i: big/used
			k: 0
			while [i > 0][
				j: ciL
				while [j > 0][
					c: (px/i >>> ((j - 1) >>> 3)) and FFh
					if all [
						c = 0
						k = 0
						i + j <> 2
					][
						continue
					]

					id: as byte! c >> 4 and 15 + 1
					p2: as byte-ptr! p
					p2/1: id
					p: p + 1
					id: as byte! c and 15 + 1
					p2: as byte-ptr! p
					p2/1: id
					p: p + 1

					k: 1
					j: j -1
				]
				i: i - 1
			]
		][
			T: make-at stack/push* 1
			copy big T
			if T/sign = -1 [
				T/sign: 1
			]

			write-hlp T radix as integer! :p
		]

		p2: as byte-ptr! p
		p2/1: as byte! 0
		p: p + 1
		olen/value: p - as integer! buf
		0
	]

	compare*: func [
		value1    [red-bignum!]						;-- first operand
		value2    [red-bignum!]						;-- second operand
		op	      [integer!]						;-- type of comparison
		return:   [integer!]
		/local
			res	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/compare"]]

		if all [
			op = COMP_STRICT_EQUAL
			TYPE_OF(value1) <> TYPE_OF(value2)
		][return 1]

		switch op [
			COMP_EQUAL		[res: compare value1 value2]
			COMP_NOT_EQUAL 	[res: not compare value1 value2]
			default [
				res: SIGN_COMPARE_RESULT(value1 value2)
			]
		]
		res
	]

	absolute: func [
		return:		[red-bignum!]
		/local
			big		[red-bignum!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/absolute"]]

		big: as red-bignum! stack/arguments
		big/sign: 1
		big 											;-- re-use argument slot for return value
	]

	add*: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bignum/add"]]

		as red-value! do-math OP_ADD
	]
	
	divide: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bignum/divide"]]

		as red-value! do-math OP_DIV
	]

	multiply: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bignum/multiply"]]
		as red-value! do-math OP_MUL
	]

	subtract: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bignum/subtract"]]

		as red-value! do-math OP_SUB
	]

	negate: func [
		big		[red-bignum!]
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/complement"]]

		either big/sign = 1 [
			big/sign: -1
		][
			big/sign: 1
		]
		as red-value! big
	]

	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bignum/remainder"]]
		as red-value! do-math OP_REM
	]
	
	swap: func [
		big1	 	[red-bignum!]
		big2	 	[red-bignum!]
		return:	 	[red-bignum!]
		/local
			node 	[node!]
			sign 	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/swap"]]

		node: big1/node
		sign: big1/sign
		big1/node: big2/node
		big1/sign: big2/sign
		big2/node: node
		big2/sign: sign
		big1
	]

	init: does [
		datatype/register [
			TYPE_BIGNUM
			TYPE_VALUE
			"bignum!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			null			;to
			:form
			:mold
			null			;eval-path
			null			;set-path
			:compare*
			;-- Scalar actions --
			:absolute
			:add*
			:divide
			:multiply
			:negate
			null			;power
			:remainder
			null			;round
			:subtract
			null			;even?
			null			;odd?
			;-- Bitwise actions --
			null			;and~
			null			;complement
			null			;or~
			null			;xor~
			;-- Series actions --
			null			;append
			null			;at
			null			;back
			null			;change
			null			;clear
			null			;copy
			null			;find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;move
			null			;next
			null			;pick
			null			;poke
			null			;put
			null			;remove
			null			;reverse
			null			;select
			null			;sort
			null			;skip
			:swap
			null			;tail
			null			;tail?
			null			;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			null			;modify
			null			;open
			null			;open?
			null			;query
			null			;read
			null			;rename
			null			;update
			null			;write
		]
	]
]
