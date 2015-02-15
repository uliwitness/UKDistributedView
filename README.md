What is it
----------

UKDistributedView is an NSTableView-like class that displays a list of items in a Finder-style "icon view" as icons that can be freely moved around. Note that while this view's appearance aims to track the current Mac OS X releases, the model for this view's behaviour is mostly the MacOS 9 Finder, and not the slightly broken implementation of MacOS X 10.2.

Like an NSTableColumn, UKDistributedView uses an NSCell subclass to perform the actual display of the data. You can specify what kind of cell is to be used.

How do I use it?
----------------

I've tried to model UKDistributedView close to NSTableView. There is a delegate, a data source, and a numberOfItemsInDistributedView: method. To provide the data for your items, implement

	distributedView:positionForCell:atItemIndex:

and assign the desired values to the NSCell (the kind of which you can change using setPrototype: - a Finder-icon-like cell class is included).

The header and implementation files are pretty decently commented and should give you all the clues you need after reading through the example application's source code. Familiarity with NSTableView and co. is definitely helpful.


License
-------

	Copyright 2003-2014 by Uli Kusterer.
	
	This software is provided 'as-is', without any express or implied
	warranty. In no event will the authors be held liable for any damages
	arising from the use of this software.
	
	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:
	
	   1. The origin of this software must not be misrepresented; you must not
	   claim that you wrote the original software. If you use this software
	   in a product, an acknowledgment in the product documentation would be
	   appreciated but is not required.
	
	   2. Altered source versions must be plainly marked as such, and must not be
	   misrepresented as being the original software.
	
	   3. This notice may not be removed or altered from any source
	   distribution.
