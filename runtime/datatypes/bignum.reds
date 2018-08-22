Red/System [
	Title:   "bignum! type defination"
	Author:  "bitbegin"
	File: 	 %bignum.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

red-bignum: context [
	verbose: 0

	make-at: func [
		slot		[red-value!]
		size 		[integer!]								;-- number of bytes to pre-allocate
		return:		[red-bignum!]
		/local 
			big		[red-bignum!]
	][
		big: as red-bignum! slot
		big/header: TYPE_BIGNUM
		big/int: null
		big/fact: null
		big
	]

	make-in: func [
		parent		[red-block!]
		size		[integer!]
		return:		[red-bignum!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bin/make-in"]]
		
		make-at ALLOC_TAIL(parent) size
	]

	load-int: func [
		int			[integer!]
		return:		[red-bignum!]
		/local
			big		[red-bignum!]
	][
		big: make-at stack/push* 2
		big/int: bignum/load-int int
	]

	load-bn: func [
		big			[bignum!]
		return:		[red-bignum!]
		/local
			big		[red-bignum!]
	][
		big: make-at stack/push* 2
		big/int: big
	]

	load-in: func [
		src			[byte-ptr!]
		size		[integer!]
		blk			[red-block!]
		cstr?		[logic!]
		return:		[red-bignum!]
		/local
			slot	[red-value!]
			big		[red-bignum!]
	][
		slot: either null = blk [stack/push*][ALLOC_TAIL(blk)]
		big: make-at slot size
		big/int: bignum/load-bin src size
		big
	]

	load: func [
		src			[byte-ptr!]
		size		[integer!]
		cstr?		[logic!]
		return:		[red-bignum!]
	][
		load-in src size null cstr?
	]

	make: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-bignum!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/make"]]
		as red-bignum! to proto spec type
	]

	to: func [
		proto		[red-value!]
		spec		[red-value!]
		type		[integer!]								;-- target type
		return:		[red-value!]
		/local
			int		[red-integer!]
			big		[red-bignum!]
			bin		[red-binary!]
			sbin	[series!]
			head	[byte-ptr!]
			tail	[byte-ptr!]
			size	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/to"]]

		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				big: load-int int/value
			]
			TYPE_BINARY [
				bin: as red-binary! spec
				sbin: GET_BUFFER(bin)
				head: (as byte-ptr! sbin/offset) + bin/head
				tail: as byte-ptr! sbin/tail
				size: as-integer tail - head
				either size = 0 [
					big: load-int 0
				][
					big: load head size false
				]
			]
			default [--NOT_IMPLEMENTED--]
		]

		as red-value! big
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
			int-big	[bignum!]
			p		[byte-ptr!]
			size	[integer!]
			bytes	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/serialize"]]

		int-big: big/int
		p: as byte-ptr! int-big/data
		either int-big/used = 0 [
			size: 1
		][
			size: int-big/used * 4
		]
		p: p + size

		bytes: 0
		if size > 30 [
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: part - 1
		]

		if int-big/sign = -1 [
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

	serialize-10: func [
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
			int-big	[bignum!]
			p		[byte-ptr!]
			size	[integer!]
			rsize	[integer!]
			tmp		[byte-ptr!]
			bytes	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/serialize"]]

		int-big: big/int
		p: as byte-ptr! int-big/data
		either int-big/used = 0 [
			size: 1
		][
			size: int-big/used * 4
		]

		rsize: 0
		tmp: allocate size * 32 / 2 + 3
		if 0 <> write-string int-big 10 tmp size * 10 :rsize [
			print "something wrong!"
		]

		size: rsize
		p: tmp

		bytes: 0
		if size > 30 [
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: part - 1
		]

		if int-big/sign = -1 [
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

	form: func [
		big		[red-bignum!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/form"]]

		serialize-10 big buffer no no no arg part no
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

		serialize-10 big buffer only? all? flat? arg part yes
	]

	swap: func [
		big1		[red-bignum!]
		big2		[red-bignum!]
		return:		[red-bignum!]
		/local
			int		[bignum!]
			fact	[bignum!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/swap"]]

		int: big1/int
		fact: big1/fact
		big1/int: big2/int
		big1/fact: big2/fact
		big2/int: int
		big2/fact: fact
		big1
	]

	do-math: func [
		type		[math-op!]
		return:		[red-value!]
		/local
			left	[red-bignum!]
			right	[red-bignum!]
			int		[red-integer!]
			big		[red-bignum!]
	][
		left: as red-bignum! stack/arguments
		right: left + 1

		assert TYPE_OF(left) = TYPE_BIGNUM

		assert any [
			TYPE_OF(right) = TYPE_INTEGER
			TYPE_OF(right) = TYPE_BIGNUM
		]
		
		make-at as red-value! :big 1
		switch TYPE_OF(right) [
			TYPE_INTEGER [
				int: as red-integer! right
				switch type [
					OP_ADD [
						big: load-bn bignum/add-int left/int int/value
					]
					OP_SUB [
						big: load-bn bignum/sub-int left/int int/value
					]
					OP_MUL [
						big: load-bn bignum/mul-int left/int int/value
					]
					OP_DIV [
						big: load-bn bignum/div-int left/int int/value false
					]
					OP_REM [
						big: load-int bignum/module-int left/int int/value
					]
				]
			]
			TYPE_BIGNUM [
				switch type [
					OP_ADD [
						big: load-bn bignum/add left/int right/int
					]
					OP_SUB [
						big: load-bn bignum/sub left/int right/int
					]
					OP_MUL [
						big: load-bn bignum/mul left/int right/int
					]
					OP_DIV [
						big: load-bn bignum/div left/int right/int false
					]
					OP_REM [
						big: load-bn bignum/module left/int right/int
					]
				]
			]
		]
		SET_RETURN(big)
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
			:to
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