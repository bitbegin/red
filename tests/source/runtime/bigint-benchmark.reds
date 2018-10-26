Red/System []

#include %../../../runtime/datatypes/bigdecimal.reds

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

bigint-add-test: func [
	big1				[bigint!]
	step				[integer!]
	count				[integer!]
	/local
		big2			[bigint!]
		tm1				[float!]
		tm2				[float!]
		ibuf			[integer!]
		ilen			[integer!]
][
	big2: bigint/load-uint step
	tm1: get-time yes yes
	loop count [
		big1: bigint/add big1 big2 true
	]
	tm2: get-time yes yes
	print-line ["		time: " tm2 - tm1]
	ibuf: 0
	ilen: 0
	bigint/form big1 10 :ibuf :ilen
	print "		result: "
	print-line as c-string! ibuf
	free as byte-ptr! ibuf
	bigint/free* big1
	bigint/free* big2
]

bigdecimal-add-test: func [
	big1				[bigint!]
	step				[integer!]
	count				[integer!]
	/local
		big2			[bigdecimal!]
		tm1				[float!]
		tm2				[float!]
		ibuf			[integer!]
		ilen			[integer!]
][
	big2: bigdecimal/load-uint step
	tm1: get-time yes yes
	loop count [
		big1: bigdecimal/add big1 big2 true
	]
	tm2: get-time yes yes
	print-line ["		time: " tm2 - tm1]
	ibuf: 0
	ilen: 0
	bigdecimal/form big1 :ibuf :ilen
	print "		result: "
	print-line as c-string! ibuf
	free as byte-ptr! ibuf
	bigdecimal/free* big1
	bigdecimal/free* big2
]

float-add-test: func [
	f1					[float!]
	step				[float!]
	count				[integer!]
	/local
		tm1				[float!]
		tm2				[float!]
][
	tm1: get-time yes yes
	loop count [
		f1: f1 + step
	]
	tm2: get-time yes yes
	print-line ["		time: " tm2 - tm1]
	print "		result: "
	print-line f1
]

bigint-sub-test: func [
	big1				[bigint!]
	step				[integer!]
	count				[integer!]
	/local
		big2			[bigint!]
		tm1				[float!]
		tm2				[float!]
		ibuf			[integer!]
		ilen			[integer!]
][
	big2: bigint/load-uint step
	tm1: get-time yes yes
	loop count [
		big1: bigint/sub big1 big2 true
	]
	tm2: get-time yes yes
	print-line ["		time: " tm2 - tm1]
	ibuf: 0
	ilen: 0
	bigint/form big1 10 :ibuf :ilen
	print "		result: "
	print-line as c-string! ibuf
	free as byte-ptr! ibuf
	bigint/free* big1
	bigint/free* big2
]

bigdecimal-sub-test: func [
	big1				[bigint!]
	step				[integer!]
	count				[integer!]
	/local
		big2			[bigdecimal!]
		tm1				[float!]
		tm2				[float!]
		ibuf			[integer!]
		ilen			[integer!]
][
	big2: bigdecimal/load-uint step
	tm1: get-time yes yes
	loop count [
		big1: bigdecimal/sub big1 big2 true
	]
	tm2: get-time yes yes
	print-line ["		time: " tm2 - tm1]
	ibuf: 0
	ilen: 0
	bigdecimal/form big1 :ibuf :ilen
	print "		result: "
	print-line as c-string! ibuf
	free as byte-ptr! ibuf
	bigdecimal/free* big1
	bigdecimal/free* big2
]

float-sub-test: func [
	f1					[float!]
	step				[float!]
	count				[integer!]
	/local
		tm1				[float!]
		tm2				[float!]
][
	tm1: get-time yes yes
	loop count [
		f1: f1 - step
	]
	tm2: get-time yes yes
	print-line ["		time: " tm2 - tm1]
	print "		result: "
	print-line f1
]

