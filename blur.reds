Red/System []

;-- used for single file compile
RECT_STRUCT: alias struct! [
	left		[integer!]
	top			[integer!]
	right		[integer!]
	bottom		[integer!]
]

#include %modules/view/backends/blur.reds

width: 40
height: 40
shadow-blur: 10
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
dump-rect src false AWidth AHeight dump-rect-radix

AlphaBoxBlur/blur src
dump-rect src false AWidth AHeight dump-rect-radix
