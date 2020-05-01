Red/System [
	Title:	"GTK3 font"
	Author: "bitbegin"
	File: 	%font.reds
	Tabs: 	4
	Rights: "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

default-attrs: as handle! 0

init-default-handle: does [
	unless null? default-attrs [
		pango_attr_list_unref default-attrs
	]
	default-attrs: create-default-attrs
]

create-default-attrs: func [
	return:		[handle!]
	/local
		list	[handle!]
		attr	[PangoAttribute!]
		rgb		[integer!]
		alpha?	[integer!]
		r		[integer!]
		g		[integer!]
		b		[integer!]
		a		[integer!]
][
	list: pango_attr_list_new
	attr: pango_attr_family_new default-font-name
	pango_attr_list_insert list attr
	attr: pango_attr_size_new PANGO_SCALE * default-font-size
	pango_attr_list_insert list attr

	alpha?: 0
	rgb: default-font-color
	alpha?: 1
	r: 0 g: 0 b: 0 a: 0
	color-u8-to-u16 rgb :r :g :b :a
	attr: pango_attr_foreground_new r g b
	pango_attr_list_insert list attr
	attr: pango_attr_foreground_alpha_new a
	pango_attr_list_insert list attr
	list
]

;-- create css styles
;-- `anti-alias` need to be set by cairo
create-css: func [
	face		[red-object!]
	font		[red-object!]
	css			[GString!]
	/local
		values	[red-value!]
		str		[red-string!]
		name	[c-string!]
		len		[integer!]
		int		[red-integer!]
		size	[integer!]
		color	[red-tuple!]
		rgb		[integer!]
		alpha?	[integer!]
		r		[integer!]
		g		[integer!]
		b		[integer!]
		a		[float!]
		style	[red-word!]
		blk		[red-block!]
		sym		[integer!]
][
	g_string_set_size css 0
	g_string_append css "* {"

	values: object/get-values font
	str: as red-string! values + FONT_OBJ_NAME
	name: either TYPE_OF(str) = TYPE_STRING [
		len: -1
		unicode/to-utf8 str :len
	][default-font-name]
	g_string_append_printf [css { font-family: "%s";} name]

	int: as red-integer! values + FONT_OBJ_SIZE
	size: either TYPE_OF(int) <> TYPE_INTEGER [default-font-size][
		int/value
	]
	g_string_append_printf [css { font-size: %dpt;} size]

	color: as red-tuple! values + FONT_OBJ_COLOR
	alpha?: 0
	either TYPE_OF(color) = TYPE_TUPLE [
		rgb: get-color-int color :alpha?
	][
		rgb: default-font-color
		alpha?: 1
	]
	b: rgb >> 16 and FFh
	g: rgb >> 8 and FFh
	r: rgb and FFh
	a: 1.0
	if alpha? = 1 [
		a: (as float! 255 - (rgb >>> 24)) / 255.0
	]
	g_string_append_printf [css { color: rgba(%d, %d, %d, %.3f);} r g b a]

	;-- ? GTK3 warnings
	;int: as red-integer! values + FONT_OBJ_ANGLE
	;if TYPE_OF(int) = TYPE_INTEGER [
	;	g_string_append_printf [css { font-style: oblique %ddeg;} int/value]
	;]

	style: as red-word! values + FONT_OBJ_STYLE
	len: switch TYPE_OF(style) [
		TYPE_BLOCK [
			blk: as red-block! style
			style: as red-word! block/rs-head blk
			len: block/rs-length? blk
		]
		TYPE_WORD  [1]
		default	   [0]
	]

	unless zero? len [
		loop len [
			sym: symbol/resolve style/symbol
			case [
				sym = _bold [
					g_string_append css " font-weight: bold;"
				]
				sym = _italic [
					g_string_append css " font-style: italic;"
				]
				sym = _underline [
					g_string_append css " text-decoration: underline;"
				]
				sym = _strike [
					g_string_append css " text-decoration: line-through;"
				]
				true			 [0]
			]
			style: style + 1
		]
	]

	g_string_append css "}"
	g_string_append css " * selection {"
	g_string_append_printf [css { background-color: rgba(%d, %d, %d, %.3f);} r g b a]
	g_string_append css "}"
]

;-- create pango attributes
;-- `angle` need to be set on label
;-- `anti-alias` need to be set by cairo
create-pango-attrs: func [
	face		[red-object!]
	font		[red-object!]
	return:		[handle!]
	/local
		list	[handle!]
		attr	[PangoAttribute!]
		values	[red-value!]
		str		[red-string!]
		name	[c-string!]
		len		[integer!]
		int		[red-integer!]
		size	[integer!]
		color	[red-tuple!]
		rgb		[integer!]
		alpha?	[integer!]
		r		[integer!]
		g		[integer!]
		b		[integer!]
		a		[integer!]
		style	[red-word!]
		blk		[red-block!]
		sym		[integer!]
][
	list: pango_attr_list_new

	values: object/get-values font

	str: as red-string! values + FONT_OBJ_NAME
	name: either TYPE_OF(str) = TYPE_STRING [
		len: -1
		unicode/to-utf8 str :len
	][default-font-name]
	attr: pango_attr_family_new name
	pango_attr_list_insert list attr

	int: as red-integer! values + FONT_OBJ_SIZE
	size: either TYPE_OF(int) <> TYPE_INTEGER [default-font-size][
		int/value
	]
	attr: pango_attr_size_new PANGO_SCALE * size
	pango_attr_list_insert list attr

	color: as red-tuple! values + FONT_OBJ_COLOR
	if TYPE_OF(color) = TYPE_TUPLE [
		alpha?: 0
		rgb: get-color-int color :alpha?
		r: 0 g: 0 b: 0 a: 0
		color-u8-to-u16 rgb :r :g :b :a
		attr: pango_attr_foreground_new r g b
		pango_attr_list_insert list attr
		attr: pango_attr_foreground_alpha_new a
		pango_attr_list_insert list attr
	]

	unless null? face [
		color: as red-tuple! (object/get-values face) + FACE_OBJ_COLOR
		if all [
			TYPE_OF(color) = TYPE_TUPLE
			not all [
				TUPLE_SIZE?(color) = 4
				color/array1 and FF000000h = FF000000h
			]
		][
			alpha?: 0
			rgb: get-color-int color :alpha?
			r: 0 g: 0 b: 0 a: 0
			color-u8-to-u16 rgb :r :g :b :a
			attr: pango_attr_background_new r g b
			pango_attr_list_insert list attr
			attr: pango_attr_background_alpha_new a
			pango_attr_list_insert list attr
		]
	]

	style: as red-word! values + FONT_OBJ_STYLE
	len: switch TYPE_OF(style) [
		TYPE_BLOCK [
			blk: as red-block! style
			style: as red-word! block/rs-head blk
			len: block/rs-length? blk
		]
		TYPE_WORD  [1]
		default	   [0]
	]

	unless zero? len [
		loop len [
			sym: symbol/resolve style/symbol
			case [
				sym = _bold [
					attr: pango_attr_weight_new PANGO_WEIGHT_BOLD
					pango_attr_list_insert list attr
				]
				sym = _italic [
					attr: pango_attr_style_new PANGO_STYLE_ITALIC
					pango_attr_list_insert list attr
				]
				sym = _underline [
					attr: pango_attr_underline_new PANGO_UNDERLINE_SINGLE
					pango_attr_list_insert list attr
				]
				sym = _strike [
					attr: pango_attr_strikethrough_new true
					pango_attr_list_insert list attr
				]
				true			 [0]
			]
			style: style + 1
		]
	]
	list
]

free-pango-attrs: func [
	attrs		[handle!]
][
	pango_attr_list_unref attrs
]

make-font: func [
	face		[red-object!]
	font		[red-object!]
	return:		[handle!]
	/local
		attrs	[handle!]
		values	[red-value!]
		blk		[red-block!]
		int		[red-integer!]
][
	if TYPE_OF(font) <> TYPE_OBJECT [
		return null
	]
	attrs: as handle! 1									;-- placeholder handle, just to fill font/state
	values: object/get-values font
	blk: as red-block! values + FONT_OBJ_STATE
	either TYPE_OF(blk) <> TYPE_BLOCK [
		block/make-at blk 2
		handle/make-in blk as-integer attrs
		none/make-in blk
	][
		int: as red-integer! block/rs-head blk
		int/header: TYPE_HANDLE
		int/value: as-integer attrs
	]

	blk: as red-block! values + FONT_OBJ_PARENT
	if all [face <> null TYPE_OF(blk) <> TYPE_BLOCK][
		blk: block/make-at as red-block! values + FONT_OBJ_PARENT 4
		block/rs-append blk as red-value! face
	]
	attrs
]

get-font-handle: func [
	font		[red-object!]
	idx			[integer!]
	return:		[handle!]
	/local
		state	[red-block!]
		handle	[red-handle!]
][
	state: as red-block! (object/get-values font) + FONT_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		handle: (as red-handle! block/rs-head state) + idx
		if TYPE_OF(handle) = TYPE_HANDLE [
			return as handle! handle/value
		]
	]
	null
]

