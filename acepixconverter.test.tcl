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


proc test_getInverseBlock {} {
	puts -nonewline "test_getInverseBlock() - "
	
	if {[::AcePixConverter::getInverseBlock [list 0 0 1 1]] !=  [list 1 1 0 0]} {
		puts "Failed."
		exit
	}
	
	puts "Passed."

}

proc test_inverseCharExists {} {
	puts -nonewline "test_inverseCharExists() - "
	
	set ::AcePixConverter::charSet [lsort [list {0 0 1 1} {1 1 0 0} {0 1 1 0}]]

	# Test that it detects an inverse character
	if {![::AcePixConverter::inverseCharExists [list 0 0 1 1]]} {
		puts "Failed."
		exit
	}

	# Test that it detects when no inverse character exists
	if {[::AcePixConverter::inverseCharExists [list 1 0 1 1]]} {
		puts "Failed."
		exit
	}
	
	
	puts "Passed."
}



proc test_removeCharSetChar {} {
	puts -nonewline "test_removeCharSetChar()  - "
	set ::AcePixConverter::charSet [lsort [list {0 0 1 1} {1 1 0 0} {0 1 1 0} {1 0 0 1}]]
	set ::AcePixConverter::charSetSize 4
	
	
	# Test removing a char that exists
	::AcePixConverter::removeCharSetChar {1 1 0 0}
	
	if {$::AcePixConverter::charSetSize != 2} {
		puts "Failed."
		exit
	}
	
	if {$::AcePixConverter::charSet != [list {0 1 1 0} {1 0 0 1}]} {
		puts "Failed."
		exit
	}
	
	# Test removing a char that doesn't exist
	::AcePixConverter::removeCharSetChar [list 0 0 0 1]
	
	if {$::AcePixConverter::charSetSize != 2} {
		puts "Failed."
		exit
	}
	
	if {$::AcePixConverter::charSet != [list {0 1 1 0} {1 0 0 1}]} {
		puts "Failed."
		exit
	}

	
	# Test removing a char but not its inverse 
	::AcePixConverter::removeCharSetChar [list 1 0 0 1] false
	
	if {$::AcePixConverter::charSetSize != 1} {
		puts "Failed."
		exit
	}
	
	if {$::AcePixConverter::charSet != [list {0 1 1 0} ]} {
		puts "Failed."
	}
	
	puts "Passed."
}


proc test_createInitialCharSet {} {
	puts -nonewline "test_createInitialCharSet()  - "
	
	set ::AcePixConverter::blocks [list {0 0 1 1} {1 1 0 0} {0 1 1 0} {0 0 1 1} {1 0 0 1} {0 1 1 0} {0 0 1 1} {1 1 1 1}]
	::AcePixConverter::createInitialCharSet
	
	
	
	if {$::AcePixConverter::charSetSize != 6} {
		puts "Failed."
		exit
	}

	if {$::AcePixConverter::charSet != [list {0 0 0 0} {0 0 1 1} {0 1 1 0} {1 0 0 1} {1 1 0 0} {1 1 1 1} ]} {
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


proc test_finalizeCharSet {} {
	puts -nonewline "test_finalizeCharSet()  - "
	
	set ::AcePixConverter::blocks [list {0 0 1 1} {1 1 0 0} {0 1 1 0} {0 0 1 1} {1 0 0 1} {0 1 1 0} {0 0 1 1} {1 1 1 1}]
	::AcePixConverter::createInitialCharSet
	
	::AcePixConverter::finalizeCharSet
	
	if {[llength $::AcePixConverter::charSet] != 6} {
		puts "Failed."
		exit
	}

	if {$::AcePixConverter::charSetSize != 6} {
		puts "Failed."
		exit
	}

	for {set i 0} {$i < [expr {$::AcePixConverter::charSetSize/2}]} {incr i} {
		if {[lindex $::AcePixConverter::charSet $i] != [::AcePixConverter::getInverseBlock [lindex $::AcePixConverter::charSet [expr {$i + 3}]]]} {
			puts "Failed."
			exit
		}
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
test_getInverseBlock
test_replaceBlocks

test_finalizeCharSet			
exit
