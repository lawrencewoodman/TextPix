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



#TODO: replace lreplace with lset where appropriate




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

	variable charSet						;# Dictionary with the char as the key and the frequency as the value
	
	variable plainCharSet					;# charset as plain list without any frequency data

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


	
	# Count the number of black pixels in each sixteenth
	proc blockSixteenth {block sixteenth} {
		# TODO: Tidy up these formulae
		set startY [expr {int(floor(($sixteenth*2) / 8)*2)}]
		set endY [expr {$startY+1}]
		set startX [expr {($sixteenth*2) % 8}]
		set endX [expr {$startX+1}]
		
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
	

	# Check the difference in the number of pixels in each sixteenth
	proc blockSixteenthDifference {block1 block2} {

		set difference 0
		for {set i 0} {$i < 16} {incr i} {
			if {[blockSixteenth $block1 $i] != [blockSixteenth $block2 $i]} {
				incr difference
			}
		}
		
		return $difference
	}
	


	# Find all the blocks with the given difference
	proc findBlocksWithDifference {compareChar difference} {
		variable charSet 

		foreach char [dict keys $charSet] {
			if {$char != $compareChar && [blockSixteenthDifference $char $compareChar] == $difference} {
				lappend foundChars $char 
			}
		}

		if {![info exists foundChars]} {
			return -1
		}
		
		return $foundChars
	
	}


	
	# Returns the index to the nearest block with the specified difference from the block passed. 
	# If it can't find a block then it returns -1
	# TODO: Improve this so that it tries to find a block near the centre of the picture
	proc findSimilarBlock {compareChar difference} {
		variable blockSize

		set foundChars [findBlocksWithDifference $compareChar $difference]

		if {![info exists foundChars]} {
			return -1
		}
		

		set lowestPixelCountDifference $blockSize

		# Find the nearest chars in terms of pixel count
		foreach char $foundChars {
			set tempPixelCountDifference [blockPixelCountDifference $char $compareChar]
			if {$tempPixelCountDifference == $lowestPixelCountDifference} {
				lappend nearestPixelCountChars $char
			} elseif {$tempPixelCountDifference < $lowestPixelCountDifference} {
				set lowestPixelCountDifference $tempPixelCountDifference
				set nearestPixelCountChars [list $char]
			}
		}
		
		set lowestPixelMatchingDifference $blockSize
		set nearestChar [lindex $nearestPixelCountChars 0]

		# Find the nearest block in terms of matching pixels
		foreach char $nearestPixelCountChars {
			set tempPixelMatchingDifference [blockPixelMatchingDifference $char $compareChar] 
			if {$tempPixelMatchingDifference < $lowestPixelMatchingDifference} {
				set lowestPixelDifference $tempPixelMatchingDifference
				set nearestChar $char
			}
		}
		
		return $nearestChar
	}	



	proc createInitialCharSet {} {
		variable blocks
		variable charSet

		# Create a list of the unique blocks
		foreach char $blocks {
			set freq [llength [lsearch -all -exact $blocks $char]]
			dict set charSet $char $freq
		}
	}
	

	proc removeCharSetChar {char} {
		variable charSet

		dict unset charSet $char
	}

	# Get the charset into a state where it can be exported to a data file ready to be loaded by the ace
	proc calcPlainCharSet {} {
		variable charSet
		variable plainCharSet
		
		set plainCharSet [list] 

		dict for {char freq} $charSet {
			lappend plainCharSet $char
		}
		
		
	}

	proc getScreenData {} {
		variable blocks
		variable plainCharSet

		foreach block $blocks {
			lappend screenData [lsearch -exact $plainCharSet $block]
		}


		puts "$screenData"
		return $screenData
	}

	proc getCharSetData {} {
		variable plainCharSet
		variable blockSize
		
		foreach char $plainCharSet { 
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
				set bLine [expr {$bLine | int(pow(2, (7-$column)) * $pixel)}]

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
			#lset blocks $blockIndex $newBlock]
			set blocks [lreplace $blocks $blockIndex $blockIndex $newBlock]  
		}

		# Update the chars frequency in the charset
		# TODO: Calculate this rather than using lsearch		
		set freq [llength [lsearch -all -exact $blocks $newBlock]]
		dict set charSet $newBlock $freq

	
	}


	proc dictFilter_notAlreadyProcessedChar {fChar fFreq alreadyProcessedChars charFrequency} {
	
		if {[lsearch -exact $alreadyProcessedChars $fChar] != -1} {
			return false
		}
		
		if {$fFreq != $charFrequency} {
			return false
		} 
		
		return true
	}

	proc reduceNumBlocks {} {
		variable blocks
		variable numBlocks
		variable charSet

		createInitialCharSet

		for {set differenceCheck 0} {[dict size $charSet] > 128} {incr differenceCheck} {
			for {set charFrequency 1} {$charFrequency <= $numBlocks && [dict size $charSet] > 128} {incr charFrequency} {
				set alreadyProcessedChars [list]			
				set checkFreq true
				while {$checkFreq} {
					set checkFreq false
					
					set i 0		;# DEBUG: Get rid of this once all ok
					dict for {char freq} [dict filter $charSet script {fChar fFreq} {dictFilter_notAlreadyProcessedChar $fChar $fFreq $alreadyProcessedChars $charFrequency}] {
						lappend alreadyProcessedChars $char
						incr i	;# DEBUG: Get rid of this once all ok
						
						set copyChar [findSimilarBlock $char $differenceCheck]
		
						if {$copyChar != -1} {
							puts "reduceNumBlocks() - found Similar Block - i: $i, charFrequency: $charFrequency"
							removeCharSetChar $char
							replaceBlocks $char $copyChar
							
							if {[dict size $charSet] <= 128} { 
								break
							}
							
							set checkFreq true
							break
						}
					}
				}
			}
	
			puts -nonewline "AFTER: reduce - differenceCheck: $differenceCheck unique blocks: [lcountUnique $blocks] "
			puts "charSetSize: [dict size $charSet]"
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


