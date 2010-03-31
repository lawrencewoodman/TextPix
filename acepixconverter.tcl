#############################################################
# File:		acepixconverter.tcl
# Author:	Lawrence Woodman
# Created:	31st March 2010
#------------------------------------------------------------
# Functions for converting a picture into a form that can be
# loaded by the Jupiter Ace.
#############################################################
package require Img
source acepixpreprocessor.tcl


# Append a value to a list if the value doesn't already exist
# TODO: May not need this
proc lappendUnique {list value} {
	upvar $list l

	if {![info exists l] || [lsearch -exact $l $value] < 0} {
		lappend l $value
	}
}

# Count the number of unique elements in a list
proc lcountUnique {aList} {
	set count 0

	set uniqueList [list]
	
	foreach element $aList {
		lappendUnique uniqueList $element
	}

	

	return [llength $uniqueList]
}


namespace eval AcePixConverter {
	# The Ace's screen size (256x192)
	variable aceWidth 256
	variable aceHeight 192
	variable aceImage

	variable blocks
	variable numBlocks 768
	variable blockDiameter 8
	variable blockSize 64					;# The number of pixels in a block

	variable charSet
	variable charSetSize

	proc convertToBlocks {filename} {
		variable aceWidth
		variable aceHeight
		variable blocks
		variable blockDiameter
		variable aceImage

		set aceImage [::acePixPreprocessor::preprocess $filename]

		for {set y 0} {$y < $aceHeight} {incr y $blockDiameter} {
			for {set x 0} {$x < $aceWidth} {incr x $blockDiameter} {
				lappend blocks [getBlock $x $y]
			}
		}		
		

		puts "[lcountUnique $blocks] unique blocks."


	}
	

	proc getPixel {x y} {
		variable aceImage
		set colourList [$aceImage get $x $y]
	
		set blackList [list 255 255 255]
	
		if {$colourList == $blackList} {
			return 0
		} else {
			return 1
		}
	}

	proc getBlock {blockX blockY} {
		variable blockDiameter
		for {set y 0} {$y < $blockDiameter} {incr y} {
			for {set x 0} {$x < $blockDiameter} {incr x} {
				lappend block [getPixel [expr {$blockX+$x}] [expr {$blockY+$y}]]
			}
		}
	
		return $block
	}

	proc blockPixelMatchingDifference {block1 block2} {
		variable blockSize

		set difference 0

		for {set i 0} {$i <	$blockSize} {incr i} {
			if {[lindex $block1 $i] != [lindex $block2 $i]} {
				incr difference
			}
		}

		return $difference
	}
	
	
	proc blockPixelCount {block} {
		set count 0
		
		foreach b $block {
			if {$b == 1} {
				incr count
			}
		}
		
		return $count
	}
	
	proc blockPixelCountDifference {block1 block2} {
		return [expr {abs([blockPixelCount $block1] - [blockPixelCount $block2])}]
	}	


	# Count the number of black pixels in each quarter
	proc blockQuarter {block quarter} {
		switch $quarter {
			0	{	set startY 0
					set endY 3
					set startX 0
					set endX 3
				}
				
			1	{	set startY 0
					set endY 3
					set startX 4
					set endX 7
				}
				
			2	{	set startY 4
					set endY 7
					set startX 0
					set endX 3
				}
				
			3	{	set startY 4
					set endY 7
					set startX 4
					set endX 7
				}
		}	
		
		set count 0
		for {set y $startY} {$y <= $endY} {incr y} {
			for {set x $startX} {$x <= $endX} {incr x} {
				set i [expr {$y*8 + $x}]
				if {[lindex $block $i] == 1} {
					incr count
				}
			}	
		}
		
		return $count
	}				
	
	# Check the difference in the number of pixels in each quarter
	proc blockQuarterDifference {block1 block2} {
		
		set block1List [list [blockQuarter $block1 0] [blockQuarter $block1 1] [blockQuarter $block1 2] [blockQuarter $block1 3]]
		set block2List [list [blockQuarter $block2 0] [blockQuarter $block2 1] [blockQuarter $block2 2] [blockQuarter $block2 3]]
			
			
		set difference 0		
		for {set i 0} {$i < 4} {incr i} {
			if {[lindex $block1List $i] != [lindex $block2List $i]} {
				incr difference
			}
		}
		
		return $difference
	}

	
	# Returns the index to the nearest block with the specified difference from the block passed. 
	# If it can't find a block then it returns -1
	# TODO: Improve this so that it tries to find a block near the centre of the picture
	proc findSimilarBlock {char quarterDifference} {
		variable charSet 
		variable blockSize

		# Find all the blocks with the given difference
		for {set i 0} {$i < [llength $charSet]} {incr i} {
			if {[blockQuarterDifference [lindex $charSet $i] $char] == $quarterDifference} {
				lappend foundChars $i
			}
		}

		if {![info exists foundChars]} {
			return -1
		}

		set lowestPixelCountDifference $blockSize

		# Find the nearest chars in terms of pixel count
		foreach fChar $foundChars {
			set tempPixelCountDifference [blockPixelCountDifference [lindex $char $fChar] $char]
			if {$tempPixelCountDifference == $lowestPixelCountDifference} {
				lappend nearestPixelCountChars $fChar
			} elseif {$tempPixelCountDifference < $lowestPixelCountDifference} {
				set lowestPixelCountDifference $tempPixelCountDifference
				set nearestPixelCountChars [list $fChar]
			}
		}
		
		set lowestPixelMatchingDifference $blockSize
		set nearestChar [lindex $nearestPixelCountChars 0]

		# Find the nearest block in terms of matching pixels
		foreach nChar $nearestPixelCountChars {
			set tempPixelMatchingDifference [blockPixelMatchingDifference [lindex $char $nChar] $char] 
			if {$tempPixelMatchingDifference < $lowestPixelMatchingDifference} {
				set lowestPixelDifference $tempPixelMatchingDifference
				set nearestChar $nChar
			}
		}
		
		

		return $nearestChar
	}	