get-font: func [
	face		[red-object!]
	font		[red-object!]
	return:		[handle!]
	/local
		hFont	[handle!]
][
	if TYPE_OF(font) <> TYPE_OBJECT [return null]
	hFont: get-font-handle font 0
	if null? hFont [hFont: make-font face font]
	hFont
]

free-font: func [
	font		[red-object!]
	/local
		state	[red-block!]
		hFont	[handle!]
][
	hFont: get-font-handle font 0
	if hFont <> null [
		state: as red-block! (object/get-values font) + FONT_OBJ_STATE
		state/header: TYPE_NONE
	]
]

update-font: func [
	font		[red-object!]
	flag		[integer!]
][
	switch flag [
		FONT_OBJ_NAME
		FONT_OBJ_SIZE
		FONT_OBJ_STYLE
		FONT_OBJ_ANGLE
		FONT_OBJ_ANTI-ALIAS? [
			;-- to make sure the font/state will be always exist
			get-font null font
		]
		default [0]
	]
]

change-font: func [
	widget		[handle!]
	face		[red-object!]
	values		[red-value!]
	sym			[integer!]
	/local
		font	[red-object!]
		prov	[handle!]
		css		[GString!]
		style	[handle!]
		label	[handle!]
][
	font: as red-object! values + FACE_OBJ_FONT

	prov: GET-RED-FONT(widget)
	either null? prov [
		prov: create-provider widget
		SET-RED-FONT(widget prov)
		css: g_string_sized_new 128
		SET-FONT-STR(widget css)
	][
		css: GET-FONT-STR(widget)
	]
	if any [
		null? font
		TYPE_OF(font) <> TYPE_OBJECT
	][
		g_string_set_size css 0
		gtk_css_provider_load_from_data prov css/str -1 null
		exit
	]
	create-css face font css
	gtk_css_provider_load_from_data prov css/str -1 null

	;-- special styles
	case [
		sym = text [
			set-label-attrs widget face font
		]
		any [
			sym = button
			sym = check
			sym = radio
		][
			label: gtk_bin_get_child widget
			;-- some button maybe have empty label
			if g_type_check_instance_is_a label gtk_label_get_type [
				set-label-attrs label face font
			]
		]
		true [0]
	]
]

