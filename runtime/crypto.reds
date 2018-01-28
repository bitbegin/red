Red/System [
	Title:	"cryptographic API"
	Author: "Qingtian Xie"
	File: 	%crypto.reds
	Tabs:	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

crypto: context [

	_md5:	0
	_sha1:	0
	_crc32: 0
	_sha256:	0
	_sha384:	0
	_sha512:	0
	_rsa:		0
	_pkcs1:		0
	_oaep:		0
	_ssl:		0

	init: does [
		_md5:	symbol/make "md5"
		_sha1:	symbol/make "sha1"
		_crc32: symbol/make "crc32"
		_sha256:	symbol/make "sha256"
		_sha384:	symbol/make "sha384"
		_sha512:	symbol/make "sha512"
		_rsa:		symbol/make "rsa"
		_pkcs1:		symbol/make "pkcs1"
		_oaep:		symbol/make "oaep"
		_ssl:		symbol/make "ssl"
	]

	#enum crypto-algorithm! [
		ALG_CRC32
		ALG_MD5
		ALG_SHA1
		ALG_SHA256
		ALG_SHA384
		ALG_SHA512
		ALG_RSA
	]

	crc32-table: declare int-ptr!
	crc32-table: null

	make-crc32-table: func [
		/local
			c	[integer!]
			n	[integer!]
			k	[integer!]
	][
		n: 1
		crc32-table: as int-ptr! allocate 256 * size? integer!
		until [
			c: n - 1
			k: 0
			until [
				c: either zero? (c and 1) [c >>> 1][c >>> 1 xor EDB88320h]
				k: k + 1
				k = 8
			]
			crc32-table/n: c
			n: n + 1
			n = 257
		]
	]

	CRC32: func [
		data	[byte-ptr!]
		len		[integer!]
		return:	[integer!]
		/local
			c	[integer!]
			n	[integer!]
			i	[integer!]
	][
		c: FFFFFFFFh
		n: 1

		if crc32-table = null [make-crc32-table]

		len: len + 1
		while [n < len][
			i: c xor (as-integer data/n) and FFh + 1
			c: c >>> 8 xor crc32-table/i
			n: n + 1
		]

		not c
	]

	MD5: func [
		data	[byte-ptr!]
		len		[integer!]
		return:	[byte-ptr!]
	][
		get-digest data len ALG_MD5
	]

	SHA1: func [
		data	[byte-ptr!]
		len		[integer!]
		return:	[byte-ptr!]
	][
		get-digest data len ALG_SHA1
	]

	SHA256: func [
		data	[byte-ptr!]
		len		[integer!]
		return:	[byte-ptr!]
	][
		get-digest data len ALG_SHA256
	]

	SHA384: func [
		data	[byte-ptr!]
		len		[integer!]
		return:	[byte-ptr!]
	][
		get-digest data len ALG_SHA384
	]

	SHA512: func [
		data	[byte-ptr!]
		len		[integer!]
		return:	[byte-ptr!]
	][
		get-digest data len ALG_SHA512
	]
	
	RSA-ENCRYPT:  func [
		key		[byte-ptr!]
		keylen	[integer!]
		data	[byte-ptr!]
		datalen	[integer!]
		pad		[integer!]
		retlen	[int-ptr!]
		return: [byte-ptr!]
	][
		get-rsa-encrypt key keylen data datalen pad retlen
	]
	
	RSA-DECRYPT:  func [
		key		[byte-ptr!]
		keylen	[integer!]
		data	[byte-ptr!]
		datalen	[integer!]
		pad		[integer!]
		retlen	[int-ptr!]
		return: [byte-ptr!]
	][
		get-rsa-decrypt key keylen data datalen pad retlen
	]

#switch OS [
	Windows [
		#import [
			"kernel32.dll" stdcall [
				GetLastError: "GetLastError" [
					return: [integer!]
				]
			]
			"Crypt32.dll" stdcall [
				CryptStringToBinary: "CryptStringToBinaryA" [
					keystr		[byte-ptr!]
					strlen		[integer!]
					flags		[integer!]
					keybin		[byte-ptr!]
					binlen		[int-ptr!]
					optskip		[int-ptr!]
					optflags	[int-ptr!]
					return:		[integer!]
				]
				CryptBinaryToString: "CryptBinaryToStringA" [
					keybin		[byte-ptr!]
					binlen		[integer!]
					flags		[integer!]
					keystr		[c-string!]
					strlen		[int-ptr!]
					return:		[integer!]
				]
				CryptDecodeObjectEx: "CryptDecodeObjectEx" [
					certtype	[integer!]
					structtype	[byte-ptr!]
					keybuff		[byte-ptr!]
					bufflen		[integer!]
					flags		[integer!]
					para		[byte-ptr!]
					keybin		[byte-ptr!]
					binlen		[int-ptr!]
					return:		[integer!]
				]
			]
			"advapi32.dll" stdcall [
				CryptAcquireContext: "CryptAcquireContextA" [
					handle-ptr	[int-ptr!]
					container	[c-string!]
					provider	[c-string!]
					type		[integer!]
					flags		[integer!]
					return:		[integer!]
				]
				CryptImportKey: "CryptImportKey" [
					provider	[integer!]
					key			[byte-ptr!]
					keyLen		[integer!]
					hPubKey		[integer!]
					flags		[integer!]
					phKey		[int-ptr!]
					return:		[integer!]
				]
				CryptDestroyKey: "CryptDestroyKey" [
					hPubKey		[integer!]
					return:		[integer!]
				]
				CryptEncrypt: "CryptEncrypt" [
					hKey		[integer!]
					hHash		[byte-ptr!]
					final		[byte!]
					flags		[integer!]
					data		[byte-ptr!]
					dataLen		[int-ptr!]
					BufLen		[integer!]
					return:		[integer!]
				]
				CryptDecrypt: "CryptDecrypt" [
					hKey		[integer!]
					hHash		[byte-ptr!]
					final		[byte!]
					flags		[integer!]
					data		[byte-ptr!]
					dataLen		[int-ptr!]
					BufLen		[integer!]
					return:		[integer!]
				]
				CryptCreateHash: "CryptCreateHash" [
					provider 	[integer!]
					algorithm	[integer!]
					hmackey		[int-ptr!]
					flags		[integer!]
					handle-ptr	[int-ptr!]
					return:		[integer!]
				]
				CryptHashData:	"CryptHashData" [
					handle		[integer!]
					data		[byte-ptr!]
					dataLen		[integer!]
					flags		[integer!]
					return:		[integer!]
				]
				CryptGetHashParam: "CryptGetHashParam" [
					handle		[integer!]
					param		[integer!]
					buffer		[byte-ptr!]
					written		[int-ptr!]
					flags		[integer!]
					return:		[integer!]
				]
				CryptDestroyHash:	"CryptDestroyHash" [
					handle		[integer!]
					return:		[integer!]
				]
				CryptReleaseContext: "CryptReleaseContext" [
					handle		[integer!]
					flags		[integer!]
					return:		[integer!]
				]
			]
		]

		#define PROV_RSA_FULL 			1
		#define PROV_RSA_AES            24
		#define CRYPT_VERIFYCONTEXT     F0000000h				;-- Says we're using ephemeral, not stored, keys
		#define HP_HASHVAL              0002h  					;-- Get hash value
		#define CALG_MD5				00008003h
		#define CALG_SHA1				00008004h
		#define CALG_SHA_256	        0000800Ch
		#define CALG_SHA_384	        0000800Dh
		#define CALG_SHA_512	        0000800Eh
		#define AT_KEYEXCHANGE          1
		#define CRYPT_STRING_BASE64HEADER	0
		#define CRYPT_STRING_BASE64		1
		#define X509_ASN_ENCODING		1
		#define PKCS_7_ASN_ENCODING		00010000h
		#define PKCS_RSA_PRIVATE_KEY	43
		#define RSA_CSP_PUBLICKEYBLOB	19
		#define RSA_PUB_MAGIC			31415352h
		#define RSA_PRI_MAGIC			32415352h
		
		MS-Enhanced-Crypt-Str: "Microsoft Enhanced Cryptographic Provider v1.0"
		
		get-digest: func [
			data	[byte-ptr!]
			len		[integer!]
			type	[integer!]
			return:	[byte-ptr!]
			/local
				provider [integer!]
				handle	[integer!]
				hash	[byte-ptr!]
				size	[integer!]
		][
			; The hash buffer needs to be big enough to hold the longest result.
			hash: as byte-ptr! "0000000000000000000000000000000000000000000000000000000000000000"
			provider: 0
			handle: 0
			switch type [
				ALG_MD5     [type: CALG_MD5      size: 16]
				ALG_SHA1    [type: CALG_SHA1     size: 20]
				ALG_SHA256  [type: CALG_SHA_256  size: 32]
				ALG_SHA384  [type: CALG_SHA_384  size: 48]
				ALG_SHA512  [type: CALG_SHA_512  size: 64]
			]
			CryptAcquireContext :provider null null PROV_RSA_AES CRYPT_VERIFYCONTEXT
			CryptCreateHash provider type null 0 :handle
			CryptHashData handle data len 0
			CryptGetHashParam handle HP_HASHVAL hash :size 0
			CryptDestroyHash handle
			CryptReleaseContext provider 0
			hash
		]
		
		outputbuff: allocate 4096
		outputlen: 0
		
		get-rsa-encrypt: func [
			key		[byte-ptr!]
			keylen	[integer!]
			data	[byte-ptr!]
			datalen	[integer!]
			pad		[integer!]
			retlen	[int-ptr!]
			return: [byte-ptr!]
			/local
				provider 	[integer!]
				hKey		[integer!]
				keybin		[byte-ptr!]
				binlen		[integer!]
				hdr			[int-ptr!]
				keysize		[integer!]
		][
			provider: 0
			hKey: 0
			outputlen: datalen
			keysize: ((keylen + 7) / 8) * 64
			binlen: keysize / 8
			keybin: allocate (binlen + 20)
			hdr: as int-ptr! keybin
			hdr/1: 0206h
			hdr/2: A400h
			hdr/3: RSA_PUB_MAGIC
			hdr/4: keysize
			hdr/5: 00010001h
			copy-memory keybin + 20 key binlen
			print-line ["binlen: " binlen]
			dump-memory keybin 1 17
			CryptAcquireContext :provider null MS-Enhanced-Crypt-Str PROV_RSA_FULL CRYPT_VERIFYCONTEXT
			CryptImportKey provider keybin binlen + 20 0 0 :hKey
			copy-memory outputbuff data datalen
			CryptEncrypt hKey null as byte! 1 0 outputbuff :outputlen binlen
			CryptDestroyKey hKey
			free keybin
			retlen/1: outputlen
			outputbuff
		]
		
		get-rsa-decrypt: func [
			key		[byte-ptr!]
			keylen	[integer!]
			data	[byte-ptr!]
			datalen	[integer!]
			pad		[integer!]
			retlen	[int-ptr!]
			return: [byte-ptr!]
			/local
				provider 	[integer!]
				hKey		[integer!]
				keybin		[byte-ptr!]
				binlen		[integer!]
				hdr			[int-ptr!]
				keysize		[integer!]
		][
			provider: 0
			hKey: 0
			outputlen: datalen
			keysize: 1024;((keylen + 7) / 8) * 64
			binlen: keysize / 8
			keybin: allocate (binlen + 20)
			hdr: as int-ptr! keybin
			hdr/1: 0207h
			hdr/2: A400h
			hdr/3: RSA_PRI_MAGIC
			hdr/4: keysize
			hdr/5: 00010001h
			copy-memory keybin + 20 key binlen
			print-line ["binlen: " binlen]
			dump-memory keybin 1 17
			CryptAcquireContext :provider null MS-Enhanced-Crypt-Str PROV_RSA_FULL CRYPT_VERIFYCONTEXT
			CryptImportKey provider keybin binlen + 20 0 0 :hKey
			copy-memory outputbuff data datalen
			CryptDecrypt hKey null as byte! 1 0 outputbuff :outputlen binlen
			CryptDestroyKey hKey
			free keybin
			retlen/1: outputlen
			outputbuff
		]
		
	]
	Linux [
		;-- Using User-space interface for Kernel Crypto API
		;-- Exists in kernel starting from Linux 2.6.38
		#import [
			LIBC-file cdecl [
				socket: "socket" [
					family	[integer!]
					type	[integer!]
					protocl	[integer!]
					return: [integer!]
				]
				sock-bind: "bind" [
					fd 		[integer!]
					addr	[byte-ptr!]
					addrlen [integer!]
					return:	[integer!]
				]
				accept:	"accept" [
					fd		[integer!]
					addr	[byte-ptr!]
					addrlen	[int-ptr!]
					return:	[integer!]
				]
				read:	"read" [
					fd		[integer!]
					buf	    [byte-ptr!]
					size	[integer!]
					return:	[integer!]
				]
				close:	"close" [
					fd		[integer!]
					return:	[integer!]
				]
			]
		]

		#define AF_ALG 					38
		#define SOCK_SEQPACKET 			5

		;struct sockaddr_alg {					;-- 88 bytes
		;    __u16   salg_family;
		;    __u8    salg_type[14];				;-- offset: 2
		;    __u32   salg_feat;					;-- offset: 16
		;    __u32   salg_mask;
		;    __u8    salg_name[64];				;-- offset: 24
		;};

		get-digest: func [
			data		[byte-ptr!]
			len			[integer!]
			type		[integer!]
			return:		[byte-ptr!]
			/local
				fd		[integer!]
				opfd	[integer!]
				sa		[byte-ptr!]
				alg		[c-string!]
				hash	[byte-ptr!]
				size	[integer!]
		][
			hash: as byte-ptr! "0000000000000000000"
			sa: allocate 88
			set-memory sa #"^@" 88
			sa/1: as-byte AF_ALG
			copy-memory sa + 2 as byte-ptr! "hash" 4
			either type = ALG_MD5 [
				alg: "md5"
				size: 16
			][
				alg: "sha1"
				size: 20
			]
			copy-memory sa + 24 as byte-ptr! alg 4
			fd: socket AF_ALG SOCK_SEQPACKET 0
			sock-bind fd sa 88
			opfd: accept fd null null
			write opfd as c-string! data len
			read opfd hash size
			close opfd
			close fd
			free sa
			hash
		]
	]
	#default [											;-- MacOSX,Android,Syllable,FreeBSD
		;-- Using OpenSSL Crypto library
		#switch OS [
			MacOSX [
				#define LIBCRYPTO-file "libcrypto.dylib"
			]
			FreeBSD [
				#define LIBCRYPTO-file "libcrypto.so.7"
			]
			#default [
				#define LIBCRYPTO-file "libcrypto.so"
			]
		]
		#import [
			LIBCRYPTO-file cdecl [
				compute-md5: "MD5" [
					data	[byte-ptr!]
					len		[integer!]
					output	[byte-ptr!]
					return: [byte-ptr!]
				]
				compute-sha1: "SHA1" [
					data	[byte-ptr!]
					len		[integer!]
					output	[byte-ptr!]
					return: [byte-ptr!]
				]
			]
		]

		;typedef struct MD5state_st						;-- 92 bytes
		;	{
		;	MD5_LONG A,B,C,D;
		;	MD5_LONG Nl,Nh;
		;	MD5_LONG data[MD5_LBLOCK];
		;	unsigned int num;
		;	} MD5_CTX;

		get-digest: func [
			data		[byte-ptr!]
			len			[integer!]
			type		[integer!]
			return:		[byte-ptr!]
			/local
				fd		[integer!]
				opfd	[integer!]
				sa		[byte-ptr!]
				alg		[c-string!]
				hash	[byte-ptr!]
				size	[integer!]
		][
			hash: as byte-ptr! "0000000000000000000"
			either type = ALG_MD5 [
				compute-md5 data len hash
			][
				compute-sha1 data len hash
			]
			hash
		]
	]]
]
