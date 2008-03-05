;; @file       demo.nu
;; @discussion NuTcl demonstration.
;; @copyright  Copyright (c) 2008 Neon Design Technology, Inc.
;;
;;   Licensed under the Apache License, Version 2.0 (the "License");
;;   you may not use this file except in compliance with the License.
;;   You may obtain a copy of the License at
;;
;;       http://www.apache.org/licenses/LICENSE-2.0
;;
;;   Unless required by applicable law or agreed to in writing, software
;;   distributed under the License is distributed on an "AS IS" BASIS,
;;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;   See the License for the specific language governing permissions and
;;   limitations under the License.

(load "NuTcl")

;; this command creates an array from its arguments and returns it.
(class ArrayCommand is TclCommand
     (- (id) main:(id) arguments is
        (arguments subarrayWithRange:(list 1 (- (arguments count) 1)))))

;; this command counts the members of an array and returns the count.
(class CountCommand is TclCommand
     (- (id) main:(id) arguments is
        (set a (arguments 1))
        (puts "counting elements in array #{(a description)}")
        (a count)))

;; this command adds its arguments and returns the result.
(class AddCommand is TclCommand
     (- (id) main:(id) arguments is
        ((arguments subarrayWithRange:(list 1 (- (arguments count) 1))) reduce:(do (x y) (+ x y)) from:0)))

;; this is our Tcl interpreter wrapper.
(class TclInterpreter
     (- (void) install:(id) commandClass withName:(id) name is
        (self addCommand:((commandClass alloc) init) withName:name)))

;; create a Tcl interpreter and install our commands.
(set tcl ((TclInterpreter alloc) init))
(tcl install:ArrayCommand withName:"array")
(tcl install:CountCommand withName:"count")
(tcl install:AddCommand withName:"add")

;; run the interpreter to evaluate some instances of our commands.
(tcl eval:<<-END
	set x [array 1 2 3]
	puts "we just made an array $x"
	puts "the number of elements in the array is [count $x]"
	puts "the sum of the first five whole numbers is [add 1 2 3 4 5]"
END)

;; try this in an interactive nush session
;(tcl interact)