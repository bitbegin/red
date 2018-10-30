Red/System [
	Title:	"Gaussian Blur for image"
	Author: "bitbegin"
	File: 	%blur.reds
	Note:	"Gaussian Blur algorithm"
	Tabs: 	4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

;-- here some useful references
;-- https://www.w3.org/TR/filter-effects/#feGaussianBlurElement
;-- http://blog.ivank.net/fastest-gaussian-blur.html
;-- https://github.com/mozilla/gecko-dev/blob/master/gfx/2d/Blur.cpp


;-- (3 * sqrt(2 * PI) / 4) * 1.5
#define GAUSSIAN_SCALE_FACTOR		2.819956808959875

#define INIT_ITER [
	temp: as integer! src/1
	alphaSum: alphaSum + as float! temp
	src: src + inputStep
]

#define LEFT_ITER [
	ft: alphaSum * reciprocal
	ft: ft / 16777216.0		; ft >>> 24
	temp: as integer! ft
	dst/1: as byte! temp
	temp: (as integer! src/1) - (as integer! firstVal)
	alphaSum: alphaSum + as float! temp
	dst: dst + outputStep
	src: src + inputStep
]

#define CENTER_ITER [
	ft: alphaSum * reciprocal
	ft: ft / 16777216.0		; ft >>> 24
	temp: as integer! ft
	dst/1: as byte! temp
	p: src + boxStep
	temp: (as integer! p/1) - (as integer! src/1)
	alphaSum: alphaSum + as float! temp
	dst: dst + outputStep
	src: src + inputStep
]

#define RIGHT_ITER [
	ft: alphaSum * reciprocal
	ft: ft / 16777216.0		; ft >>> 24
	temp: as integer! ft
	dst/1: as byte! temp
	temp: (as integer! lastVal) - (as integer! src/1)
	alphaSum: alphaSum + as float! temp
	dst: dst + outputStep
	src: src + inputStep
]

#define _MIN(a b) [either a > b [b][a]]
#define _MAX(a b) [either a < b [b][a]]

INT_SIZE: alias struct! [
	width				[integer!]
	height				[integer!]
]

;-- used for single file compile
RECT_STRUCT: alias struct! [
	left		[integer!]
	top			[integer!]
	right		[integer!]
	bottom		[integer!]
]

#if debug? = yes [
	dump-rect-radix: true
	dump-rect: func [
		src		[byte-ptr!]
		w		[integer!]
		h		[integer!]
		hex?	[logic!]
		/local
			i	[integer!]
			j	[integer!]
			p	[byte-ptr!]
	][
		i: 0
		while [i < w][
			j: 0
			while [j < h][
				p: src + (i * w) + j
				j: j + 1
				either hex? [
					prin-hex-chars as integer! p/1 2
				][
					print as integer! p/1
				]
				print " "
			]
			print-line lf
			i: i + 1
		]
		print-line ""
	]

	rect-print: func [
		rc					[RECT_STRUCT]
	][
		print-line ["left: " rc/left " top: " rc/top " right: " rc/right " bottom: " rc/bottom]
	]
]

rect-init: func [
	rc					[RECT_STRUCT]
	left				[integer!]
	top					[integer!]
	right				[integer!]
	bottom				[integer!]
][
	rc/left: left
	rc/top: top
	rc/right: right
	rc/bottom: bottom
]

rect-offset: func [
	rc					[RECT_STRUCT]
	x					[integer!]
	y					[integer!]
][
	rc/left: rc/left + x
	rc/right: rc/right + x
	rc/top: rc/top + y
	rc/bottom: rc/bottom + y
]

rect-inflate: func [
	rc					[RECT_STRUCT]
	x					[integer!]
	y					[integer!]
	/local
		t				[integer!]
][
	rc/left: rc/left - x
	rc/right: rc/right + x
	rc/top: rc/top - y
	rc/bottom: rc/bottom + y
	if rc/left > rc/right [t: rc/left rc/left: rc/right rc/right: t]
	if rc/top > rc/bottom [t: rc/top rc/top: rc/bottom rc/bottom: t]
	if rc/left < 0 [rc/left: 0]
	if rc/top < 0 [rc/top: 0]
]

