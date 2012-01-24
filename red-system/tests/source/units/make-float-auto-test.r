REBOL [
  Title:   "Generates Red/System float! tests"
	Author:  "Peter W A Wood"
	File: 	 %make-float-auto-test.r
	Version: 0.1.0
	Rights:  "Copyright (C) 2011 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;; initialisations 
tests: copy ""                          ;; string to hold generated tests
test-number: 0                          ;; number of the generated test
make-dir %auto-tests/
file-out: %auto-tests/float-auto-test.reds

;; create a block of values to be used in the binary ops tests
test-values: [
            0.0                   
  -2147483648.0                   
   2147483647.0
           -1.0
            3.0
           -7.0
            5.0
       123456.7890
            1.222090944E+33
            9.99999E-45
            7.7E18
]

tol: 1e-4   

;; create blocks of operators to be applied
test-binary-ops: [
  +
  -
  *
  /
]

test-comparison-ops: [
  =
  <>
  <
  >
  >=
  <=
]

test-comparison-values: [
  -1E-13
  0.0
  +1E-13
]

;; create test file with header
append tests "Red/System [^(0A)"
append tests {  Title:   "Red/System auto-generated float! tests"^(0A)}
append tests {	Author:  "Peter W A Wood"^(0A)}
append tests {  File: 	 %float-auto-test.reds^(0A)}
append tests {  License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"^(0A)}
append tests "]^(0A)^(0A)"
append tests "^(0A)^(0A)comment {"
append tests "  This file is generated by make-float-auto-test.r^(0A)"
append tests "  Do not edit this file directly.^(0A)"
append tests "}^(0A)^(0A)"
append tests join ";make-length:" 
                  [length? read %make-float-auto-test.r "^(0A)^(0A)"]
append tests "#include %../../../../../quick-test/quick-test.reds^(0A)^(0A)"
append tests {~~~start-file~~~ "Auto-generated tests for integers"^(0A)^(0A)}
append tests {===start-group=== "Auto-generated tests for integers"^(0A)^(0A)}

write file-out tests
tests: copy ""

;; binary operator tests - in global context
foreach op test-binary-ops [
  foreach operand1 test-values [
    foreach operand2 test-values [
      ;; only write a test if REBOL produces a result
      if attempt [expected: do reduce [operand1 op operand2]][
        
        expected: to decimal! expected
        
        ;; test with literal values
        test-number: test-number + 1
        append tests join {  --test-- "float-auto-} [test-number {"^(0A)}]
        append tests "  --assertf~= "
        append tests reform [expected " (" operand1 op operand2 ") " tol "^(0A)"]
        
        ;; test with variables
        test-number: test-number + 1
        append tests join {  --test-- "float-auto-} [test-number {"^(0A)}]
        append tests join "      i: " [operand1 "^(0A)"]
        append tests join "      j: " [operand2 "^(0A)"]
        append tests rejoin ["      k:  i " op " j^(0A)"]
        append tests "  --assertf~= "
        append tests reform [expected " k " tol "^(0A)"]
           
        ;; write tests to file
        write/append file-out tests
        tests: copy ""
      ]
      recycle
    ]
  ]
]

;; binary operator tests - inside a function

;; write function spec
tests: {
float-auto-test-func: func [
  /local
    i [float!]
    j [float!]
    k [float!]
][
}

write/append file-out tests
tests: copy ""

foreach op test-binary-ops [
  foreach operand1 test-values [
    foreach operand2 test-values [
      ;; only write a test if REBOL produces a result
      if attempt [expected: do reduce [operand1 op operand2]][
       
        expected: to decimal! expected
        
        ;; test with variables inside the function
        test-number: test-number + 1
        append tests join {    --test-- "float-auto-} [test-number {"^(0A)}]
        append tests join "      i: " [operand1 "^(0A)"]
        append tests join "      j: " [operand2 "^(0A)"]
        append tests rejoin ["      k:  i " op " j^(0A)"]
        append tests "    --assertf~= "
        append tests reform [expected " k " tol "^(0A)"]
        
        
        ;; write tests to file
        write/append file-out tests
        tests: copy ""
      ]
      recycle
    ]
  ]
]

;; write closing bracket and function call
append tests "  ]^(0a)"
append tests "float-auto-test-func^(0a)"
write/append file-out tests
tests: copy ""


;; comparison tests
foreach op test-comparison-ops [
  foreach operand1 test-values [
    foreach oper2 test-comparison-values [
      ;; only write a test if REBOL produces a result
      if all [
        attempt [operand2: operand1 + oper2]
        attempt [expected: do reduce [operand1 op operand2]]
      ][
        test-number: test-number + 1
        append tests join {  --test-- "float-auto-} [test-number {"^(0A)}]
        append tests "  --assert "
        append tests reform [expected " = (" operand1 op operand2 ")^(0A)"]

        ;; write tests to file
        write/append file-out tests
        tests: copy ""
      ]
    ]
  ]
]


;; write file epilog
append tests "^(0A)===end-group===^(0A)^(0A)"
append tests {~~~end-file~~~^(0A)^(0A)}

write/append file-out tests
      
print ["Number of assertions generated" test-number]

