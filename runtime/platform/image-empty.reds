Red/System [
	Title:   "Image routine functions (template)"
	Author:  "bitbegin"
	File: 	 %image-empty.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

OS-image: context [
	;-- public interface
	load-image: func [
		img			[red-image!]
		src			[red-string!]
		return:		[logic!]
	][false]

	;-- public interface
	load-binary: func [
		img		[red-image!]
		data	[byte-ptr!]
		len		[integer!]
		return:	[logic!]
	][false]

	;-- public interface
	encode: func [
		image	[red-image!]
		slot	[red-value!]
		format	[integer!]
		return: [red-value!]
	][as red-image! none-value]
]