bigint-mul-test: func [
	big1				[bigint!]
	step				[integer!]
	count				[integer!]
	/local
		big2			[bigint!]
		tm1				[float!]
		tm2				[float!]
		ibuf			[integer!]
		ilen			[integer!]
][
	big2: bigint/load-uint step
	tm1: get-time yes yes
	loop count [
		big1: bigint/mul big1 big2 true
	]
	tm2: get-time yes yes
	print-line ["		time: " tm2 - tm1]
	ibuf: 0
	ilen: 0
	bigint/form big1 16 :ibuf :ilen
	print "		result: "
	print-line as c-string! ibuf
	free as byte-ptr! ibuf
	bigint/free* big1
	bigint/free* big2
]

bigdecimal-mul-test: func [
	big1				[bigint!]
	step				[integer!]
	count				[integer!]
	/local
		big2			[bigdecimal!]
		tm1				[float!]
		tm2				[float!]
		ibuf			[integer!]
		ilen			[integer!]
][
	big2: bigdecimal/load-uint step
	tm1: get-time yes yes
	loop count [
		big1: bigdecimal/mul big1 big2 true
	]
	tm2: get-time yes yes
	print-line ["		time: " tm2 - tm1]
	ibuf: 0
	ilen: 0
	bigdecimal/form big1 :ibuf :ilen
	print "		result: "
	print-line as c-string! ibuf
	free as byte-ptr! ibuf
	bigdecimal/free* big1
	bigdecimal/free* big2
]

bigint-div-test: func [
	big1				[bigint!]
	step				[integer!]
	count				[integer!]
	/local
		big2			[bigint!]
		tm1				[float!]
		tm2				[float!]
		ibuf			[integer!]
		ilen			[integer!]
][
	big2: bigint/load-uint step
	tm1: get-time yes yes
	loop count [
		big1: bigint/div big1 big2 true
	]
	tm2: get-time yes yes
	print-line ["		time: " tm2 - tm1]
	ibuf: 0
	ilen: 0
	bigint/form big1 16 :ibuf :ilen
	print "		result: "
	print-line as c-string! ibuf
	free as byte-ptr! ibuf
	bigint/free* big1
	bigint/free* big2
]

bigdecimal-div-test: func [
	big1				[bigint!]
	step				[integer!]
	count				[integer!]
	/local
		big2			[bigdecimal!]
		tm1				[float!]
		tm2				[float!]
		ibuf			[integer!]
		ilen			[integer!]
][
	big2: bigdecimal/load-uint step
	tm1: get-time yes yes
	loop count [
		big1: bigdecimal/div big1 big2 true
	]
	tm2: get-time yes yes
	print-line ["		time: " tm2 - tm1]
	ibuf: 0
	ilen: 0
	bigdecimal/form big1 :ibuf :ilen
	print "		result: "
	print-line as c-string! ibuf
	free as byte-ptr! ibuf
	bigdecimal/free* big1
	bigdecimal/free* big2
]

init: 0
step: 1
count: 1000000
print-line ["add test, init " init ", step " step ", count " count]
print-line "	bigint add:"
bigint-add-test bigint/load-uint init step count
print-line "	bigdecimal add:"
bigdecimal-add-test bigdecimal/load-uint init step count

init: 0
step: 100000000
count: 1000000
print-line ["add test, init " init ", step " step ", count " count]
print-line "	bigint add:"
bigint-add-test bigint/load-uint init step count
print-line "	bigdecimal add:"
bigdecimal-add-test bigdecimal/load-uint init step count
;print-line "	float add: (init 0, step 123456789.123456789, count 10000000)"
;float-add-test 0.0 123456789.123456789 10000000

init-str: "100000000000000"
step: 100000000
count: 1000000
print-line ["sub test, init " init-str ", step " step ", count " count]
print-line "	bigint sub:"
bigint-sub-test bigint/load-str init-str -1 10 step count
print-line "	bigdecimal sub:"
bigdecimal-sub-test bigdecimal/load-str init-str -1 step count
;print-line "	float sub: (init 1234567891139712.0, step 123456789.123456789, count 10000000)"
;float-sub-test 1234567891139712.0 123456789.123456789 10000000

