TextPix
=======
TextPix takes an image and converts it into a redefined character set and text screen data.

History
-------
The program came about because I wanted to be able to load images on the Jupiter Ace, but the Ace has no way of allowing you to control individual pixels on the screen.  The best that you can do is redefine the character set and then use those redefined characters to display your image.  This does however present a problem as the Ace only allows you 128 characters plus their inverse in the character set.  Since the screen contains 32x24=768 characters, there would have to be massive repetition in the image to be able to use only 128 characters plus their inverse to display the image.  TextPix therefore tries to find similar sections of the images to replace other similar sections so that the number of characters needed in the character set can be brought down to 128.

Since first writing the program, I have decided to make it more generic so that it will work on other machines.  The ultimate aim of doing this on other computers is that it would allow small movies to be displayed by just displaying text with a redefined character set. 

Status
------
The program is in very early development at the moment and isn't ready for casual users.  In particular it should be noted that when creating a number of files it doesn't check to see if they already exist.  The program also only creates output files for the Jupiter Ace currently.  While TextPix is fully functional and will convert an image into a format so that it can be displayed on the Jupiter Ace, it is very slow; on my machine it can take up to 4 minutes to process one image!

Links
-----
*	[The TextPix Project Homepage](http://techtinkering.com/projects/textpix)
*	[TextPix Repository on GitHub](http://github.com/LawrenceWoodman/TextPix)
*	[TextPix Development Mailing List](http://www.freelists.org/list/textpix-dev)

Running
-------
To run TextPix, for the moment, go into the 'src' sub-directory and run:  
`$ wish textpix.tcl`

Load a file through the 'File->Open File To Convert' menu option then click on 'Reduce'.  This will probably take a long time at the moment.  Once it is done it will display the new image and you can click on 'Save ace.byt'.  This will create two files: charset.byt and screen.byt.

If you are using a Jupiter Ace emulator such as xace, you can put these in a directory where xace can find them and then start the emulator.  Within this type the following to load the image:  
`10240 1024 bload charset 8192 768 bload screen`

Developers
----------
If you are interested in contributing to TextPix, please look at the links above and join the dev mailing list.  It would be great to have you aboard.

License
-------
This software is licensed under a 2 clause BSD license.  Please see the file, LICENSE, for details.

