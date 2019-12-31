Red/System [
	Title:	"DRAW Direct2D Backend"
	Author: "Xie Qingtian"
	File: 	%draw.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %text-box.reds

draw-state!: alias struct! [
	block			[this!]
	pen-clr			[integer!]
	brush-clr		[integer!]
	pen-join		[integer!]
	pen-cap			[integer!]
	pen				[this!]
	brush			[this!]
	pen?			[logic!]
	brush?			[logic!]
	bitmap-brush?	[logic!]
	bitmap-brush	[this!]
	grad-pen		[gradient! value]
	grad-brush		[gradient! value]
]

#enum DRAW-BRUSH-TYPE! [
	DRAW_BRUSH_NONE
	DRAW_BRUSH_COLOR
	DRAW_BRUSH_IMAGE
	DRAW_BRUSH_GRADIENT
	DRAW_BRUSH_GRADIENT_SMART
]

grad-stops: as D2D1_GRADIENT_STOP allocate 256 * size? D2D1_GRADIENT_STOP

draw-begin: func [
	ctx			[draw-ctx!]
	hWnd		[handle!]
	img			[red-image!]
	on-graphic? [logic!]
	paint?		[logic!]
	return: 	[draw-ctx!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
		bg-clr	[integer!]
		brush	[ptr-value!]
		target	[render-target!]
		brushes [int-ptr!]
		pbrush	[ID2D1SolidColorBrush]
		d3d-clr [D3DCOLORVALUE]
		values	[red-value!]
		clr		[red-tuple!]
		text	[red-string!]
		pos		[red-pair! value]
		bmp		[ptr-value!]
		wic-bmp	[this!]
		IUnk	[IUnknown]
][
	zero-memory as byte-ptr! ctx size? draw-ctx!
	ctx/pen-width:	as float32! 1.0
	ctx/pen-join: D2D1_LINE_JOIN_MITER
	ctx/pen-cap: D2D1_CAP_STYLE_FLAT
	ctx/pen-style:	null
	ctx/hwnd:		hWnd
	update-pen-style ctx

	this: d2d-ctx
	dc: as ID2D1DeviceContext this/vtbl

	either hWnd <> null [
		target: get-hwnd-render-target hWnd
	][
		wic-bmp: OS-image/to-pbgra img
		;-- create a bitmap target
		target: as render-target! alloc0 size? render-target!
		target/brushes: as int-ptr! allocate D2D_MAX_BRUSHES * 2 * size? int-ptr!
		if 0 <> dc/CreateBitmapFromWicBitmap2 this wic-bmp null bmp [
			;TBD error!!!
			probe "CreateBitmapFromWicBitmap2 failed in draw-begin"
			return ctx
		]
		ctx/image: img/node
		target/bitmap: as this! bmp/value
		COM_SAFE_RELEASE(IUnk wic-bmp)
	]
	ctx/dc: as ptr-ptr! this
	ctx/target: as int-ptr! target

	dc/SetTextAntialiasMode this 1				;-- ClearType
	dc/SetTarget this target/bitmap
	dc/SetAntialiasMode this 0					;-- D2D1_ANTIALIAS_MODE_PER_PRIMITIVE

	dc/BeginDraw this
	matrix2d/identity m
	dc/SetTransform this :m						;-- set to identity matrix

	d3d-clr: to-dx-color ctx/pen-color null
	dc/CreateSolidColorBrush this d3d-clr null :brush
	ctx/pen: as this! brush/value

	dc/CreateSolidColorBrush this d3d-clr null :brush
	ctx/brush: as this! brush/value

	ctx/pen?: yes
	ctx/brush?: no
	ctx/bitmap-brush?: no
	init-gradient ctx/grad-pen
	init-gradient ctx/grad-brush

	if hWnd <> null [
		values: get-face-values hWnd
		clr: as red-tuple! values + FACE_OBJ_COLOR
		bg-clr: either TYPE_OF(clr) = TYPE_TUPLE [clr/array1][-1]
		if bg-clr <> -1 [							;-- paint background
			dc/Clear this to-dx-color bg-clr null
		]

		text: as red-string! values + FACE_OBJ_TEXT
		if TYPE_OF(text) = TYPE_STRING [
			pos/x: 0 pos/y: 0
			OS-draw-text ctx pos as red-string! get-face-obj hWnd yes
		]
	]
	ctx
]

init-gradient: func [
	grad		[gradient!]
][
	grad/on?: off
	grad/matrix-on?: off
	grad/offset-on?: off
	grad/focal-on?: off
	grad/handle-on?: off
]

release-gradient: func [
	grad		[gradient!]
	/local
		IUnk	[IUnknown]
][
	if grad/on? [
		if grad/handle-on? [
			COM_SAFE_RELEASE(IUnk grad/handle)
		]
		COM_SAFE_RELEASE(IUnk grad/stop)
	]
]

release-ctx: func [
	ctx			[draw-ctx!]
	/local
		IUnk	[IUnknown]
][
	COM_SAFE_RELEASE(IUnk ctx/pen)
	COM_SAFE_RELEASE(IUnk ctx/brush)
	if ctx/bitmap-brush? [
		COM_SAFE_RELEASE(IUnk ctx/bitmap-brush)
	]
	release-gradient ctx/grad-pen
	release-gradient ctx/grad-brush
	release-pen-style ctx
]

draw-end: func [
	ctx			[draw-ctx!]
	hWnd		[handle!]
	on-graphic? [logic!]
	cache?		[logic!]
	paint?		[logic!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		sc		[IDXGISwapChain1]
		rt		[render-target!]
		hr		[integer!]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	dc/EndDraw this null null
	dc/SetTarget this null

	release-ctx ctx		;@@ Possible improvement: cache resources for window target

	rt: as render-target! ctx/target
	either hWnd <> null [	;-- window target
		this: rt/swapchain
		sc: as IDXGISwapChain1 this/vtbl
		hr: sc/Present this 0 0

		switch hr [
			COM_S_OK [ValidateRect hWnd null]
			DXGI_ERROR_DEVICE_REMOVED
			DXGI_ERROR_DEVICE_RESET [
				d2d-release-target rt
				ctx/dc: null
				SetWindowLong hWnd wc-offset - 24 0
				DX-create-dev
				InvalidateRect hWnd null 0
			]
			default [
				0			;@@ TBD log error!!!
			]
		]
	][						;-- image! target
		;TBD save rt/bitmap to ctx/image
		d2d-release-target rt
	]
]

release-pen-style: func [
	ctx			[draw-ctx!]
	/local
		IUnk	[IUnknown]
][
	unless null? ctx/pen-style [
		COM_SAFE_RELEASE(IUnk ctx/pen-style)
	]
]

update-pen-style: func [
	ctx			[draw-ctx!]
	/local
		prop	[D2D1_STROKE_STYLE_PROPERTIES value]
		d2d		[ID2D1Factory]
		hr		[integer!]
		style	[ptr-value!]
][
	release-pen-style ctx

	prop/startCap: ctx/pen-cap
	prop/endCap: ctx/pen-cap
	prop/dashCap: ctx/pen-cap
	prop/lineJoin: ctx/pen-join
	prop/miterLimit: as float32! 10.0
	prop/dashStyle: 0
	prop/dashOffset: as float32! 0.0

	d2d: as ID2D1Factory d2d-factory/vtbl
	hr: d2d/CreateStrokeStyle d2d-factory prop null 0 :style
	ctx/pen-style: as this! style/value
]

OS-draw-pen: func [
	ctx			[draw-ctx!]
	color		[integer!]
	off?		[logic!]
	/local
		IUnk	[IUnknown]
		this	[this!]
		brush	[ID2D1SolidColorBrush]
][
	ctx/pen?: not off?
	if ctx/grad-pen/on? [
		if ctx/grad-pen/handle-on? [
			COM_SAFE_RELEASE(IUnk ctx/grad-pen/handle)
		]
		ctx/grad-pen/handle-on?: off
		ctx/grad-pen/on?: off
	]
	if all [not off? ctx/pen-color <> color][
		ctx/pen-color: color
		unless ctx/font-color? [ctx/font-color: color]	;-- if no font, use pen color for text color
		this: as this! ctx/pen
		brush: as ID2D1SolidColorBrush this/vtbl
		brush/SetColor this to-dx-color color null
	]
]

OS-draw-text: func [
	ctx			[draw-ctx!]
	pos			[red-pair!]
	text		[red-string!]
	catch?		[logic!]
	return:		[logic!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		layout	[this!]
		brush	[ID2D1SolidColorBrush]
		color?	[logic!]
		pen		[this!]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl

	layout: either TYPE_OF(text) = TYPE_OBJECT [				;-- text-box!
		OS-text-box-layout as red-object! text as render-target! ctx/target 0 yes
	][
		if null? ctx/text-format [
			ctx/text-format: as this! create-text-format as red-object! text null
		]
		create-text-layout text ctx/text-format 0 0
	]
	color?: no
	if ctx/font-color <> ctx/pen-color [
		pen: as this! ctx/pen
		brush: as ID2D1SolidColorBrush pen/vtbl
		brush/SetColor pen to-dx-color ctx/font-color null
		color?: yes
	]
	txt-box-draw-background ctx/target pos layout
	dc/DrawTextLayout this as float32! pos/x as float32! pos/y layout ctx/pen 0
	if color? [
		brush/SetColor pen to-dx-color ctx/pen-color null
	]
	true
]

update-handle: func [
	grad		[gradient!]
	handle		[this!]
	tx			[float32!]
	ty			[float32!]
	/local
		m		[D2D_MATRIX_3X2_F value]
		IUnk	[IUnknown]
][
	matrix2d/translate grad/matrix (as float32! 0.0) - tx (as float32! 0.0) - ty m
	copy-memory as byte-ptr! grad/matrix as byte-ptr! m size? D2D_MATRIX_3X2_F
	grad/matrix-on?: on

	either grad/handle-on? [
		COM_SAFE_RELEASE(IUnk grad/handle)
	][
		grad/handle-on?: on
	]
	grad/handle: handle
]

check-grad-points: func [
	ctx			[draw-ctx!]
	grad		[gradient!]
	upper-x		[float32!]
	upper-y		[float32!]
	lower-x		[float32!]
	lower-y		[float32!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		handle	[this!]
		hv		[com-ptr! value]
		lprops	[D2D1_LINEAR_GRADIENT_BRUSH_PROPERTIES value]
		rprops	[D2D1_RADIAL_GRADIENT_BRUSH_PROPERTIES value]
		t		[float32!]
		t2		[float32!]
		tx		[float32!]
		ty		[float32!]
		delta	[float32!]
		IUnk	[IUnknown]
][
	unless grad/on? [exit]
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	handle: null
	case [
		grad/type = linear [
			either grad/offset-on? [
				lprops/startPoint.x: upper-x + grad/offset/x
				lprops/startPoint.y: upper-y + grad/offset/y
				lprops/endPoint.x: upper-x + grad/offset2/x
				lprops/endPoint.y: upper-y + grad/offset2/y
			][
				lprops/startPoint.x: upper-x
				lprops/startPoint.y: upper-y
				lprops/endPoint.x: lower-x
				lprops/endPoint.y: lower-y
			]
			tx: lprops/startPoint.x
			ty: lprops/startPoint.y
			dc/CreateLinearGradientBrush this :lprops null grad/stop :hv
			handle: hv/value
		]
		grad/type = radial [
			if upper-x > lower-x [
				t: lower-x
				lower-x: upper-x
				upper-x: t
			]
			if upper-y > lower-y [
				t: lower-y
				lower-y: upper-y
				upper-y: t
			]
			either grad/offset-on? [
				rprops/center.x: lower-x + upper-x / as float32! 2.0
				rprops/center.y: lower-y + upper-y / as float32! 2.0
				rprops/radius.x: grad/offset2/x
				rprops/radius.y: grad/offset2/y
				either grad/focal-on? [
					rprops/offset.x: grad/focal/x
					rprops/offset.y: grad/focal/x
				][
					rprops/offset.x: as float32! 0.0
					rprops/offset.y: as float32! 0.0
				]
			][
				rprops/center.x: lower-x + upper-x / as float32! 2.0
				rprops/center.y: lower-y + upper-y / as float32! 2.0
				tx: upper-x - lower-x / as float32! 2.0
				ty: upper-y - lower-y / as float32! 2.0
				delta: tx
				if tx > ty [delta: ty]
				rprops/radius.x: delta
				rprops/radius.y: delta
				rprops/offset.x: as float32! 0.0
				rprops/offset.y: as float32! 0.0
			]
			tx: rprops/center.x
			ty: rprops/center.y
			dc/CreateRadialGradientBrush this :rprops null grad/stop :hv
			handle: hv/value
		]
		true [0]
	]
	either null? handle [
		COM_SAFE_RELEASE(IUnk grad/handle)
		grad/handle-on?: off
	][
		update-handle grad handle tx ty
	]
]

check-grad-line: func [
	ctx			[draw-ctx!]
	grad		[gradient!]
	upper		[red-pair!]
	lower		[red-pair!]
][
	check-grad-points ctx grad
		as float32! upper/x
		as float32! upper/y
		as float32! lower/x
		as float32! lower/y
]

get-shape-pen: func [
	ctx			[draw-ctx!]
	bounds		[RECT_F!]
	return:		[this!]
][
	unless ctx/pen? [
		return null
	]
	unless ctx/grad-pen/on? [
		return ctx/pen
	]

	check-grad-points ctx ctx/grad-pen
		bounds/left
		bounds/top
		bounds/right
		bounds/bottom
	ctx/grad-pen/handle
]

get-shape-brush: func [
	ctx			[draw-ctx!]
	bounds		[RECT_F!]
	return:		[this!]
][
	unless ctx/brush? [
		return null
	]
	if ctx/bitmap-brush? [
		return ctx/bitmap-brush
	]
	unless ctx/grad-brush/on? [
		return ctx/brush
	]

	check-grad-points ctx ctx/grad-brush
		bounds/left
		bounds/top
		bounds/right
		bounds/bottom
	ctx/grad-brush/handle
]

OS-draw-shape-beginpath: func [
	ctx			[draw-ctx!]
	/local
		d2d		[ID2D1Factory]
		path	[ptr-value!]
		hr		[integer!]
		pthis	[this!]
		gpath	[ID2D1PathGeometry]
		sink	[ptr-value!]
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		vpoint	[D2D_POINT_2F value]
][
	d2d: as ID2D1Factory d2d-factory/vtbl
	hr: d2d/CreatePathGeometry d2d-factory :path
	pthis: as this! path/value
	gpath: as ID2D1PathGeometry pthis/vtbl
	hr: gpath/Open pthis :sink
	sthis: as this! sink/value
	gsink: as ID2D1GeometrySink sthis/vtbl

	ctx/sub/path: as integer! pthis
	ctx/sub/sink: as integer! sthis
	ctx/sub/last-pt-x: as float32! 0.0
	ctx/sub/last-pt-y: as float32! 0.0
	ctx/sub/shape-curve?: no
	vpoint/x: ctx/sub/last-pt-x
	vpoint/y: ctx/sub/last-pt-y
	gsink/BeginFigure sthis vpoint 1				;-- D2D1_FIGURE_BEGIN_HOLLOW
]

OS-draw-shape-endpath: func [
	ctx			[draw-ctx!]
	close?		[logic!]
	return:		[logic!]
	/local
		pthis	[this!]
		gpath	[ID2D1PathGeometry]
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		hr		[integer!]
		m		[D2D_MATRIX_3X2_F value]
		bounds	[RECT_F! value]
		bthis	[this!]
		this	[this!]
		dc		[ID2D1DeviceContext]
][
	pthis: as this! ctx/sub/path
	gpath: as ID2D1PathGeometry pthis/vtbl
	sthis: as this! ctx/sub/sink
	gsink: as ID2D1GeometrySink sthis/vtbl

	gsink/EndFigure sthis either close? [1][0]

	hr: gsink/Close sthis
	gsink/Release sthis

	matrix2d/identity m
	gpath/GetBounds pthis :m :bounds

	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	bthis: get-shape-brush ctx :bounds
	unless null? bthis [
		dc/FillGeometry this as int-ptr! pthis bthis null
	]
	bthis: get-shape-pen ctx :bounds
	unless null? bthis [
		dc/DrawGeometry this as int-ptr! pthis bthis ctx/pen-width ctx/pen-style
	]

	gpath/Release pthis

	ctx/sub/path: 0
	ctx/sub/sink: 0
	true
]

OS-draw-shape-close: func [
	ctx			[draw-ctx!]
	/local
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		vpoint	[D2D_POINT_2F value]
][
	sthis: as this! ctx/sub/sink
	gsink: as ID2D1GeometrySink sthis/vtbl
	gsink/EndFigure sthis 1
	vpoint/x: ctx/sub/last-pt-x
	vpoint/y: ctx/sub/last-pt-y
	gsink/BeginFigure sthis vpoint 1				;-- D2D1_FIGURE_BEGIN_HOLLOW
]

OS-draw-shape-moveto: func [
	ctx			[draw-ctx!]
	coord		[red-pair!]
	rel?		[logic!]
	/local
		dx		[float32!]
		dy		[float32!]
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		vpoint	[D2D_POINT_2F value]
][
	dx: as float32! coord/x
	dy: as float32! coord/y
	either rel? [
		ctx/sub/last-pt-x: ctx/sub/last-pt-x + dx
		ctx/sub/last-pt-y: ctx/sub/last-pt-y + dy
	][
		ctx/sub/last-pt-x: dx
		ctx/sub/last-pt-y: dy
	]
	sthis: as this! ctx/sub/sink
	gsink: as ID2D1GeometrySink sthis/vtbl
	gsink/EndFigure sthis 0
	vpoint/x: ctx/sub/last-pt-x
	vpoint/y: ctx/sub/last-pt-y
	gsink/BeginFigure sthis vpoint 1				;-- D2D1_FIGURE_BEGIN_HOLLOW
	ctx/sub/shape-curve?: no
]

OS-draw-shape-line: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
	/local
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		vpoint	[D2D_POINT_2F value]
		dx		[float32!]
		dy		[float32!]
		x		[float32!]
		y		[float32!]
		pair	[red-pair!]
][
	sthis: as this! ctx/sub/sink
	gsink: as ID2D1GeometrySink sthis/vtbl

	dx: ctx/sub/last-pt-x
	dy: ctx/sub/last-pt-y
	pair: start
	while [pair <= end][
		x: as float32! pair/x
		y: as float32! pair/y
		if rel? [
			x: x + dx
			y: y + dy
			dx: x
			dy: y
		]
		vpoint/x: x
		vpoint/y: y
		gsink/AddLine sthis vpoint
		pair: pair + 1
	]

	ctx/sub/last-pt-x: x
	ctx/sub/last-pt-y: y
	ctx/sub/shape-curve?: no
]

OS-draw-shape-axis: func [
	ctx			[draw-ctx!]
	start		[red-value!]
	end			[red-value!]
	rel?		[logic!]
	hline?		[logic!]
	/local
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		len		[float32!]
		sx		[float32!]
		sy		[float32!]
		vpoint	[D2D_POINT_2F value]
][
	sthis: as this! ctx/sub/sink
	gsink: as ID2D1GeometrySink sthis/vtbl

	len: get-float32 as red-integer! start
	sx: ctx/sub/last-pt-x
	sy: ctx/sub/last-pt-y
	either hline? [
		ctx/sub/last-pt-x: either rel? [sx + len][len]
	][
		ctx/sub/last-pt-y: either rel? [sy + len][len]
	]
	vpoint/x: ctx/sub/last-pt-x
	vpoint/y: ctx/sub/last-pt-y
	gsink/AddLine sthis vpoint
]

draw-curve: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
	short?		[logic!]
	num			[integer!]				;--	number of points
	/local
		dx		[float32!]
		dy		[float32!]
		p3y		[float32!]
		p3x		[float32!]
		p2y		[float32!]
		p2x		[float32!]
		p1y		[float32!]
		p1x		[float32!]
		pf		[float32-ptr!]
		pt		[red-pair!]
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		bezier	[D2D1_BEZIER_SEGMENT value]
		qbezier	[D2D1_QUADRATIC_BEZIER_SEGMENT value]
][
	pt: start + 1
	p1x: as float32! start/x
	p1y: as float32! start/y
	p2x: as float32! pt/x
	p2y: as float32! pt/y
	if num = 3 [					;-- cubic Bézier
		pt: start + 2
		p3x: as float32! pt/x
		p3y: as float32! pt/y
	]

	dx: ctx/sub/last-pt-x
	dy: ctx/sub/last-pt-y
	if rel? [
		pf: :p1x
		loop num [
			pf/1: pf/1 + dx			;-- x
			pf/2: pf/2 + dy			;-- y
			pf: pf + 2
		]
	]

	if short? [
		either ctx/sub/shape-curve? [
			;-- The control point is assumed to be the reflection of the control point
			;-- on the previous command relative to the current point
			p1x: dx * (as float32! 2.0) - ctx/sub/control-x
			p1y: dy * (as float32! 2.0) - ctx/sub/control-y
		][
			;-- if previous command is not curve/curv/qcurve/qcurv, use current point
			p1x: dx
			p1y: dy
		]
	]

	ctx/sub/shape-curve?: yes
	sthis: as this! ctx/sub/sink
	gsink: as ID2D1GeometrySink sthis/vtbl
	either num = 3 [				;-- cubic Bézier
		bezier/point1/x: p1x
		bezier/point1/y: p1y
		bezier/point2/x: p2x
		bezier/point2/y: p2y
		bezier/point3/x: p3x
		bezier/point3/y: p3y
		gsink/AddBezier sthis bezier
		ctx/sub/control-x: p2x
		ctx/sub/control-y: p2y
		ctx/sub/last-pt-x: p3x
		ctx/sub/last-pt-y: p3y
	][								;-- quadratic Bézier
		qbezier/point1/x: p1x
		qbezier/point1/y: p1y
		qbezier/point2/x: p2x
		qbezier/point2/y: p2y
		gsink/AddQuadraticBezier sthis qbezier
		ctx/sub/control-x: p1x
		ctx/sub/control-y: p1y
		ctx/sub/last-pt-x: p2x
		ctx/sub/last-pt-y: p2y
	]
]

OS-draw-shape-curve: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
][
	draw-curve ctx start end rel? no 3
]

OS-draw-shape-qcurve: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
][
	draw-curve ctx start end rel? no 2
]

