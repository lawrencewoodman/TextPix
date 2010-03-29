# For debian make sure that libtk-img package is present.
# Ensure that ImageMagick is installed.
package require Img

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

	foreach element $aList {
		set indices [lsearch -all $aList $element]
		if {[llength $indices] == 1} {
			incr count
		}
	}

	return $count
}


namespace eval acepix {
	# The Ace's screen size (256x192)
	variable aceWidth 256
	variable aceHeight 192
	variable tempFilename 
	variable aceImage

	variable blocks
	variable numBlocks 768
	variable blockDiameter 8
	variable blockSize 64					;# The number of pixels in a block

	variable charSet

	namespace export add convert  
	namespace ensemble create

	proc convert {filename} {
		variable tempFilename
		variable aceImage
		variable blocks

		createTemporaryFile $filename
		
		scale2Ace

		set aceImage [image create photo  -file $tempFilename]
		expand2Ace 

		getAllBlocks

		puts "[lcountUnique $blocks] unique blocks."


	}
	
	proc createTemporaryFile {filename} {
		variable tempFilename "tmp.$filename.png"
		
		# TODO: Sort this out as it could overwrite a file that may be needed
		exec convert $filename $tempFilename

	}


	proc scaleImage {percent} {
		variable tempFilename
		exec convert $tempFilename -resize $percent% -type Grayscale -posterize 2 $tempFilename
	}

	# Expand the image to the size of the Ace's screen size 
	proc expand2Ace {{backgroundColour white}} {
		variable aceWidth
		variable aceHeight
		variable aceImage

		set imageWidth [image width $aceImage]
		set imageHeight [image height $aceImage]

		if {$imageWidth < $aceWidth || $imageHeight < $aceHeight} {
			set tempImage [image create photo -width $aceWidth -height $aceHeight]
		
			set xOffset [expr {int(floor(($aceWidth - $imageWidth)/2))}]
			set yOffset [expr {int(floor(($aceHeight - $imageHeight)/2))}]

			colourBackground $tempImage $backgroundColour
			$tempImage copy $aceImage -from 0 0 -to $xOffset $yOffset
			$aceImage copy $tempImage
			image delete $tempImage
		}	
	}


	proc colourBackground { image {backgroundColour white}} {
		variable aceWidth
		variable aceHeight
		variable aceImage

		if {$backgroundColour == "white"} {
			set putColour #fff
		} else {
			set putColour #000
		}

		$image put $putColour -to 0 0 $aceWidth $aceHeight	
	}

	# Return the percent that the file needs scaling by
	proc scalePercent {} {
		variable aceWidth
		variable aceHeight
		variable tempFilename

		set tempImage [image create photo  -file $tempFilename]

		set imageWidth [image width $tempImage]
		set imageHeight [image height $tempImage]

		set percent [expr {1.0 * $aceWidth / $imageWidth}]

		if {[expr {$percent * $imageHeight}] > $aceHeight} {
			set percent [expr {1.0 * $percent * ($aceHeight / ($imageHeight * $percent))}]
		}

		set percent [expr {$percent * 100}]
		image delete $tempImage

		return $percent
	}

	proc scale2Ace {} {
		scaleImage [scalePercent]	
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

	proc blockPixelDifference {block1 block2} {
		variable blockSize

		set difference 0

		for {set i 0} {$i <	$blockSize} {incr i} {
			if {[lindex $block1 $i] != [lindex $block2 $i]} {
				incr difference
			}
		}

		return $difference
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

	proc getAllBlocks {} {
		variable aceWidth
		variable aceHeight
		variable blocks
		variable blockDiameter

		for {set y 0} {$y < $aceHeight} {incr y $blockDiameter} {
			for {set x 0} {$x < $aceWidth} {incr x $blockDiameter} {
				lappend blocks [getBlock $x $y]
			}
		}
	}
	
	# Returns the index to the nearest block with the specified difference from the block passed. 
	# If it can't find a block then it returns -1
	# TODO: Improve this so that it tries to find a block near the centre of the picture
	proc findSimilarBlock {block quarterDifference} {
		variable blocks
		variable blockSize

		# Find all the blocks with the given difference
		for {set i 0} {$i < [llength $blocks]} {incr i} {
			if {[blockQuarterDifference [lindex $blocks $i] $block] == $quarterDifference} {
				lappend foundBlocks $i
			}
		}

		if {![info exists foundBlocks]} {
			return -1
		}

		set lowestPixelDifference $blockSize
		set nearestBlock [lindex $foundBlocks 0]

		return [lindex $foundBlocks 0]

		# Find the nearest block in terms of matching pixels
		for {set i 0} {$i < [llength $foundBlocks]} {incr i} {
			set tempPixelDifference [blockPixelDifference [lindex $blocks [lindex $foundBlocks $i]] $block] 
			if {$tempPixelDifference < $lowestPixelDifference} {
				set lowestPixelDifference $tempPixelDifference
				set nearestBlock [lindex $foundBlocks $i]
			}
		}

		return $nearestBlock
	}

	proc getInverseBlock {block} {
		
		foreach element $block {
			if {$element == 0} {
				lappend returnBlock 1
			}
				lappend returnBlock 0
			}

		return $returnBlock
	}


	# Searches $charSet to see if an inverse block exists
	proc inverseBlockExists {block} {
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
		foreach block $blocks {
			lappendUnique charSet $block
		}

		set charSet [lsort $charSet]
	}

	proc numberInCharSet {} {
		variable charSet

		set inverseBlocks 0
		foreach block $charSet {
			if {[inverseBlockExists $block]} {
				incr inverseBlocks
			}
		}	

		set numberBlocks [expr {[llength $charSet]	- ($inverseBlocks/2)}]

		return $numberBlocks

	}

	proc removeCharSetBlock {block} {
		variable charSet

		set charSetIndex [lsearch -exact -sorted $charSet $block]
		if {$charSetIndex != -1 } {
			set charSet [lreplace $charSet $charSetIndex $charSetIndex]
		}
	}

	proc reduceNumBlocks {} {
		variable blocks
		variable charSet

		createInitialCharSet

		set charSetSize [numberInCharSet]
		for {set differenceCheck 1} {$charSetSize > 128} {incr differenceCheck} {
			for {set i 0} {$i < [llength $blocks]  && $charSetSize > 128 } {incr i} {
if {[expr {$i % 100}] == 0} {puts "i: $i"}
				set copyBlockIndex [findSimilarBlock [lindex $blocks $i] $differenceCheck]

				if {$copyBlockIndex != -1} {
					removeCharSetBlock [lindex $blocks $i]
					set blocks [lreplace $blocks $i $i [lindex $blocks $copyBlockIndex]]
					set charSetSize [numberInCharSet]
				}
			}

			puts "reduce - differenceCheck: $differenceCheck unique blocks: [lcountUnique $blocks] "
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


acepix convert martin_the_gorilla.jpg

ttk::button .reduce -text Reduce -command ::acepix::reduceNumBlocks
ttk::button .refresh -text Refresh -command ::acepix::displayBlocks
ttk::button .save -text Save -command {$::acepix::aceImage write $::acepix::tempFilename -format PNG}
label .img -image $::acepix::aceImage
grid .reduce .refresh .save .img	

