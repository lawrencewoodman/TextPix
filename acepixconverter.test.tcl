#############################################################
# File:		acepixconverter.test.tcl
# Author:	Lawrence Woodman
# Created:	31st March 2010
#------------------------------------------------------------
# Tests for AcePixConverter namespace
#############################################################
source acepixconverter.tcl

proc test_lcountUnique {} {
	puts -nonewline "test_lcountUnique()  - "
	
	if {[lcountUnique [list 9 48 845 284 245 12 9 48 32 48 12 4 6 ]] != 9} {
		puts "Failed."
		exit
	}
	
	puts "Passed."
}


# TODO: Extened this to the checking of changing of blocks where inverse is removed and still in use.
proc test_removeCharSetChar {} {
	puts -nonewline "test_removeCharSetChar()  - "
	set ::AcePixConverter::charSet [dict create {0 0 1 1} 1 {1 1 0 0} 1 {0 1 1 0} 1 {1 0 0 1} 1]
	
	# Test removing a char that exists
	::AcePixConverter::removeCharSetChar {1 1 0 0}
	
	if {[dict size $::AcePixConverter::charSet] != 2} {
		puts "Failed."
		exit
	}
	
	if {$::AcePixConverter::charSet != [dict create {0 1 1 0} 1 {1 0 0 1} 1]} {
		puts "Failed."
		exit
	}
	
	# Test removing a char that doesn't exist
	::AcePixConverter::removeCharSetChar {0 0 0 1}
	
	if {[dict size $::AcePixConverter::charSet] != 2} {
		puts "Failed."
		exit
	}
	
	if {$::AcePixConverter::charSet != [dict create {0 1 1 0} 1 {1 0 0 1} 1]} {
		puts "Failed."
		exit
	}

	
	# Test removing a char but not its inverse 
	::AcePixConverter::removeCharSetChar {1 0 0 1} false
	
	if {[dict size $::AcePixConverter::charSet] != 1} {
		puts "Failed."
		exit
	}
	
	if {$::AcePixConverter::charSet != [dict create {0 1 1 0} 1]} {
		puts "Failed."
	}
	
	puts "Passed."
}


proc test_createInitialCharSet {} {
	puts -nonewline "test_createInitialCharSet()  - "
	
	set ::AcePixConverter::blocks [list {0 0 1 1} {1 1 0 0} {0 1 1 0} {0 0 1 1} {1 0 0 1} {0 1 1 0} {0 0 1 1} {1 1 1 1}]
	::AcePixConverter::createInitialCharSet
	
	
	
	if {[dict size $::AcePixConverter::charSet] != 6} {
		puts "Failed."
		exit
	}

	if {$::AcePixConverter::charSet != [dict create {0 0 1 1} 3 {1 1 0 0} 1 {0 1 1 0} 2 {1 0 0 1} 1 {1 1 1 1} 1 {0 0 0 0} 0]} {
		puts "Failed."
		exit
	}
	
	puts "Passed."
}

proc test_replaceBlocks {} {
	puts -nonewline "test_replaceBlocks()  - "
	
	set ::AcePixConverter::blocks [list {0 0 1 1} {1 1 0 0} {0 1 1 0} {0 0 1 1} {1 0 0 1} {0 1 1 0} {0 0 1 1} {1 1 1 1}]
		
	::AcePixConverter::replaceBlocks [list 0 1 1 0] [list 0 1 1 1]

	if {$::AcePixConverter::blocks != [list {0 0 1 1} {1 1 0 0} {0 1 1 1} {0 0 1 1} {1 0 0 0} {0 1 1 1} {0 0 1 1} {1 1 1 1}]} {
		puts "Failed."
		exit
	}
	
	puts "Passed."
}



proc test_blockSixteenth {} {
	puts -nonewline "test_blockSixteenth()  - "
	
	set block [list 0 1 0 1 1 1 0 0 \
					1 0 0 0 1 1 0 0 \
					1 0 1 1 1 1 1 0 \
					0 0 0 1 0 0 0 1 \
					0 1 1 0 0 1 0 1 \
					0 1 0 0 1 1 1 0 \
					1 0 1 0 0 0 1 1 \
					1 1 0 0 1 1 0 0 ]
					
	if {[::AcePixConverter::blockSixteenth $block 0] != 2} {
		puts "Faileda."
		exit
	}
	
	if {[::AcePixConverter::blockSixteenth $block 1] != 1} {
		puts "Failedb."
		exit
	}

	if {[::AcePixConverter::blockSixteenth $block 2] != 4} {
		puts "Failedc."
		exit
	}
		
	if {[::AcePixConverter::blockSixteenth $block 3] != 0} {
		puts "Failedd."
		exit
	}

	if {[::AcePixConverter::blockSixteenth $block 4] != 1} {
		puts "Failede."
		exit
	}

	if {[::AcePixConverter::blockSixteenth $block 5] != 3} {
		puts "Failedf."
		exit
	}

	if {[::AcePixConverter::blockSixteenth $block 6] != 2} {
		puts "Failedg."
		exit
	}
	
	if {[::AcePixConverter::blockSixteenth $block 7] != 2} {
		puts "Failed."
		exit
	}
	
	if {[::AcePixConverter::blockSixteenth $block 8] != 2} {
		puts "Failed."
		exit
	}
	
	if {[::AcePixConverter::blockSixteenth $block 9] != 1} {
		puts "Failed."
		exit
	}
	
	if {[::AcePixConverter::blockSixteenth $block 10] != 3} {
		puts "Failed."
		exit
	}

	if {[::AcePixConverter::blockSixteenth $block 11] != 2} {
		puts "Failed."
		exit
	}

	if {[::AcePixConverter::blockSixteenth $block 12] != 3} {
		puts "Failed."
		exit
	}

	if {[::AcePixConverter::blockSixteenth $block 13] != 1} {
		puts "Failed."
		exit
	}

	if {[::AcePixConverter::blockSixteenth $block 14] != 2} {
		puts "Failed."
		exit
	}

	if {[::AcePixConverter::blockSixteenth $block 15] != 2} {
		puts "Failed."
		exit
	}

	
	puts "Passed."
}