OS-draw-shape-curv: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
][
	draw-curve ctx start - 1 end rel? yes 3
]

OS-draw-shape-qcurv: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
][
	draw-curve ctx start - 1 end rel? yes 2
]

OS-draw-shape-arc: func [
	ctx			[draw-ctx!]
	end			[red-pair!]
	sweep?		[logic!]
	large?		[logic!]
	rel?		[logic!]
	/local
		item		[red-integer!]
		p1-x		[float32!]
		p1-y		[float32!]
		p2-x		[float32!]
		p2-y		[float32!]
		radius-x	[float32!]
		radius-y	[float32!]
		theta		[float32!]
		arc			[D2D1_ARC_SEGMENT value]
		sthis		[this!]
		gsink		[ID2D1GeometrySink]
][
	;-- parse arguments
	p1-x: ctx/sub/last-pt-x
	p1-y: ctx/sub/last-pt-y
	p2-x: either rel? [ p1-x + as float32! end/x ][ as float32! end/x ]
	p2-y: either rel? [ p1-y + as float32! end/y ][ as float32! end/y ]
	ctx/sub/last-pt-x: p2-x
	ctx/sub/last-pt-y: p2-y
	item: as red-integer! end + 1
	radius-x: get-float32 item
	item: item + 1
	radius-y: get-float32 item
	item: item + 1
	theta: get-float32 item

	arc/point/x: p2-x
	arc/point/y: p2-y
	arc/size/width: radius-x
	arc/size/height: radius-y
	arc/angle: theta
	arc/direction: either sweep? [1][0]
	arc/arcSize: either large? [1][0]

	sthis: as this! ctx/sub/sink
	gsink: as ID2D1GeometrySink sthis/vtbl
	gsink/AddArc sthis arc
]

