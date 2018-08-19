Red/System [
	Title:   "C tools for porting"
	Author:  "bitbegin"
	File: 	 %c-tools.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#define GET-BYTE-AT(arr i) (b-p: arr + i b-p/value)
#define SET-BYTE-AT(arr i value) [b-p: arr + i b-p/value: value]
#define GET-INT-AT(arr i) (i-p: arr + i i-p/value)
#define SET-INT-AT(arr i value) [i-p: arr + i i-p/value: value]

