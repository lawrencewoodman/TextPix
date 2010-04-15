#############################################################
# File:		textpixconverter.tcl
# Author:	Lawrence Woodman
# Created:	31st March 2010
#------------------------------------------------------------
# Functions to convert pictures into a character set and text
# screen data using references to that character set.
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
package require Img
source textpixpreprocessor.tcl



# Append a value to a list if the value doesn't already exist
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


namespace eval TextPixConverter {
	variable pixelWidth
	variable pixelHeight
	variable aceImage
	
	variable horizontalChars
	variable verticalChars
	variable charSetSize
	variable aceInverseMode

	variable blocks
	variable numBlocks 
	variable blockDiameter 8
	variable blockSize 64					;# The number of pixels in a block

	variable charSet						;# Dictionary with the char as the key and the frequency as the value
	variable plainCharSet					;# $charSet as a plain list without any frequency data
	
	
	proc init {pHorizontalChars pVerticalChars pCharSetSize pAceInverseMode} {
		variable horizontalChars $pHorizontalChars
		variable verticalChars $pVerticalChars
		variable charSetSize $pCharSetSize
		variable aceInverseMode $pAceInverseMode
		variable pixelWidth [expr {$horizontalChars * 8}]
		variable pixelHeight [expr {$verticalChars * 8}]
		variable numBlocks [expr {$horizontalChars * $verticalChars}]
	}