OS-draw-anti-alias: func [
	ctx			[draw-ctx!]
	on?			[logic!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	dc/SetAntialiasMode this either on? [0][1]
]

_OS-draw-polygon: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	close?		[logic!]
	/local
		d2d		[ID2D1Factory]
		path	[ptr-value!]
		hr		[integer!]
		pthis	[this!]
		gpath	[ID2D1PathGeometry]
		sink	[ptr-value!]
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		point	[D2D_POINT_2F value]
		m		[D2D_MATRIX_3X2_F value]
		bounds	[RECT_F! value]
		bthis	[this!]
		this	[this!]
		dc		[ID2D1DeviceContext]
][
	d2d: as ID2D1Factory d2d-factory/vtbl
	hr: d2d/CreatePathGeometry d2d-factory :path
	pthis: as this! path/value
	gpath: as ID2D1PathGeometry pthis/vtbl
	hr: gpath/Open pthis :sink
	sthis: as this! sink/value
	gsink: as ID2D1GeometrySink sthis/vtbl

	point/x: as float32! start/x
	point/y: as float32! start/y
	gsink/BeginFigure sthis point 1				;-- D2D1_FIGURE_BEGIN_HOLLOW
	start: start + 1
	while [start <= end] [
		point/x: as float32! start/x
		point/y: as float32! start/y
		gsink/AddLine sthis point
		start: start + 1
	]
	gsink/EndFigure sthis as-integer close?		;-- D2D1_FIGURE_END_CLOSED

	hr: gsink/Close sthis
	gsink/Release sthis

	matrix2d/identity m
	gpath/GetBounds pthis :m :bounds

	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	bthis: get-shape-brush ctx :bounds
	unless null? bthis [
		dc/FillGeometry this as int-ptr! pthis bthis null
	]
	bthis: get-shape-pen ctx :bounds
	unless null? bthis [
		dc/DrawGeometry this as int-ptr! pthis bthis ctx/pen-width ctx/pen-style
	]

	gpath/Release pthis
]

