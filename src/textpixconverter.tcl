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
	variable originalImage
	variable workingImage
	
	variable horizontalChars
	variable verticalChars
	variable charSetSize
	variable aceInverseMode

	variable originalBlocks
	variable workingBlocks
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
		variable originalBlocks
		variable workingBlocks
		variable blockDiameter
		variable originalImage
		variable workingImage
		
		set originalBlocks [list]
		set workingBlocks [list]

		set originalImage [::TextPixPreprocessor::preprocess $filename $pixelWidth $pixelHeight]
		set workingImage [image create photo]
		$workingImage copy $originalImage

		for {set y 0} {$y < $pixelHeight} {incr y $blockDiameter} {
			for {set x 0} {$x < $pixelWidth} {incr x $blockDiameter} {
				set block [getBlock $x $y]
				lappend originalBlocks $block			
				lappend workingBlocks $block
			}
		}		


		puts "[lcountUnique $workingBlocks] unique workingBlocks."


	}
	

	proc getPixel {x y} {
		variable workingImage
		set colourList [$workingImage get $x $y]
	
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

	
	# Count the number of black pixels in each sixteenth
	proc blockSixteenth {block sixteenth} {
		# TODO: Tidy up these formulae
		set startY [expr {int(($sixteenth / 4)*2)}]
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

		set foundChars [list]
		dict for {char freq} $charSet {
			if {$char != $compareChar && [blockSixteenthDifference $char $compareChar] == $difference} {
				lappend foundChars $char  
			}
		}
	
		return $foundChars
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

		if {[llength $foundChars] == 0} {
			return -1
		}
		
		puts "number of foundChars: [llength $foundChars]"

		# Find the nearest chars in terms of charDistance
		set lowestCharDistance [expr {$blockSize * 8}]
		foreach char $foundChars {
			set tempCharDistance [charDistance $char $compareChar]
			if {$tempCharDistance == $lowestCharDistance} {
				lappend nearestCharDistanceChars $char
			} elseif {$tempCharDistance < $lowestCharDistance} {
				set lowestCharDistance $tempCharDistance
				set nearestCharDistanceChars [list $char]
			}
		}
		
		puts "findSimilarBlock() - length of \$nearestCharDistanceChars: [llength $nearestCharDistanceChars]"
		
		# Pick one of these chars at random.  The reason for this is to try and stop certain characters being repeated too much.
		set lengthNearestCharDistanceChars [llength $nearestCharDistanceChars]
		set nearestChar [lindex $nearestCharDistanceChars [expr {int(rand() * ($lengthNearestCharDistanceChars-1))}]]
		
		return $nearestChar
	}	




	proc createInitialCharSet {} {
		variable workingBlocks
		variable charSet
		
		set charSet [dict create]

		# Create a list of the unique blocks
		foreach char $workingBlocks {
			set freq [llength [lsearch -all -exact $workingBlocks $char]]
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
		variable workingBlocks
		variable plainCharSet
		variable aceInverseMode

		foreach block $workingBlocks {
			set charSetIndex [lsearch -exact $plainCharSet $block]
			
			if {$aceInverseMode && $charSetIndex == -1} {
				set charSetIndex [lsearch -exact $plainCharSet [getInverseChar $block]]
				incr charSetIndex 128
			}
			
			lappend screenData $charSetIndex
		}


		puts "$screenData"
		return $screenData
	}

	proc getCharSetData {} {
		variable plainCharSet
		variable blockSize
		
		foreach char $plainCharSet { 
			set inverseChar [getInverseChar $char]
			for {set pixelIndex 0} {$pixelIndex < $blockSize} {incr pixelIndex} {
				set columnNum [expr {$pixelIndex % 8}]
				
				set pixel [lindex $inverseChar $pixelIndex]
				
				if {$columnNum == 0} {
					set binaryLine 0
				}
				
				set binaryLine [expr {$binaryLine | int(pow(2, (7-$columnNum)) * $pixel)}]

				if {$columnNum == 7} {
					lappend charSetData $binaryLine
				}

				
			}			
			
		}
		
		
		return $charSetData
	}
	
	proc replaceBlocks {oldBlock newBlock} {
		variable workingBlocks
		
		set oldBlockIndices [lsearch -all -exact $workingBlocks $oldBlock]
	
		foreach blockIndex $oldBlockIndices {
			lset workingBlocks $blockIndex $newBlock
		}

		# Update the chars frequency in the charset
		dict incr charSet $newBlock [llength $oldBlockIndices]		
	}


	proc reduceCharSet {} {
		variable workingBlocks
		variable numBlocks
		variable charSet
		variable charSetSize
		variable aceInverseMode

		createInitialCharSet

		for {set charFrequency 1} {$charFrequency <= $numBlocks && [dict size $charSet] > $charSetSize} {incr charFrequency} {
			for {set differenceCheck 0} {[dict size $charSet] > $charSetSize} {incr differenceCheck} {
				dict for {char freq} [dict filter $charSet value $charFrequency] {
					set copyChar [findSimilarBlock $char $differenceCheck]
		
					# NOTE: frequency is re-established in case it has changed in current loop
					if {$copyChar != -1 && [dict get $charSet $char] == $charFrequency} {
						puts "reduceNumBlocks() - found Similar Block - differenceCheck: $differenceCheck charFrequency: $charFrequency"
						removeCharSetChar $char
						replaceBlocks $char $copyChar
							
						if {[dict size $charSet] <= $charSetSize} { 
							break
						}
						puts "new charSetSize: [dict size $charSet]"
					}
				}
			}
	
			puts -nonewline "AFTER: reduce - differenceCheck: $differenceCheck unique workingBlocks: [lcountUnique $workingBlocks] "
			puts "charSetSize: [dict size $charSet]"
		}
		
		if {$aceInverseMode} {
			aceInverseAdjust
		}	
	}
	
	
	proc getInverseChar {char} {
		foreach pixel $char {
			if {$pixel == 0} {
				lappend inverseChar 1
			} else {
				lappend inverseChar 0
			}
		}
		
		return $inverseChar
	}

	# Go through the character set and return the nearest char from the inverse set to the char passed as a parameter
	proc findNearestInverseChar {compareChar} {
		variable charSet
		variable blockSize
	
	
		# Find the nearest char in terms of blockSixteenthDifference
		set lowestSixteenthDifference 16
		dict for {char freq} $charSet {
			set inverseChar [getInverseChar $char]
			set tempSixteenthDifference [blockSixteenthDifference $inverseChar $compareChar]
			if {$tempSixteenthDifference == $lowestSixteenthDifference} {
				lappend nearestSixteenthDifferenceChars $inverseChar
			} elseif {$tempSixteenthDifference < $lowestSixteenthDifference} {
				set lowestSixteenthDifference $tempSixteenthDifference
				set nearestSixteenthDifferenceChars [list $inverseChar]
			} 
		}

	
		# Find the nearest chars in terms of charDistance
		set lowestCharDistance [expr {8 * $blockSize}]
		set nearestCharDistanceChars [list [lindex $nearestSixteenthDifferenceChars 0]]
		foreach char $nearestSixteenthDifferenceChars {
			set tempCharDistance [charDistance $inverseChar $compareChar]
			if {$tempCharDistance <= $lowestCharDistance} {
				set lowestCharDistance $tempCharDistance
				set nearestCharDistanceChar [list $char]
			}
		}

		# Pick one of these chars at random.  The reason for this is to try and stop certain characters being repeated too much.
		set lengthNearestCharDistanceChars [llength $nearestCharDistanceChars]
		set nearestChar [lindex $nearestCharDistanceChars [expr {int(rand() * ($lengthNearestCharDistanceChars-1))}]]
	
		return $nearestChar
	
	}
	
	
	# Get characters in the character set that have the inverse in the character set.
	proc getInverseCharDuplicates {} {
		variable charSet
		
		set inverseDuplicateChars [list]
		
		dict for {char freq} $charSet {
			set inverseChar [getInverseChar $char]
			if {[dict exists $charSet $inverseChar] && [lsearch -exact $inverseDuplicateChars $inverseChar] == -1 && [lsearch -exact $inverseDuplicateChars $char] == -1} {
				lappend inverseDuplicateChars $char
			}
		}
		
		return $inverseDuplicateChars
	}

	
	# Replaces a character in the character set
	# NOTE: This sets its frequency to 1
	proc replaceCharSetChar {oldChar newChar} {
		variable charSet
		
		dict unset charSet $oldChar
		dict set charSet $newChar 1
	}
	
	
	# Go back over the image and see if any of the inverse characters from the character set are a better match
	proc aceInverseAdjust {} {
		variable numBlocks
		variable originalBlocks
		variable workingBlocks

		set replacementChars [list]
		set inverseDuplicates [getInverseCharDuplicates]
		for {set differenceCheck 16} {$differenceCheck >= 0 && [llength $inverseDuplicates] > 0} {incr differenceCheck -1} {
			for {set b 0} {$b < $numBlocks && [llength $inverseDuplicates] > 0} {incr b} {
				set workingBlockChar [lindex $workingBlocks $b]
				set originalBlockChar [lindex $originalBlocks $b]
					
				if {[blockSixteenthDifference $workingBlockChar $originalBlockChar] == $differenceCheck} {
					replaceBlocks $workingBlockChar $originalBlockChar
					replaceCharSetChar [lindex $inverseDuplicates 0] $originalBlockChar
					set inverseDuplicates [lrange $inverseDuplicates 1 end]
				}
			}
		
		}
		

		# TODO: Sort out the variable names below.  E.g. sixteenth vs charDistance
		for {set b 0} {$b < $numBlocks} {incr b} {
			puts "b: $b"
			set workingBlockChar [lindex $workingBlocks $b]
			set originalBlockChar [lindex $originalBlocks $b]
			set nearestInverseChar [findNearestInverseChar $workingBlockChar]
			set charDistanceToInverseChar [blockSixteenthDifference $nearestInverseChar $originalBlockChar]
			set charDistanceToCurrentChar [blockSixteenthDifference $workingBlockChar $originalBlockChar]
			if {$charDistanceToInverseChar < $charDistanceToCurrentChar} {
				lset workingBlocks $b $nearestInverseChar
				puts "found nearer InverseChar - b:$b"
			}			
		}
	}	

	
	proc displayBlocks {} {
		variable pixelWidth
		variable pixelHeight
		variable workingImage
		variable horizontalChars
		variable workingBlocks
		variable numBlocks

		for {set b 0} {$b <	$numBlocks} {incr b} {
			set i 0
			for {set y [expr {$b / $horizontalChars} * 8]} {$y < [expr {$b / $horizontalChars * 8 + 8}]} {incr y} {
				for {set x [expr {$b % $horizontalChars * 8}]} {$x < [expr {$b % $horizontalChars * 8 + 8}]} {incr x} {
					set block [lindex $workingBlocks $b]
					if {[lindex $block $i] == 1} {
						set colour #000 
					} else {
						set colour #fff 
					}

					$workingImage put $colour -to $x $y

					incr i
				}
			}
		}
	}
}


