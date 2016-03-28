Red/System [
	Title:   "Bignum! datatype runtime functions"
	Author:  "bitbegin"
	File: 	 %bignum.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Nenad Rakocevic & Qingtian Xie & bitbegin. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

bignum: context [
	verbose: 1
	
	push: func [
		big [red-bignum!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/push"]]

		copy-cell as red-value! big stack/push*
	]
	
	;--- Actions ---

	make: func [
		proto	[red-value!]
		spec	[red-value!]
		return:	[red-bignum!]
		/local
			str		[red-string!]
			s		[series!]
			big	 	[red-bignum!]
			head	[byte-ptr!]
			tail	[byte-ptr!]
			size	[integer!]
			p		[byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/make"]]

		switch TYPE_OF(spec) [
			TYPE_STRING [
				str: as red-string! spec
				s: GET_BUFFER(str)
				head: (as byte-ptr! s/offset) + str/head
				tail: as byte-ptr! s/tail
				size: as integer! tail - head
					
				big: as red-bignum! stack/push*
				big/header: TYPE_BIGNUM
				big/head: 	0
				big/node: 	alloc-bytes size
			
				s: GET_BUFFER(big)
				p: (as byte-ptr! s/offset) + big/head
				s/tail: as cell! p
								
				either head/1 = #"-" [
					big/sign: -1
					head: head + 1
					size: size - 1
				][
					big/sign: 1
				]
				s/tail: as cell! ((as integer! s/tail) + size)
								
				loop size [
					p/1: head/1 - #"0"
					p: p + 1
					head: head + 1
				]
			]
			default [--NOT_IMPLEMENTED--]
		]
		big
	]

	mold: func [
		big		[red-bignum!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]		
		return: [integer!]
		/local
			s      [series!]
			bytes  [integer!]
			head   [byte-ptr!]
			tail   [byte-ptr!]
			size   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/mold"]]

		s: GET_BUFFER(big)
		head: (as byte-ptr! s/offset) + big/head
		tail: as byte-ptr! s/tail
		size: as integer! tail - head
		
		print-line s/tail
		print-line s/offset
		
		if size > 30 [
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: part - 1
		]
		
		either big/sign = -1 [
			bytes: 1
			string/append-char GET_BUFFER(buffer) as-integer #"-"
		][
			bytes: 0
		] 

		part: part - 2
		while [head < tail][
			string/append-char GET_BUFFER(buffer) as integer! (head/1 + #"0")
			bytes: bytes + 1
			if bytes % 32 = 0 [
				string/append-char GET_BUFFER(buffer) as-integer lf
				part: part - 1
			]
			part: part - 2
			if all [OPTION?(arg) part <= 0][return part]
			head: head + 1
		]
		if all [size > 30 bytes % 32 <> 0] [
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: part - 1
		]
		part - 1
	]
	
	add: func [return: [red-value!]
		/local
			left		[red-bignum!]
			right		[red-bignum!]
			big			[red-bignum!]
			s      		[series!]
			left-head   [byte-ptr!]
			left-tail   [byte-ptr!]
			right-head  [byte-ptr!]
			right-tail  [byte-ptr!]
			left-size	[integer!]
			right-size	[integer!]
			size		[integer!]
			c			[byte!]
			p			[byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/add"]]
		
		left: as red-bignum! stack/arguments
		right: left + 1
		
		s: GET_BUFFER(left)
		left-head: (as byte-ptr! s/offset) + left/head
		left-tail: as byte-ptr! s/tail
		left-size: as integer! left-tail - left-head
	
		s: GET_BUFFER(right)
		right-head: (as byte-ptr! s/offset) + right/head
		right-tail: as byte-ptr! s/tail
		right-size: as integer! right-tail - right-head
		
		size: either left-size < right-size [right-size + 1][left-size + 1]
			
		either left/sign <> right/sign [
			SET_RETURN(left)
		][
			big: as red-bignum! stack/push*
			big/header: TYPE_BIGNUM							;-- implicit reset of all header flags
			big/head: 	0
			big/node: 	alloc-bytes size
			big/sign:	left/sign
			
			s: GET_BUFFER(big)
			p: (as byte-ptr! s/offset) + big/head
			
			c: as byte! 0
			loop size [
				p/1: (c + left-head/1 + right-head/1) % 10
				c: (c + left-head/1 + right-head/1) / 10
				print-line as integer! p/1
				print-line as integer! c
				p: p + 1
				left-head: left-head + 1
				right-head: right-head + 1
			]
			s/tail: as cell! ((as integer! s/tail) + size)
			print-line s/tail
			print-line s/offset
			
			zero-justify big
			SET_RETURN(big)
		]
	]
	
	zero-justify: func [big [red-bignum!]
		/local
			s      		[series!]
			head  		[byte-ptr!]
			tail  		[byte-ptr!]
			size  		[integer!]
	][
		s: GET_BUFFER(big)
		head: (as byte-ptr! s/offset) + big/head
		tail: as byte-ptr! s/tail
		size: as integer! tail - head
		print-line size
		
		while [
			all [
				size <> 0
				tail/1 = as byte! 0
			]
		][
			print-line s/tail
			print-line tail
			print-line size
			s/tail: as cell! ((as integer! s/tail) - 1)
			tail: as byte-ptr! s/tail
			size: as integer! tail - head
		]
		
		s/tail: as cell! ((as integer! s/tail) + 1)
		
		if all [
			size = 0
			tail/1 = as byte! 0
		][
			big/sign: 1
		]
	]
	
	init: does [
		datatype/register [
			TYPE_BIGNUM
			TYPE_VALUE
			"bignum!"
			;-- General actions --
			:make
			INHERIT_ACTION	;random
			null			;reflect
			null;:to
			null;:form
			:mold
			INHERIT_ACTION	;eval-path
			null			;set-path
			null;:compare
			;-- Scalar actions --
			null			;absolute
			:add
			null			;divide
			null			;multiply
			null			;negate
			null			;power
			null			;remainder
			null			;round
			null			;subtract
			null			;even?
			null			;odd?
			;-- Bitwise actions --
			null;:and~
			null;:complement
			null;:or~
			null;:xor~
			;-- Series actions --
			null			;append
			INHERIT_ACTION	;at
			INHERIT_ACTION	;back
			null			;change
			INHERIT_ACTION	;clear
			INHERIT_ACTION	;copy
			INHERIT_ACTION	;find
			INHERIT_ACTION	;head
			INHERIT_ACTION	;head?
			INHERIT_ACTION	;index?
			null;:insert
			INHERIT_ACTION	;length?
			INHERIT_ACTION	;next
			INHERIT_ACTION	;pick
			INHERIT_ACTION	;poke
			null			;put
			INHERIT_ACTION	;remove
			INHERIT_ACTION	;reverse
			INHERIT_ACTION	;select
			INHERIT_ACTION	;sort
			INHERIT_ACTION	;skip
			INHERIT_ACTION	;swap
			INHERIT_ACTION	;tail
			INHERIT_ACTION	;tail?
			INHERIT_ACTION	;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			INHERIT_ACTION	;modify
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
