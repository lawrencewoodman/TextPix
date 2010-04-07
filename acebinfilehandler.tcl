#############################################################
# File:		acebinfilehandler.tcl
# Author:	Lawrence Woodman
# Created:	31 March 2010
#------------------------------------------------------------
# Functions for handling Jupiter Ace binary files.
#############################################################

namespace eval AceBinFileHandler {

	# data is a list
	proc writeFile {filename data} {
		# TODO: Need to catch here
		set fid [open $filename.byt w]

		chan configure $fid -translation binary

		set fileSize [llength $data]
		puts "fileSize: $fileSize"
		# Write header
		puts -nonewline $fid [binary format c3A10sA13s {0x1A 0x00 0x20} $filename $fileSize {} [expr {$fileSize+1}]]

		# Write Data
		foreach element $data {
			puts -nonewline $fid [binary format c $element]
		}

		# TODO: Need to catch here
		close $fid
	}
}