init-str: "100000000000001"
step: 100000000
count: 1000000
print-line ["sub test, init " init-str ", step " step ", count " count]
print-line "	bigint sub:"
bigint-sub-test bigint/load-str init-str -1 10 step count
print-line "	bigdecimal sub:"
bigdecimal-sub-test bigdecimal/load-str init-str -1 step count

bigint/set-max-size 100000
bigdecimal/set-default-prec 1000

init: 1
step: 3
count: 100000
print-line ["mul test, init " init ", step " step ", count " count]
print-line "	bigint mul:"
bigint-mul-test bigint/load-uint init step count
print-line "	bigdecimal mul:"
bigdecimal-mul-test bigdecimal/load-uint init step count


init-str: "03159DAAF1600096FC5CA229B26A9DF10E284A66D02C7B692E7911DB7DFF9E4371BF3923060BBF89875AED54A28ED0FF88DBF35D2CFDBC2A9A86FB0237B03A4A2E765B735C10BEB99C5092B9933A82351860E4171AD7010AE7AEDFEC86C12361CF81D11A0621A7B854B1B404704A46E1265C453D98839DA3A4F536EEB750C3A919DAB146054295FAE834059A81AFB2D7F901B8F8AFEE11345C408747B51C36EE216F816D6302584C054143C575E6CFB78D7CC932CB4973EAE6E67023AACF716DAEE805E71754AC7B5ED282FB90DF6BCE786DA7470F6FF68A015BC3076AE864FA091D85BBA3535C72214325AB9A26361F0EDF89F257830599759C2EBA295A32AAA8E41CE8CAA097C04838C8F628D0A34399637E79490EE715C9F1D0B5366CDECDCEECB8417B15CB4D2971313B628C8E2C9D91D8D4FA4E749E9FAD75FC563E14B0580B88C099A11451218D6B33C6E6E264DB7F11A3B64353D66510CD8CA9CD5B7A121BBDE0D0DADCA0E672D71950AD20DF9B4FC6AFDA3168A00FE2D1D3BEF7AA8BB1BE605BED0765C75A88A16212259CDC1D0EA4400412404118D1F9BFDB6421167DF02B3E9E60BD45993D79115FBC40B0F88E794D3DD1C957BD740B41D0DCDF26AFBD4CFA7543FBA5CDC5ADC3F89C4700BF7A36685712029C6D6CE7B7A338ACBBD55DC13B0B65E3AB71C931CF580E2AD90D52F1D4F83FD8B1EBBC5B42E6B13AEAEBD0C910C1DD02A24A3AA3805B2F89FDA7ABD527FC397255B7ACD51F4752FCA9A73AC3C8896FC1FDD10AB792E93F91B7F3D2B7CE112FE70F4082F6BE1F6CF4E5CD47C1042E3D9513B90E3885389164BEAF4911656D7817D9AFDB63E5B82C9D2D1E14EC3BFD374F22AA07F7FE235D18617A749003E0EBE45B54E64AE75A0EBDF7CD7789CBAA6DBCBFC44E034227486AF0A65F5A9CACA4321327369800C01E53BEAFA40512CFB0616DEF0CD5A4AAD9DE7DFED3E725C1FF79D3623C523F1D2C9D3F3C78C0975E758D8953BCF389AD347F8FC5D29BF3AD8EC7365D64154AF10142FA20DF2CD0B5B5930AA871C3A92C71446A7CD9ADBF1028297C4FEF3E606A74ED85AEAF2150B13BD94293AA781D67F394C1D85E8E517BBC43BA64600CFDC2B485CA3B745F045189B60DCF7ABC9F4AA6D63EAE7BB75A580314B3208D297EEAF9CAD09F146FEDDC9CADA269036FD9543E36B3274413571F3A70D0111E0A575F89A257205B67AA29EE1AB98FA8D6EAC6C30C42A9F6E510A116BE923F28A7EE444C9F554846BA05BCE5921987BCA0A5FA635C9AD845715B870842C83912824F18BB6D918AE364591AEE0DDE7CE05FFF0573372DAB548C51E3631E455D9C5112652D5E2DAF32E872E5125059F8CA06824794E672CB8FA8D333BF1098CB0435C06A7E6CDD49C34A3D2BF45FFAACD10E6C9DAF379E8A6527E28F08C39B4D940F42DC4CD61B95B10A9ECAE497353CD855355AF245FF8DD0C297912AAD9331A8ABCFBC33FB37C9A090AC5E15EFCA2C5FB87649294A4D5E010482E4A021B116D7C68B9CDB908A70ACC1FA5DDEFCDF427AE4DE09C20A7E95B10236993BC0B7C23BEC405866A47C911920B6EDD53A7A61A9A369CB06D5F76ED238DAE8FE137D2932BE45FF4EF8389B20023982B082F3EB17E69DB70F495B1AD42B66A2B908AD157337919A9967DFD80CC7E86FAFD2FCED97988B042B2D080D1714BF53FFB09189757E899E954ECF4F20EF39C77812EF71993719DB2A7F5742EF7435261B754DFD7CD3650196599417BA45BABF698AC56C2D8F98BE81C60AD60D0C71ED24F652CE4521325CDA6A74F58A17027998D3A8CE514DE1D42DB61319F00AEE9581C83686086CE9BF24B1DC2E861343702EFF2EF14802ECBB0362A6E4B453F340857554083275C0F3B2BE40B4B8BE2F6F9AC2DB37FBC12F22102CDF71A1EAB5831931B4A8FE8E82DF7B87ACB631161EF66A1C8696712171A29F592A8C052C00B85050ACC5B305D1220E2380086D1D2DC01E8E834753A9C159C7465E928EA463260C0C09BCEF49A4846A8513E068B3CF343F02A77FE0841098CB2A1888306B178AAFB0B2E2169FB5BED9118530749980EA5D000633EA4EB00FBCFA35D92B4BC28436CFB3EBA594270B9434E9A30C193EDF9635689CE283F19189087B27AA9DB34847FD48B0FAAE32EC8CE4AB9F45B58A5F79E58ED7E272ACD6E0A4528020D3B0FDD1841C28BF7CC7C76F64DEE5A0FD097D932656E5C2FBD9DA268850CE59ABCFB78A6FC8C68167BF9AF960A0C76962A10BE77B161F36852B007F3C4B54421270F77C7282A8559B4E7D392E712A74C7EA305941772E167371D146DAE4C2961F28982FBA4D4B143855E2981E0A7F16717E2FDB84F7B9E763E27675073496A3B2839158AA25C18F4DC016926D993601B658F41D4D2EB0F85D900577678C99920156D3C1D86BDDF9AB1C45A98637469E23E59409BE62A1778356B5D36E8FF7C9F9CC07577EC817ECFA22E15552EB9F450E7B650DA07C79C0172895222D2C9172D86506C83812569D582678A2C4BB2D8D8E733BBD63C201BD14971F8C516A05E0702DE0A051BCDD27892897C29223F2BB7DB5A7BCC2569327263169F539ADD0A1974022FEA3460E94794D6AB893D70C8B99647B0854B9324635E2E6FC96C66505861A48E94464AC6FF548E51F232B131BAE08B1C2B077A61F62129EF015882DCAA4D00736E095D521D63C19EB691442E977D99577076894C0A7A4CA2A94CD7D0772B471DD66A248C9DB445D58639CEDC7A7C9273BF25FE318EF856F2DD663693B50BD72790AD7B666AD150341"
step: 3
count: 10000
print-line ["div test, init " init-str ", step " step ", count " count]
print-line "	bigint div:"
bigint-div-test bigint/load-str init-str -1 16 step count
print-line "	bigdecimal div:"
bigdecimal-div-test bigdecimal/load-float "1.6313501853426258965E4771" -1 step count