OS-draw-line: func [
	ctx			[draw-ctx!]
	point		[red-pair!]
	end			[red-pair!]
	/local
		pt0		[red-pair!]
		pt1		[red-pair!]
		this	[this!]
		dc		[ID2D1DeviceContext]
		bounds	[RECT_F! value]
		bthis	[this!]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	pt0: point
	pt1: pt0 + 1

	either pt1 = end [
		bounds/left: as float32! pt0/x
		bounds/top: as float32! pt0/y
		bounds/right: as float32! pt1/x
		bounds/bottom: as float32! pt1/y
		bthis: get-shape-pen ctx :bounds
		unless null? bthis [
			dc/DrawLine
				this
				as float32! pt0/x as float32! pt0/y
				as float32! pt1/x as float32! pt1/y
				bthis
				ctx/pen-width
				ctx/pen-style
		]
	][
		_OS-draw-polygon ctx point end no
	]
]

OS-draw-fill-pen: func [
	ctx			[draw-ctx!]
	color		[integer!]									;-- 00bbggrr format
	off?		[logic!]
	alpha?		[logic!]
	/local
		IUnk	[IUnknown]
		this	[this!]
		brush	[ID2D1SolidColorBrush]
][
	ctx/brush?: not off?
	if ctx/grad-brush/on? [
		if ctx/grad-brush/handle-on? [
			COM_SAFE_RELEASE(IUnk ctx/grad-brush/handle)
		]
		ctx/grad-brush/handle-on?: off
		ctx/grad-brush/on?: off
	]

	if all [not off? ctx/brush-color <> color][
		ctx/brush-color: color
		this: as this! ctx/brush
		brush: as ID2D1SolidColorBrush this/vtbl
		brush/SetColor this to-dx-color color null
	]
]

OS-draw-line-width: func [
	ctx			[draw-ctx!]
	width		[red-value!]
	/local
		width-v [float32!]
][
	width-v: (get-float32 as red-integer! width)
	if ctx/pen-width <> width-v [
		ctx/pen-width: width-v
	]
]

OS-draw-box: func [
	ctx			[draw-ctx!]
	upper		[red-pair!]
	lower		[red-pair!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		rc		[RECT_F! value]
		bthis	[this!]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl

	rc/right: as float32! lower/x
	rc/bottom: as float32! lower/y
	rc/left: as float32! upper/x
	rc/top: as float32! upper/y

	bthis: get-shape-brush ctx :rc
	unless null? bthis [
		dc/FillRectangle this rc bthis
	]
	bthis: get-shape-pen ctx :rc
	unless null? bthis [
		dc/DrawRectangle this rc bthis ctx/pen-width ctx/pen-style
	]
]

OS-draw-triangle: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
][
	OS-draw-polygon ctx start start + 2
]

OS-draw-polygon: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
][
	_OS-draw-polygon ctx start end yes
]

spline-delta: 1.0 / 25.0

do-spline-step: func [
	sthis		[this!]
	p0			[red-pair!]
	p1			[red-pair!]
	p2			[red-pair!]
	p3			[red-pair!]
	/local
		gsink	[ID2D1GeometrySink]
		t		[float!]
		t2		[float!]
		t3		[float!]
		x		[float!]
		y		[float!]
		point	[D2D_POINT_2F value]
][
		gsink: as ID2D1GeometrySink sthis/vtbl
		t: 0.0
		loop 25 [
			t: t + spline-delta
			t2: t * t
			t3: t2 * t

			x:
			   2.0 * (as-float p1/x) + ((as-float p2/x) - (as-float p0/x) * t) +
			   ((2.0 * (as-float p0/x) - (5.0 * (as-float p1/x)) + (4.0 * (as-float p2/x)) - (as-float p3/x)) * t2) +
			   (3.0 * ((as-float p1/x) - (as-float p2/x)) + (as-float p3/x) - (as-float p0/x) * t3) * 0.5
			y:
			   2.0 * (as-float p1/y) + ((as-float p2/y) - (as-float p0/y) * t) +
			   ((2.0 * (as-float p0/y) - (5.0 * (as-float p1/y)) + (4.0 * (as-float p2/y)) - (as-float p3/y)) * t2) +
			   (3.0 * ((as-float p1/y) - (as-float p2/y)) + (as-float p3/y) - (as-float p0/y) * t3) * 0.5
			point/x: as float32! x
			point/y: as float32! y
			gsink/AddLine sthis point
		]
]

OS-draw-spline: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	closed?		[logic!]
	/local
		d2d		[ID2D1Factory]
		path	[ptr-value!]
		hr		[integer!]
		pthis	[this!]
		gpath	[ID2D1PathGeometry]
		sink	[ptr-value!]
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		point	[D2D_POINT_2F value]
		m		[D2D_MATRIX_3X2_F value]
		bounds	[RECT_F! value]
		bthis	[this!]
		this	[this!]
		dc		[ID2D1DeviceContext]
		pt		[red-pair!]
		stop	[red-pair!]
][
	if (as-integer end - start) >> 4 = 1 [		;-- two points input
		OS-draw-line ctx start end				;-- draw a line
		exit
	]

	d2d: as ID2D1Factory d2d-factory/vtbl
	hr: d2d/CreatePathGeometry d2d-factory :path
	pthis: as this! path/value
	gpath: as ID2D1PathGeometry pthis/vtbl
	hr: gpath/Open pthis :sink
	sthis: as this! sink/value
	gsink: as ID2D1GeometrySink sthis/vtbl

	point/x: as float32! start/x
	point/y: as float32! start/y
	gsink/BeginFigure sthis point 1				;-- D2D1_FIGURE_BEGIN_HOLLOW

	either closed? [
		do-spline-step sthis
			end
			start
			start + 1
			start + 2
	][
		do-spline-step sthis
			start
			start
			start + 1
			start + 2
	]

	pt: start
	stop: end - 3

	while [pt <= stop] [
		do-spline-step sthis
			pt
			pt + 1
			pt + 2
			pt + 3
		pt: pt + 1
	]

	either closed? [
		do-spline-step sthis
			end - 2
			end - 1
			end
			start
		do-spline-step sthis
			end - 1
			end
			start
			start + 1
		gsink/EndFigure sthis 1						;-- D2D1_FIGURE_END_CLOSED
	][
		do-spline-step sthis
			end - 2
			end - 1
			end
			end
		gsink/EndFigure sthis 0						;-- D2D1_FIGURE_END_OPEN
	]

	hr: gsink/Close sthis
	gsink/Release sthis

	matrix2d/identity m
	gpath/GetBounds pthis :m :bounds

	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	bthis: get-shape-brush ctx :bounds
	unless null? bthis [
		dc/FillGeometry this as int-ptr! pthis bthis null
	]
	bthis: get-shape-pen ctx :bounds
	unless null? bthis [
		dc/DrawGeometry this as int-ptr! pthis bthis ctx/pen-width ctx/pen-style
	]
	gpath/Release pthis
]

