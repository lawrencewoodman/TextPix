#############################################################
# File:		textpixconverter.test.tcl
# Author:	Lawrence Woodman
# Created:	31st March 2010
#------------------------------------------------------------
# Tests for TextPixConverter namespace
#------------------------------------------------------------
# License:
# Copyright (c) 2010, Lawrence Woodman
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or 
# without modification, are permitted provided that the following 
# conditions are met:
#
#    * Redistributions of source code must retain the above 
#      copyright notice, this list of conditions and the following 
#      disclaimer.
#    * Redistributions in binary form must reproduce the above 
#      copyright notice, this list of conditions and the following 
#      disclaimer in the documentation and/or other materials 
#      provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
#############################################################
source textpixconverter.tcl

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
	set ::TextPixConverter::charSet [dict create {0 0 1 1} 1 {1 1 0 0} 1 {0 1 1 0} 1 {1 0 0 1} 1]
	
	# Test removing a char that exists
	::TextPixConverter::removeCharSetChar {1 1 0 0}
	
	if {[dict size $::TextPixConverter::charSet] != 3} {
		puts "Failed."
		exit
	}
	
	if {$::TextPixConverter::charSet != [dict create {0 0 1 1} 1 {0 1 1 0} 1 {1 0 0 1} 1]} {
		puts "Failed."
		exit
	}
	
	# Test removing a char that doesn't exist
	::TextPixConverter::removeCharSetChar {0 0 0 1}
	
	if {[dict size $::TextPixConverter::charSet] != 3} {
		puts "Failed."
		exit
	}
	
	
	if {$::TextPixConverter::charSet != [dict create {0 0 1 1} 1 {0 1 1 0} 1 {1 0 0 1} 1]} {
		puts "Failed."
		exit
	}

	
	puts "Passed."
}


proc test_createInitialCharSet {} {
	puts -nonewline "test_createInitialCharSet()  - "
	
	set ::TextPixConverter::blocks [list {0 0 1 1} {1 1 0 0} {0 1 1 0} {0 0 1 1} {1 0 0 1} {0 1 1 0} {0 0 1 1} {1 1 1 1}]
	::TextPixConverter::createInitialCharSet
	
	
	
	if {[dict size $::TextPixConverter::charSet] != 5} {
		puts "Failed."
		exit
	}

	if {$::TextPixConverter::charSet != [dict create {0 0 1 1} 3 {1 1 0 0} 1 {0 1 1 0} 2 {1 0 0 1} 1 {1 1 1 1} 1 ]} {
		puts "Failed."
		exit
	}
	
	puts "Passed."
}

