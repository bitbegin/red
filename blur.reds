Red/System []

;-- used for single file compile
RECT_STRUCT: alias struct! [
	left		[integer!]
	top			[integer!]
	right		[integer!]
	bottom		[integer!]
]

#include %modules/view/backends/blur.reds

tagSYSTEMTIME: alias struct! [
	year-month	[integer!]
	week-day	[integer!]
	hour-minute	[integer!]
	second		[integer!]
]

#import [
	"kernel32.dll" stdcall [
		GetSystemTime: "GetSystemTime" [
			time			[tagSYSTEMTIME]
		]
	]
]

get-time: func [
	utc?	 [logic!]
	precise? [logic!]
	return:  [float!]
	/local
		tm	[tagSYSTEMTIME value]
		h		[integer!]
		m		[integer!]
		sec		[integer!]
		milli	[integer!]
		t		[float!]
		mi		[float!]
][
	GetSystemTime tm
	h: tm/hour-minute and FFFFh
	m: tm/hour-minute >>> 16
	sec: tm/second and FFFFh
	milli: either precise? [tm/second >>> 16][0]
	mi: as float! milli
	mi: mi / 1000.0
	t: as-float h * 3600 + (m * 60) + sec
	t: t + mi
	t
]

width: 400
height: 400
shadow-blur: 40
shadow-spread: 0

rect: declare RECT_STRUCT
blur: declare INT_SIZE
spread: declare INT_SIZE
SkipRect: declare RECT_STRUCT
rect/left: 0
rect/right: width
rect/top: 0
rect/bottom: height
blur/width: shadow-blur
blur/height: shadow-blur
spread/width: shadow-spread
spread/height: shadow-spread
AlphaBoxBlur/Init rect spread blur null null

size: AlphaBoxBlur/GetSize
src: allocate size
set-memory src null-byte size
rect-offset rect shadow-blur shadow-blur
AlphaBoxBlur/set-rect-memory src rect 200
AWidth: AlphaBoxBlur/GetWidth
AHeight: AlphaBoxBlur/GetHeight
;dump-rect src false AWidth AHeight dump-rect-radix

tm1: get-time yes yes

AlphaBoxBlur/blur src
;dump-rect src false AWidth AHeight dump-rect-radix
	tm2: get-time yes yes
print-line ["time: " tm2 - tm1]
