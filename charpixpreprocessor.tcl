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