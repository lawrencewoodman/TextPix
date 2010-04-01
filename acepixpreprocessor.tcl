#############################################################
# File:		acepixpreprocessor.tcl
# Author:	Lawrence Woodman
# Created:	31 March 2010
#------------------------------------------------------------
# Functions for preprocessing a picture e.g. scaling it to 
# the right size and dithering the number of colours down to 
# two.
#------------------------------------------------------------
# Requires:
# * For debian make sure that libtk-img package is present.
# * ImageMagick must be installed.#
#------------------------------------------------------------
# TODO:
# * Consider upping the contrast before converting the image.
#############################################################
package require Img

namespace eval acePixPreprocessor {
	# The Ace's screen size (256x192)
	variable aceWidth 256
	variable aceHeight 192
	variable tempFilename 
	variable aceImage


	proc preprocess {filename {background white}} {
		variable tempFilename
		variable aceImage
		
		createTemporaryFile $filename
		
		scale2Ace

		set aceImage [image create photo  -file $tempFilename]
		expand2Ace $background
		deleteTemporaryFile
		
		return $aceImage
	}

	# TODO: Sort this out as it could overwrite a file that may be needed	
	proc createTemporaryFile {filename} {
		variable tempFilename "tmp.$filename.png"

		exec convert $filename $tempFilename

	}
	
	
	proc deleteTemporaryFile {} {
		variable tempFilename
		file delete $tempFilename
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
}