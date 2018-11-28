Red/System [
	Title:   "bigint datatype runtime functions"
	Author:  "Bitbegin, Xie Qingtian"
	File: 	 %bigint.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

red-bigint: context [
	verbose: 0

	serialize: func [
		big			[red-bigint!]
		buffer		[red-string!]
		flat?		[logic!]
		arg			[red-value!]
		part		[integer!]
		mold?		[logic!]
		return: 	[integer!]
		/local
			s		[series!]
			ibuf	[integer!]
			ilen	[integer!]
			ret		[logic!]
			n		[integer!]
			i		[integer!]
			bytes	[integer!]
			pos		[integer!]
			buf		[byte-ptr!]
	][
		;;@@ TBD Optimization, the string is ASCII only

		s: GET_BUFFER(big)
		ibuf: 0
		ilen: 0
		either mold? [
			ret: bigint/form as bigint! s/offset 16 :ibuf :ilen
		][
			ret: bigint/form as bigint! s/offset 10 :ibuf :ilen
		]
		unless ret [fire [TO_ERROR(math overflow)]]
		buf: as byte-ptr! ibuf
		pos: 1
		n: ilen
		if ilen > 64 [n: n + (ilen / 64) + 4]

		s: GET_BUFFER(buffer)
		s: expand-series s s/size + n				;-- allocate enough memory

		if buf/pos = #"-" [
			string/append-char s as-integer #"-"
			part: part - 1
			pos: pos + 1
			ilen: ilen - 1
		]

		if mold? [
			string/concatenate-literal buffer "0x"
			part: part - 2
		]

		bytes: 0
		loop ilen [
			string/append-char GET_BUFFER(buffer) as-integer buf/pos
			bytes: bytes + 1
			if bytes % 64 = 0 [
				string/append-char GET_BUFFER(buffer) as-integer lf
				part: part - 1
			]
			part: part - 1
			if all [OPTION?(arg) part <= 0][free buf return part]
			pos: pos + 1
		]
		if all [ilen > 62 bytes % 64 <> 0] [
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: part - 1
		]
		free buf
		part
	]

	do-math: func [
		type		[math-op!]
		return:		[red-value!]
		/local
			left	[red-bigint!]
			right	[red-bigint!]
			s1		[series!]
			s2		[series!]
			big		[red-bigint!]
			bint	[bigint!]
			int		[red-integer!]
			ret		[integer!]
	][
		left: as red-bigint! stack/arguments
		s1: GET_BUFFER(left)
		right: left + 1

		assert any [
			TYPE_OF(right) = TYPE_INTEGER
			TYPE_OF(right) = TYPE_BIGINT
			TYPE_OF(right) = TYPE_HEX
		]

		big: as red-bigint! stack/push*
		switch TYPE_OF(right) [
			TYPE_INTEGER [
				int: as red-integer! right
				switch type [
					OP_ADD [
						bint: bigint/add-int as bigint! s1/offset int/value false
					]
					OP_SUB [
						bint: bigint/sub-int as bigint! s1/offset int/value false
					]
					OP_MUL [
						bint: bigint/mul-int as bigint! s1/offset int/value false
					]
					OP_DIV [
						bint: bigint/div-int as bigint! s1/offset int/value false
					]
					OP_REM [
						bint: bigint/remainder-int as bigint! s1/offset int/value false
					]
					OP_AND [
						bint: bigint/and-uint* as bigint! s1/offset int/value false
					]
					OP_OR  [
						bint: bigint/or-uint* as bigint! s1/offset int/value false
					]
					OP_XOR [
						bint: bigint/xor-uint* as bigint! s1/offset int/value false
					]
				]
			]
			TYPE_BIGINT TYPE_HEX [
				s2: GET_BUFFER(right)
				switch type [
					OP_ADD [
						bint: bigint/add as bigint! s1/offset as bigint! s2/offset false
					]
					OP_SUB [
						bint: bigint/sub as bigint! s1/offset as bigint! s2/offset false
					]
					OP_MUL [
						bint: bigint/mul as bigint! s1/offset as bigint! s2/offset false
					]
					OP_DIV [
						bint: bigint/div as bigint! s1/offset as bigint! s2/offset false
					]
					OP_REM [
						bint: bigint/remainder as bigint! s1/offset as bigint! s2/offset false
					]
					OP_AND [
						bint: bigint/and* as bigint! s1/offset as bigint! s2/offset false
					]
					OP_OR  [
						bint: bigint/or* as bigint! s1/offset as bigint! s2/offset false
					]
					OP_XOR [
						bint: bigint/xor* as bigint! s1/offset as bigint! s2/offset false
					]
				]
			]
		]
		big/header: TYPE_OF(left)
		big/node: to-node bint
		SET_RETURN(big)
	]

	make-at: func [
		slot		[red-value!]
		return:		[red-bigint!]
		/local
			big		[red-bigint!]
	][
		;-- make bigint!
		big: as red-bigint! slot
		big/header: TYPE_UNSET
		big/node:	null
		big/header: TYPE_BIGINT

		big
	]

	to-node: func [
		bint		[bigint!]
		return:		[node!]
		/local
			len		[integer!]
			node	[node!]
			s		[series!]
			p		[byte-ptr!]
	][
		len: 4 * either bint/used >= 0 [bint/used][ 0 - bint/used]
		len: len + size? bigint!
		node: alloc-series len 1 0
		s: as series! node/value
		p: as byte-ptr! s/offset
		copy-memory p as byte-ptr! bint len
		bigint/free* bint
		node
	]

	;--- Actions ---

	make: func [
		proto		[red-value!]
		spec		[red-value!]
		type		[integer!]
		return:		[red-bigint!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bigint/make"]]
		as red-bigint! to proto spec type
	]

	to: func [
		proto		[red-value!]
		spec		[red-value!]
		type		[integer!]								;-- target type
		return:		[red-value!]
		/local
			int		[red-integer!]
			bint	[bigint!]
			bin		[red-binary!]
			big		[red-bigint!]
			sbin	[series!]
			pbig	[byte-ptr!]
			head	[byte-ptr!]
			tail	[byte-ptr!]
			len		[integer!]
			size	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bigint/to"]]

		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				bint: bigint/load-int int/value
			]
			TYPE_BINARY [
				bin: as red-binary! spec
				sbin: GET_BUFFER(bin)
				head: (as byte-ptr! sbin/offset) + bin/head
				tail: as byte-ptr! sbin/tail
				size: as-integer tail - head
				bint: bigint/load-bin head size
			]
			TYPE_HEX [
				big: as red-bigint! spec
				make-at as red-value! proto
				big: as red-bigint! proto
				big/node: copy-series GET_BUFFER(big)
				return proto
			]
			default [fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_BIGINT spec]]
		]
		make-at as red-value! proto
		big: as red-bigint! proto
		big/node: to-node bint
		proto
	]

	form: func [
		big			[red-bigint!]
		buffer		[red-string!]
		arg			[red-value!]
		part 		[integer!]
		return:		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bigint/form"]]

		serialize big buffer yes arg part no
	]

	mold: func [
		big			[red-bigint!]
		buffer		[red-string!]
		only?		[logic!]
		all?		[logic!]
		flat?		[logic!]
		arg			[red-value!]
		part		[integer!]
		indent		[integer!]
		return:		[integer!]
		/local
			formed	[c-string!]
			s		[series!]
			unit	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bigint/mold"]]

		serialize big buffer flat? arg part no
	]

	compare: func [
		value1		[red-bigint!]						;-- first operand
		value2		[red-bigint!]						;-- second operand
		op			[integer!]						;-- type of comparison
		return:		[integer!]
		/local
			res		[integer!]
			int		[red-integer!]
			s1		[series!]
			s2		[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bigint/compare"]]

		if all [
			any [op = COMP_FIND op = COMP_STRICT_EQUAL]
			TYPE_OF(value1) <> TYPE_OF(value2)
		][return 1]

		s1: GET_BUFFER(value1)
		switch TYPE_OF(value2) [
			TYPE_BIGINT TYPE_HEX [
				s2: GET_BUFFER(value2)
				res: bigint/compare as bigint! s1/offset as bigint! s2/offset
			]
			TYPE_INTEGER TYPE_CHAR [
				int: as red-integer! value2
				res: bigint/compare-int as bigint! s1/offset int/value
			]
			default [RETURN_COMPARE_OTHER]
		]
		SIGN_COMPARE_RESULT(res 0)
	]

	absolute: func [
		return:		[red-bigint!]
		/local
			big		[red-bigint!]
			s		[series!]
			bint	[bigint!]
			ret		[red-bigint!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bigint/absolute"]]
		big: as red-bigint! stack/arguments
		s: GET_BUFFER(big)
		bint: bigint/absolute* as bigint! s/offset false
		ret: as red-bigint! stack/push*
		make-at as red-value! ret
		ret/node: to-node bint
		stack/set-last as red-value! ret
		ret
	]

	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bigint/add"]]

		as red-value! do-math OP_ADD
	]

	divide: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bigint/divide"]]

		as red-value! do-math OP_DIV
	]

	multiply: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bigint/multiply"]]
		as red-value! do-math OP_MUL
	]

	subtract: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bigint/subtract"]]

		as red-value! do-math OP_SUB
	]


	and~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bigint/and~"]]
		as red-value! do-math OP_AND
	]

	or~: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bigint/or~"]]
		as red-value! do-math OP_OR
	]

	xor~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bigint/xor~"]]
		as red-value! do-math OP_XOR
	]

	even?: func [
		big			[red-bigint!]
		return:		[logic!]
		/local
			s		[series!]
	][
		s: GET_BUFFER(big)
		bigint/even?* as bigint! s/offset
	]

	odd?: func [
		big			[red-bigint!]
		return:		[logic!]
		/local
			s		[series!]
	][
		s: GET_BUFFER(big)
		bigint/odd?* as bigint! s/offset
	]

	negate: func [
		return:		[red-bigint!]
		/local
			big		[red-bigint!]
			s		[series!]
			bint	[bigint!]
			ret		[red-bigint!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bigint/negate"]]
		big: as red-bigint! stack/arguments
		s: GET_BUFFER(big)
		bint: bigint/negative* as bigint! s/offset false
		ret: as red-bigint! stack/push*
		make-at as red-value! ret
		ret/node: to-node bint
		stack/set-last as red-value! ret
		ret
	]

	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bigint/remainder"]]
		as red-value! do-math OP_REM
	]

	init: does [
		datatype/register [
			TYPE_BIGINT
			TYPE_VALUE
			"bigint!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			:to
			:form
			:mold
			null			;eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			:absolute
			:add
			:divide
			:multiply
			:negate
			null			;power
			:remainder
			null			;round
			:subtract
			:even?
			:odd?
			;-- Bitwise actions --
			:and~
			null			;complement
			:or~
			:xor~
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
			null			;swap
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