do-draw-ellipse: func [
	ctx			[draw-ctx!]
	x			[integer!]
	y			[integer!]
	width		[integer!]
	height		[integer!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		cx		[float32!]
		cy		[float32!]
		rx		[float32!]
		ry		[float32!]
		ellipse	[D2D1_ELLIPSE value]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl

	cx: as float32! x
	cy: as float32! y
	rx: as float32! width
	ry: as float32! height
	rx: rx / as float32! 2.0
	ry: ry / as float32! 2.0
	ellipse/x: cx + rx
	ellipse/y: cy + ry
	ellipse/radiusX: rx
	ellipse/radiusY: ry
	;-- TBD
		dc/FillEllipse this ellipse ctx/brush
		dc/DrawEllipse this ellipse ctx/pen ctx/pen-width ctx/pen-style
]

OS-draw-circle: func [
	ctx			[draw-ctx!]
	center		[red-pair!]
	radius		[red-integer!]
	/local
		rad-x	[integer!]
		rad-y	[integer!]
		w		[integer!]
		h		[integer!]
		f		[red-float!]
][
	either TYPE_OF(radius) = TYPE_INTEGER [
		either center + 1 = radius [					;-- center, radius
			rad-x: radius/value
			rad-y: rad-x
		][
			rad-y: radius/value							;-- center, radius-x, radius-y
			radius: radius - 1
			rad-x: radius/value
		]
		w: rad-x * 2
		h: rad-y * 2
	][
		f: as red-float! radius
		either center + 1 = radius [
			rad-x: as-integer f/value + 0.75
			rad-y: rad-x
			w: as-integer f/value * 2.0
			h: w
		][
			rad-y: as-integer f/value + 0.75
			h: as-integer f/value * 2.0
			f: f - 1
			rad-x: as-integer f/value + 0.75
			w: as-integer f/value * 2.0
		]
	]
	do-draw-ellipse ctx center/x - rad-x center/y - rad-y w h
]

OS-draw-ellipse: func [
	ctx			[draw-ctx!]
	upper		[red-pair!]
	diameter	[red-pair!]
][
	do-draw-ellipse ctx upper/x upper/y diameter/x diameter/y
]

OS-draw-font: func [
	ctx		[draw-ctx!]
	font	[red-object!]
	/local
		clr [red-tuple!]
][
	ctx/text-format: as this! create-text-format font null
	;-- set font color
	clr: as red-tuple! (object/get-values font) + FONT_OBJ_COLOR
	if TYPE_OF(clr) = TYPE_TUPLE [
		ctx/font-color: clr/array1
		ctx/font-color?: yes
	]
]

OS-draw-arc: func [
	ctx				[draw-ctx!]
	center			[red-pair!]
	end				[red-value!]
	/local
		cx			[float32!]
		cy			[float32!]
		rad			[float32!]
		radius		[red-pair!]
		rad-x		[float32!]
		rad-y		[float32!]
		begin		[red-integer!]
		angle-begin [float32!]
		angle		[red-integer!]
		sweep		[integer!]
		i			[integer!]
		angle-end	[float32!]
		start-x		[float32!]
		start-y		[float32!]
		end-x		[float32!]
		end-y		[float32!]
		closed?		[logic!]
		d2d			[ID2D1Factory]
		path		[ptr-value!]
		hr			[integer!]
		pthis		[this!]
		gpath		[ID2D1PathGeometry]
		sink		[ptr-value!]
		sthis		[this!]
		gsink		[ID2D1GeometrySink]
		point		[D2D_POINT_2F value]
		this		[this!]
		dc			[ID2D1DeviceContext]
		arc			[D2D1_ARC_SEGMENT value]
][
	cx: as float32! center/x
	cy: as float32! center/y
	rad: (as float32! PI) / as float32! 180.0

	radius: center + 1
	rad-x: as float32! radius/x
	rad-y: as float32! radius/y
	begin: as red-integer! radius + 1
	angle-begin: rad * as float32! begin/value
	angle: begin + 1
	sweep: angle/value
	i: begin/value + sweep
	angle-end: rad * as float32! i
	start-x: as float32! cos as float! angle-begin
	start-x: cx + (rad-x * start-x)
	start-y: as float32! sin as float! angle-begin
	start-y: cy + (rad-y * start-y)
	end-x: as float32! cos as float! angle-end
	end-x: cx + (rad-x * end-x)
	end-y: as float32! sin as float! angle-end
	end-y: cy + (rad-y * end-y)

	closed?: angle < end

	d2d: as ID2D1Factory d2d-factory/vtbl
	hr: d2d/CreatePathGeometry d2d-factory :path
	pthis: as this! path/value
	gpath: as ID2D1PathGeometry pthis/vtbl
	hr: gpath/Open pthis :sink
	sthis: as this! sink/value
	gsink: as ID2D1GeometrySink sthis/vtbl

	point/x: start-x
	point/y: start-y
	gsink/BeginFigure sthis point 1				;-- D2D1_FIGURE_BEGIN_HOLLOW
	arc/point/x: end-x
	arc/point/y: end-y
	arc/size/width: rad-x
	arc/size/height: rad-y
	arc/angle: as float32! 0.0
	arc/direction: 1							;-- D2D1_SWEEP_DIRECTION_CLOCKWISE
	arc/arcSize: either sweep >= 180 [1][0]
	hr: gsink/AddArc sthis arc
	gsink/EndFigure sthis either closed? [1][0]

	hr: gsink/Close sthis
	gsink/Release sthis

	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	;-- TBD
		dc/FillGeometry this as int-ptr! pthis ctx/brush null
		dc/DrawGeometry this as int-ptr! pthis ctx/pen ctx/pen-width ctx/pen-style
	gpath/Release pthis
]

OS-draw-curve: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	/local
		cp1x	[float32!]
		cp1y	[float32!]
		cp2x	[float32!]
		cp2y	[float32!]
		p2		[red-pair!]
		p3		[red-pair!]
		ps		[D2D1_BEZIER_SEGMENT value]
		d2d		[ID2D1Factory]
		path	[ptr-value!]
		hr		[integer!]
		pthis	[this!]
		gpath	[ID2D1PathGeometry]
		sink	[ptr-value!]
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		point	[D2D_POINT_2F value]
		m		[D2D_MATRIX_3X2_F value]
		bounds	[RECT_F! value]
		bthis	[this!]
		this	[this!]
		dc		[ID2D1DeviceContext]
][
	p2: start + 1
	p3: start + 2

	either 2 = ((as-integer end - start) >> 4) [		;-- p0, p1, p2  -->  p0, (p0 + 2p1) / 3, (2p1 + p2) / 3, p2
		cp1x: (as float32! p2/x << 1 + start/x) / as float32! 3.0
		cp1y: (as float32! p2/y << 1 + start/y) / as float32! 3.0
		cp2x: (as float32! p2/x << 1 + p3/x) / as float32! 3.0
		cp2y: (as float32! p2/y << 1 + p3/y) / as float32! 3.0
	][
		cp1x: as float32! p2/x
		cp1y: as float32! p2/y
		cp2x: as float32! p3/x
		cp2y: as float32! p3/y
	]
	ps/point1/x: cp1x
	ps/point1/y: cp1y
	ps/point2/x: cp2x
	ps/point2/y: cp2y
	ps/point3/x: as float32! end/x
	ps/point3/y: as float32! end/y

	d2d: as ID2D1Factory d2d-factory/vtbl
	hr: d2d/CreatePathGeometry d2d-factory :path
	pthis: as this! path/value
	gpath: as ID2D1PathGeometry pthis/vtbl
	hr: gpath/Open pthis :sink
	sthis: as this! sink/value
	gsink: as ID2D1GeometrySink sthis/vtbl

	point/x: as float32! start/x
	point/y: as float32! start/y
	gsink/BeginFigure sthis point 1				;-- D2D1_FIGURE_BEGIN_HOLLOW
	hr: gsink/AddBezier sthis ps
	gsink/EndFigure sthis 0
	hr: gsink/Close sthis
	gsink/Release sthis

	matrix2d/identity m
	gpath/GetBounds pthis :m :bounds

	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	bthis: get-shape-brush ctx :bounds
	unless null? bthis [
		dc/FillGeometry this as int-ptr! pthis bthis null
	]
	bthis: get-shape-pen ctx :bounds
	unless null? bthis [
		dc/DrawGeometry this as int-ptr! pthis bthis ctx/pen-width ctx/pen-style
	]
	gpath/Release pthis
]

