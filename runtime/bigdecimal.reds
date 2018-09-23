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
		/local
			bused			[integer!]
			pb				[int-ptr!]
	][
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
		bigint/modulo as bigint! big1 as bigint! big2 iR free?
	]

	modulo-int: func [
		big1				[bigdecimal!]
		int					[integer!]
		iR					[int-ptr!]
		free?				[logic!]
		return:				[logic!]
	][
		bigint/modulo-int as bigint! big1 int iR free?
	]

	modulo-uint: func [
		big1				[bigdecimal!]
		uint				[integer!]
		iR					[int-ptr!]
		free?				[logic!]
		return:				[logic!]
	][
		bigint/modulo-uint as bigint! big1 uint iR free?
	]

	#if debug? = yes [
		dump: func [
			big				[bigdecimal!]
		][
			bigint/dump as bigint! big
		]
	]

]
