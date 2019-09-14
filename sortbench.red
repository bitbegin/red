Red []

gen-vector: context [
	shuffled-int: function [size][
		ret: make block! size
		repeat i size [append ret i - 1]
		random ret
		ret
	]

	shuffled-16-values-int: function [size][
		ret: make block! size
		repeat i size [append ret i - 1 % 16]
		random ret
		ret
	]

	all-equal-int: function [size][
		ret: make block! size
		repeat i size [append ret 0]
		ret
	]

	ascending-int: function [size][
		ret: make block! size
		repeat i size [append ret i - 1]
		ret
	]

	descending-int: function [size][
		ret: make block! size
		i: size - 1
		while [i >= 0][
			append ret i
			i: i - 1
		]
		ret
	]

	pipe-organ-int: function [size][
		ret: make block! size
		i: 0
		m: size / 2
		while [i < m][
			append ret i
			i: i + 1
		]
		i: m
		while [i < size][
			append ret size - i
			i: i + 1
		]
		ret
	]

	push-front-int: function [size][
		ret: make block! size
		repeat i size - 1 [append ret i]
		append ret 0
		ret
	]

	push-middle-int: function [size][
		ret: make block! size
		i: 0
		m: size / 2
		while [i < size][
			if i <> m [
				append ret i
			]
			i: i + 1
		]
		append ret m
		ret
	]
]

test-all: function [size][
	dists: keys-of gen-vector
	forall dists [
		prin mold dists/1
		prin "			"
		f: get in gen-vector dists/1
		v: f size
		t: none
		loop 5 [
			v2: copy v
			s: now/time/precise
			sort v2
			e: now/time/precise
			d: (to float! e - s) * 1000
			either t = none [
				t: d
			][
				t: t + d
			]
		]
		clear v2
		prin to integer! t / 5
		prin "ms			"
		t: none
		loop 5 [
			v2: copy v
			s: now/time/precise
			sort/pbqsort v2
			e: now/time/precise
			d: (to float! e - s) * 1000
			either t = none [
				t: d
			][
				t: t + d
			]
		]
		clear v clear v2
		prin to integer! t / 5
		print "ms"
	]
]

print "1000000				qsort				pbqsort"
test-all 1000000
