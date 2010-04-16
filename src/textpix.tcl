#!/usr/bin/wish
#############################################################
# File:		textpix.tcl
# Author:	Lawrence Woodman
# Created:	24th March 2010
#------------------------------------------------------------
# Program to convert pictures into a character set and text
# screen data using references to that character set.
#------------------------------------------------------------
# Requires:
# * For debian make sure that libtk-img package is present.
# * ImageMagick must be installed.
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
source acebinfilehandler.tcl

proc saveByteFile {} {
	::TextPixConverter::calcPlainCharSet
	set charSetData [::TextPixConverter::getCharSetData]	
	set screenData [::TextPixConverter::getScreenData]

	::AceBinFileHandler::writeFile "screen" $screenData
	::AceBinFileHandler::writeFile "charset" $charSetData
}

proc savePNGfile {} {
	$::TextPixConverter::aceImage write textpix.png -format PNG
}

proc reduce {} {
	global filename
	global originalImage	
	global reducedImage
	global charWidth
	global charHeight
	global charSetSize
	
	::TextPixConverter::init $charWidth $charHeight $charSetSize true
	
	::TextPixConverter::convertToBlocks $filename
	$originalImage copy $::TextPixConverter::aceImage	
	
	::TextPixConverter::reduceNumBlocks
	::TextPixConverter::displayBlocks	
	$reducedImage copy $::TextPixConverter::aceImage
}


proc openFile {} {
	global filename
	global originalImage
	
	set filename [tk_getOpenFile -filetypes {{PNG .png} {JPEG .jpg} {All .*}}]
}



#---------------------------
# Set up the user interface
#---------------------------
menu .mbar
. configure -menu .mbar
.mbar add cascade -label File -menu .mbar.file -underline 0

menu .mbar.file
.mbar.file add command -label "Open file to convert" -command openFile -underline 0
.mbar.file add command -label "Quit" -command exit -underline 0

frame .buttons
frame .pix

label .labelCharWidth -text "Character width:"
label .labelCharHeight -text "Character height:"
label .labelCharSetSize -text "Character set size:"

# Set default values for the spinboxes.  These are the normal settings for the Jupiter ace.
set charWidth 32
set charHeight 24
set charSetSize 128

spinbox .charWidth -width 2 -relief sunken -bd 2 -textvariable charWidth -from 5 -to 40 -increment 1 -state normal
spinbox .charHeight -width 2 -relief sunken -bd 2 -textvariable charHeight -from 5 -to 25 -increment 1 -state normal
spinbox .charSetSize -width 3 -relief sunken -bd 2 -textvariable charSetSize -from 5 -to 256 -increment 1 -state normal

ttk::button .reduce -text Reduce -command reduce
ttk::button .savepng -text "Save .PNG" -command savePNGfile
ttk::button .saveace -text "Save ace.byt" -command saveByteFile

set originalImage [image create photo]
set reducedImage [image create photo]

label .labelOriginalImage -text "Original Image in 2 Colours"
label .labelReducedImage -text "Reduced Image"
label .originalImage -image $originalImage -text "Original 2 Colour Image"
label .reducedImage -image $reducedImage

pack .reduce .savepng .saveace .labelCharWidth .charWidth .labelCharHeight .charHeight .labelCharSetSize .charSetSize -in .buttons -side left
grid .originalImage .reducedImage -row 1 -in .pix
grid .labelOriginalImage .labelReducedImage -row 2 -in .pix

grid .buttons -row 1
grid .pix -row 2