proc test_calcPlainCharSet {} {
	puts -nonewline "test_finalizeCharSet()  - "
	
	set ::AcePixConverter::blocks [list {0 0 1 1} {1 1 0 0} {0 1 1 0} {0 0 1 1} {1 0 0 1} {0 1 1 0} {0 0 1 1} {1 1 1 1}]
	::AcePixConverter::createInitialCharSet
	
	::AcePixConverter::calcPlainCharSet
	
	if {[llength $::AcePixConverter::plainCharSet] != 6} {
		puts "Failed."
		exit
	}

	for {set i 0} {$i < [expr {[llength $::AcePixConverter::plainCharSet/2]}]} {incr i} {
		if {[lindex $::AcePixConverter::plainCharSet $i] != [::AcePixConverter::getInverseBlock [lindex $::AcePixConverter::plainCharSet [expr {$i + 3}]]]} {
			puts "Failed."
			exit
		}
	}


	puts "Passed."
}


proc test_findBlocksWithDifference {} {
	puts -nonewline "test_findBlocksWithDifference()  - "
	
	
	set ::AcePixConverter::blocks [list]
	
	lappend ::AcePixConverter::blocks [list  0 1 0 1 1 1 0 0 \
											 1 0 0 0 1 1 0 0 \
											 1 0 1 1 1 1 1 0 \
											 0 0 0 1 0 0 0 1 \
											 0 1 1 0 0 1 0 1 \
											 0 1 0 0 1 1 1 0 \
											 1 0 1 0 0 0 1 1 \
											 1 1 0 0 1 1 0 0]  


	lappend ::AcePixConverter::blocks [list 1 0 1 1 0 1 0 1 \
						 					1 0 0 1 1 0 1 0 \
							 				1 1 0 1 1 0 0 1 \
											1 0 1 1 0 1 1 0 \
						 				 	1 0 1 1 0 1 0 1 \
						 				 	1 1 0 1 1 0 1 0 \
						 				 	0 1 1 0 0 1 0 1 \
						 				 	1 0 1 1 1 0 1 0 ]
						 				 
	lappend ::AcePixConverter::blocks [list 1 0 1 1 1 0 0 0 \
										 	1 1 1 1 1 0 0 1 \
						 				 	1 1 0 0 1 1 0 1 \
										 	0 1 1 1 1 0 1 0 \
										 	0 1 0 1 1 0 0 0 \
										 	1 0 1 1 0 1 0 0 \
										 	1 0 0 1 0 0 1 0 \
										 	1 1 0 0 1 0 0 0]
										 	
	lappend ::AcePixConverter::blocks [list 0 1 1 0 1 0 0 1 \
						 					0 1 1 1 1 0 1 0 \
							 				1 1 0 1 0 1 0 1 \
											1 0 1 1 1 0 1 0 \
						 				 	1 0 1 1 0 1 0 1 \
						 				 	1 1 0 1 1 0 1 0 \
						 				 	0 1 1 0 0 1 0 0 \
						 				 	1 0 1 1 1 0 1 1 ]
 
											 
							 
			 
	::AcePixConverter::createInitialCharSet
						 
	set charNotExist [list  1 1 0 1 0 1 1 0 \
							0 0 1 1 0 1 1 0 \
							1 0 1 0 0 1 0 1 \
							1 1 1 0 0 0 1 0 \
							0 1 0 1 0 1 1 1 \
							0 0 0 1 1 1 0 0 \
							1 0 1 1 1 1 0 1 \
							1 0 0 0 0 0 0 1 ]
							
							 		
	set charNoDifference [lindex $::AcePixConverter::blocks 1]	
	
	# Test for a char that doesn't exist							
	if {[::AcePixConverter::findBlocksWithDifference $charNotExist 0] != -1} {
		puts "Failed."
		exit
	}

	# Test for a char that exists and is no different in terms of 
	set foundChars [::AcePixConverter::findBlocksWithDifference $charNoDifference 0]
	
	if {$foundChars == -1} {
		puts "Failed."
		exit
	}
	
	if {[llength $foundChars] != 2} {
		puts "Failed."
		exit
	}
	
	
	if {[lindex $foundChars 0 ] != $charNoDifference} {
		puts "Failed."
		puts $foundChars
		exit
	}
	

												 
						 
	puts "Passed."					 
}




########################################################
#                    Run the tests
########################################################
test_createInitialCharSet
test_removeCharSetChar

test_lcountUnique
test_inverseCharExists
test_getInverseChar
#test_replaceBlocks
test_blockSixteenth
test_calcPlainCharSet
test_findBlocksWithDifference			
exit