OS-draw-line-join: func [
	ctx			[draw-ctx!]
	style		[integer!]
	/local
		mode	[integer!]
][
	case [
		style = miter		[mode: D2D1_LINE_JOIN_MITER]
		style = miter-bevel [mode: D2D1_LINE_JOIN_MITER_OR_BEVEL]
		style = _round		[mode: D2D1_LINE_JOIN_ROUND]
		style = bevel		[mode: D2D1_LINE_JOIN_BEVEL]
		true				[mode: D2D1_LINE_JOIN_MITER]
	]
	ctx/pen-join: mode
	update-pen-style ctx
]

OS-draw-line-cap: func [
	ctx			[draw-ctx!]
	style		[integer!]
	/local
		mode	[integer!]
][
	case [
		style = flat		[mode: D2D1_CAP_STYLE_FLAT]
		style = square		[mode: D2D1_CAP_STYLE_SQUARE]
		style = _round		[mode: D2D1_CAP_STYLE_ROUND]
		true				[mode: D2D1_CAP_STYLE_FLAT]
	]
	ctx/pen-cap: mode
	update-pen-style ctx
]

create-4p-matrix: func [
	size		[SIZE_F!]
	ul			[D2D_POINT_2F]
	ur			[D2D_POINT_2F]
	ll			[D2D_POINT_2F]
	lr			[D2D_POINT_2F]
	m			[MATRIX_4x4_F!]
	/local
		s		[MATRIX_4x4_F! value]
		a		[MATRIX_4x4_F! value]
		b		[MATRIX_4x4_F! value]
		c		[MATRIX_4x4_F! value]
		den		[float32!]
		t1		[float32!]
		t2		[float32!]
][
	matrix4x4/identity s
	s/_11: (as float32! 1.0) / size/width
	s/_22: (as float32! 1.0) / size/height

	matrix4x4/identity a
	a/_41: ul/x
	a/_42: ul/y
	a/_11: ur/x - ul/x
	a/_12: ur/y - ul/y
	a/_21: ll/x - ul/x
	a/_22: ll/y - ul/y

	matrix4x4/identity b
	den: a/_11 * a/_22 - (a/_12 * a/_21)
	t1: a/_22 * lr/x - (a/_21 * lr/y) + (a/_21 * a/_42) - (a/_22 * a/_41)
	t1: t1 / den
	t2: a/_11 * lr/y - (a/_12 * lr/x) + (a/_12 * a/_41) - (a/_11 * a/_42)
	t2: t2 / den
	b/_11: t1 / (t1 + t2 - as float32! 1.0)
	b/_22: t2 / (t1 + t2 - as float32! 1.0)
	b/_14: b/_11 - as float32! 1.0
	b/_24: b/_22 - as float32! 1.0

	matrix4x4/identity c
	matrix4x4/mul s b c
	matrix4x4/mul c a m
]