rect-intersect: func [
	rc1					[RECT_STRUCT]
	rc2					[RECT_STRUCT]
	ret					[RECT_STRUCT]
][
	ret/left: _MAX(rc1/left rc2/left)
	ret/top: _MAX(rc1/top rc2/top)
	ret/right: _MIN(rc1/right rc2/right)
	ret/bottom: _MIN(rc1/bottom rc2/bottom)
	if any [
		ret/right < ret/left
		ret/bottom < ret/top
	][
		ret/right: ret/left
		ret/bottom: ret/top
	]
]

rect-copy: func [
	rc					[RECT_STRUCT]
	src					[RECT_STRUCT]
][
	rc/left: src/left
	rc/top: src/top
	rc/right: src/right
	rc/bottom: src/bottom
]

rect-swap: func [
	rect				[RECT_STRUCT]
	/local
		temp			[integer!]
][
	temp: rect/left
	rect/left: rect/top
	rect/top: temp
	temp: rect/right
	rect/right: rect/bottom
	rect/bottom: temp
]

rect-contains: func [
	outer				[RECT_STRUCT]
	inner				[RECT_STRUCT]
	return:				[logic!]
][
	if all [
		outer/left <= inner/left
		outer/right >= inner/right
		outer/top <= inner/top
		outer/bottom >= inner/bottom
	][return true]
	false
]

rect-empty?: func [
	rc					[RECT_STRUCT]
	return: 			[logic!]
][
	if any [
		rc/right <= rc/left
		rc/bottom <= rc/top
	][return true]
	false
]

rect-equal?: func [
	rc1					[RECT_STRUCT]
	rc2					[RECT_STRUCT]
	return: 			[logic!]
][
	if all [
		rc1/left = rc2/left
		rc1/right = rc2/right
		rc1/top = rc2/top
		rc1/bottom = rc2/bottom
	][return true]
	false
]

rect-interior-equal?: func [
	rc1					[RECT_STRUCT]
	rc2					[RECT_STRUCT]
	return: 			[logic!]
][
	if rect-equal? rc1 rc2 [return true]
	if all [
		rect-empty? rc1
		rect-empty? rc2
	][return true]
	false
]

GetAlignedStride: func [
	alignment			[integer!]
	aWidth				[integer!]
	aBytesPerPixel		[integer!]
	return:				[integer!]
	/local
		mask			[integer!]
		stride			[integer!]
		ret				[integer!]
][
	if alignment <= 0 [return 0]
	if (alignment and (alignment - 1)) <> 0 [return 0]
	mask: alignment - 1
	stride: aWidth * aBytesPerPixel + mask
	ret: stride and not mask
	ret
]

BufferSizeFromStrideAndHeight: func [
	aStride				[integer!]
	aHeight				[integer!]
	aExtraBytes			[integer!]
	return:				[integer!]
	/local
		requiredBytes	[integer!]
][
	if any [
		aHeight <= 0
		aStride <= 0
	][return 0]
	requiredBytes: aStride * aHeight + aExtraBytes
	requiredBytes
]

ComputeMinSizeForShadowShape: func [
	aCornerRadii		[int-ptr!]
	aBlurRadius			[INT_SIZE]
	aOutSlice			[RECT_STRUCT]
	aRectSize			[INT_SIZE]
	minSize				[INT_SIZE]
	/local
		cornerSize		[INT_SIZE value]
		i				[integer!]
		corners			[INT_SIZE]
][
	cornerSize/width: 0
	cornerSize/height: 0
	if aCornerRadii <> null [
		i: 0
		while [i < 4][
			corners: as INT_SIZE aCornerRadii + i
			cornerSize/width: _MAX(cornerSize/width corners/width)
			cornerSize/height: _MAX(cornerSize/height corners/height)
			i: i + 1
		]
	]
	cornerSize/width: cornerSize/width + aBlurRadius/width
	cornerSize/height: cornerSize/height + aBlurRadius/height

	aOutSlice/top: cornerSize/height
	aOutSlice/right: cornerSize/width
	aOutSlice/bottom: cornerSize/height
	aOutSlice/left: cornerSize/width
	minSize/width: aOutSlice/left + aOutSlice/right + 1
	minSize/height: aOutSlice/top + aOutSlice/bottom + 1
	if aRectSize/width < minSize/width [
		minSize/width: aRectSize/width
		aOutSlice/left: 0
		aOutSlice/right: 0
	]
	if aRectSize/height < minSize/height [
		minSize/height: aRectSize/height
		aOutSlice/top: 0
		aOutSlice/bottom: 0
	]
]

