# For debian make sure that libtk-img package is present.
# Ensure that ImageMagick is installed.
package require Img

# The Ace's screen size (256x192)
set aceWidth 256
set aceHeight 192

proc scaleImage {filename percent} {
	exec convert $filename -resize $percent% -type Grayscale -posterize 2 $filename
}

# Expand the image to the size of the Ace's screen size 
proc expand2Ace {image {backgroundColour white}} {
	global aceWidth
	global aceHeight

	set imageWidth [image width $image]
	set imageHeight [image height $image]

	if {$imageWidth < $aceWidth || $imageHeight < $aceHeight} {
		set tempImage [image create photo -width $aceWidth -height $aceHeight]
		
		set xOffset [expr {int(floor(($aceWidth - $imageWidth)/2))}]
		set yOffset [expr {int(floor(($aceHeight - $imageHeight)/2))}]

		colourBackground $tempImage $backgroundColour
		$tempImage copy $image -from 0 0 -to $xOffset $yOffset
		$image blank 
		$image copy $tempImage
		image delete $tempImage
	}	
}


proc colourBackground {image backgroundColour} {
	global aceWidth
	global aceHeight

	if {$backgroundColour == "white"} {
		set putColour #fff
	} else {
		set putColour #000
	}

	$image put $putColour -to 0 0 $aceWidth $aceHeight	
}


proc scalePercent {filename} {
	global aceWidth
	global aceHeight

	set aceImage [image create photo  -file $filename]

	set imageWidth [image width $aceImage]
	set imageHeight [image height $aceImage]

	set percent [expr {1.0 * $aceWidth / $imageWidth}]

	if {[expr {$percent * $imageHeight}] > $aceHeight} {
		set percent [expr {1.0 * $percent * ($aceHeight / ($imageHeight * $percent))}]
	}


	set percent [expr {$percent * 100}]
	image delete $aceImage

	return $percent
}

proc scale2Ace {filename} {
	set percent [scalePercent $filename]
	scaleImage $filename $percent	
}

proc getPixel {image x y} {
	set colourList [$image get $x $y]

	set blackList [list 255 255 255]

	if {$colourList == $blackList} {
		return 0
	} else {
		return 1
	}
}

proc getBlock {image blockX blockY} {
	for {set y 0} {$y < 8} {incr y} {
		for {set x 0} {$x < 8} {incr x} {
			lappend block [getPixel $image [expr {$blockX+$x}] [expr {$blockY+$y}]]
		}
	}

	return $block
}

# Append a value to a list if the value doesn't already exist
proc lappendUnique {list value} {
	upvar $list l

	if {![info exists l] || [lsearch $l $value] < 0} {
		lappend l $value
	}
}

proc getAllBlocks {image} {
	global aceWidth
	global aceHeight

	for {set y 0} {$y < $aceHeight} {incr y 8} {
		for {set x 0} {$x < $aceWidth} {incr x 8} {
			lappendUnique blocks [getBlock $image $x $y]
		}
	}

	return $blocks
}


set filename martin_the_gorilla.jpg
# TODO: Sort this out as it could overwrite a file that may be needed
exec convert $filename tmp.$filename.png

set filename "tmp.$filename.png"
scale2Ace $filename

set aceImage [image create photo  -file $filename]
expand2Ace $aceImage

# Convert the image to black and white
$aceImage configure -palette 2

$aceImage write test.png -format PNG

set blocks [getAllBlocks $aceImage]

puts "blocks: $blocks"

# TODO: Now need to find how many blocks are 1 pixel different from another, then 2 pixels, until we have a low enough number

label .img -image $aceImage -anchor center
grid .img
