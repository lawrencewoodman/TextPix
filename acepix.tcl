#############################################################
# File:		acepix.tcl
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
source acepixconverter.tcl
source acebinfilehandler.tcl

proc saveByteFile {} {
	::AcePixConverter::finalizeCharSet
	set charSetData [::AcePixConverter::getCharSetData]	
	set screenData [::AcePixConverter::getScreenData]

	::aceBinFileHandler::writeFile "screen" $screenData
	::aceBinFileHandler::writeFile "charset" $charSetData
}

proc savePNGfile {} {
	$::AcePixConverter::aceImage write $::AcePixConverter::tempFilename -format PNG
}


set filename martin_the_gorilla.jpg
#set filename isaac2.jpg		;# Note the white background on this
#set filename isaac.jpg
#set filename cimg1446.jpg

::AcePixConverter::convertToBlocks $filename

ttk::button .reduce -text Reduce -command ::AcePixConverter::reduceNumBlocks
ttk::button .refresh -text Refresh -command ::AcePixConverter::displayBlocks
ttk::button .savepng -text "Save .PNG" -command savePNGfile
ttk::button .saveace -text "Save ace.byt" -command saveByteFile

set originalImage [image create photo]
$originalImage copy $::AcePixConverter::aceImage
label .originalImage -image $originalImage
label .aceImage -image $::AcePixConverter::aceImage

grid .reduce .refresh .savepng .saveace .originalImage .aceImage	