box-blur-row: func [
	aTransposeInput		[logic!]
	aTransposeOutput	[logic!]
	aInput				[byte-ptr!]
	aOutput				[byte-ptr!]
	aLeftLobe			[integer!]
	aRightLobe			[integer!]
	aWidth				[integer!]
	aStride				[integer!]
	aStart				[integer!]
	aEnd				[integer!]
	/local
		inputStep		[integer!]
		outputStep		[integer!]
		boxSize			[integer!]
		reciprocal		[float!]
		alphaSum		[float!]
		initLeft		[integer!]
		initRight		[integer!]
		temp			[integer!]
		p				[byte-ptr!]
		src				[byte-ptr!]
		iterEnd			[byte-ptr!]
		splitLeft		[integer!]
		splitRight		[integer!]
		dst				[byte-ptr!]
		firstVal		[byte!]
		boxStep			[integer!]
		firstLastDiff	[integer!]
		lastVal			[byte!]
		ft				[float!]
][
	inputStep: either aTransposeInput [aStride][1]
	outputStep: either aTransposeOutput [aStride][1]
	boxSize: aLeftLobe + aRightLobe + 1
	reciprocal: (as float! (1 << 24)) / as float! boxSize
	alphaSum: as float! ((boxSize + 1) / 2)
	initLeft: aStart - aLeftLobe
	if initLeft < 0 [
		temp: initLeft * as integer! aInput/1
		alphaSum: alphaSum - as float! temp
		initLeft: 0
	]
	initRight: aStart + boxSize - aLeftLobe
	if initRight > aWidth [
		p: aInput + ((aWidth - 1) * inputStep)
		temp: (initRight - aWidth) * as integer! p/1
		alphaSum: alphaSum + as float! temp
		initRight: aWidth
	]

	src: aInput + (initLeft * inputStep)
	iterEnd: aInput + (initRight * inputStep)
	while [(src + (16 * inputStep)) <= iterEnd][
		INIT_ITER INIT_ITER INIT_ITER INIT_ITER
		INIT_ITER INIT_ITER INIT_ITER INIT_ITER
		INIT_ITER INIT_ITER INIT_ITER INIT_ITER
		INIT_ITER INIT_ITER INIT_ITER INIT_ITER
	]
	while [src < iterEnd][
		INIT_ITER
	]

	temp: _MAX(aLeftLobe aStart)
	splitLeft: _MIN(temp aEnd)
	temp: aWidth - (boxSize - aLeftLobe)
	temp: _MAX(temp aStart)
	splitRight: _MIN(temp aEnd)
	if boxSize > aWidth [
		temp: splitLeft
		splitLeft: splitRight
		splitRight: temp
	]

	dst: aOutput + (aStart * outputStep)
	iterEnd: aOutput + (splitLeft * outputStep)
	temp: (aStart + boxSize - aLeftLobe) * inputStep
	src: aInput + temp
	firstVal: aInput/1
	while [(dst + (16 * outputStep)) <= iterEnd][
		LEFT_ITER LEFT_ITER LEFT_ITER LEFT_ITER
		LEFT_ITER LEFT_ITER LEFT_ITER LEFT_ITER
		LEFT_ITER LEFT_ITER LEFT_ITER LEFT_ITER
		LEFT_ITER LEFT_ITER LEFT_ITER LEFT_ITER
	]
	while [dst < iterEnd][
		LEFT_ITER
	]

	iterEnd: aOutput + (splitRight * outputStep)
	either boxSize <= aWidth [
		temp: (splitLeft - aLeftLobe) * inputStep
		src: aInput + temp
		boxStep: boxSize * inputStep
		while [(dst + (16 * outputStep)) <= iterEnd][
			CENTER_ITER CENTER_ITER CENTER_ITER CENTER_ITER
			CENTER_ITER CENTER_ITER CENTER_ITER CENTER_ITER
			CENTER_ITER CENTER_ITER CENTER_ITER CENTER_ITER
			CENTER_ITER CENTER_ITER CENTER_ITER CENTER_ITER
		]
		while [dst < iterEnd][
			CENTER_ITER
		]
	][
		p: aInput + ((aWidth - 1) * inputStep)
		firstLastDiff: (as integer! p/1) - (as integer! aInput/1)

		while [dst < iterEnd][
			ft: alphaSum * reciprocal
			ft: ft / 16777216.0		; ft >>> 24
			temp: as integer! ft
			dst/1: as byte! temp
			alphaSum: alphaSum + as float! firstLastDiff
			dst: dst + outputStep
		]
	]

	iterEnd: aOutput + (aEnd * outputStep)
	temp: (splitRight - aLeftLobe) * inputStep
	src: aInput + temp
	temp: (aWidth - 1) * inputStep
	p: aInput + temp
	lastVal: p/1
	while [(dst + (16 * outputStep)) <= iterEnd][
		RIGHT_ITER RIGHT_ITER RIGHT_ITER RIGHT_ITER
		RIGHT_ITER RIGHT_ITER RIGHT_ITER RIGHT_ITER
		RIGHT_ITER RIGHT_ITER RIGHT_ITER RIGHT_ITER
		RIGHT_ITER RIGHT_ITER RIGHT_ITER RIGHT_ITER
	]
	while [dst < iterEnd][
		RIGHT_ITER
	]
]

