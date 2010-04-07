#############################################################
# File:		charpix.tcl
# Author:	Lawrence Woodman
# Created:	24th March 2010
#------------------------------------------------------------
# Program to convert pictures into a form that can be
# loaded by the Jupiter Ace.
#------------------------------------------------------------
# Requires:
# * For debian make sure that libtk-img package is present.
# * ImageMagick must be installed.
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


set filename martin_the_gorilla.jpg
#set filename isaac2.jpg		;# Note the white background on this
#set filename isaac.jpg
#set filename cimg1446.jpg


::CharPixConverter::init 32 24 128 true

::CharPixConverter::convertToBlocks $filename

ttk::button .reduce -text Reduce -command ::CharPixConverter::reduceNumBlocks
ttk::button .refresh -text Refresh -command ::CharPixConverter::displayBlocks
ttk::button .savepng -text "Save .PNG" -command savePNGfile
ttk::button .saveace -text "Save ace.byt" -command saveByteFile

set originalImage [image create photo]
$originalImage copy $::CharPixConverter::aceImage
label .originalImage -image $originalImage
label .aceImage -image $::CharPixConverter::aceImage

grid .reduce .refresh .savepng .saveace .originalImage .aceImage	


