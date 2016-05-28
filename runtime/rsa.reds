Red/System [
	Title:   "RSA encrypt/decrypt"
	Author:  "bitbegin"
	File: 	 %rsa.reds
	Tabs:	 4
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

rsa: context [

	rsa-context!: alias struct! [
		ver			[integer!]
		len			[integer!]
		N			[red-bignum!]
		E			[red-bignum!]
		D			[red-bignum!]
		P			[red-bignum!]
		Q			[red-bignum!]
		DP			[red-bignum!]
		DQ			[red-bignum!]
		QP			[red-bignum!]
		RN			[red-bignum!]
		RP			[red-bignum!]
		RQ			[red-bignum!]
		Vi			[red-bignum!]
		Vf			[red-bignum!]
		padding		[integer!]
		hash_id		[integer!]
	]

	rsa-init:  func [
		ctx			[rsa-context!]
		padding		[integer!]
		hash_id		[integer!]
	][
		rsa-set-padding ctx padding hash_id
	]

	rsa-set-padding: func [
		ctx			[rsa-context!]
		padding		[integer!]
		hash_id		[integer!]
	][
		ctx/padding: padding
		ctx/hash_id: hash_id
	]

	rsa-check-pubkey: func [
		ctx			[rsa-context!]
		return:		[logic!]
		/local
			s	 	[series!]
			p		[int-ptr!]
			pn		[int-ptr!]
			pe		[int-ptr!]
			len		[integer!]
	][
		if any [
			ctx/N/used = 0
			ctx/E/used = 0
		][
			return false
		]
		if any [
			ctx/N/used = 0
			ctx/E/used = 0
		][
			return false
		]
		
		s: GET_BUFFER(ctx/N)
		pn: as int-ptr! s/offset
		s: GET_BUFFER(ctx/E)
		pe: as int-ptr! s/offset
		if any [
			(pn/1 and 1) = 0
			(pe/1 and 1) = 0
		][
			return false
		]
		
		len: bignum/bitlen ctx/N
		if any [
			len < 128
			len > bignum/BN_MAX_LIMB
		][
			return false
		]
		
		len: bignum/bitlen ctx/E
		if any [
			len < 2
			(bignum/compare E N) >= 0
		][
			return false
		]
		
		return true
	]

	rsa-check-privkey: func [
		ctx			[rsa-context!]
		return:		[logic!]
	][
		return true
	]

	rsa-public: func [
		ctx			[rsa-context!]
		input		[c-string!]
		output		[c-string!]
		/local
			ret		[red-integer!]
			olen	[red-integer!]
			T		[red-bignum!]
	][
		bignum/read-binary T input ctx/len
		
		if (bignum/compare T ctx/N) >= 0 [
			exit
		]
		
		olen: ctx/len
		bignum/exp-mod T ctx/E ctx/N ctx/RN T
		bignum/write-binary T output olen
	]
]
