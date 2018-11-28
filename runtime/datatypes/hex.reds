Red/System [
	Title:   "Hex datatype runtime functions"
	Author:  "Xie Qingtian"
	File: 	 %hex.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

hex: context [
	verbose: 0

	make-at: func [
		slot		[red-value!]
		return:		[red-bigint!]
		/local
			big		[red-bigint!]
	][
		big: red-bigint/make-at slot
		big/header: TYPE_HEX
		big
	]

	load-str: func [
		slot	[red-value!]
		p		[byte-ptr!]
		len		[integer!]
		unit	[integer!]
		/local
			bint	[bigint!]
			big		[red-bigint!]
	][
		assert len > 0
		bint: bigint/load-str as c-string! p len 16
		big: make-at slot
		big/node: red-bigint/to-node bint
	]

	;--- Actions ---

	make: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-bigint!]
	][
		#if debug? = yes [if verbose > 0 [print-line "hex/make"]]
		as red-bigint! to proto spec type
	]

	to: func [
		proto		[red-value!]
		spec		[red-value!]
		type		[integer!]								;-- target type
		return:		[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "hex/to"]]

		red-bigint/to proto spec type
		proto/header: TYPE_HEX
		proto
	]

	mold: func [
		big		[red-bigint!]
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
		#if debug? = yes [if verbose > 0 [print-line "hex/mold"]]

		red-bigint/serialize big buffer flat? arg part yes
	]

	init: does [
		datatype/register [
			TYPE_HEX
			TYPE_BIGINT
			"hex!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			:to
			INHERIT_ACTION	;form
			:mold
			null			;eval-path
			null			;set-path
			INHERIT_ACTION	;compare
			;-- Scalar actions --
			INHERIT_ACTION	;absolute
			INHERIT_ACTION	;add
			INHERIT_ACTION	;divide
			INHERIT_ACTION	;multiply
			null			;negate
			INHERIT_ACTION	;power
			INHERIT_ACTION	;remainder
			INHERIT_ACTION	;round
			INHERIT_ACTION	;subtract
			INHERIT_ACTION	;even?
			INHERIT_ACTION	;odd?
			;-- Bitwise actions --
			INHERIT_ACTION	;and~
			INHERIT_ACTION	;complement
			INHERIT_ACTION	;or~
			INHERIT_ACTION	;xor~
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