	proc convertToBlocks {filename} {
		variable pixelWidth
		variable pixelHeight
		variable blocks
		variable blockDiameter
		variable aceImage

		set aceImage [::TextPixPreprocessor::preprocess $filename $pixelWidth $pixelHeight]

		for {set y 0} {$y < $pixelHeight} {incr y $blockDiameter} {
			for {set x 0} {$x < $pixelWidth} {incr x $blockDiameter} {
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
	
	
	proc dictFilter_charDifference {char compareChar difference} {
		if {$char != $compareChar && [blockSixteenthDifference $char $compareChar] == $difference} {  
			return true
		} else {
			return false		
		}
	}


	# Find all the blocks with the given difference
	proc findBlocksWithDifference {compareChar difference} {
		variable charSet 

		return [dict filter $charSet script {char freq} {dictFilter_charDifference $char $compareChar $difference}]
	
	}


	proc getCharPixel {char x y} {
		return [lindex $char [expr {($y * 8)+$x}]]
	}

	# Returns whether there is a matching pixel at the specified distance
	proc matchingPixelAtDistance {char xCentre yCentre distance pixel} {
		set xStart [expr {max(0, ($xCentre-$distance))}]
		set yStart [expr {max(0, ($yCentre-$distance))}]
		set xEnd [expr {min(7, ($xCentre+$distance))}]
		set yEnd [expr {min(7, ($yCentre+$distance))}]
		
		# Check top horizontal side
		for {set x $xStart} {$x <= $xEnd} {incr x} {
			if {!($distance >= 1 && $x == $xCentre && $yStart == $yCentre) && [getCharPixel $char $x $yStart] == $pixel} {
				return true
			}
		}
		
		# Check vertical sides
		# NOTE: I know that four of the pixels will be checked twice above and below, 
		#		but this is quicker than recalculating and checking new boundaries
		for {set y $yStart} {$y <= $yStart} {incr y} {
			if {!($distance >= 1 && $xStart == $xCentre && $y == $yCentre) && [getCharPixel $char $xStart $y] == $pixel} {
				return true
			}
			
			if {!($distance >= 1 && $xEnd == $xCentre && $y == $yCentre) && [getCharPixel $char $xEnd $y] == $pixel} {
				return true
			}
			
		}
		
		
		# Check bottom horizontal side
		for {set x $xStart} {$x <= $xEnd} {incr x} {
			if {!($distance >= 1 && $x == $xCentre && $yEnd == $yCentre) && [getCharPixel $char $x $yEnd] == $pixel} {
				return true
			}
		}
		
		return false
	}
	
	# Returns the distance to the nearest matching pixel or 8 if none found
	proc distanceToPixel {char x y pixel} {
		for {set distance 0} {$distance <= 7} {incr distance} {
			if {[matchingPixelAtDistance $char $x $y $distance $pixel]} {
				return $distance
			}
		}
		
		return 8	;# Chose 8 because this is outside the char boundary
	}
	
	# Calculates the distance between two characters by adding the distance of each non-matching pixel to its nearest matching pixel
	proc charDistance {char1 char2} {
		set distance 0
	
		for {set y 0} {$y < 8} {incr y} {	
			for {set x 0} {$x < 8} {incr x} {
				# NOTE: The distance is checked both way rounds because they can be different
				set pixelDistance1 [distanceToPixel $char1 $x $y [getCharPixel $char2 $x $y]]
				set pixelDistance2 [distanceToPixel $char2 $x $y [getCharPixel $char1 $x $y]]
				incr distance [expr {max ($pixelDistance1, $pixelDistance2)}]
			}
		} 
		
		
		return $distance		
	}

	
	# Returns the index to the nearest block with the specified difference from the block passed. 
	# If it can't find a block then it returns -1
	# TODO: Improve this so that it tries to find a block near the centre of the picture
	proc findSimilarBlock {compareChar difference} {
		variable charSet
		variable blockSize

		set foundChars [findBlocksWithDifference $compareChar $difference]

		if {[dict size $foundChars] == 0} {
			return -1
		}
		
		puts "number of foundChars: [dict size $foundChars]"		

		# Find the nearest chars in terms of charDistance
		set lowestCharDistance $blockSize
		set nearestCharDistanceChars [list [lindex $foundChars 0]]
		dict for {char freq} $foundChars {
			set tempCharDistance [charDistance $char $compareChar]
			if {$tempCharDistance == $lowestCharDistance} {
				lappend nearestCharDistanceChars $char
			} elseif {$tempCharDistance < $lowestCharDistance} {
				set lowestCharDistance $tempCharDistance
				set nearestCharDistanceChars [list $char]
			}
		}
		
		puts "findSimilarBlock() - length of \$nearestCharDistanceChars: [llength $nearestCharDistanceChars]"
		
		# Find the nearest block in terms of matching pixels
		set lowestPixelMatchingDifference $blockSize
		set nearestChar [lindex $nearestCharDistanceChars 0]
		
		foreach char $nearestCharDistanceChars {
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
		
		
		return $charSetData
	}
	
	proc replaceBlocks {oldBlock newBlock} {
		variable blocks
		
		set oldBlockIndices [lsearch -all -exact $blocks $oldBlock]
	
		foreach blockIndex $oldBlockIndices {
			lset blocks $blockIndex $newBlock
		}

		# Update the chars frequency in the charset
		dict incr charSet $newBlock [llength $oldBlockIndices]		
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
		variable charSetSize

		createInitialCharSet

		for {set differenceCheck 0} {[dict size $charSet] > $charSetSize} {incr differenceCheck} {
			for {set charFrequency 1} {$charFrequency <= $numBlocks && [dict size $charSet] > $charSetSize} {incr charFrequency} {
				dict for {char freq} [dict filter $charSet value $charFrequency] {
#					puts "differenceCheck: $differenceCheck charFrequency: $charFrequency"
					set copyChar [findSimilarBlock $char $differenceCheck]
		
					if {$copyChar != -1} {
						puts "reduceNumBlocks() - found Similar Block - freq: $freq"
						removeCharSetChar $char
						replaceBlocks $char $copyChar
							
						if {[dict size $charSet] <= $charSetSize} { 
							break
						}
						puts "new charSetSize: [dict size $charSet]"
					}
				}
			}
	
			puts -nonewline "AFTER: reduce - differenceCheck: $differenceCheck unique blocks: [lcountUnique $blocks] "
			puts "charSetSize: [dict size $charSet]"
		}	
	}	

	
	proc displayBlocks {} {
		variable pixelWidth
		variable pixelHeight
		variable aceImage
		variable horizontalChars
		variable blocks
		variable numBlocks

		for {set b 0} {$b <	$numBlocks} {incr b} {
			set i 0
			for {set y [expr {$b / $horizontalChars} * 8]} {$y < [expr {$b / $horizontalChars * 8 + 8}]} {incr y} {
				for {set x [expr {$b % $horizontalChars * 8}]} {$x < [expr {$b % $horizontalChars * 8 + 8}]} {incr x} {
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