box-blur: func [
	aTranspose			[logic!]
	aData				[byte-ptr!]
	aLobes				[int-ptr!]
	aWidth				[integer!]
	aRows				[integer!]
	aStride				[integer!]
	aSkipRect			[RECT_STRUCT]
	/local
		temp			[integer!]
		tmpRow			[byte-ptr!]
		tmpRow2			[byte-ptr!]
		stride			[integer!]
		skipWhole?		[logic!]
		y				[integer!]
		inSkipRectY		[logic!]
		p				[int-ptr!]
		skipStart		[integer!]
		skipEnd			[integer!]
][
	if aTranspose [
		temp: aWidth
		aWidth: aRows
		aRows: temp
		rect-swap aSkipRect
	]

	tmpRow: allocate 2 * aWidth
	if tmpRow = null [exit]
	set-memory tmpRow null-byte 2 * aWidth
	tmpRow2: tmpRow + aWidth

	stride: either aTranspose [1][aStride]
	skipWhole?: either all [aSkipRect/left <= 0 aSkipRect/right >= aWidth][true][false]

	y: 0
	while [y < aRows][
		inSkipRectY: either all [y >= aSkipRect/top y < aSkipRect/bottom][true][false]
		if all [inSkipRectY skipWhole?][
			temp: stride * (aSkipRect/bottom - y)
			aData: aData + temp
			y: aSkipRect/bottom
			continue
		]
		p: aLobes
		box-blur-row aTranspose false aData tmpRow p/1 p/2 aWidth aStride 0 aWidth
		p: aLobes + 2
		box-blur-row false false tmpRow tmpRow2 p/1 p/2 aWidth aStride 0 aWidth

		skipStart: either inSkipRectY [
			temp: _MAX(aSkipRect/left 0)
			_MIN(temp aWidth)
		][aWidth]
		skipEnd: _MAX(skipStart aSkipRect/right)
		p: aLobes + 4
		if skipStart > 0 [
			box-blur-row false aTranspose tmpRow2 aData p/1 p/2 aWidth aStride 0 skipStart
		]
		if skipEnd < aWidth [
			box-blur-row false aTranspose tmpRow2 aData p/1 p/2 aWidth aStride skipEnd skipStart
		]
		aData: aData + stride
		y: y + 1
	]
	free tmpRow
]

compute-lobes: func [
	aRadius				[integer!]
	aLobes				[int-ptr!]
	/local
		major			[integer!]
		minor			[integer!]
		final			[integer!]
		z				[integer!]
		p				[int-ptr!]
][
	z: aRadius / 3
	switch aRadius % 3 [
		0	[major: z minor: z final: z]
		1	[major: z + 1 minor: z final: z]
		2	[major: z + 1 final: z + 1 minor: z]
		default [major: 0 minor: 0 final: 0]
	]
	aLobes/1: major
	aLobes/2: minor
	aLobes/3: minor
	aLobes/4: major
	aLobes/5: final
	aLobes/6: final
]

