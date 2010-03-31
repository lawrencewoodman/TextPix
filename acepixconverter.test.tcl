#############################################################
# File:		acepixconverter.test.tcl
# Author:	Lawrence Woodman
# Created:	31st March 2010
#------------------------------------------------------------
# Tests for AcePixConverter namespace
#############################################################
source acepixconverter.tcl


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



proc test_calculateCharSetSize {} {
	puts -nonewline "test_calculateCharSetSize() - "
	
	set ::AcePixConverter::charSet [lsort [list {0 0 1 1} {1 1 0 0} {0 1 1 0}]]

	::AcePixConverter::calculateCharSetSize

	if {$::AcePixConverter::charSetSize != 2} {
		puts "Failed."
		exit
	}
	
	
	puts "Passed."
}



proc test_removeCharSetChar {} {
	puts -nonewline "test_removeCharSetChar()  - "
	set ::AcePixConverter::charSet [lsort [list {0 0 1 1} {1 1 0 0} {0 1 1 0}]]
		set ::AcePixConverter::charSetSize 3
	
	
	# Test removing a char that exists
	::AcePixConverter::removeCharSetChar {1 1 0 0}
	
	if {$::AcePixConverter::charSetSize != 2} {
		puts "Failed."
		exit
	}
	
	if {$::AcePixConverter::charSet != [list {0 0 1 1} {0 1 1 0}]} {
		puts "Failed."
		exit
	}
	
	# Test removing a char that doesn't exist
	::AcePixConverter::removeCharSetChar [list {1 0 0 1}]
	
	if {$::AcePixConverter::charSetSize != 2} {
		puts "Failed."
		exit
	}
	
	if {$::AcePixConverter::charSet != [list {0 0 1 1} {0 1 1 0}]} {
		puts "Failed."
		exit
	}

	
	
	puts "Passed."
}


proc test_createInitialCharSet {} {
	puts -nonewline "test_createInitialCharSet()  - "
	
	set ::AcePixConverter::blocks [list {0 0 1 1} {1 1 0 0} {0 1 1 0} {0 0 1 1} {1 0 0 1} {0 1 1 0} {0 0 1 1} {1 1 1 1}]
	::AcePixConverter::createInitialCharSet
	
	
	
	if {$::AcePixConverter::charSetSize != 3} {
		puts "Failed."
		exit
	}
	
	if {$::AcePixConverter::charSet != [list {0 0 1 1} {0 1 1 0} {1 0 0 1} {1 1 0 0} {1 1 1 1}]} {
		puts "Failed."
		exit
	}
	
	puts "Passed."
}

proc test_replaceBlocks {} {
	puts -nonewline "test_replaceBlocks()  - "
	
	set ::AcePixConverter::blocks [list {0 0 1 1} {1 1 0 0} {0 1 1 0} {0 0 1 1} {1 0 0 1} {0 1 1 0} {0 0 1 1} {1 1 1 1}]
		
	::AcePixConverter::replaceBlocks [list 0 1 1 0] [list 0 1 1 1]

	if {$::AcePixConverter::blocks != [list {0 0 1 1} {1 1 0 0} {0 1 1 1} {0 0 1 1} {1 0 0 1} {0 1 1 1} {0 0 1 1} {1 1 1 1}]} {
		puts "Failed."
		exit
	}
	
	puts "Passed."
}


########################################################
#                    Run the tests
########################################################
test_inverseCharExists
test_getInverseBlock
test_calculateCharSetSize
test_removeCharSetChar
test_createInitialCharSet
test_replaceBlocks

exit