Red/System [
	Title:   "Image routine functions using GDI+"
	Author:  "Qingtian Xie"
	File: 	 %image-gdiplus.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

;-- In-memory pixel data formats:
;-- bits 0-7 = format index
;-- bits 8-15 = pixel size (in bits)
;-- bits 16-23 = flags
;-- bits 24-31 = reserved

#define PixelFormatIndexed			00010000h ;-- Indexes into a palette
#define PixelFormatGDI				00020000h ;-- Is a GDI-supported format
#define PixelFormatAlpha			00040000h ;-- Has an alpha component
#define PixelFormatPAlpha			00080000h ;-- Pre-multiplied alpha
#define PixelFormatExtended			00100000h ;-- Extended color 16 bits/channel
#define PixelFormatCanonical		00200000h

#define PixelFormatUndefined		0
#define PixelFormatDontCare			0

#define PixelFormat32bppARGB		2498570   ;-- [10 or (32 << 8) or PixelFormatAlpha or PixelFormatGDI or PixelFormatCanonical]
#define PixelFormat32bppPARGB		925707    ;-- [11 or (32 << 8) or PixelFormatAlpha or PixelFormatPAlpha or PixelFormatGDI]
#define PixelFormat32bppCMYK		8207	  ;-- [15 or (32 << 8)]
#define PixelFormatMax				16

;-- PixelFormat
#define GL_COLOR_INDEX				1900h
#define GL_STENCIL_INDEX			1901h
#define GL_DEPTH_COMPONENT			1902h
#define GL_RED						1903h
#define GL_GREEN					1904h
#define GL_BLUE						1905h
#define GL_ALPHA					1906h
#define GL_RGB						1907h
#define GL_RGBA						1908h
#define GL_LUMINANCE				1909h
#define GL_LUMINANCE_ALPHA			190Ah

#define GMEM_MOVEABLE	2

#define GpBitmap!	int-ptr!
#define GpImage!	int-ptr!
#define GpGraphics! int-ptr!

OS-image: context [

	CLSID_BMP_ENCODER:  [557CF400h 11D31A04h 0000739Ah 2EF31EF8h]
	CLSID_JPEG_ENCODER: [557CF401h 11D31A04h 0000739Ah 2EF31EF8h]
	CLSID_GIF_ENCODER:  [557CF402h 11D31A04h 0000739Ah 2EF31EF8h]
	CLSID_TIFF_ENCODER: [557CF405h 11D31A04h 0000739Ah 2EF31EF8h]
	CLSID_PNG_ENCODER:  [557CF406h 11D31A04h 0000739Ah 2EF31EF8h]

	RECT!: alias struct! [
		left	[integer!]
		top		[integer!]
		right	[integer!]
		bottom	[integer!]
	]

	BitmapData!: alias struct! [
		width		[integer!]
		height		[integer!]
		stride		[integer!]
		pixelFormat	[integer!]
		scan0		[byte-ptr!]
		reserved	[integer!]
	]

	#import [
		"kernel32.dll" stdcall [
			GlobalAlloc: "GlobalAlloc" [
				flags		[integer!]
				size		[integer!]
				return:		[integer!]
			]
			GlobalFree: "GlobalFree" [
				hMem		[integer!]
				return:		[integer!]
			]
			GlobalLock: "GlobalLock" [
				hMem		[integer!]
				return:		[byte-ptr!]
			]
			GlobalUnlock: "GlobalUnlock" [
				hMem		[integer!]
				return:		[integer!]
			]
		]
		"ole32.dll" stdcall [
			CreateStreamOnHGlobal: "CreateStreamOnHGlobal" [
				hMem		[integer!]
				fAutoDel	[logic!]
				ppstm		[int-ptr!]
				return:		[integer!]
			]
		]
		"gdiplus.dll" stdcall [
			GdipCloneImage: "GdipCloneImage" [
				image		[integer!]
				new-image	[int-ptr!]
				return:		[integer!]
			]
			GdipCloneBitmapAreaI: "GdipCloneBitmapAreaI" [
				x			[integer!]
				y			[integer!]
				width		[integer!]
				height		[integer!]
				format		[integer!]
				src			[integer!]
				dst			[int-ptr!]
				return:		[integer!]
			]
			GdipCreateBitmapFromFile: "GdipCreateBitmapFromFile" [
				filename	[c-string!]
				image		[GpBitmap!]
				return:		[integer!]
			]
			GdipBitmapLockBits: "GdipBitmapLockBits" [
				bitmap		[integer!]
				rect		[RECT!]
				flags		[integer!]
				format		[integer!]
				data		[BitmapData!]
				return:		[integer!]
			]
			GdipBitmapUnlockBits: "GdipBitmapUnlockBits" [
				bitmap		[integer!]
				data		[BitmapData!]
				return:		[integer!]
			]
			GdipBitmapGetPixel: "GdipBitmapGetPixel" [
				bitmap		[integer!]
				x			[integer!]
				y			[integer!]
				argb		[int-ptr!]
				return:		[integer!]
			]
			GdipBitmapSetPixel: "GdipBitmapSetPixel" [
				bitmap		[integer!]
				x			[integer!]
				y			[integer!]
				argb		[integer!]
				return:		[integer!]
			]
			GdipGetImageWidth: "GdipGetImageWidth" [
				image		[integer!]
				width		[int-ptr!]
				return:		[integer!]
			]
			GdipGetImageHeight: "GdipGetImageHeight" [
				image		[integer!]
				height		[int-ptr!]
				return:		[integer!]
			]
			GdipCreateBitmapFromGdiDib: "GdipCreateBitmapFromGdiDib" [
				bmi			[byte-ptr!]
				data		[byte-ptr!]
				bitmap		[int-ptr!]
				return:		[integer!]
			]
			GdipCreateBitmapFromScan0: "GdipCreateBitmapFromScan0" [
				width		[integer!]
				height		[integer!]
				stride		[integer!]
				format		[integer!]
				scan0		[byte-ptr!]
				bitmap		[int-ptr!]
				return:		[integer!]
			]
			GdipCreateBitmapFromStream: "GdipCreateBitmapFromStream" [
				stream		[integer!]
				bitmap		[int-ptr!]
				return:		[integer!]
			]
			GdipGetImagePixelFormat: "GdipGetImagePixelFormat" [
				image		[integer!]
				format		[int-ptr!]
				return:		[integer!]
			]
			GdipSaveImageToStream: "GdipSaveImageToStream" [
				image		[integer!]
				stream		[this!]
				encoder		[int-ptr!]
				params		[integer!]
				return:		[integer!]
			]
			GdipGetImageGraphicsContext: "GdipGetImageGraphicsContext" [
				image		[integer!]
				graphics	[GpGraphics!]
				return:		[integer!]
			]
			GdipDrawImageRectRectI: "GdipDrawImageRectRectI" [
				graphics	[integer!]
				image		[integer!]
				dstx		[integer!]
				dsty		[integer!]
				dstwidth	[integer!]
				dstheight	[integer!]
				srcx		[integer!]
				srcy		[integer!]
				srcwidth	[integer!]
				srcheight	[integer!]
				srcUnit		[integer!]
				attribute	[integer!]
				callback	[integer!]
				data		[integer!]
				return:		[integer!]
			]
			GdipDeleteGraphics: "GdipDeleteGraphics" [
				graphics	[integer!]
				return:		[integer!]
			]
			GdipDisposeImage: "GdipDisposeImage" [
				image		[integer!]
				return:		[integer!]
			]
			GdipGetImagePaletteSize: "GdipGetImagePaletteSize" [
				image		[integer!]
				size		[int-ptr!]
				return:		[integer!]
			]
			GdipGetImagePalette: "GdipGetImagePalette" [
				image		[integer!]
				palette		[byte-ptr!]
				size		[integer!]
				return:		[integer!]
			]
			GdipSetImagePalette: "GdipSetImagePalette" [
				image		[integer!]
				palette		[byte-ptr!]
				return:		[integer!]
			]
		]
	]

	width?: func [
		handle		[int-ptr!]
		return:		[integer!]
		/local
			width	[integer!]
	][
		width: 0
		GdipGetImageWidth as-integer handle :width
		width
	]

	height?: func [
		handle		[int-ptr!]
		return:		[integer!]
		/local
			height	[integer!]
	][
		height: 0
		GdipGetImageHeight as-integer handle :height
		height
	]


	delete: func [img [red-image!]][
		0
	]

	load-image: func [
		img			[red-image!]
		src			[red-string!]
		return:		[logic!]
		/local
			handle	[integer!]
			res		[integer!]
	][
		handle: 0
		res: GdipCreateBitmapFromFile file/to-OS-path src :handle
		unless zero? res [img/header: TYPE_NONE return false]
		load-handle img as int-ptr! handle
		GdipDisposeImage handle
		true
	]

	;-- from ARGB(OS's bitmap) to ABGR(Red's format), Red's a = 255 - os's a
	make-binary: func [
		img		[red-image!]
		width	[integer!]
		height	[integer!]
		src		[int-ptr!]
		return:	[red-image!]
		/local
			size	[integer!]
			s		[series!]
			dst		[int-ptr!]
			offset	[integer!]
			old		[integer!]
			p		[byte-ptr!]
			b		[byte!]
	][
		size: width * height * 4
		img/head: 0
		img/size: height << 16 or width
		img/node: alloc-bytes size
		img/header: TYPE_IMAGE							;-- implicit reset of all header flags
		s: GET_BUFFER(img)
		dst: as int-ptr! s/offset
		offset: 1
		copy-memory as byte-ptr! dst as byte-ptr! src size
		s/tail: as cell! (as byte-ptr! s/tail) + size
		img
	]

	;-- load os's bitmap handle
	load-handle: func [
		img		[red-image!]
		bmp		[int-ptr!]
		return:	[logic!]
		/local
			w		[integer!]
			h		[integer!]
			data	[BitmapData! value]
	][
		w: width? bmp
		h: height? bmp
		if 0 <> GdipBitmapLockBits as integer! bmp null 1 PixelFormat32bppARGB :data [
			img/header: TYPE_NONE
			return false
		]
		make-binary img w h as int-ptr! data/scan0
		GdipBitmapUnlockBits as integer! bmp :data
		true
	]

	;-- load os's binary format
	load-binary: func [
		img		[red-image!]
		data	[byte-ptr!]
		len		[integer!]
		return:	[logic!]
		/local
			hMem	[integer!]
			p		[byte-ptr!]
			s		[integer!]
			bmp		[integer!]
			sthis	[this!]
			stream	[IStream]
			ret		[logic!]
	][
		hMem: GlobalAlloc GMEM_MOVEABLE len
		p: GlobalLock hMem
		copy-memory p data len
		GlobalUnlock hMem

		s: 0
		bmp: 0
		CreateStreamOnHGlobal hMem true :s
		GdipCreateBitmapFromStream s :bmp
		sthis: as this! s
		stream: as IStream sthis/vtbl
		stream/Release sthis				;-- the hMem will also be released
		ret: load-handle img as int-ptr! bmp
		GdipDisposeImage bmp
		ret
	]

	encode: func [
		image	[red-image!]
		slot	[red-value!]
		format	[integer!]
		return: [red-value!]
		/local
			bin		[red-binary!]
			s		[series!]
			clsid	[int-ptr!]
			stream	[IStream]
			storage [IStorage]
			stat	[tagSTATSTG]
			IStm	[interface!]
			ISto	[interface!]
			len		[integer!]
			hr		[integer!]
	][
		switch format [
			IMAGE_BMP  [clsid: CLSID_BMP_ENCODER]
			IMAGE_PNG  [clsid: CLSID_PNG_ENCODER]
			IMAGE_GIF  [clsid: CLSID_GIF_ENCODER]
			IMAGE_JPEG [clsid: CLSID_JPEG_ENCODER]
			IMAGE_TIFF [clsid: CLSID_TIFF_ENCODER]
			default    [probe "Cannot find image encoder" return null]
		]

		ISto: declare interface!
		IStm: declare interface!
		stat: declare tagSTATSTG
		hr: StgCreateDocfile
			null
			STGM_READWRITE or STGM_CREATE or STGM_SHARE_EXCLUSIVE or STGM_DELETEONRELEASE 
			0
			ISto
		storage: as IStorage ISto/ptr/vtbl
		hr: storage/CreateStream
			ISto/ptr
			#u16 "RedImageStream"
			STGM_READWRITE or STGM_SHARE_EXCLUSIVE
			0
			0
			IStm
		hr: GdipSaveImageToStream as-integer image/node IStm/ptr clsid 0

		stream: as IStream IStm/ptr/vtbl
		stream/Stat IStm/ptr stat 1
		len: stat/cbSize_low

		bin: as red-binary! slot
		bin/header: TYPE_UNSET
		bin/head: 0
		bin/node: alloc-bytes len
		bin/header: TYPE_BINARY
		
		s: GET_BUFFER(bin)
		s/tail: as cell! (as byte-ptr! s/tail) + len

		stream/Seek IStm/ptr 0 0 0 0 0
		stream/Read IStm/ptr as byte-ptr! s/offset len :hr
		stream/Release IStm/ptr
		storage/Release ISto/ptr
		as red-value! bin
	]
]