proc test_replaceBlocks {} {
	puts -nonewline "test_replaceBlocks()  - "
	
	set ::TextPixConverter::blocks [list {0 0 1 1} {1 1 0 0} {0 1 1 0} {0 0 1 1} {1 0 0 1} {0 1 1 0} {0 0 1 1} {1 1 1 1}]
		
	::TextPixConverter::replaceBlocks {0 1 1 0} {0 1 1 1}

	if {$::TextPixConverter::blocks != [list {0 0 1 1} {1 1 0 0} {0 1 1 1} {0 0 1 1} {1 0 0 1} {0 1 1 1} {0 0 1 1} {1 1 1 1}]} {
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
					
	if {[::TextPixConverter::blockSixteenth $block 0] != 2} {
		puts "Failed."
		exit
	}
	
	if {[::TextPixConverter::blockSixteenth $block 1] != 1} {
		puts "Failed."
		exit
	}

	if {[::TextPixConverter::blockSixteenth $block 2] != 4} {
		puts "Failed."
		exit
	}
		
	if {[::TextPixConverter::blockSixteenth $block 3] != 0} {
		puts "Failed."
		exit
	}

	if {[::TextPixConverter::blockSixteenth $block 4] != 1} {
		puts "Failed."
		exit
	}

	if {[::TextPixConverter::blockSixteenth $block 5] != 3} {
		puts "Failed."
		exit
	}

	if {[::TextPixConverter::blockSixteenth $block 6] != 2} {
		puts "Failed."
		exit
	}
	
	if {[::TextPixConverter::blockSixteenth $block 7] != 2} {
		puts "Failed."
		exit
	}
	
	if {[::TextPixConverter::blockSixteenth $block 8] != 2} {
		puts "Failed."
		exit
	}
	
	if {[::TextPixConverter::blockSixteenth $block 9] != 1} {
		puts "Failed."
		exit
	}
	
	if {[::TextPixConverter::blockSixteenth $block 10] != 3} {
		puts "Failed."
		exit
	}

	if {[::TextPixConverter::blockSixteenth $block 11] != 2} {
		puts "Failed."
		exit
	}

	if {[::TextPixConverter::blockSixteenth $block 12] != 3} {
		puts "Failed."
		exit
	}

	if {[::TextPixConverter::blockSixteenth $block 13] != 1} {
		puts "Failed."
		exit
	}

	if {[::TextPixConverter::blockSixteenth $block 14] != 2} {
		puts "Failed."
		exit
	}

	if {[::TextPixConverter::blockSixteenth $block 15] != 2} {
		puts "Failed."
		exit
	}

	
	puts "Passed."
}


proc test_calcPlainCharSet {} {
	puts -nonewline "test_calcPlainCharSet()  - "
	
	set ::TextPixConverter::blocks [list {0 0 1 1} {1 1 0 0} {0 1 1 0} {0 0 1 1} {1 0 0 1} {0 1 1 0} {0 0 1 1} {1 1 1 1}]
	::TextPixConverter::createInitialCharSet
	
	::TextPixConverter::calcPlainCharSet
	
	if {[llength $::TextPixConverter::plainCharSet] != 5} {
		puts "Failed."
		exit
	}

	if {$::TextPixConverter::plainCharSet != [list {0 0 1 1} {0 1 1 0} {1 0 0 1} {1 1 0 0} {1 1 1 1}]} {
		puts "Failed."
		exit	
	}

	puts "Passed."
}


# TODO: Test with greater difference than 0
proc test_findBlocksWithDifference {} {
	puts -nonewline "test_findBlocksWithDifference()  - "
	
	
	set ::TextPixConverter::blocks [list]
	
	lappend ::TextPixConverter::blocks [list 0 1 0 1 1 1 0 0 \
											 1 0 0 0 1 1 0 0 \
											 1 0 1 1 1 1 1 0 \
											 0 0 0 1 0 0 0 1 \
											 0 1 1 0 0 1 0 1 \
											 0 1 0 0 1 1 1 0 \
											 1 0 1 0 0 0 1 1 \
											 1 1 0 0 1 1 0 0]  


	lappend ::TextPixConverter::blocks [list 1 0 1 1 0 1 0 1 \
						 					 1 0 0 1 1 0 1 0 \
							 				 1 1 0 1 1 0 0 1 \
											 1 0 1 1 0 1 1 0 \
						 				 	 1 0 1 1 0 1 0 1 \
						 				 	 1 1 0 1 1 0 1 0 \
						 				 	 0 1 1 0 0 1 0 1 \
						 				 	 1 0 1 1 1 0 1 0 ]
						 				 
	lappend ::TextPixConverter::blocks [list 1 0 1 1 1 0 0 0 \
										 	 1 1 1 1 1 0 0 1 \
						 				 	 1 1 0 0 1 1 0 1 \
										 	 0 1 1 1 1 0 1 0 \
										 	 0 1 0 1 1 0 0 0 \
										 	 1 0 1 1 0 1 0 0 \
										 	 1 0 0 1 0 0 1 0 \
										 	 1 1 0 0 1 0 0 0]
										 	
	lappend ::TextPixConverter::blocks [list 0 1 1 0 1 0 0 1 \
						 					 0 1 1 1 1 0 1 0 \
							 				 1 1 0 1 0 1 0 1 \
											 1 0 1 1 1 0 1 0 \
						 				 	 1 0 1 1 0 1 0 1 \
						 				 	 1 1 0 1 1 0 1 0 \
						 				 	 0 1 1 0 0 1 0 0 \
						 				 	 1 0 1 1 1 0 1 1 ]
 
											 
							 
			 
	::TextPixConverter::createInitialCharSet
						 
	set charNotExist [list  1 1 0 1 0 1 1 0 \
							0 0 1 1 0 1 1 0 \
							1 0 1 0 0 1 0 1 \
							1 1 1 0 0 0 1 0 \
							0 1 0 1 0 1 1 1 \
							0 0 0 1 1 1 0 0 \
							1 0 1 1 1 1 0 1 \
							1 0 0 0 0 0 0 1 ]
							
							 		
	set charNoDifference [lindex $::TextPixConverter::blocks 1]	
	
	# Test for a char that doesn't exist
	set foundChars [::TextPixConverter::findBlocksWithDifference $charNotExist 0]	
	if {[dict size $foundChars] != 0} {
		puts "Failed."
		exit
	}

	# Test for a char that exists and is no different in terms of 
	set foundChars [::TextPixConverter::findBlocksWithDifference $charNoDifference 0]
	
	if {[dict size $foundChars] != 1} {
		puts "Failed."
		exit
	}

	if {[dict get $foundChars [lindex $::TextPixConverter::blocks 3]] != 1} {
		puts "Failed."

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
#test_inverseCharExists
#test_getInverseChar
test_replaceBlocks
test_blockSixteenth
test_calcPlainCharSet
test_findBlocksWithDifference			
exit
