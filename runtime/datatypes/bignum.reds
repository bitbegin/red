Red/System [
	Title:   "bignum! type defination"
	Author:  "bitbegin"
	File: 	 %bignum.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

bignum: context [
	verbose: 0

	expand-float: func [
		str			[c-string!]
		slen		[integer!]
		iBuff		[int-ptr!]
		iLen		[int-ptr!]
		iPtLen		[int-ptr!]
		return:		[logic!]
		/local
			bak		[c-string!]
			len		[integer!]
			pos		[integer!]
			dot?	[logic!]
			dotp	[integer!]
			exp?	[logic!]
			exp		[integer!]
			expp	[integer!]
			esign	[integer!]
			intLen	[integer!]
			ptLen	[integer!]
			nptLen	[integer!]
			total	[integer!]
			buffer	[byte-ptr!]
	][
		len: length? str
		if slen > 0 [
			len: either len < slen [len][slen]
		]
		bak: str
		pos: 1
		dot?: false
		exp?: false
		until [
			if str/1 = #"." [
				either dot? [
					return false
				][
					dot?: true
					dotp: pos
				]
			]
			if any [str/1 = #"e" str/1 = #"E"][
				exp?: true
				expp: pos
				exp: 0
				esign: 1
				pos: pos + 1
				str: str + 1
				if pos > len [return false]
				if str/1 = #"-" [esign: -1 pos: pos + 1 str: str + 1]
				if str/1 = #"+" [esign: 1 pos: pos + 1 str: str + 1]
				if pos > len [return false]
				while [pos <= len] [
					if any [str/1 < #"0" str/1 > #"9"][return false]
					exp: exp * 10 + as integer! (str/1 - #"0")
					pos: pos + 1
					str: str + 1
				]
			]

			pos: pos + 1
			str: str + 1
			pos > len
		]

		either exp? [
			either dot? [
				intLen: dotp - 1
				ptLen: expp - dotp - 1
			][
				intLen: expp - 1
				ptLen: 0
			]
			either esign = 1 [
				nptLen: either ptLen < exp [exp][ptLen]
				total: intLen + nptLen
			][
				nptLen: exp + ptLen
				total: intLen + ptLen + exp
			]
		][
			either dot? [
				intLen: dotp - 1
				ptLen: len - dotp
			][
				intLen: len
				ptLen: 0
			]
			nptLen: ptLen
			total: intLen + ptLen
		]

		buffer: allocate total
		set-memory buffer #"0" total
		copy-memory buffer as byte-ptr! bak intLen
		copy-memory buffer + intLen as byte-ptr! bak + dotp ptLen

		iBuff/value: as integer! buffer
		iLen/value: total
		iPtLen/value: nptLen
		true
	]

	make-at: func [
		slot		[red-value!]
		size 		[integer!]								;-- number of bytes to pre-allocate
		return:		[red-bignum!]
		/local 
			big		[red-bignum!]
	][
		big: as red-bignum! slot
		big/header: TYPE_BIGNUM
		big/value: null
		big/point: 0
		big
	]

	make-in: func [
		parent		[red-block!]
		size		[integer!]
		return:		[red-bignum!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/make-in"]]
		
		make-at ALLOC_TAIL(parent) size
	]

	load-int: func [
		int			[integer!]
		return:		[red-bignum!]
		/local
			big		[red-bignum!]
	][
		big: make-at stack/push* 2
		big/value: _bignum/load-int int
		big
	]

	load-bn: func [
		bn			[bignum!]
		point		[integer!]
		return:		[red-bignum!]
		/local
			big		[red-bignum!]
	][
		big: make-at stack/push* 2
		big/value: bn
		big/point: point
		big
	]

	load-in: func [
		src			[byte-ptr!]
		size		[integer!]
		ptLen		[integer!]
		blk			[red-block!]
		cstr?		[logic!]
		radix		[integer!]
		return:		[red-bignum!]
		/local
			slot	[red-value!]
			big		[red-bignum!]
	][
		slot: either null = blk [stack/push*][ALLOC_TAIL(blk)]
		big: make-at slot size
		either cstr? [
			big/value: _bignum/load-str as c-string! src size radix
		][
			big/value: _bignum/load-bin src size
		]
		big/point: ptLen
		big
	]

	load: func [
		src			[byte-ptr!]
		size		[integer!]
		ptLen		[integer!]
		cstr?		[logic!]
		radix		[integer!]
		return:		[red-bignum!]
	][
		load-in src size ptLen null cstr? radix
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
			fl		[red-float!]
			fl-buf	[c-string!]
			iBuff	[integer!]
			iLen	[integer!]
			iPtLen	[integer!]
			str		[red-string!]
			s		[series!]
			unit	[integer!]
			p		[byte-ptr!]
			len		[integer!]
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
			TYPE_FLOAT [
				fl: as red-float! spec
				fl-buf: float/form-float fl/value 1
				print-line fl-buf
				iBuff: 0
				iLen: 0
				iPtLen: 0
				if false = expand-float fl-buf -1 :iBuff :iLen :iPtLen [
					fire [TO_ERROR(math overflow)]
				]
				big: load as byte-ptr! iBuff iLen iPtLen true 10
				free as byte-ptr! iBuff
			]
			TYPE_STRING [
				str: as red-string! spec
				s: GET_BUFFER(str)
				unit: GET_UNIT(s)
				p: (as byte-ptr! s/offset) + (str/head << log-b unit)
				len: (as-integer s/tail - p) >> log-b unit
				big: load p len 0 true 10
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
					big: load head size 0 false 0
				]
			]
			default [fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_BIGNUM spec]]
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
			rsize	[integer!]
			itmp	[integer!]
			tmp		[byte-ptr!]
			tsize	[integer!]
			bytes	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/serialize"]]

		int-big: big/value
		p: as byte-ptr! int-big/data
		either int-big/used = 0 [
			size: 1
		][
			size: int-big/used * 4
		]

		rsize: 0
		itmp: 0
		if not _bignum/write-string int-big 10 :itmp :rsize [
			fire [TO_ERROR(math overflow)]
		]
		tmp: as byte-ptr! itmp
		size: rsize
		p: tmp + 4

		string/concatenate-literal buffer "make bignum! "
		part: part - 13

		bytes: 0
		if size > 30 [
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: part - 1
		]

		loop size - 1 [
			string/append-char GET_BUFFER(buffer) as-integer p/1
			bytes: bytes + 1
			if bytes % 32 = 0 [
				string/append-char GET_BUFFER(buffer) as-integer lf
				part: part - 1
			]
			part: part - 1
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

		serialize big buffer no no no arg part no
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
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/mold"]]

		serialize big buffer only? all? flat? arg part yes
	]

	do-math: func [
		type		[math-op!]
		return:		[red-value!]
		/local
			left	[red-bignum!]
			right	[red-bignum!]
			int		[red-integer!]
			iB		[integer!]
			big		[red-bignum!]
	][
		left: as red-bignum! stack/arguments
		right: left + 1

		assert TYPE_OF(left) = TYPE_BIGNUM

		assert any [
			TYPE_OF(right) = TYPE_INTEGER
			TYPE_OF(right) = TYPE_BIGNUM
		]

		switch TYPE_OF(right) [
			TYPE_INTEGER [
				int: as red-integer! right
				switch type [
					OP_ADD [
						big: load-bn _bignum/add-int left/value int/value false 0
					]
					OP_SUB [
						big: load-bn _bignum/sub-int left/value int/value false 0
					]
					OP_MUL [
						big: load-bn _bignum/mul-int left/value int/value false 0
					]
					OP_DIV [
						if int/value = 0 [
							fire [TO_ERROR(math zero-divide)]
						]
						iB: 0
						if false = _bignum/div-int left/value int/value :iB null false [
							fire [TO_ERROR(math overflow)]
						]
						big: load-bn as bignum! iB 0
					]
					OP_REM [
						if int/value = 0 [
							fire [TO_ERROR(math zero-divide)]
						]
						iB: 0
						if false = _bignum/div-int left/value int/value null :iB false [
							fire [TO_ERROR(math overflow)]
						]
						big: load-bn as bignum! iB 0
					]
				]
			]
			TYPE_BIGNUM [
				switch type [
					OP_ADD [
						big: load-bn _bignum/add left/value right/value false 0
					]
					OP_SUB [
						big: load-bn _bignum/sub left/value right/value false 0
					]
					OP_MUL [
						big: load-bn _bignum/mul left/value right/value false 0
					]
					OP_DIV [
						if _bignum/bn-zero? right/value [
							fire [TO_ERROR(math zero-divide)]
						]
						iB: 0
						if false = _bignum/div left/value right/value :iB null false [
							fire [TO_ERROR(math overflow)]
						]
						big: load-bn as bignum! iB 0
					]
					OP_REM [
						if _bignum/bn-zero? right/value [
							fire [TO_ERROR(math zero-divide)]
						]
						iB: 0
						if false = _bignum/div left/value right/value null :iB false [
							fire [TO_ERROR(math overflow)]
						]
						big: load-bn as bignum! iB 0
					]
				]
			]
		]
		SET_RETURN(big)
	]

	compare*: func [
		value1		[red-bignum!]						;-- first operand
		value2		[red-bignum!]						;-- second operand
		op			[integer!]						;-- type of comparison
		return:		[integer!]
		/local
			res		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/compare"]]

		if all [
			op = COMP_STRICT_EQUAL
			TYPE_OF(value1) <> TYPE_OF(value2)
		][return 1]

		switch op [
			COMP_EQUAL		[res: _bignum/compare value1/value value2/value]
			COMP_NOT_EQUAL 	[res: not _bignum/compare value1/value value2/value]
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
			bn		[bignum!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/absolute"]]

		big: as red-bignum! stack/arguments
		bn: big/value
		bn/sign: 1
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

	multiply: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bignum/multiply"]]
		as red-value! do-math OP_MUL
	]

	negate: func [
		big			[red-bignum!]
		return:		[red-value!]
		/local
			bn		[bignum!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/complement"]]

		bn: big/value
		either bn/sign = 1 [
			bn/sign: -1
		][
			bn/sign: 1
		]
		as red-value! big
	]

	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bignum/remainder"]]
		as red-value! do-math OP_REM
	]

	subtract: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bignum/subtract"]]

		as red-value! do-math OP_SUB
	]

	swap: func [
		big1		[red-bignum!]
		big2		[red-bignum!]
		return:		[red-bignum!]
		/local
			value	[bignum!]
			point	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/swap"]]

		value: big1/value
		point: big1/point
		big1/value: big2/value
		big1/point: big2/point
		big2/value: value
		big2/point: point
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