	proc getInverseBlock {block} {
		
		foreach element $block {
			if {$element == 0} {
				lappend returnBlock 1
			} else {
				lappend returnBlock 0
			}
		}

		return $returnBlock
	}


	# Searches $charSet to see if an inverse block exists
	proc inverseCharExists {block} {
		variable charSet
	
		if {[lsearch -exact -sorted $charSet [getInverseBlock $block]] >= 0} {
			return true
		} else {
			return false
		}

	}

	proc createInitialCharSet {} {
		variable blocks
		variable charSet

		# Create a list of the unique blocks
		foreach char $blocks {
			lappendUnique charSet $char
		}

		set charSet [lsort $charSet]
		calculateCharSetSize

	}

	proc removeCharSetChar {char} {
		variable charSet

		set charSetIndex [lsearch -exact -sorted $charSet $char]
		
		if {$charSetIndex != -1 } {
			set charSet [lreplace $charSet $charSetIndex $charSetIndex]
			calculateCharSetSize
		}
	}

	proc calculateCharSetSize {} {
		variable charSet
		variable charSetSize

		set inverseChars 0
		foreach char $charSet {
			if {[inverseCharExists $char]} {
				incr inverseChars
			}
		}	

		set charSetSize [expr {[llength $charSet]	- ($inverseChars/2)}]
	}


	# Get the charset into a state where it can be exported to a data file ready to be loaded by the ace
	proc finalizeCharSet {} {
		variable charSet
	
		# Remove any inverse characters
		for {set i 0} {$i < [llength $charSet]} {incr i} {
			if {[inverseCharExists [lindex $charSet $i]]} {
				removeCharSetChar [lindex $charSet $i]
			}
		}

		# Put inverse characters of the charset at the end
		foreach char $charSet {
			lappend	charSet [getInverseBlock $char]
		}
		
	}

	proc getScreenData {} {
		variable blocks
		variable charSet

		foreach block $blocks {
			lappend screenData [lsearch -exact $charSet $block]
		}


		puts "$screenData"
		return $screenData
	}

	proc getCharSetData {} {
		variable charSet
		variable blockSize
		foreach char $charSet { 
			for {set element 0} {$element < $blockSize} {incr element} {

				set column [expr {$element % 8}]

				set pixel [lindex $char $element]
				
				# Invert the pixel
				if {$pixel == 0} {
					set pixel 1
				} else {
					set pixel 0
				}
				

				if {$column == 0} {
					set bLine 0
				}
				set bLine [expr {$bLine | int(pow(2, $column) * $pixel)}]

				if {$column == 7} {
					lappend charSetData $bLine
				}
			}
		}
		return [lrange $charSetData 0 1023]
	}
	
	proc replaceBlocks {oldBlock newBlock} {
		variable blocks
		
		set oldBlockIndices [lsearch -all -exact $blocks $oldBlock]
		
	
		foreach blockIndex $oldBlockIndices {
			set blocks [lreplace $blocks $blockIndex $blockIndex $newBlock]  
		}
	
	}

	proc reduceNumBlocks {} {
		variable blocks
		variable charSet
		variable charSetSize

		createInitialCharSet

		for {set differenceCheck 1} {$charSetSize > 128} {incr differenceCheck} {
			for {set i 0} {$i < [llength $blocks]  && $charSetSize > 128 } {incr i} {
			
				if {[expr {$i % 100}] == 0} {puts "i: $i"}
				
				set currentBlock [lindex $blocks $i]
				
				set copyCharIndex [findSimilarBlock $currentBlock $differenceCheck]

				if {$copyCharIndex != -1} {
				
					set copyChar [lindex $charSet $copyCharIndex]
					removeCharSetChar $currentBlock
					replaceBlocks $currentBlock $copyChar
					
				}
			}

			puts -nonewline "AFTER: reduce - differenceCheck: $differenceCheck unique blocks: [lcountUnique $blocks] "
			puts "unique chars [lcountUnique $charSet]  charSetSize: $charSetSize"
		}	
	}

	proc displayBlocks {} {
		variable aceWidth
		variable aceHeight
		variable aceImage
		variable blocks
		variable numBlocks

		for {set b 0} {$b <	$numBlocks} {incr b} {
			set i 0
			for {set y [expr {$b / 32} * 8]} {$y < [expr {$b / 32 * 8 + 8}]} {incr y} {
				for {set x [expr {$b % 32 * 8}]} {$x < [expr {$b % 32 * 8 + 8}]} {incr x} {
					set block [lindex $blocks $b]
					if {[lindex $block $i] == 1} {
						set colour #000 
					} else {
						set colour #fff 
					}

					$aceImage put $colour -to $x $y

					incr i
				}
			}
		}
	}
}


