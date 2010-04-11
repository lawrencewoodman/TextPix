#!/usr/bin/wish
#############################################################
# File:		charpix.tcl
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
source charpixconverter.tcl
source acebinfilehandler.tcl

proc saveByteFile {} {
	::CharPixConverter::calcPlainCharSet
	set charSetData [::CharPixConverter::getCharSetData]	
	set screenData [::CharPixConverter::getScreenData]

	::AceBinFileHandler::writeFile "screen" $screenData
	::AceBinFileHandler::writeFile "charset" $charSetData
}

proc savePNGfile {} {
	$::CharPixConverter::aceImage write charpix.png -format PNG
}

proc reduce {} {
	global reducedImage
	::CharPixConverter::reduceNumBlocks
	::CharPixConverter::displayBlocks	
	$reducedImage copy $::CharPixConverter::aceImage
}


proc openFile {} {
	global filename
	global originalImage
	
	set filename [tk_getOpenFile -filetypes {{PNG .png} {JPEG .jpg} {All .*}}]
	::CharPixConverter::convertToBlocks $filename
	$originalImage copy $::CharPixConverter::aceImage	
}

menu .mbar
. configure -menu .mbar
.mbar add cascade -label File -menu .mbar.file -underline 0

menu .mbar.file
.mbar.file add command -label "Open file to convert" -command openFile -underline 0
.mbar.file add command -label "Quit" -command exit -underline 0


#::CharPixConverter::init 32 24 128 true
::CharPixConverter::init 40 24 256 false

frame .buttons
frame .pix

ttk::button .reduce -text Reduce -command reduce
ttk::button .savepng -text "Save .PNG" -command savePNGfile
ttk::button .saveace -text "Save ace.byt" -command saveByteFile

set originalImage [image create photo]
set reducedImage [image create photo]

label .originalImage -image $originalImage
label .reducedImage -image $reducedImage

pack .reduce .savepng .saveace -in .buttons -side left
pack .originalImage .reducedImage -in .pix

pack .buttons -side top -fill x 
pack .pix -side bottom -fill x

