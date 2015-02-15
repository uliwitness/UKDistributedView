//
//  MyDistViewItem.m
//  UKDistributedView
//
//  Created by Uli Kusterer on Wed Jun 25 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//
//	This software is provided 'as-is', without any express or implied
//	warranty. In no event will the authors be held liable for any damages
//	arising from the use of this software.
//
//	Permission is granted to anyone to use this software for any purpose,
//	including commercial applications, and to alter it and redistribute it
//	freely, subject to the following restrictions:
//
//	   1. The origin of this software must not be misrepresented; you must not
//	   claim that you wrote the original software. If you use this software
//	   in a product, an acknowledgment in the product documentation would be
//	   appreciated but is not required.
//
//	   2. Altered source versions must be plainly marked as such, and must not be
//	   misrepresented as being the original software.
//
//	   3. This notice may not be removed or altered from any source
//	   distribution.
//

#import "MyDistViewItem.h"


@implementation MyDistViewItem

-(id)	initWithTitle: (NSString*)theTitle andImage: (NSImage*)img
{
	if( self = [super init] )
	{
		title = [theTitle retain];
		image = [img retain];
		position = NSMakePoint( 0,0 );
	}
	
	return self;
}

-(NSString*)	title
{
	return title;
}


-(void)	setTitle: (NSString*)theTitle
{
	[theTitle retain];
	[title release];
	title = theTitle;
}

-(NSImage*)		image
{
	return image;
}


-(void)	setImage: (NSImage*)img
{
	[img retain];
	[image release];
	image = img;
}

-(NSPoint)		position
{
	return position;
}


-(void)	setPosition: (NSPoint)pos
{
	position = pos;
}


-(NSComparisonResult)	compare: (id)toWhom
{
	return [[self title] caseInsensitiveCompare: [toWhom title]];
}


@end