spread-h: func [
	aInput				[byte-ptr!]
	aOutput				[byte-ptr!]
	aRadius				[integer!]
	aWidth				[integer!]
	aRows				[integer!]
	aStride				[integer!]
	aSkipRect			[RECT_STRUCT]
	/local
		skipWhole?		[logic!]
		y				[integer!]
		inSkipRectY		[logic!]
		x				[integer!]
		sMin			[integer!]
		sMax			[integer!]
		v				[integer!]
		s				[integer!]
		temp			[integer!]
		temp2			[integer!]
		p				[byte-ptr!]
][
	if aRadius = 0 [
		copy-memory aOutput aInput aStride * aRows
		exit
	]

	skipWhole?: either all [aSkipRect/left <= 0 aSkipRect/right >= aWidth][true][false]
	y: 0
	while [y < aRows][
		inSkipRectY: either all [y >= aSkipRect/top y < aSkipRect/bottom][true][false]
		if all [inSkipRectY skipWhole?][
			y: aSkipRect/bottom
			continue
		]

		x: 0
		while [x < aWidth][
			if all [
				inSkipRectY
				x >= aSkipRect/left
				x < aSkipRect/right
			][
				x: aSkipRect/right
				if x >= aWidth [break]
			]

			temp: x - aRadius
			sMin: _MAX(temp 0)
			temp: x + aRadius
			temp2: aWidth - 1
			sMax: _MIN(temp temp2)
			v: 0
			s: sMin
			while [s <= sMax][
				temp: aStride * y + s
				p: aInput + temp
				temp: as integer! p/1
				v: _MAX(v temp)
				s: s + 1
			]
			temp: aStride * y + x
			p: aOutput + temp
			p/1: as byte! v
			x: x + 1
		]
		y: y + 1
	]
]

spread-v: func [
	aInput				[byte-ptr!]
	aOutput				[byte-ptr!]
	aRadius				[integer!]
	aWidth				[integer!]
	aRows				[integer!]
	aStride				[integer!]
	aSkipRect			[RECT_STRUCT]
	/local
		skipWhole?		[logic!]
		y				[integer!]
		inSkipRectX		[logic!]
		x				[integer!]
		sMin			[integer!]
		sMax			[integer!]
		v				[integer!]
		s				[integer!]
		temp			[integer!]
		temp2			[integer!]
		p				[byte-ptr!]
][
	if aRadius = 0 [
		copy-memory aOutput aInput aStride * aRows
		exit
	]

	skipWhole?: either all [aSkipRect/top <= 0 aSkipRect/bottom >= aRows][true][false]

	x: 0
	while [x < aWidth][
		inSkipRectX: either all [x >= aSkipRect/left x < aSkipRect/right][true][false]
		if all [inSkipRectX skipWhole?][
			x: aSkipRect/right
			continue
		]

		y: 0
		while [y < aRows][
			if all [
				inSkipRectX
				y >= aSkipRect/top
				y < aSkipRect/bottom
			][
				y: aSkipRect/bottom
				if y >= aRows [break]
			]

			temp: y - aRadius
			sMin: _MAX(temp 0)
			temp: y + aRadius
			temp2: aRows - 1
			sMax: _MIN(temp temp2)
			v: 0
			s: sMin
			while [s <= sMax][
				temp: aStride * s + x
				p: aInput + temp
				temp: as integer! p/1
				v: _MAX(v temp)
				s: s + 1
			]
			temp: aStride * y + x
			p: aOutput + temp
			p/1: as byte! v
			y: y + 1
		]
		x: x + 1
	]
]

