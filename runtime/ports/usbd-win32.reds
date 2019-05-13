Red/System [
	Title:	"usb port! implementation on Windows"
	Author: "bitbegin"
	File: 	%usb-win32.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %usbd-common.reds

usb-device: context [

	GUID_DEVINTERFACE_USB_HOST_CONTROLLER: declare UUID!
	GUID_DEVINTERFACE_USB_DEVICE: declare UUID!
	GUID_DEVINTERFACE_USB_HUB: declare UUID!
	GUID_DEVINTERFACE_HID: declare UUID!
	GUID_DEVINTERFACE_VENDOR: declare UUID!

	device-list: declare list-entry!

	enum-devices-with-guid: func [
		device-list			[list-entry!]
		guid				[UUID!]
		/local
			dev-info		[int-ptr!]
			info-data		[DEV-INFO-DATA! value]
			interface-data	[DEV-INTERFACE-DATA! value]
			detail-data		[DEV-INTERFACE-DETAIL!]
			index			[integer!]
			error			[integer!]
			success			[logic!]
			pNode			[DEVICE-INFO-NODE!]
			bResult			[logic!]
			reqLen			[integer!]
			pbuffer			[integer!]
			plen			[integer!]
			buf				[byte-ptr!]
			port			[integer!]
			hub				[integer!]
			device-id		[c-string!]
			vid				[integer!]
			pid				[integer!]
			serial			[c-string!]
			inst			[integer!]
			path			[byte-ptr!]
	][
		clear-device-list device-list
		dev-info: SetupDiGetClassDevs guid null 0 DIGCF_PRESENT or DIGCF_DEVICEINTERFACE
		if dev-info = INVALID_HANDLE [exit]
		index: 0 error: 0 plen: 0 pbuffer: 0
		while [error <> ERROR_NO_MORE_ITEMS][
			pNode: as DEVICE-INFO-NODE! allocate size? DEVICE-INFO-NODE!
			if pNode = null [continue]
			set-memory as byte-ptr! pNode null-byte size? DEVICE-INFO-NODE!
			dlink/init pNode/interface-entry
			info-data/cbSize: size? DEV-INFO-DATA!
			interface-data/cbSize: size? DEV-INTERFACE-DATA!
			success: SetupDiEnumDeviceInfo dev-info index info-data
			index: index + 1
			either success = false [
				error: GetLastError
				free-device-info-node pNode
			][
				success: SetupDiEnumDeviceInterfaces dev-info 0 guid index - 1
							interface-data
				if success <> true [
					free-device-info-node pNode
					continue
				]

				reqLen: 0
				success: SetupDiGetDeviceInterfaceDetail dev-info interface-data
							null 0 :reqLen null
				error: GetLastError
				if all [
					success <> true
					error <> ERROR_INSUFFICIENT_BUFFER
				][
					free-device-info-node pNode
					continue
				]
				buf: allocate reqLen
				if buf = null [
					free-device-info-node pNode
					continue
				]
				detail-data: as DEV-INTERFACE-DETAIL! buf
				detail-data/cbSize: 5				; don't use size? DEV-INTERFACE-DETAIL!, as it's actual size = 5
				success: SetupDiGetDeviceInterfaceDetail dev-info interface-data
							detail-data reqLen :reqLen null
				if success <> true [
					free-device-info-node pNode
					free buf
					continue
				]
				path: allocate reqLen
				if path = null [
					free-device-info-node pNode
					free buf
					continue
				]
				copy-memory path buf + 4 reqLen - 4
				pNode/path: as c-string! path
				free buf

				buf: get-name dev-info info-data :plen
				if buf <> null [
					pNode/name: buf
					pNode/name-len: plen
				]

				success: get-device-property-a dev-info info-data
							SPDRP_LOCATION_INFORMATION :pbuffer :plen
				either success <> true [
					hub: -1 port: -1
				][
					hub: 0 port: 0
					sscanf [pbuffer "Port_#%d.Hub_#%d" :port :hub]
				]
				pNode/port: port

				pid: 65535
				vid: 65535
				serial: null
				device-id: get-device-id dev-info info-data
				if device-id <> null [
					serial: as c-string! allocate 256
					sscanf [device-id "USB\VID_%x&PID_%x\%s"
						:vid :pid serial]
					pNode/vid: vid
					pNode/pid: pid
					pNode/serial-num: serial
					free as byte-ptr! device-id
				]

				pNode/inst: info-data/DevInst
				dlink/init pNode/interface-entry
				if all [
					vid <> 65535
					pid <> 65535
				][
					enum-children pNode/interface-entry info-data/DevInst vid pid
				]

				dlink/append device-list as list-entry! pNode
			]
		]
		SetupDiDestroyDeviceInfoList dev-info
	]

	get-descriptions: func [
		pNode			[DEVICE-INFO-NODE!]
		return:			[USB-DESCRIPTION!]
		/local
			desc		[USB-DESCRIPTION!]
			inst		[integer!]
			rint		[integer!]
			dev-path	[c-string!]
			hHub		[integer!]
			buf			[byte-ptr!]
			plen		[integer!]
			id			[integer!]
	][
		if pNode/port = -1 [return null]
		desc: as USB-DESCRIPTION! allocate size? USB-DESCRIPTION!
		if desc = null [return null]
		inst: 0
		plen: 0
		rint: CM_Get_Parent :inst pNode/inst 0
		if rint <> 0 [
			free-description desc
			return null
		]

		dev-path: get-dev-path-with-guid inst GUID_DEVINTERFACE_USB_HUB
		if dev-path = null [
			free-description desc
			return null
		]
		hHub: CreateFileA dev-path GENERIC_WRITE FILE_SHARE_WRITE null
				OPEN_EXISTING 0 null
		if hHub = -1 [
			free-description desc
			return null
		]
		buf: get-device-desc hHub pNode/port :plen
		if buf <> null [
			desc/device-desc: buf
			desc/device-desc-len: plen
		]
		buf: get-config-desc hHub pNode/port 0 :plen
		if buf <> null [
			desc/config-desc: buf
			desc/config-desc-len: plen
		]
		if desc/device-desc <> null [
			id: get-language-id hHub pNode/port
			if id <> 0 [
				desc/language-id: id
				buf: get-vendor-str hHub pNode/port desc/device-desc id :plen
				if buf <> null [
					desc/vendor-str: buf
					desc/vendor-str-len: plen
				]
				buf: get-product-str hHub pNode/port desc/device-desc id :plen
				if buf <> null [
					desc/product-str: buf
					desc/product-str-len: plen
				]
				buf: get-serial-str hHub pNode/port desc/device-desc id :plen
				if buf <> null [
					desc/serial-str: buf
					desc/serial-str-len: plen
				]
			]
		]
		CloseHandle as int-ptr! hHub
		desc
	]

	enum-children: func [
		list			[list-entry!]
		inst			[integer!]
		vid				[integer!]
		pid				[integer!]
		/local
			dev-info		[int-ptr!]
			info-data		[DEV-INFO-DATA! value]
			buf				[byte-ptr!]
			path			[byte-ptr!]
			len				[integer!]
			len2			[integer!]
			len3			[integer!]
			rint			[integer!]
			type			[integer!]
			pNode			[INTERFACE-INFO-NODE!]
			reg				[integer!]
			guid			[UUID! value]
			pguid			[UUID!]
			index			[integer!]
			error			[integer!]
			success			[logic!]
			nvid			[integer!]
			npid			[integer!]
			nmi				[integer!]
			ncol			[integer!]
			nserial			[c-string!]
	][
		dev-info: SetupDiGetClassDevs null null 0 DIGCF_PRESENT or DIGCF_ALLCLASSES
		if dev-info = INVALID_HANDLE [
			exit
		]
		buf: allocate 256
		nserial: as c-string! allocate 256
		if buf = null [
			exit
		]
		index: 0 error: 0 len: 0
		while [error <> ERROR_NO_MORE_ITEMS][
			info-data/cbSize: size? DEV-INFO-DATA!
			success: SetupDiEnumDeviceInfo dev-info index info-data
			index: index + 1
			either success = false [
				error: GetLastError
			][
				success: SetupDiGetDeviceInstanceId dev-info info-data buf 256 :len
				either success = false [
					error: GetLastError
				][
					unless inst-ancestor? info-data/DevInst inst [
						continue
					]
					nvid: 65535
					npid: 65535
					nmi: 255
					ncol: 255
					;print-line as c-string! buf
					either 0 = compare-memory buf as byte-ptr! "USB\" 4 [
						sscanf [buf "USB\VID_%4hx&PID_%4hx&MI_%2hx\%s"
							:nvid :npid :nmi nserial]
						if nmi = 255 [
							sscanf [buf "USB\VID_%4hx&PID_%4hx\%s"
								:nvid :npid nserial]
						]
						unless all [
							vid = nvid
							pid = npid
						][
							continue
						]
						reg: SetupDiOpenDevRegKey dev-info info-data DICS_FLAG_GLOBAL 0 DIREG_DEV KEY_READ
						if reg = -1 [
							continue
						]
						len3: 0
						len2: 80
						path: allocate 256
						rint: RegQueryValueExW reg #u16 "DeviceInterfaceGUIDs" null :len3 path :len2
						if rint = 2 [
							rint: RegQueryValueExW reg #u16 "DeviceInterfaceGUID" null :len3 path :len2
						]
						RegCloseKey reg
						if rint <> 0 [
							free path
							continue
						]
						if 0 <> IIDFromString as c-string! path guid [
							free path
							continue
						]
						free path
						pguid: guid
						type: DRIVER-TYPE-WINUSB
					][
						either 0 = compare-memory buf as byte-ptr! "HID\" 4 [
							sscanf [buf "HID\VID_%4hx&PID_%4hx&MI_%2hx&COL%2hx\%s"
								:nvid :npid :nmi :ncol nserial]
							if ncol = 255 [
								sscanf [buf "HID\VID_%4hx&PID_%4hx&MI_%2hx\%s"
									:nvid :npid :nmi nserial]
								if nmi = 255 [
									sscanf [buf "HID\VID_%4hx&PID_%4hx\%s"
										:nvid :npid nserial]
								]
							]
							unless all [
								vid = nvid
								pid = npid
							][
								continue
							]
							pguid: GUID_DEVINTERFACE_HID
							type: DRIVER-TYPE-HIDUSB
						][continue]
					]
					pNode: as INTERFACE-INFO-NODE! allocate size? INTERFACE-INFO-NODE!
					if pNode = null [
						continue
					]
					set-memory as byte-ptr! pNode null-byte size? INTERFACE-INFO-NODE!
					pNode/interface-num: nmi
					pNode/collection/index: ncol
					pNode/hType: type
					pNode/path: get-dev-path-with-guid info-data/DevInst pguid
					path: get-name dev-info info-data :len
					if path <> null [
						pNode/name: path
						pNode/name-len: len
					]
					dlink/append list as list-entry! pNode
				]
			]
		]
		free buf
		free as byte-ptr! nserial
		SetupDiDestroyDeviceInfoList dev-info
	]

	inst-ancestor?: func [
		inst			[integer!]
		ancestor		[integer!]
		return:			[logic!]
		/local
			parent		[integer!]
			nparent		[integer!]
			rint		[integer!]
	][
		parent: 0 nparent: 0
		rint: CM_Get_Parent :parent inst 0
		if rint <> 0 [return false]
		if parent = ancestor [return true]
		rint: CM_Get_Parent :nparent parent 0
		if rint <> 0 [return false]
		nparent = ancestor
	]

	get-dev-path-with-guid: func [
		inst			[integer!]
		guid			[UUID!]
		return:			[c-string!]
		/local
			dev-info		[int-ptr!]
			info-data		[DEV-INFO-DATA! value]
			interface-data	[DEV-INTERFACE-DATA! value]
			detail-data		[DEV-INTERFACE-DETAIL!]
			index			[integer!]
			error			[integer!]
			success			[logic!]
			reqLen			[integer!]
			buf				[byte-ptr!]
			ret				[c-string!]
	][
		dev-info: SetupDiGetClassDevs guid null 0 DIGCF_PRESENT or DIGCF_DEVICEINTERFACE
		if dev-info = INVALID_HANDLE [
			return null
		]
		index: 0 error: 0
		while [error <> ERROR_NO_MORE_ITEMS][
			info-data/cbSize: size? DEV-INFO-DATA!
			success: SetupDiEnumDeviceInfo dev-info index info-data
			index: index + 1
			either success = false [
				error: GetLastError
			][
				if info-data/DevInst = inst [
					interface-data/cbSize: size? DEV-INTERFACE-DATA!
					success: SetupDiEnumDeviceInterfaces dev-info 0 guid index - 1
								interface-data
					if success <> true [
						continue
					]
					reqLen: 0
					success: SetupDiGetDeviceInterfaceDetail dev-info interface-data
								null 0 :reqLen null
					error: GetLastError
					if all [
						success <> true
						error <> ERROR_INSUFFICIENT_BUFFER
					][
						continue
					]
					buf: allocate reqLen
					if buf = null [
						continue
					]
					detail-data: as DEV-INTERFACE-DETAIL! buf
					detail-data/cbSize: 5				; don't use size? DEV-INTERFACE-DETAIL!, as it's actual size = 5
					success: SetupDiGetDeviceInterfaceDetail dev-info interface-data
								detail-data reqLen :reqLen null
					if success <> true [
						free buf
						continue
					]
					ret: as c-string! allocate reqLen - 4
					copy-memory as byte-ptr! ret buf + 4 reqLen - 4
					free buf
					SetupDiDestroyDeviceInfoList dev-info
					return ret
				]
			]
		]
		SetupDiDestroyDeviceInfoList dev-info
		null
	]

	get-device-desc: func [
		hHub			[integer!]
		port			[integer!]
		plen			[int-ptr!]
		return:			[byte-ptr!]
		/local
			success		[logic!]
			bytes		[integer!]
			bytes-ret	[integer!]
			req-buf		[byte-ptr!]
			desc-req	[USB-DESCRIPTOR-REQUEST!]
			desc		[USB-DEVICE-DESCRIPTOR!]
			ret			[byte-ptr!]
	][
		bytes: (size? USB-DESCRIPTOR-REQUEST!) + size? USB-DEVICE-DESCRIPTOR!
		req-buf: allocate bytes
		if req-buf = null [return null]
		bytes-ret: 0
		set-memory req-buf null-byte 12
		bytes: 12 + 18
		desc-req: as USB-DESCRIPTOR-REQUEST! req-buf
		desc: as USB-DEVICE-DESCRIPTOR! (req-buf + 12)
		desc-req/port: port
		desc-req/wValue1: #"^(00)"
		desc-req/wValue2: USB_DEVICE_DESCRIPTOR_TYPE
		desc-req/wLength1: #"^(12)"
		desc-req/wLength2: #"^(00)"

		success: DeviceIoControl as int-ptr! hHub IOCTL_USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION as byte-ptr! desc-req bytes
					as byte-ptr! desc-req bytes :bytes-ret null
		if success <> true [
			free req-buf
			return null
		]
		if bytes-ret <> 30 [
			free req-buf
			return null
		]
		plen/value: 18
		ret: allocate 18
		copy-memory ret req-buf + 12 18
		free req-buf
		ret
	]

	get-config-desc: func [
		hHub			[integer!]
		port			[integer!]
		config			[integer!]
		plen			[int-ptr!]
		return:			[byte-ptr!]
		/local
			success		[logic!]
			bytes		[integer!]
			bytes-ret	[integer!]
			req-buf		[byte-ptr!]
			desc-req	[USB-DESCRIPTOR-REQUEST!]
			desc		[USB-CONFIGURATION-DESCRIPTOR!]
			total		[integer!]
			total2		[integer!]
			ret			[byte-ptr!]
	][
		bytes: (size? USB-DESCRIPTOR-REQUEST!) + size? USB-CONFIGURATION-DESCRIPTOR!
		req-buf: allocate bytes
		if req-buf = null [return null]
		bytes-ret: 0
		set-memory req-buf null-byte 12
		bytes: 12 + 9
		desc-req: as USB-DESCRIPTOR-REQUEST! req-buf
		desc: as USB-CONFIGURATION-DESCRIPTOR! (req-buf + 12)
		desc-req/port: port
		desc-req/wValue1: as byte! config
		desc-req/wValue2: USB_CONFIGURATION_DESCRIPTOR_TYPE
		desc-req/wLength1: #"^(09)"
		desc-req/wLength2: #"^(00)"

		success: DeviceIoControl as int-ptr! hHub IOCTL_USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION as byte-ptr! desc-req bytes
					as byte-ptr! desc-req bytes :bytes-ret null
		if success <> true [
			free req-buf
			return null
		]
		if bytes <> bytes-ret [
			free req-buf
			return null
		]
		total: (as integer! desc/wTotalLen2) << 8 + (as integer! desc/wTotalLen1)
		if total < 9 [
			free req-buf
			return null
		]
		free req-buf
		bytes: 12 + total
		req-buf: allocate bytes
		if req-buf = null [return null]
		set-memory req-buf null-byte 12
		desc-req: as USB-DESCRIPTOR-REQUEST! req-buf
		desc: as USB-CONFIGURATION-DESCRIPTOR! (req-buf + 12)
		desc-req/port: port
		desc-req/wValue1: as byte! config
		desc-req/wValue2: USB_CONFIGURATION_DESCRIPTOR_TYPE
		desc-req/wLength1: #"^(09)"
		desc-req/wLength2: #"^(00)"
		success: DeviceIoControl as int-ptr! hHub IOCTL_USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION as byte-ptr! desc-req bytes
					as byte-ptr! desc-req bytes :bytes-ret null
		if success <> true [
			free req-buf
			return null
		]
		if bytes <> bytes-ret [
			free req-buf
			return null
		]
		total2: (as integer! desc/wTotalLen2) << 8 + (as integer! desc/wTotalLen1)
		if total <> total2 [
			free req-buf
			return null
		]
		plen/value: total2
		ret: allocate total2
		copy-memory ret req-buf + 12 total2
		free req-buf
		ret
	]

	get-vendor-str: func [
		hHub			[integer!]
		port			[integer!]
		dev-desc		[byte-ptr!]
		id				[integer!]
		plen			[int-ptr!]
		return:			[byte-ptr!]
	][
		if dev-desc/15 <> null-byte [
			return get-string-desc hHub port dev-desc/15 id plen
		]
		null
	]

	get-product-str: func [
		hHub			[integer!]
		port			[integer!]
		dev-desc		[byte-ptr!]
		id				[integer!]
		plen			[int-ptr!]
		return:			[byte-ptr!]
	][
		if dev-desc/16 <> null-byte [
			return get-string-desc hHub port dev-desc/16 id plen
		]
		null
	]

	get-serial-str: func [
		hHub			[integer!]
		port			[integer!]
		dev-desc		[byte-ptr!]
		id				[integer!]
		plen			[int-ptr!]
		return:			[byte-ptr!]
	][
		if dev-desc/17 <> null-byte [
			return get-string-desc hHub port dev-desc/17 id plen
		]
		null
	]

	get-language-id: func [
		hHub			[integer!]
		port			[integer!]
		return:			[integer!]
		/local
			len			[integer!]
			buf			[byte-ptr!]
			id			[integer!]
	][
		len: 0
		buf: get-string-desc hHub port null-byte 0 :len
		if buf = null [return 0]
		id: (as integer! buf/1) + ((as integer! buf/2) << 8)
		free buf
		id
	]

	get-string-desc: func [
		hHub			[integer!]
		port			[integer!]
		index			[byte!]
		langID			[integer!]
		plen			[int-ptr!]
		return:			[byte-ptr!]
		/local
			success		[logic!]
			bytes		[integer!]
			bytes-ret	[integer!]
			req-buf		[byte-ptr!]
			desc-req	[USB-DESCRIPTOR-REQUEST!]
			desc		[USB-STRING-DESCRIPTOR!]
			len			[integer!]
			ret			[byte-ptr!]
	][
		bytes: (size? USB-DESCRIPTOR-REQUEST!) + MAXIMUM_USB_STRING_LENGTH
		req-buf: allocate bytes
		if req-buf = null [return null]
		bytes-ret: 0
		set-memory req-buf null-byte 12
		bytes: 12 + MAXIMUM_USB_STRING_LENGTH
		desc-req: as USB-DESCRIPTOR-REQUEST! req-buf
		desc: as USB-STRING-DESCRIPTOR! (req-buf + 12)
		desc-req/port: port
		desc-req/wValue1: index
		desc-req/wValue2: USB_STRING_DESCRIPTOR_TYPE
		desc-req/wLength1: #"^(FF)"
		desc-req/wLength2: #"^(00)"
		desc-req/wIndex1: as byte! langID
		desc-req/wIndex2: as byte! (langID >> 8)

		success: DeviceIoControl as int-ptr! hHub IOCTL_USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION as byte-ptr! desc-req bytes
					as byte-ptr! desc-req bytes :bytes-ret null
		if success <> true [
			free req-buf
			return null
		]
		if bytes-ret <= 14 [
			free req-buf
			return null
		]
		if desc/bDescType <> USB_STRING_DESCRIPTOR_TYPE [
			free req-buf
			return null
		]
		if (as integer! desc/bLength) <> (bytes-ret - 12) [
			free req-buf
			return null
		]
		if (as integer! desc/bLength) % 2 <> 0 [
			free req-buf
			return null
		]
		len: (as integer! desc/bLength) - 2
		ret: allocate len
		if ret = null [
			free req-buf
			return null
		]
		plen/value: len
		copy-memory ret (as byte-ptr! desc) + 2 len
		free req-buf
		ret
	]

	get-device-property: func [
		dev-info		[int-ptr!]
		info-data		[DEV-INFO-DATA!]
		property		[integer!]
		ppBuffer		[int-ptr!]
		plen			[int-ptr!]
		return:			[logic!]
		/local
			bResult		[logic!]
			reqLen		[integer!]
			lastError	[integer!]
			buf			[byte-ptr!]
	][
		if ppBuffer = null [return false]
		ppBuffer/value: 0
		reqLen: 0
		bResult: SetupDiGetDeviceRegistryPropertyW dev-info info-data property
					null null 0 :reqLen
		lastError: GetLastError
		if any [
			reqLen = 0
			all [
				bResult <> false
				lastError <> ERROR_INSUFFICIENT_BUFFER
			]
		][return false]
		buf: allocate reqLen
		if buf = null [return false]
		ppBuffer/value: as integer! buf
		bResult: SetupDiGetDeviceRegistryPropertyW dev-info info-data property
					null buf reqLen :reqLen
		if bResult = false [
			free buf
			ppBuffer/value: 0
			return false
		]
		plen/value: reqLen
		true
	]

	get-device-property-a: func [
		dev-info		[int-ptr!]
		info-data		[DEV-INFO-DATA!]
		property		[integer!]
		ppBuffer		[int-ptr!]
		plen			[int-ptr!]
		return:			[logic!]
		/local
			bResult		[logic!]
			reqLen		[integer!]
			lastError	[integer!]
			buf			[byte-ptr!]
	][
		if ppBuffer = null [return false]
		ppBuffer/value: 0
		reqLen: 0
		bResult: SetupDiGetDeviceRegistryProperty dev-info info-data property
					null null 0 :reqLen
		lastError: GetLastError
		if any [
			reqLen = 0
			all [
				bResult <> false
				lastError <> ERROR_INSUFFICIENT_BUFFER
			]
		][return false]
		buf: allocate reqLen
		if buf = null [return false]
		ppBuffer/value: as integer! buf
		bResult: SetupDiGetDeviceRegistryProperty dev-info info-data property
					null buf reqLen :reqLen
		if bResult = false [
			free buf
			ppBuffer/value: 0
			return false
		]
		plen/value: reqLen
		true
	]

	get-device-id: func [
		dev-info			[int-ptr!]
		info-data			[DEV-INFO-DATA!]
		return:				[c-string!]
		/local
			len					[integer!]
			status				[logic!]
			last-error			[integer!]
			buf					[byte-ptr!]
	][
		len: 0
		status: SetupDiGetDeviceInstanceId dev-info info-data null 0 :len
		last-error: GetLastError
		if all [
			status <> false
			last-error <> ERROR_INSUFFICIENT_BUFFER
		][
			return null
		]
		len: len + 1
		buf: allocate len
		if buf = null [
			return null
		]
		status: SetupDiGetDeviceInstanceId dev-info info-data
					buf len :len
		if status = false [
			return null
		]
		as c-string! buf
	]

	get-name: func [
		dev-info			[int-ptr!]
		info-data			[DEV-INFO-DATA!]
		plen				[int-ptr!]
		return:				[byte-ptr!]
		/local
			nbuf			[integer!]
			nlen			[integer!]
			status			[logic!]
	][
		nbuf: 0 nlen: 0
		status: get-device-property dev-info info-data
					SPDRP_DEVICEDESC :nbuf :nlen
		if status = false [
			return null
		]
		plen/value: nlen
		as byte-ptr! nbuf
	]

	enum-all-devices: does [
		enum-devices-with-guid device-list GUID_DEVINTERFACE_USB_DEVICE
	]

	open-inteface: func [
		pNode					[INTERFACE-INFO-NODE!]
		return:					[USB-ERROR!]
	][
		case [
			pNode/hType = DRIVER-TYPE-WINUSB [
				return open-winusb pNode
			]
			pNode/hType = DRIVER-TYPE-HIDUSB [
				return open-hidusb pNode
			]
			true [
				return USB-ERROR-UNSUPPORT
			]
		]
	]

	close-interface: func [
		pNode					[INTERFACE-INFO-NODE!]
	][
		if pNode/hInf <> 0 [
			WinUsb_Free pNode/hInf
			pNode/hInf: 0
		]
		if pNode/hDev <> 0 [
			CloseHandle as int-ptr! pNode/hDev
			pNode/hDev: 0
		]
	]

	open-winusb: func [
		pNode					[INTERFACE-INFO-NODE!]
		return:					[USB-ERROR!]
		/local
			index				[integer!]
			pipe-info			[PIPE-INFO! value]
			pipe-id				[integer!]
			pipe-type			[PIPE-TYPE!]
	][
		print-line pNode/path
		pNode/hDev: CreateFileA pNode/path GENERIC_WRITE or GENERIC_READ FILE_SHARE_READ null
				OPEN_EXISTING FILE_FLAG_OVERLAPPED null
		if pNode/hDev = -1 [
			return USB-ERROR-OPEN
		]
		if false = WinUsb_Initialize pNode/hDev :pNode/hInf [
			CloseHandle as int-ptr! pNode/hDev
			return USB-ERROR-INIT
		]
		;index: 0
		;WinUsb_GetCurrentAlternateSetting pNode/hInf :index
		index: 0
		forever [
			unless WinUsb_QueryPipe pNode/hInf 0 index pipe-info [
				break
			]
			;dump-hex as byte-ptr! pipe-info
			pipe-id: as integer! pipe-info/pipeID
			pipe-type: pipe-info/pipeType
			switch pipe-type [
				PIPE-TYPE-BULK [
					either (pipe-id and 80h) = 80h [
						pNode/bulk-in: pipe-id
						pNode/bulk-in-size: as integer! pipe-info/maxPackSize2
						;print-line "bulk in: "
						;print-line pipe-id
					][
						pNode/bulk-out: pipe-id
						pNode/bulk-out-size: as integer! pipe-info/maxPackSize2
						;print-line "bulk out: "
						;print-line pipe-id
					]
				]
				PIPE-TYPE-INTERRUPT [
					either (pipe-id and 80h) = 80h [
						pNode/interrupt-in: pipe-id
						pNode/interrupt-in-size: as integer! pipe-info/maxPackSize2
						;print-line "int in: "
						;print-line pipe-id
					][
						pNode/interrupt-out: pipe-id
						pNode/interrupt-out-size: as integer! pipe-info/maxPackSize2
						;print-line "int out: "
						;print-line pipe-id
					]
				]
			]
			index: index + 1
		]
		if false = async-pipo-setup pNode pNode/interrupt-out [
			print-line "setup issue!"
		]
		USB-ERROR-OK
	]

	open-hidusb: func [
		pNode					[INTERFACE-INFO-NODE!]
		return:					[USB-ERROR!]
		/local
			pbuf				[integer!]
			caps				[HIDP-CAPS! value]
	][
		pNode/hDev: CreateFileA pNode/path GENERIC_WRITE or GENERIC_READ FILE_SHARE_READ null
				OPEN_EXISTING FILE_FLAG_OVERLAPPED null
		if pNode/hDev = -1 [
			return USB-ERROR-OPEN
		]
		pbuf: 0
		unless HidD_GetPreparsedData as int-ptr! pNode/hDev :pbuf [
			return USB-ERROR-INIT
		]
		if HIDP_STATUS_SUCCESS = HidP_GetCaps as int-ptr! pbuf caps [
			pNode/collection/usage: caps/usage >>> 16
			pNode/collection/usage-page: caps/usage and FFFFh
			pNode/input-size: caps/ReportByteLength >>> 16
			if pNode/input-size = 0 [pNode/input-size: 64]
			pNode/input-buffer: allocate pNode/input-size
			pNode/output-size: caps/ReportByteLength and FFFFh
			;print-line pNode/usage
			;print-line pNode/usage-page
		]
		HidD_FreePreparsedData as int-ptr! pbuf
		USB-ERROR-OK
	]

	async-pipo-setup: func [
		pNode					[INTERFACE-INFO-NODE!]
		pipe-id					[integer!]
		return:					[logic!]
		/local
			value				[integer!]
	][
		value: 1
		WinUsb_SetPipePolicy pNode/hInf pipe-id RAW-IO 1 :value
	]

	pipo-timeout: func [
		pNode					[INTERFACE-INFO-NODE!]
		pipe-id					[integer!]
		timeout					[integer!]
		return:					[logic!]
	][
		WinUsb_SetPipePolicy pNode/hInf pipe-id PIPE-TRANSFER-TIMEOUT 4 :timeout
	]

	find-usb: func [
		device-list				[list-entry!]
		vid						[integer!]
		pid						[integer!]
		sn						[c-string!]
		mi						[integer!]
		col						[integer!]
		return:					[DEVICE-INFO-NODE!]
		/local
			entry				[list-entry!]
			dnode				[DEVICE-INFO-NODE!]
			len					[integer!]
			len2				[integer!]
			children			[list-entry!]
			child-entry			[list-entry!]
			inode				[INTERFACE-INFO-NODE!]
	][
		entry: device-list/next
		while [entry <> device-list][
			dnode: as DEVICE-INFO-NODE! entry
			if all [
				dnode/vid = vid
				dnode/pid = pid
			][
				len: length? sn
				len2: length? dnode/serial-num
				if all [
					len <> 0
					len = len2
					0 = compare-memory as byte-ptr! sn as byte-ptr! dnode/serial-num len
				][
					children: dnode/interface-entry
					child-entry: children/next
					while [child-entry <> children][
						inode: as INTERFACE-INFO-NODE! child-entry
						if any [
							mi = 255
							inode/interface-num = 255
						][
							dlink/remove-entry device-list entry/prev entry/next
							clear-device-list device-list
							dnode/interface: inode
							return dnode
						]
						if mi = inode/interface-num [
							if any [
								col = 255
								inode/collection/index = 255
							][
								dlink/remove-entry device-list entry/prev entry/next
								clear-device-list device-list
								dnode/interface: inode
								return dnode
							]
							if col = inode/collection/index [
								dlink/remove-entry device-list entry/prev entry/next
								clear-device-list device-list
								dnode/interface: inode
								return dnode
							]
						]
						child-entry: child-entry/next
					]
				]
			]
			entry: entry/next
		]
		clear-device-list device-list
		null
	]

	open: func [
		vid						[integer!]
		pid						[integer!]
		sn						[c-string!]
		mi						[integer!]
		col						[integer!]
		return:					[DEVICE-INFO-NODE!]
		/local
			dnode				[DEVICE-INFO-NODE!]
			inode				[INTERFACE-INFO-NODE!]
	][
		clear-device-list device-list
		enum-devices-with-guid device-list GUID_DEVINTERFACE_USB_DEVICE
		dnode: find-usb device-list vid pid sn mi col
		if dnode = null [return null]
		inode: dnode/interface
		if USB-ERROR-OK <> open-inteface inode [
			free-device-info-node dnode
			return null
		]
		print-line "open"
		print-line inode/hDev
		;print-line inode/hInf
		dnode
	]

	write-data: func [
		pNode					[INTERFACE-INFO-NODE!]
		buf						[byte-ptr!]
		buflen					[integer!]
		plen					[int-ptr!]
		ov						[OVERLAPPED!]
		timeout					[integer!]
		return:					[integer!]
		/local
			ret					[integer!]
	][
		case [
			pNode/hType = DRIVER-TYPE-WINUSB [
				if WinUsb_WritePipe pNode/hInf pNode/interrupt-out buf buflen plen ov [
					return 0
				]
				if 997 = GetLastError [return 0]
				return -1
			]
			pNode/hType = DRIVER-TYPE-HIDUSB [
				ret: WriteFile pNode/hDev buf buflen plen as integer! ov
				print-line GetLastError
				print-line ret
				if as logic! ret [
					return 0
				]
				return -1
			]
			true [
				return -1
			]
		]
	]

	read-data: func [
		pNode					[INTERFACE-INFO-NODE!]
		buf						[byte-ptr!]
		buflen					[integer!]
		plen					[int-ptr!]
		ov						[OVERLAPPED!]
		timeout					[integer!]
		return:					[integer!]
		/local
			ret					[integer!]
	][
		case [
			pNode/hType = DRIVER-TYPE-WINUSB [
				if WinUsb_ReadPipe pNode/hInf pNode/interrupt-in buf buflen plen ov [
					return 0
				]
				if 997 = GetLastError [return 0]
				return -1
			]
			pNode/hType = DRIVER-TYPE-HIDUSB [
				ret: ReadFile pNode/hDev buf buflen plen as integer! ov
				print-line GetLastError
				print-line ret
				if as logic! ret [
					return 0
				]
				return -1
			]
			true [
				return -1
			]
		]
	]

	init: does [
		UuidFromString "3ABF6F2D-71C4-462A-8A92-1E6861E6AF27" GUID_DEVINTERFACE_USB_HOST_CONTROLLER
		UuidFromString "A5DCBF10-6530-11D2-901F-00C04FB951ED" GUID_DEVINTERFACE_USB_DEVICE
		UuidFromString "F18A0E88-C30C-11D0-8815-00A0C906BED8" GUID_DEVINTERFACE_USB_HUB
		UuidFromString "4D1E55B2-F16F-11CF-88CB-001111000030" GUID_DEVINTERFACE_HID
		UuidFromString "88BAE032-5A81-49f0-BC3D-A4FF138216D6" GUID_DEVINTERFACE_VENDOR
		dlink/init device-list

	]
]