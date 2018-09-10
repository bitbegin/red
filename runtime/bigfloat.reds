Red/System [
	Title:   "big float lib"
	Author:  "bitbegin"
	File: 	 %bigfloat.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#include %bigint.reds

bigfloat!: alias struct! [
	size		[integer!]				;-- size in integer!
	used		[integer!]				;-- used length in integer!
	sign		[integer!]
	expo		[integer!]
	prec		[integer!]
	data		[int-ptr!]
]

bigfloat: context [
	default-prec: 20

	set-default-prec: func [
		precise				[integer!]
	][
		default-prec: either precise >= 2 [precise][2]
	]

	load-int: func [
		int					[integer!]
		return:				[bigfloat!]
		/local
			big				[bigfloat!]
	][
		big: as bigfloat! bigint/load-int int
		if int = 0 [big/used: 1]
		big/expo: big/used
		big/prec: default-prec
		big
	]

	load-uint: func [
		uint				[integer!]
		return:				[bigfloat!]
		/local
			big				[bigfloat!]
	][
		big: as bigfloat! bigint/load-uint uint
		if uint = 0 [big/used: 1]
		big/expo: big/used
		big/prec: default-prec
		big
	]

	load-nan: func [
		return:				[bigfloat!]
		/local
			big				[bigfloat!]
	][
		big: as bigfloat! bigint/load-int -1
		big/expo: 7FFFFFFFh
		big/prec: default-prec
		big
	]

	load-inf: func [
		sign				[integer!]
		return:				[bigfloat!]
		/local
			big				[bigfloat!]
	][
		big: as bigfloat! bigint/load-int 0
		big/used: 1
		big/expo: either sign = 1 [7FFFFFFFh][80000000h]
		big/prec: default-prec
		big
	]

	int64!:  alias struct! [int1 [integer!] int2 [integer!]]

	;-- float! be placed in little endian
	;@@ Use little endian. Watch out big endian !
	load-float: func [
		f					[float!]
		return:				[bigfloat!]
		/local
			d				[int64!]
			w0				[integer!]
			sign			[integer!]
			expo			[integer!]
			big				[bigfloat!]
			manh			[integer!]
			manl			[integer!]
			sc				[integer!]
			p				[int-ptr!]
	][
		d: as int64! :f
		w0: d/int2

		sign: -1
		if 0 = (w0 and 80000000h) [sign: 1]

		if w0 and 7FF00000h = 7FF00000h [
			if all [
				zero? d/int1
				zero? (w0 and 000FFFFFh)
			][
				return load-inf sign
			]
			return load-nan
		]

		expo: (w0 and 7FF00000h) >>> 20
		manh: w0 and 000FFFFFh
		manl: d/int1

		if all [expo = 0 manh = 0 manl = 0][
			big: as bigfloat! bigint/load-int 0
			big/used: 1
			big/sign: sign
			big/prec: default-prec
			return big
		]

		big: as bigfloat! bigint/alloc* 4
		big/used: 3
		big/sign: sign
		big/prec: default-prec
		p: big/data

		manh: (1 << 31) or (manh << 11) or (manl >> 21)
		manl: manl << 11
		if expo = 0 [
			expo: 1
			until [
				manh: (manh << 1) or (manl >> 31)
				manl: manl << 1
				expo: expo - 1
				(manh and 80000000h) <> 0
			]
		]
		expo: expo - 1022
		sc: (64 * 32 + expo) % 32
		expo: (64 * 32 + expo) / 32 - 64 + 1
		either sc = 0 [
			p/3: manh
			p/2: manl
			p/1: 0
			expo: expo - 1
		][
			p/3: manh >>> (32 - sc)
			p/2: (manh << sc) or (manl >>> (32 - sc))
			p/1: manl << sc
		]
		;print-line ["p/3: " p/3 " p/2: " p/2 " p/1: " p/1]
		big/expo: expo
		big
	]

	free*: func [big [bigfloat!]][
		if big <> null [free as byte-ptr! big]
	]

	#if debug? = yes [
		dump: func [
			big			[bigfloat!]
			/local
				p		[int-ptr!]
		][
			print-line [lf "===============dump bigfloat!==============="]
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
			print-line [lf "=============dump bigfloat! end============="]
		]
	]

]

big: bigfloat/load-float 0.0
bigfloat/dump big
bigfloat/free* big
big: bigfloat/load-float 1.0
bigfloat/dump big
bigfloat/free* big
big: bigfloat/load-float 2.0
bigfloat/dump big
bigfloat/free* big
big: bigfloat/load-float 0.1
bigfloat/dump big
bigfloat/free* big
big: bigfloat/load-float 0.01
bigfloat/dump big
bigfloat/free* big
