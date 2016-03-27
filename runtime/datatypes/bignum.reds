Red/System []

bignum: context [
	verbose: 1

	;--- Actions ---

	make: func [
		proto	[red-value!]
		spec	[red-value!]
		return:	[red-bignum!]
		/local
			big	  [red-bignum!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bignum/make"]]

		big: as red-bignum! string/make proto spec
		set-type as red-value! big TYPE_BIGNUM
		big
	]

	init: does [
		datatype/register [
			TYPE_BIGNUM
			TYPE_STRING
			"bignum!"
			;-- General actions --
			:make
			INHERIT_ACTION	;random
			null			;reflect
			null;:to
			null;:form
			null;:mold
			INHERIT_ACTION	;eval-path
			null			;set-path
			null;:compare
			;-- Scalar actions --
			null			;absolute
			null			;add
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
