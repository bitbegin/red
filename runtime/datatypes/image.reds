Red/System [
	Title:   "Image! datatype runtime functions"
	Author:  "Qingtian Xie"
	File:	 %image.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %image-crop.reds

image: context [
	verbose: 0

	acquire-buffer: func [
		img		[red-image!]
		bitmap	[int-ptr!]
		return: [int-ptr!]
		/local
			s	[series!]
	][
		s: GET_BUFFER(img)
		as int-ptr! s/offset
	]

	release-buffer: func [
		img		  [red-image!]
		bitmap	  [integer!]
		modified? [logic!]
	][
		if modified? [
			ownership/check as red-value! img words/_poke as red-value! img -1 -1
		]
	]

	get-pixel: func [
		img		[red-image!]
		offset	[integer!]
		return:	[integer!]
		/local
			s	[series!]
			p	[int-ptr!]
	][
		s: GET_BUFFER(img)
		p: (as int-ptr! s/offset) + offset
		assert p < as int-ptr! s/tail
		p/value
	]

	set-pixel: func [
		img		[red-image!]
		offset	[integer!]
		pixel	[integer!]
		/local
			s	[series!]
			p	[int-ptr!]
	][
		s: GET_BUFFER(img)
		p: (as int-ptr! s/offset) + offset
		assert p < as int-ptr! s/tail
		p/value: pixel
	]

	rs-pick: func [
		img		[red-image!]
		offset	[integer!]
		return: [red-tuple!]
		/local
			pixel [integer!]
	][
		pixel: get-pixel img offset
		tuple/rs-make [
			pixel and 00FF0000h >> 16
			pixel and FF00h >> 8
			pixel and FFh
			255 - (pixel >>> 24)
		]
	]

	set-many: func [
		words	[red-block!]
		img		[red-image!]
		size	[integer!]
		/local
			i [integer!]
	][
		i: 1
		while [i <= size][
			_context/set (as red-word! _series/pick as red-series! words i null) as red-value! rs-pick img i
			i: i + 1
		]
	]

	known-image?: func [
		data	[red-binary!]
		return: [logic!]
		/local
			p	[byte-ptr!]
	][
		p: binary/rs-head data
		any [
			all [										;-- PNG
				p/1 = #"^(89)"
				p/2 = #"P" p/3 = #"N" p/4 = #"G"
			]
			all [p/1 = #"^(FF)" p/2 = #"^(D8)" p/3 = #"^(FF)"]	;-- jpg/jpeg
			all [p/1 = #"B" p/2 = #"M"]					;-- BMP
			all [										;-- GIF
				p/1 = #"G" p/2 = #"I" p/3 = #"F"
				p/4 = #"8" p/5 = #"9" p/6 = #"a"
			]
		]
	]

	;-- from Red's image! format
	make-binary: func [
		img		[red-image!]
		width	[integer!]
		height	[integer!]
		bp		[byte-ptr!]
		/local
			size	[integer!]
			s		[series!]
			d		[byte-ptr!]
	][
		size: width * height * 4
		img/head: 0
		img/size: height << 16 or width
		img/node: alloc-bytes size
		img/header: TYPE_IMAGE							;-- implicit reset of all header flags
		s: GET_BUFFER(img)
		d: as byte-ptr! s/offset
		copy-memory d bp size
		s/tail: as cell! (as byte-ptr! s/tail) + size
	]

	resize: func [
		img		[red-image!]
		width	[integer!]
		height	[integer!]
		return: [red-image!]
		/local
			s		[series!]
			src		[int-ptr!]
			sw		[integer!]
			sh		[integer!]
			d		[int-ptr!]
			ret		[red-image!]
	][
		s: GET_BUFFER(img)
		src: as int-ptr! s/offset
		sw: IMAGE_WIDTH(img/size)
		sh: IMAGE_HEIGHT(img/size)
		d: image-crop/resize src sw sh width height
		if null? d [
			return as red-image! none-value
		]
		ret: as red-image! stack/push*
		make-binary ret width height as byte-ptr! d
		free as byte-ptr! d
		ret
	]

	clone: func [
		src		[red-image!]
		dst		[red-image!]
		part	[integer!]
		size	[red-pair!]
		part?	[logic!]
		return: [red-image!]
		/local
			width	[integer!]
			height	[integer!]
			offset	[integer!]
			s		[series!]
			ps		[byte-ptr!]
			pd		[byte-ptr!]
			x		[integer!]
			y		[integer!]
			w		[integer!]
			h		[integer!]
			size2	[integer!]
	][
		width: IMAGE_WIDTH(src/size)
		height: IMAGE_HEIGHT(src/size)
		offset: src/head

		if any [
			width <= 0
			height <= 0
		][
			dst/size: 0
			dst/header: TYPE_IMAGE
			dst/head: 0
			dst/node: null
			return dst
		]

		s: GET_BUFFER(src)
		ps: as byte-ptr! s/offset
		if all [zero? offset not part?][
			make-binary dst width height ps
			return dst
		]

		x: offset % width
		y: offset / width
		either all [part? TYPE_OF(size) = TYPE_PAIR][
			w: width - x
			h: height - y
			if size/x < w [w: size/x]
			if size/y < h [h: size/y]
		][
			either zero? part [
				w: 0 h: 0
			][
				either part < width [h: 1 w: part][
					h: part / width
					w: width
				]
			]
		]
		if any [
			w <= 0
			h <= 0
		][
			dst/size: 0
			dst/header: TYPE_IMAGE
			dst/head: 0
			dst/node: null
			return dst
		]
		size2: w * h * 4
		dst/size: h << 16 or w
		dst/header: TYPE_IMAGE
		dst/head: 0
		dst/node: alloc-bytes size2
		s: GET_BUFFER(dst)
		pd: as byte-ptr! s/offset
		image-crop/crop ps width height x y pd w h
		s/tail: as cell! (as byte-ptr! s/tail) + size2
		dst
	]

	make-rgba: func [
		img			[red-image!]
		width		[integer!]
		height		[integer!]
		rgba		[byte-ptr!]
		return:		[logic!]
		/local
			s		[series!]
			size	[integer!]
			data	[byte-ptr!]
	][
		if any [zero? width zero? height][
			img/header: TYPE_NONE
			return false
		]
		size: width * height * 4
		img/size: height << 16 or width
		img/header: TYPE_IMAGE
		img/head: 0
		img/node: alloc-bytes size
		s: GET_BUFFER(img)
		s/tail: as cell! (as byte-ptr! s/tail) + size
		data: as byte-ptr! s/offset
		unless null? rgba [
			copy-memory data rgba size
		]
		true
	]

	make-image: func [
		img			[red-image!]
		width		[integer!]
		height		[integer!]
		rgb			[byte-ptr!]
		alpha		[byte-ptr!]
		color		[red-tuple!]
		return:		[logic!]
		/local
			s		[series!]
			count	[integer!]
			size	[integer!]
			data	[int-ptr!]
			a		[integer!]
			r		[integer!]
			g		[integer!]
			b		[integer!]
	][
		if any [zero? width zero? height][
			img/header: TYPE_NONE
			return false
		]
		count: width * height
		size: count * 4
		img/size: height << 16 or width
		img/header: TYPE_IMAGE
		img/head: 0
		img/node: alloc-bytes size
		s: GET_BUFFER(img)
		s/tail: as cell! (as byte-ptr! s/tail) + size
		data: as int-ptr! s/offset
		either null? color [
			loop count [
				either null? alpha [a: 255][a: 255 - as-integer alpha/1 alpha: alpha + 1]
				either null? rgb [r: 255 g: 255 b: 255][
					r: as-integer rgb/1
					g: as-integer rgb/2
					b: as-integer rgb/3
					rgb: rgb + 3
				]
				data/value: r << 16 or (g << 8) or b or (a << 24)
				data: data + 1
			]
		][
			r: color/array1
			a: either TUPLE_SIZE?(color) = 3 [255][255 - (r >>> 24)]
			r: r >> 16 and FFh or (r and FF00h) or (r and FFh << 16) or (a << 24)
			loop count [
				data/value: r
				data: data + 1
			]
		]
		true
	]

	load-binary: func [
		data	[red-binary!]
		return: [red-image!]
		/local
			img	[red-image!]
	][
		either known-image? data [
			img: as red-image! stack/push*
			OS-image/load-binary img binary/rs-head data binary/rs-length? data
			img
		][as red-image! none-value]
	]

	push: func [
		img [red-image!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/push"]]

		copy-cell as red-value! img stack/push*
	]

	make-at: func [
		slot	[red-value!]
		src		[red-string!]
		return:	[red-image!]
	][
		unless OS-image/load-image as red-image! slot src [
			fire [TO_ERROR(access cannot-open) src]
		]
		as red-image! slot
	]

	delete: func [img [red-image!]][
		0
	]

	encode: func [
		image	[red-image!]
		dst		[red-value!]
		format	[integer!]
		return: [red-value!]
	][
		if zero? image/size [fire [TO_ERROR(access bad-media)]]
		if TYPE_OF(dst) = TYPE_NONE [dst: stack/push*]
		OS-image/encode image dst format
	]

	decode: func [
		data	[red-value!]
		return: [red-image!]
	][
		either TYPE_OF(data) = TYPE_BINARY [
			load-binary as red-binary! data
		][
			make-at stack/push* as red-string! data
		]
	]

	extract-data: func [
		img		[red-image!]
		type	[integer!]
		return: [red-binary!]
		/local
			sz		[integer!]
			bytes	[integer!]
			bin		[red-binary!]
			s		[series!]
			p		[byte-ptr!]
			i		[integer!]
			pixel	[integer!]
			data	[int-ptr!]
	][
		sz: IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size)
		bytes: case [
			type = EXTRACT_ALPHA [sz]
			type = EXTRACT_RGB	 [sz * 3]
			true				 [sz * 4]
		]
		bin: binary/make-at stack/push* bytes
		if zero? sz [return bin]

		s: GET_BUFFER(bin)
		s/tail: as cell! (as byte-ptr! s/tail) + bytes
		p: as byte-ptr! s/offset

		s: GET_BUFFER(img)
		data: as int-ptr! s/offset

		either type = EXTRACT_ARGB [
			copy-memory p as byte-ptr! data bytes
		][
			i: 1
			while [i <= sz][
				pixel: data/i
				either type = EXTRACT_ALPHA [
					p/1: as-byte 255 - (pixel >>> 24)
					p: p + 1
				][
					p/1: as-byte pixel and 00FF0000h >> 16
					p/2: as-byte pixel and FF00h >> 8
					p/3: as-byte pixel and FFh
					p: p + 3
				]
				i: i + 1
			]
		]
		bin
	]

	set-data: func [
		img		[red-image!]
		bin		[red-binary!]
		method	[integer!]
		return: [red-binary!]
		/local
			offset	[integer!]
			sz		[integer!]
			s		[series!]
			p		[byte-ptr!]
			pixel	[integer!]
			tp		[red-tuple!]
			int		[red-integer!]
			color	[integer!]
			data	[int-ptr!]
			end		[int-ptr!]
			type	[integer!]
			mask	[integer!]
	][
		sz: IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size)
		if zero? sz [return bin]

		offset: img/head
		s: GET_BUFFER(img)
		data: as int-ptr! s/offset
		end: data + sz

		type: TYPE_OF(bin)
		either type = TYPE_BINARY [
			s: GET_BUFFER(bin)
			p: as byte-ptr! s/offset
			either method = EXTRACT_ARGB [
				copy-memory as byte-ptr! data p sz * 4
			][
				while [data < end][
					pixel: data/value
					either method = EXTRACT_ALPHA [
						pixel: pixel and 00FFFFFFh or ((255 - as-integer p/1) << 24)
						p: p + 1
					][
						pixel: pixel and FF000000h
								or ((as-integer p/1) << 16)
								or ((as-integer p/2) << 8)
								or (as-integer p/3)
						p: p + 3
					]
					data/value: pixel
					data: data + 1
				]
			]
		][
			switch type [
				TYPE_TUPLE [
					tp: as red-tuple! bin
					color: tp/array1
					if TUPLE_SIZE?(tp) = 3 [color: color and 00FFFFFFh]
				]
				TYPE_INTEGER [
					int: as red-integer! bin
					color: int/value
				]
				default [
					fire [TO_ERROR(script invalid-arg) bin]
				]
			]
			either method = EXTRACT_ARGB [
				mask: 255 - (color >>> 24) << 24
				color: color >> 16 and FFh or (color and FF00h) or (color and FFh << 16) or mask
				until [
					data/value: color
					data: data + 1
					data = end
				]
			][
				color: either method = EXTRACT_RGB [
					mask: FF000000h
					color: color and 00FFFFFFh
					color >> 16 or (color and FF00h) or (color and FFh << 16)
				][
					mask: 00FFFFFFh
					255 - color << 24
				]
				while [data < end][
					data/value: data/value and mask or color
					data: data + 1
				]
			]
		]
		ownership/check as red-value! img words/_poke as red-value! bin img/head 0
		bin
	]

	get-position: func [
		img			[red-image!]
		index		[red-integer!]
		base		[integer!]
		out-range	[int-ptr!]
		return:		[integer!]
		/local
			pair	[red-pair!]
			offset	[integer!]
			max		[integer!]
			idx		[integer!]
			w		[integer!]
			h		[integer!]
			x		[integer!]
			y		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/at"]]

		w: IMAGE_WIDTH(img/size)
		h: IMAGE_HEIGHT(img/size)
		either TYPE_OF(index) = TYPE_INTEGER [
			idx: index/value
		][											;-- pair!
			pair: as red-pair! index
			x: pair/x
			y: pair/y
			if out-range <> null [
				either base = 1 [
					if any [x > w x <= 0 y > h y <= 0][out-range/value: 1]
				][
					if any [x >= w x < 0 y >= h y < 0][out-range/value: 1]
				]
			]

			if all [base = 1 y > 0][y: y - 1]
			idx: y * w + x
		]

		if all [base = 1 idx <= 0][base: base - 1]
		offset: img/head + idx - base
		if negative? offset [offset: 0 idx: 0]
		max: w * h
		if offset >= max [offset: max idx: 0]
		if all [out-range <> null zero? idx][out-range/value: 1]
		offset
	]

	;-- Actions --

	make: func [
		proto	[red-image!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-image!]
		/local
			img		[red-image!]
			pair	[red-pair!]
			blk		[red-block!]
			bin		[red-binary!]
			rgb		[byte-ptr!]
			alpha	[byte-ptr!]
			color	[red-tuple!]
			x		[integer!]
			y		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/make"]]

		img: as red-image! stack/push*
		img/header: TYPE_IMAGE
		img/head: 0

		if all [
			TYPE_OF(spec) = TYPE_BLOCK
			zero? block/rs-length? as red-block! spec
		][
			either TYPE_OF(proto) = TYPE_IMAGE [
				return copy proto img null yes null
			][
				fire [TO_ERROR(script invalid-arg) spec]
			]
		]

		rgb:   null
		alpha: null
		color: null

		switch TYPE_OF(spec) [
			TYPE_PAIR [
				pair: as red-pair! spec
			]
			TYPE_BLOCK [
				blk: as red-block! spec
				pair: as red-pair! block/rs-head blk
				check-arg-type as red-value! pair TYPE_PAIR

				unless block/rs-next blk [
					bin: as red-binary! block/rs-head blk
					switch TYPE_OF(bin) [
						TYPE_BINARY [rgb: binary/rs-head bin]
						TYPE_TUPLE	[color: as red-tuple! bin]
						default		[fire [TO_ERROR(script invalid-arg) bin]]
					]
				]
				unless block/rs-next blk [
					bin: as red-binary! block/rs-head blk
					check-arg-type as red-value! bin TYPE_BINARY
					alpha: binary/rs-head bin
				]
			]
			default [return to proto spec type]
		]

		x: pair/x
		if negative? x [x: 0]
		y: pair/y
		if negative? y [y: 0]
		make-image img x y rgb alpha color
		img
	]

	to: func [											;-- to image! face! only
		proto	[red-image!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-image!]
		/local
			ret [red-logic!]
	][
		switch TYPE_OF(spec) [
			TYPE_IMAGE [					;-- copy it
				return copy as red-image! spec proto null yes null
			]
			TYPE_OBJECT [
				#either modules contains 'View [
					spec: stack/push spec						;-- store spec to avoid corrution (#2460)
					#call [face? spec]
					ret: as red-logic! stack/arguments
					if ret/value [return exec/gui/OS-to-image as red-object! spec]
				][0]
			]
			default [0]
		]
		fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_IMAGE spec]
		as red-image! proto
	]

	serialize: func [
		img		[red-image!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return: [integer!]
		/local
			height	[integer!]
			width	[integer!]
			alpha?	[logic!]
			formed	[c-string!]
			pixel	[integer!]
			count	[integer!]
			s		[series!]
			data	[int-ptr!]
			size	[integer!]
			end		[int-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/serialize"]]

		alpha?: no
		width: IMAGE_WIDTH(img/size)
		height: IMAGE_HEIGHT(img/size)

		string/concatenate-literal buffer "make image! ["
		part: part - 13
		formed: integer/form-signed width
		string/concatenate-literal buffer formed
		part: part - system/words/length? formed

		string/append-char GET_BUFFER(buffer) as-integer #"x"
		formed: integer/form-signed height
		string/concatenate-literal buffer formed
		part: part - system/words/length? formed

		if null? img/node [							;-- empty image
			string/concatenate-literal buffer " #{}]"
			return part - 5
		]

		s: GET_BUFFER(img)
		data: as int-ptr! s/offset
		end: data + (width * height)
		data: data + img/head
		size: as-integer end - data

		string/append-char GET_BUFFER(buffer) as-integer space
		string/concatenate-literal buffer "#{"
		part: part - 2
		if all [not flat? size > 30][
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: object/do-indent buffer indent part - 1
		]

		count: 0
		while [data < end][
			pixel: data/value
			string/concatenate-literal buffer string/byte-to-hex pixel and 00FF0000h >> 16
			string/concatenate-literal buffer string/byte-to-hex pixel and FF00h >> 8
			string/concatenate-literal buffer string/byte-to-hex pixel and FFh
			unless flat? [
				count: count + 1
				if count % 10 = 0 [
					string/append-char GET_BUFFER(buffer) as-integer lf
					part: object/do-indent buffer indent part - 1
				]
			]
			part: part - 6
			if all [OPTION?(arg) part <= 0][
				return part
			]
			if pixel >>> 24 <> 255 [alpha?: yes]
			data: data + 1
		]
		if all [not flat? size > 30 count % 10 <> 0] [
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: object/do-indent buffer indent part - 1
		]
		string/append-char GET_BUFFER(buffer) as-integer #"}"

		if alpha? [
			data: data - (width * height)
			string/append-char GET_BUFFER(buffer) as-integer space
			string/concatenate-literal buffer "#{^/"
			part: part - 4
			count: 0
			while [data < end][
				pixel: data/value
				string/concatenate-literal buffer string/byte-to-hex 255 - (pixel >>> 24)
				unless flat? [
					count: count + 1
					if count % 10 = 0 [string/append-char GET_BUFFER(buffer) as-integer lf]
				]
				part: part - 2
				if all [OPTION?(arg) part <= 0][
					return part
				]
				data: data + 1
			]
			string/append-char GET_BUFFER(buffer) as-integer #"}"
		]
		string/append-char GET_BUFFER(buffer) as-integer #"]"
		part - 2												;-- #"}" and #"]"
	]

	form: func [
		img		  [red-image!]
		buffer	  [red-string!]
		arg		  [red-value!]
		part 	  [integer!]
		return:   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/form"]]

		serialize img buffer no no no arg part 0
	]

	mold: func [
		img		[red-image!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/mold"]]

		serialize img buffer only? all? flat? arg part indent + 1
	]

	length?: func [
		img		[red-image!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/length?"]]

		IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size)
	]

	;--- Reading actions ---

	pick: func [
		img		[red-image!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			out-range [integer!]
			offset	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/pick"]]

		out-range: 0
		offset: either null? boxed [img/head + index - 1][get-position img as red-integer! boxed 1 :out-range]
		as red-value! either out-range = 1 [none-value][rs-pick img offset]
	]

	poke: func [
		img		[red-image!]
		index	[integer!]
		data	[red-value!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			out-range [integer!]
			color	[red-tuple!]
			offset	[integer!]
			p		[byte-ptr!]
			r		[integer!]
			g		[integer!]
			b		[integer!]
			a		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/poke"]]

		out-range: 0
		offset: get-position img as red-integer! boxed 1 :out-range
		either out-range = 1 [
			fire [TO_ERROR(script out-of-range) boxed]
		][
			unless TYPE_TUPLE = TYPE_OF(data) [fire [TO_ERROR(script invalid-arg) data]]
			color: as red-tuple! data
			p: (as byte-ptr! color) + 4
			r: as-integer p/1
			g: as-integer p/2
			b: as-integer p/3
			a: either TUPLE_SIZE?(color) > 3 [255 - as-integer p/4][255]
			set-pixel img offset a << 24 or (r << 16) or (g << 8) or b
		]
		ownership/check as red-value! img words/_poke data offset 1
		as red-value! data
	]

	eval-path: func [
		parent	[red-image!]								;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		case?	[logic!]
		return:	[red-value!]
		/local
			set? [logic!]
			w	 [red-word!]
			sym  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/eval-path"]]

		set?: value <> null
		switch TYPE_OF(element) [
			TYPE_INTEGER
			TYPE_PAIR [
				either set? [
					poke parent -1 value element
				][
					pick parent -1 element
				]
			]
			TYPE_WORD [
				w: as red-word! element
				sym: symbol/resolve w/symbol
				case [
					sym = words/size [
						if set? [fire [TO_ERROR(script invalid-path) path element]]
						pair/push IMAGE_WIDTH(parent/size) IMAGE_HEIGHT(parent/size)
					]
					sym = words/argb [
						either set? [
							set-data parent as red-binary! value EXTRACT_ARGB
						][
							extract-data parent EXTRACT_ARGB
						]
					]
					sym = words/rgb [
						either set? [
							set-data parent as red-binary! value EXTRACT_RGB
						][
							extract-data parent EXTRACT_RGB
						]
					]
					sym = words/alpha [
						either set? [
							set-data parent as red-binary! value EXTRACT_ALPHA
						][
							extract-data parent EXTRACT_ALPHA
						]
					]
					true [
						fire [TO_ERROR(script invalid-path) path element]
						null
					]
				]
			]
			default [
				fire [TO_ERROR(script invalid-path) path element]
				null
			]
		]
	]

	compare: func [
		arg1	[red-image!]								;-- first operand
		arg2	[red-image!]								;-- second operand
		op		[integer!]									;-- type of comparison
		return:	[integer!]
		/local
			type	[integer!]
			res		[integer!]
			s		[series!]
			p1		[byte-ptr!]
			p2		[byte-ptr!]
			same?	[logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/compare"]]

		type: TYPE_OF(arg2)
		if type <> TYPE_IMAGE [RETURN_COMPARE_OTHER]

		same?: all [
			arg1/node = arg2/node
			arg1/head = arg2/head
		]
		if op = COMP_SAME [return either same? [0][-1]]
		if all [
			same?
			any [op = COMP_EQUAL op = COMP_STRICT_EQUAL op = COMP_NOT_EQUAL]
		][return 0]

		switch op [
			COMP_EQUAL
			COMP_FIND
			COMP_STRICT_EQUAL
			COMP_NOT_EQUAL
			COMP_SORT
			COMP_CASE_SORT [
				either any [
					arg1/size <> arg2/size
					all [arg1/size = arg2/size arg1/head <> arg2/head]
				][
					res: 1
				][
					either zero? arg1/size [res: 0][
						s: GET_BUFFER(arg1)
						p1: as byte-ptr! s/offset
						s: GET_BUFFER(arg2)
						p2: as byte-ptr! s/offset
						res: compare-memory p1 p2 IMAGE_WIDTH(arg1/size) * IMAGE_HEIGHT(arg2/size) * 4
					]
				]
			]
			default [
				res: -2
			]
		]
		res
	]

	;--- Series actions ---

	at: func [
		return:	[red-image!]
		/local
			img	[red-image!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/at"]]

		img: as red-image! stack/arguments
		img/head: get-position img as red-integer! img + 1 1 null
		img
	]

	next: func [
		return:	[red-image!]
		/local
			img		[red-image!]
			offset	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/next"]]

		img: as red-image! stack/arguments
		offset: img/head + 1
		if IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size) > offset  [
			img/head: offset
		]
		img
	]

	skip: func [
		return:	[red-image!]
		/local
			img	[red-image!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/skip"]]

		img: as red-image! stack/arguments
		img/head: get-position img as red-integer! img + 1 0 null
		img
	]

	tail?: func [
		return:	  [red-value!]
		/local
			img	  [red-image!]
			state [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/tail?"]]

		img:   as red-image! stack/arguments
		state: as red-logic! img

		state/header: TYPE_LOGIC
		state/value:  IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size) <= (img/head + 1)
		as red-value! state
	]

	tail: func [
		return:	[red-image!]
		/local
			img	[red-image!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/tail"]]

		img: as red-image! stack/arguments
		img/head: IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size)
		img
	]

	copy: func [
		img			[red-image!]
		new			[red-image!]
		part-arg	[red-value!]
		deep?		[logic!]
		types		[red-value!]
		return:		[red-image!]
		/local
			part?	[logic!]
			int		[red-integer!]
			img2	[red-image!]
			offset	[integer!]
			part	[integer!]
			type	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "image/copy"]]

		offset: img/head
		part: IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size) - offset
		part?: no

		if OPTION?(part-arg) [
			part?: yes
			type: TYPE_OF(part-arg)
			case [
				type = TYPE_INTEGER [
					int: as red-integer! part-arg
					part: either int/value > part [part][int/value]
				]
				type = TYPE_PAIR [0]
				true [
					img2: as red-image! part-arg
					unless all [
						TYPE_OF(img2) = TYPE_IMAGE
						img2/node = img/node
					][
						ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
					]
					part: img2/head - img/head
				]
			]
		]

		if negative? part [
			part: 0 - part
			offset: offset - part
			if negative? offset [offset: 0 part: img/head]
		]

		clone img new part as red-pair! part-arg part?
	]

	init: does [
		datatype/register [
			TYPE_IMAGE
			TYPE_SERIES
			"image!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			:to
			:form
			:mold
			:eval-path
			null			;set-path
			:compare
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
			null			;and~
			null			;complement
			null			;or~
			null			;xor~
			;-- Series actions --
			null			;append
			:at
			INHERIT_ACTION	;back
			null			;change
			null			;clear
			:copy
			null			;find
			INHERIT_ACTION	;head
			INHERIT_ACTION	;head?
			INHERIT_ACTION	;index?
			null			;insert
			:length?
			null			;move
			:next
			:pick
			:poke
			null			;put
			null			;remove
			null			;reverse
			null			;select
			null			;sort
			:skip
			null			;swap
			:tail
			:tail?
			null			;take
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