OS-draw-image: func [
	ctx			[draw-ctx!]
	image		[red-image!]
	start		[red-pair!]
	end			[red-pair!]
	key-color	[red-tuple!]
	border?		[logic!]
	crop1		[red-pair!]
	pattern		[red-word!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		ithis	[this!]
		IB		[IUnknown]
		bmp		[ptr-value!]
		bthis	[this!]
		d2db	[IUnknown]
		x		[integer!]
		y		[integer!]
		width	[integer!]
		height	[integer!]
		pt		[red-pair!]
		size	[SIZE_F! value]
		ul		[D2D_POINT_2F value]
		ur		[D2D_POINT_2F value]
		ll		[D2D_POINT_2F value]
		lr		[D2D_POINT_2F value]
		m		[MATRIX_4x4_F! value]
		trans	[int-ptr!]
		dst*	[RECT_F! value]
		dst		[RECT_F!]
		src*	[RECT_F! value]
		src		[RECT_F!]
		crop2	[red-pair!]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	ithis: OS-image/to-pbgra image
	IB: as IUnknown ithis/vtbl
	dc/CreateBitmapFromWicBitmap2 this ithis null :bmp
	bthis: as this! bmp/value
	d2db: as IUnknown bthis/vtbl
	either null? start [x: 0 y: 0][x: start/x y: start/y]
	width:  IMAGE_WIDTH(image/size)
	height: IMAGE_HEIGHT(image/size)

	either crop1 <> null [
		crop2: crop1 + 1
		src*/left: as float32! crop1/x
		src*/top: as float32! crop1/y
		src*/right: as float32! crop1/x + crop2/x
		src*/bottom: as float32! crop1/y + crop2/y
		src: :src*
		size/width: as float32! crop2/x
		size/height: as float32! crop2/y
	][
		src: null
		size/width: as float32! width
		size/height: as float32! height
	]

	trans: null
	dst: null
	case [
		start = end [
			dst*/left: as float32! x
			dst*/top: as float32! y
			dst*/right: as float32! x + width
			dst*/bottom: as float32! y + height
			dst: :dst*
		]
		start + 1 = end [					;-- two control points
			dst*/left: as float32! x
			dst*/top: as float32! y
			dst*/right: as float32! end/x
			dst*/bottom: as float32! end/y
			dst: :dst*
		]
		start + 2 = end [
			pt: start
			ul/x: as float32! pt/x
			ul/y: as float32! pt/y
			pt: start + 1
			ur/x: as float32! pt/x
			ur/y: as float32! pt/y
			pt: start + 2
			ll/x: as float32! pt/x
			ll/y: as float32! pt/y
			;-- not support ll == lr
			lr/x: as float32! pt/x + 1
			lr/y: as float32! pt/y
			create-4p-matrix size ul ur ll lr m
			trans: as int-ptr! :m
		]
		start + 3 = end [
			pt: start
			ul/x: as float32! pt/x
			ul/y: as float32! pt/y
			pt: start + 1
			ur/x: as float32! pt/x
			ur/y: as float32! pt/y
			pt: start + 2
			ll/x: as float32! pt/x
			ll/y: as float32! pt/y
			pt: start + 3
			lr/x: as float32! pt/x
			lr/y: as float32! pt/y
			create-4p-matrix size ul ur ll lr m
			trans: as int-ptr! :m
		]
		true [0]
	]

	;-- D2D1_INTERPOLATION_MODE_DEFINITION_LINEAR
	dc/DrawBitmap2 this as int-ptr! bthis dst as float32! 1.0 1 src trans

	d2db/Release bthis
	IB/Release ithis
]

_OS-draw-brush-bitmap: func [
	ctx		[draw-ctx!]
	bmp		[this!]
	width	[integer!]
	height	[integer!]
	crop-1	[red-pair!]
	crop-2	[red-pair!]
	mode	[red-word!]
	brush?	[logic!]
	/local
		x		[integer!]
		y		[integer!]
		xx		[integer!]
		yy		[integer!]
		wrap	[integer!]
		wrap-x	[integer!]
		wrap-y	[integer!]
		props	[D2D1_IMAGE_BRUSH_PROPERTIES value]
		this	[this!]
		dc		[ID2D1DeviceContext]
		brush	[ptr-value!]
		unk		[IUnknown]
][
	either crop-1 = null [
		x: 0
		y: 0
	][
		x: crop-1/x
		y: crop-1/y
	]
	either crop-2 = null [
		xx: width
		yy: height
	][
		xx: crop-2/x
		yy: crop-2/y
		if xx > width [xx: width]
		if yy > height [yy: height]
	]

	wrap-x: D2D1_EXTEND_MODE_WRAP
	wrap-y: D2D1_EXTEND_MODE_WRAP
	unless mode = null [
		wrap: symbol/resolve mode/symbol
		case [
			wrap = flip-x [ wrap-x: D2D1_EXTEND_MODE_MIRROR ]
			wrap = flip-y [ wrap-y: D2D1_EXTEND_MODE_MIRROR ]
			wrap = flip-xy [
				wrap-x: D2D1_EXTEND_MODE_MIRROR
				wrap-y: D2D1_EXTEND_MODE_MIRROR
			]
			wrap = clamp [
				wrap-x: D2D1_EXTEND_MODE_CLAMP
				wrap-y: D2D1_EXTEND_MODE_CLAMP
			]
			true [0]
		]
	]

	props/left: as float32! x
	props/top: as float32! y
	props/right: as float32! xx
	props/bottom: as float32! yy
	props/extendModeX: wrap-x
	props/extendModeY: wrap-y
	props/interpolationMode: 1		;-- MODE_LINEAR

	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	dc/CreateImageBrush this bmp :props null :brush
	if ctx/bitmap-brush? [
		COM_SAFE_RELEASE(unk ctx/bitmap-brush)
	]
	ctx/bitmap-brush?: yes
	ctx/bitmap-brush: as this! brush/value
]

OS-draw-brush-bitmap: func [
	ctx		[draw-ctx!]
	img		[red-image!]
	crop-1	[red-pair!]
	crop-2	[red-pair!]
	mode	[red-word!]
	brush?	[logic!]
	/local
		width	[integer!]
		height	[integer!]
		dc		[ID2D1DeviceContext]
		this	[this!]
		ithis	[this!]
		bmp		[ptr-value!]
		unk		[IUnknown]
][
	width:  OS-image/width? img/node
	height: OS-image/height? img/node
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	ithis: OS-image/to-pbgra img
	dc/CreateBitmapFromWicBitmap2 this ithis null :bmp
	_OS-draw-brush-bitmap ctx as this! bmp/value width height crop-1 crop-2 mode brush?
	COM_SAFE_RELEASE(unk ithis)
	ithis: as this! bmp/value
	COM_SAFE_RELEASE(unk ithis)
]

OS-draw-brush-pattern: func [
	ctx		[draw-ctx!]
	size	[red-pair!]
	crop-1	[red-pair!]
	crop-2	[red-pair!]
	mode	[red-word!]
	block	[red-block!]
	brush?	[logic!]
	/local
		dc		[ID2D1DeviceContext]
		this	[this!]
		list	[com-ptr! value]
		cthis	[this!]
		cmd		[ID2D1CommandList]
		old-rt	[com-ptr! value]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	dc/CreateCommandList this :list
	cthis: list/value

	dc/GetTarget this :old-rt
	dc/SetTarget this cthis
	parse-draw ctx block no
	cmd: as ID2D1CommandList cthis/vtbl
	cmd/Close cthis
	dc/SetTarget this old-rt/value

	_OS-draw-brush-bitmap ctx cthis size/x size/y crop-1 crop-2 mode brush?
	cmd/Release cthis
]

OS-draw-grad-pen-old: func [
	ctx			[draw-ctx!]
	type		[integer!]
	mode		[integer!]
	offset		[red-pair!]
	count		[integer!]					;-- number of the colors
	brush?		[logic!]
][
	;Deprecated, no need to implement it.
]

OS-draw-grad-pen: func [
	ctx			[draw-ctx!]
	type		[integer!]
	stops		[red-value!]
	count		[integer!]
	skip-pos?	[logic!]
	positions	[red-value!]
	focal?		[logic!]
	spread		[integer!]
	brush?		[logic!]
	/local
		grad	[gradient!]
		IUnk	[IUnknown]
		point	[red-pair!]
		gstops	[D2D1_GRADIENT_STOP]
		tstops	[D2D1_GRADIENT_STOP]
		nstops	[D2D1_GRADIENT_STOP]
		f		[red-float!]
		head	[red-value!]
		next	[red-value!]
		clr		[red-tuple!]
		n		[integer!]
		delta	[float!]
		p		[float!]
		wrap	[integer!]
		sc		[com-ptr! value]
		dc		[ID2D1DeviceContext]
		this	[this!]
][
	grad: either brush? [
		ctx/brush?: yes
		ctx/grad-brush
	][
		ctx/pen?: yes
		ctx/grad-pen
	]
	unless grad/on? [
		COM_SAFE_RELEASE(IUnk grad/stop)
		grad/on?: on
	]
	grad/spread: spread
	grad/type: type

	grad/focal-on?: off
	case [
		type = linear [
			either skip-pos? [
				grad/offset-on?: off
			][
				grad/offset-on?: on
				point: as red-pair! positions
				grad/offset/x: as float32! point/x
				grad/offset/y: as float32! point/y
				point: point + 1
				grad/offset2/x: as float32! point/x
				grad/offset2/y: as float32! point/y
			]
		]
		type = radial [
			either skip-pos? [
				grad/offset-on?: off
			][
				grad/offset-on?: on
				point: as red-pair! positions
				grad/offset/x: as float32! point/x
				grad/offset/y: as float32! point/y
				grad/offset2/x: get-float32 as red-integer! point + 1
				grad/offset2/y: grad/offset2/x
				if focal? [
					grad/focal-on?: on
					point: point + 2
					grad/focal/x: as float32! point/x
					grad/focal/y: as float32! point/y
				]
			]
		]
		true [
			grad/offset-on?: off
		]
	]
	matrix2d/identity as D2D_MATRIX_3X2_F grad/matrix

	gstops: grad-stops + 1
	nstops: gstops
	n: count - 1
	delta: as float! n
	delta: 1.0 / delta
	p: 0.0
	head: stops
	loop count [
		clr: as red-tuple! either TYPE_OF(head) = TYPE_WORD [_context/get as red-word! head][head]
		next: head + 1
		to-dx-color clr/array1 as D3DCOLORVALUE (as int-ptr! gstops) + 1
		if TYPE_OF(next) = TYPE_FLOAT [head: next f: as red-float! head p: f/value]
		gstops/position: as float32! p
		if next <> head [p: p + delta]
		head: head + 1
		gstops: gstops + 1
	]

	tstops: grad-stops + 1
	if tstops/position > as float32! 0.0 [			;-- first one should be always 0.0
		copy-memory as byte-ptr! grad-stops as byte-ptr! tstops size? D2D1_GRADIENT_STOP
		grad-stops/position: as float32! 0.0
		count: count + 1
		nstops: grad-stops
	]
	tstops: gstops - 1
	if tstops/position < as float32! 1.0 [			;-- last one should be always 1.0
		copy-memory as byte-ptr! gstops as byte-ptr! tstops size? D2D1_GRADIENT_STOP
		gstops/position: as float32! 1.0
		count: count + 1
	]

	case [
		spread = _pad		[wrap: 0]
		spread = _repeat	[wrap: 1]
		spread = _reflect	[wrap: 2]
		true [wrap: 0]
	]

	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	sc/value: null
	dc/CreateGradientStopCollection this nstops count 0 wrap :sc
	grad/stop: sc/value
]

OS-set-clip: func [
	ctx		[draw-ctx!]
	u		[red-pair!]
	l		[red-pair!]
	rect?	[logic!]
	mode	[integer!]
][

]

OS-matrix-rotate: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	angle		[red-integer!]
	center		[red-pair!]
	/local
		rad		[float!]
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
		t		[D2D_MATRIX_3X2_F value]
][
	rad: PI / 180.0 * get-float angle
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m
		either angle <> as red-integer! center [
			matrix2d/translate :m as float32! 0 - center/x as float32! 0 - center/y :t
			matrix2d/rotate :t as float32! rad :m
			matrix2d/translate :m as float32! center/x as float32! center/y :t
		][
			matrix2d/rotate :m as float32! rad :t
		]
		dc/SetTransform this :t
	][
		;-- TBD
		exit
	]
]