gen-integral-row: func [
	aDest				[int-ptr!]
	aSource				[byte-ptr!]
	aPreviousRow		[int-ptr!]
	aSourceWidth		[integer!]
	aLeftInflation		[integer!]
	aRightInflation		[integer!]
	/local
		curRowSum		[integer!]
		pixel			[integer!]
		x				[integer!]
		temp			[integer!]
		alphaValues		[integer!]
		p				[byte-ptr!]
][
	curRowSum: 0
	pixel: as integer! aSource/1
	x: 0
	while [x < aLeftInflation][
		curRowSum: curRowSum + pixel
		aDest/1: curRowSum + aPreviousRow/1
		aDest: aDest + 1
		aPreviousRow: aPreviousRow + 1
		x: x + 1
	]
	x: aLeftInflation
	while [x < (aSourceWidth + aLeftInflation)][
		temp: x - aLeftInflation
		p: aSource + temp
		curRowSum: curRowSum + as integer! p/1
		aDest/1: aPreviousRow/1 + curRowSum
		aDest: aDest + 1
		aPreviousRow: aPreviousRow + 1
		curRowSum: curRowSum + as integer! p/2
		aDest/1: aPreviousRow/1 + curRowSum
		aDest: aDest + 1
		aPreviousRow: aPreviousRow + 1
		curRowSum: curRowSum + as integer! p/3
		aDest/1: aPreviousRow/1 + curRowSum
		aDest: aDest + 1
		aPreviousRow: aPreviousRow + 1
		curRowSum: curRowSum + as integer! p/4
		aDest/1: aPreviousRow/1 + curRowSum
		aDest: aDest + 1
		aPreviousRow: aPreviousRow + 1
		x: x + 4
	]
	pixel: as integer! aSource/aSourceWidth
	x: aSourceWidth + aLeftInflation
	while [x < (aSourceWidth + aLeftInflation + aRightInflation)][
		curRowSum: curRowSum + pixel
		aDest/1: curRowSum + aPreviousRow/1
		aDest: aDest + 1
		aPreviousRow: aPreviousRow + 1
		x: x + 1
	]
]

gen-integral-image: func [
	aLeftInflation		[integer!]
	aRightInflation		[integer!]
	aTopInflation		[integer!]
	aBottomInflation	[integer!]
	aIntegralImage		[int-ptr!]
	aImageStride		[integer!]
	aSource				[byte-ptr!]
	aSourceStride		[integer!]
	aSize				[INT_SIZE]
	/local
		stride32bit		[integer!]
		width			[integer!]
		height			[integer!]
		y				[integer!]
][
	stride32bit: aImageStride / 4
	width: aSize/width + aLeftInflation + aRightInflation
	height: aSize/height + aTopInflation + aBottomInflation
	set-memory as byte-ptr! aIntegralImage null-byte aImageStride

	gen-integral-row aIntegralImage aSource aIntegralImage aSize/width aLeftInflation aRightInflation
	y: 1
	while [y < (aTopInflation + 1)][
		gen-integral-row aIntegralImage + (y * stride32bit) aSource aIntegralImage + ((y - 1) * stride32bit)
				aSize/width aLeftInflation aRightInflation
		y: y + 1
	]
	y: aTopInflation + 1
	while [y < (aSize/height + aTopInflation)][
		gen-integral-row aIntegralImage + (y * stride32bit) aSource + (aSourceStride * (y - aTopInflation)) aIntegralImage + ((y - 1) * stride32bit)
				aSize/width aLeftInflation aRightInflation
		y: y + 1
	]

	if aBottomInflation <> 0 [
		y: aSize/height + aTopInflation
		while [y < height][
			gen-integral-row aIntegralImage + (y * stride32bit) aSource + ((aSize/height - 1) * aSourceStride) aIntegralImage + ((y - 1) * stride32bit)
					aSize/width aLeftInflation aRightInflation
			y: y + 1
		]
	]
]

