#############################################################
# File:		charpixpreprocessor.tcl
# Author:	Lawrence Woodman
# Created:	31 March 2010
#------------------------------------------------------------
# Functions for preprocessing a picture e.g. scaling it to 
# the right size and dithering the number of colours down to 
# two.
#------------------------------------------------------------
# Requires:
# * For debian make sure that libtk-img package is present.
# * ImageMagick must be installed.
#------------------------------------------------------------
# TODO:
# * Consider upping the contrast before converting the image.
#############################################################
package require Img

namespace eval CharPixPreprocessor {
	variable newWidth 
	variable newHeight 
	variable tempFilename 
	variable workingImage


	proc preprocess {filename pNewWidth pNewHeight {background white}} {
		variable newWidth $pNewWidth
		variable newHeight $pNewHeight
		variable tempFilename
		variable workingImage	
		
		createTemporaryFile $filename
		
		scaleImage [scalePercent]

		set workingImage [image create photo  -file $tempFilename]
		expand2NewSize $background
		deleteTemporaryFile
		
		return $workingImage
	}

	# TODO: Sort this out as it could overwrite a file that may be needed	
	proc createTemporaryFile {filename} {
		variable tempFilename [file join [file dirname $filename] tmp.[file tail $filename].png]

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

	# Expand the image to the size of the new image 
	proc expand2NewSize {{backgroundColour white}} {
		variable newWidth
		variable newHeight
		variable workingImage

		set imageWidth [image width $workingImage]
		set imageHeight [image height $workingImage]

		if {$imageWidth < $newWidth || $imageHeight < $newHeight} {
			set tempImage [image create photo -width $newWidth -height $newHeight]
		
			set xOffset [expr {int(floor(($newWidth - $imageWidth)/2))}]
			set yOffset [expr {int(floor(($newHeight - $imageHeight)/2))}]

			colourBackground $tempImage $backgroundColour
			$tempImage copy $workingImage -from 0 0 -to $xOffset $yOffset
			$workingImage copy $tempImage
			image delete $tempImage
		}	
	}


	proc colourBackground { image {backgroundColour white}} {
		variable newWidth
		variable newHeight
		variable workingImage

		if {$backgroundColour == "white"} {
			set putColour #fff
		} else {
			set putColour #000
		}

		$image put $putColour -to 0 0 $newWidth $newHeight	
	}

	# Return the percent that the file needs scaling by
	proc scalePercent {} {
		variable newWidth
		variable newHeight
		variable tempFilename

		set tempImage [image create photo  -file $tempFilename]

		set imageWidth [image width $tempImage]
		set imageHeight [image height $tempImage]

		set percent [expr {1.0 * $newWidth / $imageWidth}]

		if {[expr {$percent * $imageHeight}] > $newHeight} {
			set percent [expr {1.0 * $percent * ($newHeight / ($imageHeight * $percent))}]
		}

		set percent [expr {$percent * 100}]
		image delete $tempImage


		return $percent
	}

}