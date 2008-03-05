;; test_tcl.nu
;;  tests for the Nu/Objective-C Tcl wrapper.
;;
;;  Copyright (c) 2008 Tim Burks, Neon Design Technology, Inc.

(load "NuTcl")

(class TestNuTcl is NuTestCase
     
     (- (id) testInterpreter is
        (set tcl ((TclInterpreter alloc) init))
        (assert_equal "4" (tcl eval:"expr 2 + 2")))
     
     (- (id) testCommandCreation is
        (class CountCommand is TclCommand
             (- (id) main:(id) arguments is
                ((- (arguments count) 1) intValue)))
        
        (set tcl ((TclInterpreter alloc) init))
        (tcl addCommand:((CountCommand alloc) init) withName:"count")
        (assert_equal "0" (tcl eval:"count"))
        (assert_equal "3" (tcl eval:"count 1 2 3"))
        (assert_equal "2" (tcl eval:"count 1 [count 1 2 3 4 5]")))
     
     (- (id) testAddCommand is
        (class AddCommand is TclCommand
             (- (id) main:(id) arguments is
                ((arguments subarrayWithRange:(list 1 (- (arguments count) 1))) reduce:(do (x y) (+ x y)) from:0)))
        (set tcl ((TclInterpreter alloc) init))
        (tcl addCommand:((AddCommand alloc) init) withName:"add")
        (assert_equal "15.0" (tcl eval:"add 1 2 3 4 5")))
     
     (- (id) testVariableAccess is
        (set tcl ((TclInterpreter alloc) init))
        (tcl eval:"set X 123")
        (assert_equal "123" (tcl valueForKey:"X"))
        (assert_equal nil (tcl valueForKey:"x"))))