AlphaBoxBlur: context [
	mStride: 0
	mRect: declare RECT_STRUCT
	mSkipRect: declare RECT_STRUCT
	mBlurRadius: declare INT_SIZE
	mSpreadRadius: declare INT_SIZE
	mDirtyRect: declare RECT_STRUCT
	mHasDirtyRect: false

	RoundUpToMultipleOf4: func [
		aVal				[integer!]
		return:				[integer!]
		/local
			val				[integer!]
	][
		val: aVal + 3
		val: val / 4
		val: val * 4
		val
	]

	Init: func [
		aRect				[RECT_STRUCT]
		aSpreadRadius		[INT_SIZE]
		aBlurRadius			[INT_SIZE]
		aDirtyRect			[RECT_STRUCT]
		aSkipRect			[RECT_STRUCT]
		/local
			width			[integer!]
			height			[integer!]
			requiredBlur	[RECT_STRUCT value]
			size			[integer!]
	][
		mSpreadRadius/width: aSpreadRadius/width
		mSpreadRadius/height: aSpreadRadius/height
		mBlurRadius/width: aBlurRadius/width
		mBlurRadius/height: aBlurRadius/height

		rect-copy mRect aRect
		width: aBlurRadius/width + aSpreadRadius/width
		height: aBlurRadius/height + aSpreadRadius/height
		mRect/right: mRect/right + (2 * width)
		mRect/bottom: mRect/bottom + (2 * height)

		either aDirtyRect <> null [
			mHasDirtyRect: true
			rect-copy mDirtyRect aDirtyRect
			rect-intersect aDirtyRect mRect :requiredBlur
			requiredBlur/right: requiredBlur/right + (2 * width)
			requiredBlur/bottom: requiredBlur/bottom + (2 * height)
			rect-intersect :requiredBlur mRect mRect
		][
			mHasDirtyRect: false
		]

		if any [
			mRect/right <= mRect/left
			mRect/bottom <= mRect/top
		][exit]

		either aSkipRect <> null [
			rect-copy mSkipRect aSkipRect
			mSkipRect/right: mSkipRect/right - (2 * width)
			mSkipRect/bottom: mSkipRect/bottom - (2 * height)
			rect-intersect mSkipRect mRect mSkipRect
			if rect-interior-equal? mSkipRect mRect [exit]
			rect-offset mSkipRect 0 - mRect/left 0 - mRect/top
		][
			mSkipRect/left: 0
			mSkipRect/right: 0
			mSkipRect/top: 0
			mSkipRect/bottom: 0
		]
		mStride: mRect/right - mRect/left
	]

	new: func [
		aRect				[RECT_STRUCT]
		aStride				[integer!]
		aSigmaX				[float!]
		aSigmaY				[float!]
		/local
			minDataSize		[integer!]
	][
		rect-copy mRect aRect
		mSpreadRadius/width: 0
		mSpreadRadius/height: 0
		calc-blur-radius aSigmaX aSigmaY mBlurRadius
		mStride: aStride
		mHasDirtyRect: false
	]

	BoxBlur: func [
		aData				[byte-ptr!]
		aLeftLobe			[integer!]
		aRightLobe			[integer!]
		aTopLobe			[integer!]
		abottomLobe			[integer!]
		aIntegralImage		[int-ptr!]
		aImageStride		[integer!]
		/local
			size			[INT_SIZE value]
			boxSize			[integer!]
			stride32bit		[integer!]
			leftInflation	[integer!]
			reciprocal		[float!]
			ft				[float!]
			innerIntegral	[int-ptr!]
			y				[integer!]
			inSkipRectY		[logic!]
			topLeftBase		[int-ptr!]
			topRightBase	[int-ptr!]
			bottomRightBase	[int-ptr!]
			bottomLeftBase	[int-ptr!]
			temp			[integer!]
			x				[integer!]
			topLeft			[integer!]
			topRight		[integer!]
			bottomRight		[integer!]
			bottomLeft		[integer!]
			value			[integer!]
			p				[int-ptr!]
			pb				[byte-ptr!]
	][
		size/width: mRect/right - mRect/left
		size/height: mRect/bottom - mRect/top
		aLeftLobe: aLeftLobe + 1
		aTopLobe: aTopLobe + 1
		boxSize: (aLeftLobe + aRightLobe) * (aTopLobe + abottomLobe)
		if boxSize = 1 [exit]

		stride32bit: aImageStride / 4
		leftInflation: RoundUpToMultipleOf4 aLeftLobe

		gen-integral-image leftInflation aRightLobe aTopLobe abottomLobe aIntegralImage aImageStride aData mStride :size

		reciprocal: 4294967296.0 / as float! boxSize
		innerIntegral: aIntegralImage + (aTopLobe * stride32bit) + leftInflation

		y: 0
		while [y < size/height][
			inSkipRectY: either all [y > mSkipRect/top y < mSkipRect/bottom][true][false]
			temp: (y - aTopLobe) * stride32bit - aLeftLobe
			topLeftBase: innerIntegral + temp
			temp: (y - aTopLobe) * stride32bit + aRightLobe
			topRightBase: innerIntegral + temp
			temp: (y + abottomLobe) * stride32bit + aRightLobe
			bottomRightBase: innerIntegral + temp
			temp: (y + abottomLobe) * stride32bit - aLeftLobe
			bottomLeftBase: innerIntegral + temp

			x: 0
			while [x < size/width][
				if all [
					inSkipRectY
					x > mSkipRect/left
					x < mSkipRect/right
				][
					x: mSkipRect/right
					inSkipRectY: false
					continue
				]
				p: topLeftBase + x
				topLeft: p/1
				p: topRightBase + x
				topRight: p/1
				p: bottomRightBase + x
				bottomRight: p/1
				p: bottomLeftBase + x
				bottomLeft: p/1
				value: bottomRight - topRight - bottomLeft
				value: value + topLeft

				ft: reciprocal * as float! value
				ft: ft + 2147483648.0
				ft: ft / 4294967296.0
				temp: as integer! ft
				pb: aData + (mStride * y + x)
				pb/1: as byte! temp
				x: x + 1
			]
			y: y + 1
		]
	]

	Blur: func [
		aData				[byte-ptr!]
		/local
			size			[INT_SIZE value]
			szB				[integer!]
			tmpData			[byte-ptr!]
			horizontalLobes	[int-ptr!]
			verticalLobes	[int-ptr!]
			maxLeftLobe		[integer!]
			tWidth			[integer!]
			tHeight			[integer!]
			ImageStride		[integer!]
			bufLen			[integer!]
			temp			[integer!]
			integralImage	[int-ptr!]
	][
		if aData = null [
			exit
		]

		if all [
			mBlurRadius/width = 0
			mBlurRadius/height = 0
			mSpreadRadius/width = 0
			mSpreadRadius/height = 0
		][
			exit
		]

		size/width: mRect/right - mRect/left
		size/height: mRect/bottom - mRect/top

		if any [
			mSpreadRadius/width > 0
			mSpreadRadius/height > 0
		][
			szB: mStride * size/height
			tmpData: allocate szB
			if tmpData = null [exit]
			set-memory tmpData null-byte szB
			spread-h aData tmpData mSpreadRadius/width
				size/width size/height mStride mSkipRect
			spread-v tmpData aData mSpreadRadius/height
				size/width size/height mStride mSkipRect
			free tmpData
		]

		horizontalLobes: [0 0 0 0 0 0]
		compute-lobes mBlurRadius/width horizontalLobes
		verticalLobes: [0 0 0 0 0 0]
		compute-lobes mBlurRadius/height verticalLobes
		maxLeftLobe: RoundUpToMultipleOf4 horizontalLobes/1 + 1

		tWidth: size/width + maxLeftLobe + horizontalLobes/4
		tHeight: size/height + verticalLobes/1 + verticalLobes/4 + 1

		if (tWidth * tHeight) > (1 << 24) [
			if mBlurRadius/width > 0 [
				box-blur false aData horizontalLobes size/width size/height mStride mSkipRect
			]
			if mBlurRadius/height > 0 [
				box-blur true aData verticalLobes size/width size/height mStride mSkipRect
			]
			exit
		]

		ImageStride: GetAlignedStride 16 tWidth 4
		if ImageStride = 0 [exit]
		bufLen: BufferSizeFromStrideAndHeight ImageStride tHeight 12
		if bufLen = 0 [exit]
		temp: bufLen / 4
		temp: temp + either 0 = (bufLen % 4) [0][1]
		integralImage: as int-ptr! allocate temp * 4
		if integralImage = null [exit]
		BoxBlur aData horizontalLobes/1 horizontalLobes/2 verticalLobes/1 verticalLobes/2 integralImage ImageStride
		BoxBlur aData horizontalLobes/3 horizontalLobes/4 verticalLobes/3 verticalLobes/4 integralImage ImageStride
		BoxBlur aData horizontalLobes/5 horizontalLobes/6 verticalLobes/5 verticalLobes/6 integralImage ImageStride
	]


	cacl-window: func [
		sigma				[float!]		; standard Deviation
		return:				[integer!]
		/local
			ft				[float!]
			ret				[integer!]
	][
		case [
			sigma < 0.0 [sigma: 0.0]
			sigma > 136.0 [sigma: 136.0]
			true []
		]
		ft: sigma * GAUSSIAN_SCALE_FACTOR + 0.5
		ret: as integer! ft
		if ret < 1 [ret: 1]
		ret
	]

	calc-blur-radius: func [
		xsigma				[float!]
		ysigma				[float!]
		size				[INT_SIZE]
	][
		size/width: cacl-window xsigma
		size/height: cacl-window ysigma
	]

	calc-blur-sigma: func [
		radius				[integer!]
		return:				[float!]
	][
		(as float! radius) / GAUSSIAN_SCALE_FACTOR
	]
]