set-label-attrs: func [
	label		[handle!]
	face		[red-object!]
	font		[red-object!]
	/local
		values	[red-value!]
		int		[red-integer!]
		angle	[integer!]
		attrs	[handle!]
		style	[red-word!]
		len		[integer!]
		blk		[red-block!]
		sym		[integer!]
		attr	[PangoAttribute!]
][
	values: object/get-values font

	int: as red-integer! values + FONT_OBJ_ANGLE
	angle: either TYPE_OF(int) = TYPE_INTEGER [int/value][0]
	gtk_label_set_angle label as float! angle

	attrs: pango_attr_list_new
	style: as red-word! values + FONT_OBJ_STYLE
	len: switch TYPE_OF(style) [
		TYPE_BLOCK [
			blk: as red-block! style
			style: as red-word! block/rs-head blk
			len: block/rs-length? blk
		]
		TYPE_WORD  [1]
		default	   [0]
	]

	unless zero? len [
		loop len [
			sym: symbol/resolve style/symbol
			case [
				sym = _bold [
					0
				]
				sym = _italic [
					0
				]
				sym = _underline [
					attr: pango_attr_underline_new PANGO_UNDERLINE_SINGLE
					pango_attr_list_insert attrs attr
				]
				sym = _strike [
					0
				]
				true [0]
			]
			style: style + 1
		]
	]
	gtk_label_set_attributes label attrs
]

free-font-provider: func [
	widget		[handle!]
	/local
		prov	[handle!]
		css		[GString!]
][
	prov: GET-RED-FONT(widget)
	free-provider prov
	SET-RED-FONT(widget null)
	css: GET-FONT-STR(widget)
	g_string_free css true
	SET-FONT-STR(widget 0)
]

create-pango-font: func [
	font		[red-object!]
	return:		[handle!]
	/local
		hFont	[handle!]
		values	[red-value!]
		str		[red-string!]
		name	[c-string!]
		len		[integer!]
		int		[red-integer!]
		size	[integer!]
		style	[red-word!]
		blk		[red-block!]
		sym		[integer!]
][
	hFont: pango_font_description_new

	either TYPE_OF(font) <> TYPE_OBJECT [
		pango_font_description_set_family hFont default-font-name
		pango_font_description_set_size hFont PANGO_SCALE * default-font-size
	][
		values: object/get-values font

		str: as red-string! values + FONT_OBJ_NAME
		name: either TYPE_OF(str) = TYPE_STRING [
			len: -1
			unicode/to-utf8 str :len
		][default-font-name]
		pango_font_description_set_family hFont name

		int: as red-integer! values + FONT_OBJ_SIZE
		size: either any [
			TYPE_OF(int) <> TYPE_INTEGER
			int/value <= 0
		][
			default-font-size
		][
			int/value
		]
		pango_font_description_set_size hFont PANGO_SCALE * size

		style: as red-word! values + FONT_OBJ_STYLE
		len: switch TYPE_OF(style) [
			TYPE_BLOCK [
				blk: as red-block! style
				style: as red-word! block/rs-head blk
				len: block/rs-length? blk
			]
			TYPE_WORD  [1]
			default	   [0]
		]

		unless zero? len [
			loop len [
				sym: symbol/resolve style/symbol
				case [
					sym = _bold [
						pango_font_description_set_weight hFont PANGO_WEIGHT_BOLD
					]
					sym = _italic [
						pango_font_description_set_style hFont PANGO_STYLE_ITALIC
					]
					sym = _underline [
						0
					]
					sym = _strike [
						0
					]
					true [0]
				]
				style: style + 1
			]
		]
	]
	hFont
]

free-pango-font: func [
	hFont		[handle!]
][
	pango_font_description_free hFont
]

update-textview-tag: func [
	buffer		[handle!]
	start		[handle!]
	end			[handle!]
][
	0
]