OS-matrix-scale: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	sx			[red-integer!]
	sy			[red-integer!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
		t		[D2D_MATRIX_3X2_F value]
][
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m
		matrix2d/scale :m get-float32 sx get-float32 sy :t
		dc/SetTransform this :t
	][
		;-- TBD
		exit
	]
]

OS-matrix-translate: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	x			[integer!]
	y			[integer!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
		t		[D2D_MATRIX_3X2_F value]
][
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m
		matrix2d/translate :m as float32! x as float32! y :t
		dc/SetTransform this :t
	][
		;-- TBD
		exit
	]
]

OS-matrix-skew: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	sx			[red-integer!]
	sy			[red-integer!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
		t		[D2D_MATRIX_3X2_F value]
		x		[float32!]
		y		[float32!]
][
	x: as float32! degree-to-radians get-float sx TYPE_TANGENT
	y: as float32! degree-to-radians get-float sy TYPE_TANGENT
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m
		matrix2d/skew :m x y :t
		dc/SetTransform this :t
	][
		;-- TBD
		exit
	]
]

OS-matrix-transform: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	center		[red-pair!]
	scale		[red-integer!]
	translate	[red-pair!]
	/local
		rotate	[red-integer!]
		center?	[logic!]
][
	rotate: as red-integer! either center + 1 = scale [center][center + 1]
	center?: rotate <> center

	OS-matrix-rotate ctx pen-fill rotate center
	OS-matrix-scale ctx pen-fill scale scale + 1
	OS-matrix-translate ctx pen-fill translate/x translate/y
]

OS-draw-state-push: func [
	ctx		[draw-ctx!]
	state	[draw-state!]
	/local
		factory	[ID2D1Factory]
		blk		[ptr-value!]
		this	[this!]
		dc		[ID2D1DeviceContext]
		unk		[IUnknown]
][
	factory: as ID2D1Factory d2d-factory/vtbl
	if 0 <> factory/CreateDrawingStateBlock d2d-factory null null :blk [
		;TBD error!!!
		probe "OS-draw-state-push failed"
		exit
	]
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	dc/SaveDrawingState this as this! blk/value
	state/block: as this! blk/value
	state/pen-clr: ctx/pen-color
	state/brush-clr: ctx/brush-color
	state/pen-join: ctx/pen-join
	state/pen-cap: ctx/pen-cap
	state/pen?: ctx/pen?
	state/pen: ctx/pen
	COM_ADD_REF(unk state/pen)
	state/brush?: ctx/brush?
	state/brush: ctx/brush
	COM_ADD_REF(unk state/brush)
	state/bitmap-brush?: ctx/bitmap-brush?
	state/bitmap-brush: ctx/bitmap-brush
	if state/bitmap-brush? [
		COM_ADD_REF(unk state/bitmap-brush)
	]
	copy-memory as byte-ptr! state/grad-pen as byte-ptr! ctx/grad-pen size? gradient!
	copy-memory as byte-ptr! state/grad-brush as byte-ptr! ctx/grad-brush size? gradient!
	if state/grad-pen/on? [
		COM_ADD_REF(unk state/grad-pen/stop)
		if state/grad-pen/handle-on? [
			COM_ADD_REF(unk state/grad-pen/handle)
		]
	]
	if state/grad-brush/on? [
		COM_ADD_REF(unk state/grad-brush/stop)
		if state/grad-brush/handle-on? [
			COM_ADD_REF(unk state/grad-brush/handle)
		]
	]
]

OS-draw-state-pop: func [
	ctx		[draw-ctx!]
	state	[draw-state!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		IUnk	[IUnknown]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	dc/RestoreDrawingState this state/block
	COM_SAFE_RELEASE(IUnk state/block)
	ctx/pen-color: state/pen-clr
	ctx/brush-color: state/brush-clr
	ctx/pen-join: state/pen-join
	ctx/pen-cap: state/pen-cap
	COM_SAFE_RELEASE(IUnk ctx/pen)
	COM_SAFE_RELEASE(IUnk ctx/brush)
	ctx/pen: state/pen
	ctx/brush: state/brush
	if ctx/bitmap-brush? [
		COM_SAFE_RELEASE(IUnk ctx/bitmap-brush)
	]
	ctx/bitmap-brush?: state/bitmap-brush?
	ctx/bitmap-brush: state/bitmap-brush
	if ctx/grad-pen/on? [
		COM_SAFE_RELEASE(IUnk ctx/grad-pen/stop)
		if ctx/grad-pen/handle-on? [
			COM_SAFE_RELEASE(IUnk ctx/grad-pen/handle)
		]
	]
	if ctx/grad-brush/on? [
		COM_SAFE_RELEASE(IUnk ctx/grad-brush/stop)
		if ctx/grad-brush/handle-on? [
			COM_SAFE_RELEASE(IUnk ctx/grad-brush/handle)
		]
	]
	copy-memory as byte-ptr! ctx/grad-pen as byte-ptr! state/grad-pen size? gradient!
	copy-memory as byte-ptr! ctx/grad-brush as byte-ptr! state/grad-brush size? gradient!
	update-pen-style ctx
]

OS-matrix-reset: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
][
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		;dc/GetTransform this :m
		matrix2d/identity :m
		dc/SetTransform this :m
	][
		;-- TBD
		exit
	]
]

OS-matrix-invert: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
		t		[D2D_MATRIX_3X2_F value]
][
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m
		matrix2d/invert :m :t
		dc/SetTransform this :t
	][
		;-- TBD
		exit
	]
]

OS-matrix-set: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	blk			[red-block!]
	/local
		val		[red-integer!]
		this	[this!]
		dc		[ID2D1DeviceContext]
		m0		[D2D_MATRIX_3X2_F value]
		m		[D2D_MATRIX_3X2_F value]
		t		[D2D_MATRIX_3X2_F value]
][
	val: as red-integer! block/rs-head blk
	m/_11: get-float32 val
	m/_12: get-float32 val + 1
	m/_21: get-float32 val + 2
	m/_22: get-float32 val + 3
	m/_31: get-float32 val + 4
	m/_32: get-float32 val + 5
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m0
		matrix2d/mul m0 m t
		dc/SetTransform this :t
	][
		;-- TBD
		exit
	]
]

OS-set-matrix-order: func [
	ctx		[draw-ctx!]
	order	[integer!]
][

]

OS-draw-shadow: func [
	ctx		[draw-ctx!]
	offset	[red-pair!]
	blur	[integer!]
	spread	[integer!]
	color	[integer!]
	inset?	[logic!]
	/local
		s		[shadow!]
		ss		[shadow!]
		chain?	[logic!]
][
	chain?: ctx/shadow?
	ctx/shadow?: TYPE_OF(offset) = TYPE_PAIR
	either ctx/shadow? [
		either chain? [
			s: as shadow! allocate size? shadow!
			ss: ctx/shadows/next
			either null? ss [ctx/shadows/next: s][
				ss/next: s
			]
		][
			s: ctx/shadows
			s/next: null
		]
		s/offset-x: offset/x
		s/offset-y: offset/y
		s/blur: blur
		s/spread: spread
		s/color: color
		s/inset?: inset?
	][
		ss: ctx/shadows/next
		while [ss <> null][
			s: ss
			ss: ss/next
			free as byte-ptr! s
		]
		ctx/shadows/next: null
	]
]